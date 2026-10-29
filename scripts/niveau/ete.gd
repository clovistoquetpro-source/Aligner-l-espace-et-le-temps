extends Souvenir

## Niveau 3, en formes simples : « L'été au lac ». Thomas a 16 ans ; Juliette
## lui donne rendez-vous sur l'île au coucher du soleil. La journée se répète :
## au coucher du soleil, le peintre repeint tout, sauf ce que Thomas tient dans
## ses mains. Une règle nouvelle par journée : le premier jour, la fleur de
## Juliette apprend la boucle ; puis le tableau se finit au coucher du soleil,
## sur le ponton ; le lendemain, le peintre a repeint le pont dans le reflet.
## Le moment parfait (à l'heure, au sec, le tableau fini) est la correction du
## peintre ; le vrai soir, Thomas est arrivé à la nage.
## Voir docs/superpowers/specs/2026-10-28-direction-illusions-design.md.

enum Etat { JOURNEE, REPEINT, PARFAIT, VRAI, FIN }

const DUREE_JOUR := 120.0
## Le coucher du soleil commence ici : on peut finir le tableau, et le
## rendez-vous peut avoir lieu.
const COUCHER := 95.0
## Le coup de pinceau qui repeint la journée : il traverse l'écran, puis
## repart.
const DUREE_REPEINT := 1.2
## Le temps pour que le ciel se peigne sur le tableau, au coucher du soleil.
const PEINDRE := 4.0
## Des repères pour sentir venir le soir.
const REPERES := [[60.0, "Le soleil commence à descendre."], [80.0, "Bientôt le soir. Elle m'attend sur l'île."]]
## Le soleil descend de cette hauteur (en degrés) jusqu'à l'horizon, au
## nord-ouest, derrière l'île.
const SOLEIL_HAUT := 35.0
const SOLEIL_DIR := Vector3(-0.45, 0, -1)
## Juliette : son arrivée à mobylette, ses répliques, son départ, puis l'île.
const ARRIVEE := [3.0, 11.0]
const PAROLES := 12.0
const DEPART := 24.0
const SUR_L_ILE := 40.0
const TETE_ADO := 1.55
const VITESSE_EAU := 0.45
## Sur le pont du reflet, il faut garder les yeux vers l'eau (le regard
## descend au moins de cette pente).
const REGARD_EAU := -0.3
## Le pont et son trou (comme dans tools/constructeur_ete.gd).
const PONT_X := 4.0
const PONTON_X := -8.0
const TROU := Vector2(-14.0, -8.0)

var etat := Etat.JOURNEE
## La journée (1 : le vrai jour ; ensuite, les versions du peintre).
var journee := 1
var temps := 0.0
var tableau_fini := false
var tableau_mouille := false
## Une fois le tableau fini, le peintre repeint le pont (dans le reflet) dès
## la journée suivante.
var tableau_deja_fini := false
var pont_repeint := false
var sur_le_pont_du_reflet := false
## Le ciel du tableau, en train de se peindre (0 à 1).
var peinture := 0.0

var _dit := {}
var _ciel: ProceduralSkyMaterial
var _env: Environment

@onready var _soleil: DirectionalLight3D = $Soleil
@onready var _tableau: RigidBody3D = $Ponton/Tableau
@onready var _depart_tableau: Transform3D = $Ponton/Tableau.global_transform
@onready var _fleur: RigidBody3D = $Juliette/Fleur
@onready var _depart_fleur: Transform3D = $Juliette/Fleur.global_transform
@onready var _nage: Area3D = $Lac/Nage
@onready var _reflet: Node3D = $Pont/Reflet
@onready var _solide: CollisionShape3D = $Pont/Solide/CollisionShape3D
@onready var _mob: Node3D = $Juliette/Mobylette
@onready var _juliette: Node3D = $Juliette/Debout
@onready var _rendez_vous: Area3D = $Ile/Rendez_vous
@onready var _repeint: ColorRect = $Interface/Repeint
@onready var _fissures: Fissures = $Interface/Fissures


func _ready() -> void:
	Temps.reinitialiser()
	_joueur.camera.cull_mask &= ~Miroir.COUCHE_REFLET
	_joueur.head.position.y = TETE_ADO
	_habiller_le_joueur()
	_env = ($WorldEnvironment as WorldEnvironment).environment
	_ciel = _env.sky.sky_material as ProceduralSkyMaterial
	_chute.finie.connect(_retour_dans_la_maison_des_etoiles)
	_commencer_la_journee()
	_ouvrir_les_yeux("L'été de mes seize ans. Je peignais le lac, tout seul.")


## Le corps qu'on voit dans l'eau : Thomas à 16 ans.
func _habiller_le_joueur() -> void:
	var reflet := Node3D.new()
	reflet.name = "Reflet"
	_joueur.add_child(reflet)
	var corps := CapsuleMesh.new()
	corps.radius = 0.28
	corps.height = 1.5
	_forme_du_reflet(reflet, corps, Vector3(0, 0.75, 0), Color("457b9d"))
	var tete := SphereMesh.new()
	tete.radius = 0.14
	tete.height = 0.28
	_forme_du_reflet(reflet, tete, Vector3(0, 1.65, 0), Color("f2c6a0"))


# --- La journée --------------------------------------------------------------


func _commencer_la_journee() -> void:
	temps = 0.0
	etat = Etat.JOURNEE
	_dit.clear()
	pont_repeint = tableau_deja_fini
	_reflet.visible = pont_repeint
	$Pont/PenseeReflet.active = pont_repeint
	$Pont/PenseeBord.active = pont_repeint
	if _joueur.held != _fleur:
		_cacher_la_fleur()
	_juliette.visible = false
	_mob.visible = true
	_mob.transform = position_mobylette(0.0)
	if _joueur.held != _tableau:
		_remettre_le_tableau()
	_mettre_le_soleil()


func _remettre_le_tableau() -> void:
	_tableau.freeze = true
	_tableau.linear_velocity = Vector3.ZERO
	_tableau.global_transform = _depart_tableau
	tableau_fini = false
	tableau_mouille = false
	peinture = 0.0
	_peindre_le_tableau()


func _peindre_le_tableau() -> void:
	var p := _tableau.get_node("Peinture")
	var ciel: Node3D = p.get_node("Ciel")
	ciel.visible = tableau_fini or peinture > 0.0
	ciel.scale.x = 1.0 if tableau_fini else maxf(peinture, 0.01)
	p.get_node("Soleil").visible = tableau_fini
	p.get_node("Coulures").visible = tableau_mouille


## La fleur de Juliette n'existe que quand elle l'a donnée.
func _cacher_la_fleur() -> void:
	_fleur.freeze = true
	_fleur.visible = false
	_fleur.collision_layer = 0
	_fleur.global_transform = _depart_fleur


func _donner_la_fleur() -> void:
	_fleur.visible = true
	_fleur.collision_layer = 1
	_joueur.prendre(_fleur)


## La direction du soleil (vers lui) au moment `t` de la journée.
static func direction_soleil(t: float) -> Vector3:
	var h := deg_to_rad(lerpf(SOLEIL_HAUT, -1.0, clampf(t / DUREE_JOUR, 0.0, 1.0)))
	return (SOLEIL_DIR.normalized() * cos(h) + Vector3.UP * sin(h)).normalized()


func _mettre_le_soleil() -> void:
	var d := direction_soleil(temps)
	_soleil.basis = Basis.looking_at(-d, Vector3.UP if absf(d.y) < 0.99 else Vector3.FORWARD)
	var soir := smoothstep(COUCHER - 30.0, DUREE_JOUR, temps)
	_ciel.sky_top_color = Color("4ea8de").lerp(Color("3a2e6e"), soir)
	_ciel.sky_horizon_color = Color("ffe8a3").lerp(Color("ff7b54"), soir)
	_ciel.ground_horizon_color = _ciel.sky_horizon_color
	_soleil.light_color = Color("fff1c9").lerp(Color("ff9e5e"), soir)
	_soleil.light_energy = lerpf(1.2, 0.6, soir)
	_env.ambient_light_energy = lerpf(0.45, 0.25, soir)


func _physics_process(delta: float) -> void:
	var dans_l_eau := _nage.overlaps_body(_joueur)
	_joueur.facteur_vitesse = VITESSE_EAU if dans_l_eau else 1.0
	_animer_les_cheveux()
	match etat:
		Etat.JOURNEE:
			temps += delta
			_mettre_le_soleil()
			_juliette_dans_la_journee()
			_le_tableau(dans_l_eau, delta)
			_le_pont_du_reflet(dans_l_eau)
			_le_rendez_vous()
			if temps >= DUREE_JOUR:
				repeindre()
		Etat.VRAI:
			_le_vrai_soir()
	_ecouter_les_pensees()


func _animer_les_cheveux() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for j in [_mob.get_node("Juliette"), _juliette, $Nuit/Juliette]:
		var c: Node3D = j.get_node("Cheveux")
		c.rotation.x = 0.35 + 0.15 * sin(t * 6.0) if j == _mob.get_node("Juliette") else 0.08 * sin(t * 1.5)


func _une_fois(cle: String) -> bool:
	if _dit.has(cle):
		return false
	_dit[cle] = true
	return true


## Où est la mobylette au moment `t` : elle arrive par la route depuis l'est,
## s'approche du ponton, attend, puis repart vers l'est.
static func position_mobylette(t: float) -> Transform3D:
	var loin := Vector3(36, 0.32, 12.8)
	var route := Vector3(-6.5, 0.32, 12.8)
	var pres := Vector3(-6.5, 0.32, 2.0)
	var vers_l_ouest := Basis(Vector3.UP, PI / 2)
	var vers_le_ponton := Basis()
	var vers_l_est := Basis(Vector3.UP, -PI / 2)
	if t <= ARRIVEE[0]:
		return Transform3D(vers_l_ouest, loin)
	if t < ARRIVEE[1]:
		var k := (t - ARRIVEE[0]) / (ARRIVEE[1] - ARRIVEE[0])
		if k < 0.8:
			return Transform3D(vers_l_ouest, loin.lerp(route, k / 0.8))
		return Transform3D(vers_le_ponton, route.lerp(pres, (k - 0.8) / 0.2))
	if t < DEPART:
		return Transform3D(vers_le_ponton, pres)
	var k := clampf((t - DEPART) / 8.0, 0.0, 1.0)
	if k < 0.25:
		return Transform3D(Basis(Vector3.UP, PI), pres.lerp(route, k / 0.25))
	return Transform3D(vers_l_est, route.lerp(loin, (k - 0.25) / 0.75))


## Juliette arrive à mobylette, parle, repart, puis attend sur l'île.
func _juliette_dans_la_journee() -> void:
	_mob.transform = position_mobylette(temps)
	if temps >= PAROLES and _une_fois("paroles"):
		dire("Juliette", "Joli, ton lac. Mais il manque le ciel.")
		dire("Juliette", "Peins-le ce soir, quand le soleil se couche.")
		dire("Juliette", "Et viens me l'offrir sur l'île. Je t'attendrai.")
		if journee >= 3:
			dire("Juliette", "Ne sois pas en retard, cette fois.")
		# Le premier jour, elle lui donne une fleur (s'il a les mains libres) :
		# c'est elle qui lui apprendra que ce qu'il tient reste.
		if journee == 1 and _joueur.held == null:
			dire("Juliette", "Tiens. Pour toi.")
			_donner_la_fleur()
	_mob.visible = temps < SUR_L_ILE
	_juliette.visible = temps >= SUR_L_ILE
	for i in REPERES.size():
		if temps >= REPERES[i][0] and _une_fois("repere_%d" % i):
			penser(REPERES[i][1])
	if temps >= COUCHER and _une_fois("coucher"):
		penser("Le soleil se couche.")


## Au coucher du soleil, sur le ponton, le tableau en main : le ciel se peint
## tout seul, peu à peu.
func _le_tableau(dans_l_eau: bool, delta: float) -> void:
	if _joueur.held != _tableau:
		return
	if dans_l_eau and not tableau_mouille:
		tableau_mouille = true
		_peindre_le_tableau()
		penser("Le tableau… il est trempé.")
	if tableau_fini or tableau_mouille or temps < COUCHER:
		return
	if sur_le_ponton(_joueur.global_position):
		if _une_fois("peindre"):
			penser("La lumière du soir… Le ciel se peint.")
		peinture = minf(peinture + delta / PEINDRE, 1.0)
		_peindre_le_tableau()
		if peinture >= 1.0:
			finir_le_tableau()
	elif _une_fois("loin_du_ponton"):
		penser("La lumière du soir… Il faudrait que je sois au bout du ponton, là où je peignais.")


func finir_le_tableau() -> void:
	tableau_fini = true
	tableau_deja_fini = true
	peinture = 1.0
	_peindre_le_tableau()
	penser("Le ciel est fini… Mais elle m'attend déjà sur l'île.")


## Thomas est sur le ponton (là où il peignait).
static func sur_le_ponton(p: Vector3) -> bool:
	return absf(p.x - PONTON_X) <= 1.1 and p.z <= 0.0 and p.z >= -5.0 and p.y >= 0.4


## Thomas est au bord du trou du pont, ou dedans.
func pres_du_trou(p: Vector3) -> bool:
	return absf(p.x - PONT_X) <= 1.3 and p.z >= TROU.x - 1.0 and p.z <= TROU.y + 1.5 and p.y > 0.0


## Thomas regarde vers l'eau (et donc le reflet du pont).
func regarde_l_eau() -> bool:
	return (-_joueur.camera.global_basis.z).y <= REGARD_EAU


func _le_pont_du_reflet(dans_l_eau: bool) -> void:
	var etait := sur_le_pont_du_reflet
	sur_le_pont_du_reflet = pont_repeint and pres_du_trou(_joueur.global_position) and regarde_l_eau()
	_solide.disabled = not sur_le_pont_du_reflet
	if etait and not sur_le_pont_du_reflet:
		_dit["sur_le_reflet"] = true
	if dans_l_eau and _dit.has("sur_le_reflet") and _une_fois("leve_les_yeux"):
		penser("J'ai levé les yeux… Le pont n'est que dans l'eau.")


func _le_rendez_vous() -> void:
	if not _juliette.visible or not _rendez_vous.overlaps_body(_joueur):
		return
	if _joueur.held != _tableau:
		if _une_fois("sans_tableau"):
			dire("Juliette", "Et mon tableau ?")
	elif tableau_mouille:
		if _une_fois("mouille"):
			dire("Juliette", "Tu es venu à la nage ?!")
			penser("Non… Ça devait être parfait.")
	elif not tableau_fini:
		if _une_fois("pas_fini"):
			dire("Juliette", "Il manque toujours le ciel…")
	elif temps < COUCHER:
		if _une_fois("trop_tot"):
			dire("Juliette", "Attends… Le soleil n'est pas encore couché.")
	else:
		moment_parfait()


## Au coucher du soleil, le peintre repeint tout, d'un grand coup de pinceau
## qui traverse l'écran. Ce que Thomas tient reste dans ses mains.
func repeindre() -> void:
	etat = Etat.REPEINT
	var tenu := _joueur.held
	_repeint.anchor_left = 0.0
	_repeint.anchor_right = 0.0
	_repeint.color.a = 1.0
	var t := create_tween()
	t.tween_property(_repeint, "anchor_right", 1.0, DUREE_REPEINT).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		journee += 1
		_joueur.velocity = Vector3.ZERO
		_joueur.teleport($Rive/Depart.global_transform)
		_joueur.set_anchor($Rive/Depart.global_transform)
		var pont_avant := pont_repeint
		_commencer_la_journee()
		penser("Le même jour… Il recommence.")
		if tenu == _fleur and _joueur.held == _fleur:
			penser("Sa fleur… Je l'ai encore dans la main.")
		if tenu == _tableau and _joueur.held == _tableau:
			penser("Le tableau… Je l'ai encore dans les mains.")
			if tableau_fini and not tableau_mouille:
				penser("Il est fini. Cette fois, j'ai toute la journée.")
		if pont_repeint and not pont_avant:
			penser("Le pont… On dirait qu'il brille, dans l'eau."))
	t.tween_property(_repeint, "anchor_left", 1.0, DUREE_REPEINT).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void:
		_repeint.color.a = 0.0
		_repeint.anchor_left = 0.0
		_repeint.anchor_right = 1.0)


# --- Le moment parfait, puis la vérité ---------------------------------------


## La correction du peintre : tout devient parfait… et se fige.
func moment_parfait() -> void:
	etat = Etat.PARFAIT
	Histoire.corrections += 1
	_joueur.poser()
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	_tableau.freeze = true
	_tableau.reparent(_juliette)
	_tableau.position = Vector3(0, 1.1, -0.35)
	_tableau.rotation = Vector3(0, PI, 0)
	$Ile/Fleurs.visible = true
	_ciel.sky_top_color = Color("7b2cbf")
	_ciel.sky_horizon_color = Color("ff9e00")
	_ciel.ground_horizon_color = _ciel.sky_horizon_color
	dire("Juliette", "C'est… parfait.")
	var t := create_tween()
	t.tween_interval(4.0)
	t.tween_property(_juliette, "scale:z", 0.05, 1.5)
	t.tween_callback(penser.bind("Elle ne bouge plus."))
	t.tween_interval(2.0)
	t.tween_property(_fissures, "progres", 1.0, 3.0)
	t.tween_callback(penser.bind("Ce n'est pas vrai. Ce soir-là, je suis arrivé trop tard. À la nage."))
	t.tween_interval(5.0)
	t.tween_property(_noir, "color:a", 1.0, 1.5)
	t.tween_callback(vrai_soir)


## Le vrai soir : la nuit, Thomas dans l'eau, Juliette qui rit sur la rive.
func vrai_soir() -> void:
	etat = Etat.VRAI
	_dit.clear()
	# Les pensées de la journée n'ont plus lieu d'être.
	for p in get_tree().get_nodes_in_group(Pensee.GROUPE):
		if is_ancestor_of(p):
			p.active = false
	_fissures.progres = 0.0
	$Ile/Fleurs.visible = false
	_juliette.visible = false
	_tableau.visible = false
	_fleur.visible = false
	_mob.visible = false
	_reflet.visible = false
	$Nuit.visible = true
	temps = DUREE_JOUR + 20.0
	_soleil.light_energy = 0.0
	_ciel.sky_top_color = Color("0b1026")
	_ciel.sky_horizon_color = Color("2d1e4a")
	_ciel.ground_horizon_color = _ciel.sky_horizon_color
	_env.ambient_light_energy = 0.15
	var arrivee: Marker3D = $Nuit/Dans_l_eau
	_joueur.teleport(arrivee.global_transform)
	_joueur.set_anchor(arrivee.global_transform)
	_joueur.set_physics_process(true)
	var rire := create_tween().set_loops()
	var j: Node3D = $Nuit/Juliette
	rire.tween_property(j, "position:y", j.position.y + 0.08, 0.25)
	rire.tween_property(j, "position:y", j.position.y, 0.25)
	var t := _ouvrir_les_yeux("")
	t.tween_callback(dire.bind("Juliette", "Tu es venu à la nage ?! T'es complètement fou."))
	t.tween_callback(penser.bind("Le tableau était fichu. Elle riait."))
	t.tween_callback(dire.bind("Juliette", "Viens, idiot."))


func _le_vrai_soir() -> void:
	var j: Node3D = $Nuit/Juliette
	if _joueur.global_position.distance_to(j.global_position) < 2.5 and _une_fois("fin"):
		etat = Etat.FIN
		penser("C'était le plus beau soir de ma vie.")
		penser("Et je l'ai repeint… mille fois.")
		var t := create_tween()
		t.tween_interval(9.0)
		t.tween_callback(_tomber_dans_les_toiles.bind(_joueur))


func _retour_dans_la_maison_des_etoiles() -> void:
	Histoire.chapitre = maxi(Histoire.chapitre, 4)
	Histoire.vers("res://scenes/illusions.tscn")
