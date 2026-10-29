extends Souvenir

## Niveau 4, en formes simples : « La pluie ». Le soir de la dispute : on
## arrive à la fin du souvenir, figé (la pluie suspendue). R maintenu remonte
## le temps ; ce que Thomas tient ne remonte pas le temps. Il faut descendre
## de la mezzanine avant que l'étagère ne tombe sur l'escalier, reprendre le
## casque de Juliette avant qu'il ne tombe sous la grille, et sortir quand
## elle part. La correction du peintre : cette fois, Thomas lui court après.
## Au bout de la route, le vide : elle tombe dans tous les cas.
## Voir docs/superpowers/specs/2026-10-28-direction-illusions-design.md.

enum Etat { ATELIER, COURSE, CHUTE, VERITE, FIN }

## La dispute dure 40 s ; on arrive à la fin, quand tout est figé.
const DUREE := 40.0
const VITESSE_REBOURS := 1.5
## Quelques secondes où la porte est ouverte : Juliette part.
const PORTE := [30.6, 33.0]
## Les phrases de la dispute : [t, qui, phrase].
const PHRASES := [
	[2.0, "Juliette", "Tu ne lèves même plus les yeux de tes toiles."],
	[6.0, "Thomas", "Je travaille, Juliette."],
	[10.0, "Juliette", "Tu peins nos souvenirs au lieu de les vivre. Viens rouler avec moi."],
	[14.0, "Thomas", "Il pleut. Et je n'ai pas le temps."],
	[18.0, "Juliette", "Tu n'as jamais le temps."],
	[20.0, "Thomas", "Laisse-moi !"],
	[24.0, "Juliette", "Je pars rouler. Seule."],
	[30.0, "Juliette", "Très bien. Je m'en vais."],
	[31.0, "Thomas", "C'est ça. Va-t'en !"],
]
## La course : Thomas court plus vite qu'il ne marche ; la mobylette reste
## devant lui ; la route se tord un peu.
const VITESSE_COURSE := 1.5
const AVANCE_MOTO := 11.0
const ROULIS := 0.06
## La route de la course (en coordonnées de son groupe ; tools/
## constructeur_dispute.gd la construit à partir d'ici).
const FIN_COURSE := -330.0
const VOIES := [-3.0, 0.0, 3.0]
## Les obstacles : [z, type, voies bloquées]. Types : « barriere » (à
## sauter), « mur » (à éviter), « trou » (à sauter, longueur en m).
const OBSTACLES := [
	[-20.0, "barriere", 0], [-35.0, "mur", [0, 1]], [-50.0, "mur", [1, 2]], [-62.0, "trou", 3.0],
	[-78.0, "barriere", 0], [-90.0, "mur", [0, 2]], [-105.0, "trou", 3.5], [-118.0, "mur", [0, 1]],
	[-127.0, "barriere", 0], [-140.0, "mur", [1, 2]], [-152.0, "trou", 3.0], [-165.0, "barriere", 0],
	[-176.0, "mur", [0, 2]], [-190.0, "trou", 4.0], [-205.0, "mur", [0, 1]], [-213.0, "mur", [1, 2]],
	[-228.0, "barriere", 0], [-240.0, "trou", 3.5], [-255.0, "mur", [0, 2]], [-268.0, "barriere", 0],
	[-278.0, "trou", 3.0], [-292.0, "mur", [1, 2]], [-300.0, "mur", [0, 1]], [-314.0, "barriere", 0],
]
const REPERES := [8.0, -70.0, -145.0, -220.0, -285.0]
## La mobylette regarde ce loin devant elle pour choisir sa voie, et se
## déplace de côté de ce nombre de mètres par mètre parcouru.
const VUE_MOTO := 14.0
const DERIVE_MOTO := 1.2
## La chute : Juliette est d'abord à 5 m sous Thomas ; chaque appui sur
## Espace la rapproche, la chute l'éloigne.
const ECART_CHUTE := 5.0
const RAPPROCHE := 0.3
const ELOIGNE := 0.55
const ATTRAPEE := 0.8
const DUREE_CHUTE := 9.0

var etat := Etat.ATELIER
## L'instant du souvenir (de 0, avant la dispute, à DUREE, après).
var moment := DUREE
var rembobine := false
var ecart := ECART_CHUTE
var rattrapee := false

var _dit := {}
var _temps_reel := 0.0
## Où en est la mobylette dans la course (coordonnées de la route).
var moto_x := 0.0
var moto_z := -4.0
var _temps_chute := 0.0
var _lachee := false
var _temporels: Array[ObjetTemporel] = []

@onready var _casque: RigidBody3D = $Atelier/Casque
@onready var _sortie: Area3D = $Atelier/Sortie
@onready var _rebours: ColorRect = $Interface/Rebours
@onready var _blanc: ColorRect = $Interface/Blanc
@onready var _pluie: Pluie = $Rue/Pluie
@onready var _pluie_ouest: Pluie = $Rue/Pluie_ouest
@onready var _moto_course: Node3D = $Course/Mobylette
@onready var _pluie_course: Pluie = $Course/Pluie
@onready var _vide: Area3D = $Course/Vide
@onready var _bord: Area3D = $Course/Bord
@onready var _juliette_chute: Node3D = $Vide/Juliette
@onready var _pluie_chute: Pluie = $Vide/Pluie


func _ready() -> void:
	Temps.reinitialiser()
	touches_en_plus = "R (maintenu) : remonter le temps"
	_joueur.camera.cull_mask &= ~Miroir.COUCHE_REFLET
	for n in find_children("*", "ObjetTemporel", true, false):
		_temporels.append(n as ObjetTemporel)
	_sortie.body_entered.connect(_sur_sortie)
	_vide.body_entered.connect(_sur_vide)
	_bord.body_entered.connect(_sur_bord)
	_chute.finie.connect(_retour_dans_la_maison_des_etoiles)
	_appliquer_le_moment()
	var t := _ouvrir_les_yeux("Elle est partie. Il pleuvait.")
	t.tween_callback(penser.bind("Tout s'est arrêté, ce soir-là."))
	t.tween_interval(6.0)
	t.tween_callback(penser.bind("Si je pouvais revenir en arrière…"))


func _une_fois(cle: String) -> bool:
	if _dit.has(cle):
		return false
	_dit[cle] = true
	return true


## Une phrase écrite à l'envers, quand on remonte le temps.
static func a_l_envers(texte: String) -> String:
	var r := ""
	for i in range(texte.length() - 1, -1, -1):
		r += texte[i]
	return r


func _physics_process(delta: float) -> void:
	match etat:
		Etat.ATELIER:
			_dans_l_atelier(delta)
		Etat.COURSE:
			_dans_la_course(delta)
		Etat.CHUTE:
			_dans_la_chute(delta)
		Etat.VERITE:
			_temps_reel += delta
			_pluie.temps = _temps_reel
			_pluie_ouest.temps = _temps_reel
			if Input.is_action_pressed("rembobiner") and _une_fois("pas_de_retour"):
				penser("On ne remonte pas le temps.")
	_ecouter_les_pensees()


# --- L'atelier : le temps à rebours ------------------------------------------


func _dans_l_atelier(delta: float) -> void:
	var avant := moment
	rembobine = Input.is_action_pressed("rembobiner")
	if rembobine:
		moment = maxf(moment - delta * VITESSE_REBOURS, 0.0)
		if _une_fois("premier_rebours"):
			penser("Le temps… il recule.")
	else:
		moment = minf(moment + delta, DUREE)
	_rebours.color.a = move_toward(_rebours.color.a, 0.18 if rembobine and moment > 0.0 else 0.0, delta * 2.0)
	if moment != avant:
		_dire_les_phrases(avant, moment)
		_appliquer_le_moment()
	var tenu := _joueur.held == _casque
	if tenu:
		var o: ObjetTemporel = _casque.get_node("Temps")
		if not o.hors_du_temps:
			o.hors_du_temps = true
			penser("Son casque. Je le tiens : il ne remonte plus le temps.")
	$Atelier/PenseeGrille.active = moment > 21.5 and not _casque.get_node("Temps").hors_du_temps


## Les phrases dites entre deux instants : à l'endroit si le temps avance, à
## l'envers s'il recule.
func _dire_les_phrases(avant: float, apres: float) -> void:
	for p in PHRASES:
		var t: float = p[0]
		if avant < t and apres >= t:
			afficher("%s : « %s »" % [p[1], p[2]], 3.5)
		elif avant >= t and apres < t:
			afficher("%s : « %s »" % [p[1], a_l_envers(p[2])], 2.0)


func _appliquer_le_moment() -> void:
	for o in _temporels:
		if o.get_parent() == _casque and _joueur.held == _casque:
			continue
		o.appliquer(moment)
	_pluie.temps = moment
	_pluie_ouest.temps = moment


## La porte est ouverte (Juliette part) : on peut la suivre.
func porte_ouverte() -> bool:
	return moment >= PORTE[0] and moment <= PORTE[1]


func _sur_sortie(corps: Node3D) -> void:
	if not corps is Player or etat != Etat.ATELIER:
		return
	if _joueur.held != _casque:
		if _une_fois("sans_casque"):
			penser("Son casque… Il faut que je lui donne son casque.")
		return
	commencer_la_course()


# --- La course-poursuite : la correction -------------------------------------


## Cette fois, Thomas lui court après, son casque à la main.
func commencer_la_course() -> void:
	etat = Etat.COURSE
	Histoire.corrections += 1
	_rebours.color.a = 0.0
	var depart: Marker3D = $Course/Depart
	_joueur.teleport(depart.global_transform)
	_joueur.set_anchor(depart.global_transform)
	_joueur.avance_auto = true
	_joueur.facteur_vitesse = VITESSE_COURSE
	moto_x = 0.0
	moto_z = depart.global_position.z - ($Course as Node3D).global_position.z - AVANCE_MOTO
	penser("Cette fois, je te rattrape.")
	dire("Thomas", "Juliette ! Attends !")


## La voie que vise la mobylette à `z` : la plus proche du milieu parmi
## celles que le prochain mur laisse libres.
static func voie_moto(z: float) -> float:
	for o in OBSTACLES:
		if o[1] != "mur" or o[0] > z + 0.8 or o[0] < z - VUE_MOTO:
			continue
		var libres := []
		for v in VOIES.size():
			if not v in o[2]:
				libres.append(VOIES[v])
		libres.sort_custom(func(a: float, b: float) -> bool: return absf(a) < absf(b) or (absf(a) == absf(b) and a > b))
		return libres[0]
	return 0.0


## Un pas de la mobylette : elle avance de `dz` (vers -Z) et glisse vers sa
## voie.
static func pas_moto(x: float, z: float, dz: float) -> float:
	return move_toward(x, voie_moto(z), DERIVE_MOTO * dz)


## La hauteur de la mobylette à `z` : elle saute les barrières et les trous,
## et tombe dans le vide au bout de la route.
static func hauteur_moto(z: float) -> float:
	if z < FIN_COURSE:
		return -0.6 * pow(FIN_COURSE - z, 2.0)
	var y := 0.0
	for o in OBSTACLES:
		var debut: float = o[0] + 2.0
		var fin: float = o[0] - 2.0
		if o[1] == "trou":
			debut = o[0] + 1.5
			fin = o[0] - o[2] - 1.5
		elif o[1] != "barriere":
			continue
		if z <= debut and z >= fin:
			var k := (debut - z) / (debut - fin)
			y = maxf(y, 4.0 * 1.1 * k * (1.0 - k))
	return y


func _dans_la_course(delta: float) -> void:
	_temps_reel += delta
	var p := _joueur.global_position
	# La mobylette reste devant : elle évite les murs, saute le reste.
	var route := ($Course as Node3D).global_position
	var z := minf(p.z - route.z - AVANCE_MOTO, 10.0)
	var dz := maxf(moto_z - z, 0.0)
	var avant := moto_x
	var pas := 0.0
	while pas < dz:
		var d := minf(0.25, dz - pas)
		moto_x = pas_moto(moto_x, moto_z - pas - d, d)
		pas += d
	moto_z = minf(z, moto_z)
	_moto_course.global_position = route + Vector3(moto_x, hauteur_moto(moto_z), moto_z)
	# Elle penche dans les virages.
	_moto_course.rotation = Vector3(0.0, 0.0, clampf((moto_x - avant) * -3.0, -0.35, 0.35))
	if moto_z < FIN_COURSE and _une_fois("elle_tombe"):
		dire("Thomas", "Juliette !")
	var cheveux: Node3D = _moto_course.get_node("Juliette/Cheveux")
	cheveux.rotation.x = 0.35 + 0.15 * sin(_temps_reel * 6.0)
	_pluie_course.global_position = p + Vector3(0, 4.0, -6.0)
	_pluie_course.temps = _temps_reel
	# Le rêve se tord : la tête roule, le champ de vision respire.
	_joueur.head.rotation.z = ROULIS * sin(_temps_reel * 0.7) * (1.0 + clampf(-p.z / 200.0, 0.0, 1.5))
	_joueur.camera.fov = 80.0 + 6.0 * sin(_temps_reel * 1.3)
	if p.z < -150.0 and _une_fois("loin"):
		penser("Elle est juste là… Encore un peu.")


func _sur_vide(corps: Node3D) -> void:
	if corps is Player and etat == Etat.COURSE:
		_joueur.respawn()
		if _une_fois("tombe"):
			penser("Non… Pas encore.")


## Au bout de la route, le vide. Juliette tombe ; Thomas saute derrière elle.
func _sur_bord(corps: Node3D) -> void:
	if not corps is Player or etat != Etat.COURSE:
		return
	etat = Etat.CHUTE
	_joueur.avance_auto = false
	_joueur.facteur_vitesse = 1.0
	_joueur.head.rotation.z = 0.0
	_joueur.camera.fov = 80.0
	if _joueur.held != null:
		var c := _joueur.held
		_joueur.poser()
		c.visible = false
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	var chute: Marker3D = $Vide/Chute
	_joueur.teleport(chute.global_transform)
	_joueur.head.rotation.x = -1.35
	ecart = ECART_CHUTE
	_temps_chute = 0.0
	penser("Elle tombe…")
	penser("Vite ! Espace, Espace !")


## Un appui sur Espace pendant la chute : Thomas tend le bras.
func appuyer() -> void:
	if etat != Etat.CHUTE or rattrapee:
		return
	ecart = maxf(ecart - RAPPROCHE, 0.0)


func _dans_la_chute(delta: float) -> void:
	_temps_chute += delta
	_temps_reel += delta
	if Input.is_action_just_pressed("sauter"):
		appuyer()
	if not rattrapee:
		ecart += ELOIGNE * delta
		if ecart <= ATTRAPEE:
			rattrapee = true
			penser("Je te tiens !")
			var t := create_tween()
			t.tween_interval(2.0)
			t.tween_callback(func() -> void:
				_lachee = true
				penser("Sa main glisse…"))
	if _lachee or (not rattrapee and _temps_chute > DUREE_CHUTE):
		ecart += 6.0 * delta
	var cam := _joueur.camera.global_position
	_juliette_chute.global_position = cam + Vector3(0, -ecart - 1.6, -0.6)
	_pluie_chute.global_position = cam
	_pluie_chute.temps = _temps_reel
	if ecart > 30.0 and _une_fois("disparue"):
		var t := create_tween()
		t.tween_property(_blanc, "color:a", 1.0, 1.5)
		t.tween_callback(verite)
		t.tween_property(_blanc, "color:a", 0.0, 2.0)


# --- La vérité ---------------------------------------------------------------


## L'atelier, après. Le temps ne se remonte plus.
func verite() -> void:
	etat = Etat.VERITE
	_dit.erase("pas_de_retour")
	for p in get_tree().get_nodes_in_group(Pensee.GROUPE):
		if is_ancestor_of(p):
			p.active = false
	moment = DUREE
	for o in _temporels:
		o.hors_du_temps = false
	_appliquer_le_moment()
	$Souvenir.visible = false
	_casque.visible = false
	$Atelier/Telephone.visible = true
	var ecran: Node3D = $Atelier/Telephone/Ecran
	var clignote := create_tween().set_loops()
	clignote.tween_property(ecran, "visible", false, 0.4)
	clignote.tween_property(ecran, "visible", true, 0.4)
	var verite_pos: Marker3D = $Atelier/Verite
	_joueur.teleport(verite_pos.global_transform)
	_joueur.set_anchor(verite_pos.global_transform)
	_joueur.head.rotation.x = 0.0
	_joueur.set_physics_process(true)
	penser("Elle est partie sans son casque. Je ne l'ai pas retenue.")
	penser("Mes derniers mots, c'étaient : va-t'en.")
	penser("Plus tard, le téléphone a sonné.")
	var t := create_tween()
	t.tween_interval(16.0)
	t.tween_callback(func() -> void:
		etat = Etat.FIN
		_tomber_dans_les_toiles(_joueur))


func _retour_dans_la_maison_des_etoiles() -> void:
	Histoire.chapitre = maxi(Histoire.chapitre, 5)
	Histoire.vers("res://scenes/illusions.tscn")
