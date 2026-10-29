extends Souvenir

## Niveau 5, en formes simples : « L'atelier du peintre », puis dehors.
## Thomas devient le peintre (lui-même, vieux). Le labyrinthe des mille
## toiles aspire celui qui les regarde ; les yeux fermés, on ne voit que ce
## qui est vrai : les pétales de la fleur de Juliette. Au cœur, peindre ne
## marche jamais : la toile se finit, se fissure, et tout recommence. Il faut
## poser le pinceau. Dehors, la nature en couleurs, et des gens à qui dire
## bonjour. Voir docs/superpowers/specs/2026-10-28-direction-illusions-design.md.

enum Etat { AVANT, DEVENIR, PEINTRE, PEINT, POSE, DEHORS, GENERIQUE }

const COUCHE_VRAI := 8
const TETE_PEINTRE := 1.45
const VITESSE_PEINTRE := 0.65
const VITESSE_VIEUX := 0.75
## Une toile aspire Thomas s'il la regarde de près, assez longtemps.
const ASPIRE_DISTANCE := 3.5
const ASPIRE_ANGLE := 18.0
const ASPIRE_TEMPS := 0.6
const PENSEES_TENTATIVES := ["Encore une fois.", "Elle tombe toujours.", "Mille fois… mille fois la même pluie.", "Et si j'arrêtais de peindre ?"]
const PENSEES_ASPIRE := ["La toile m'a aspiré… Toutes les mêmes. La même route sous la pluie.", "Je ne peux plus les regarder.", "Encore cette route…"]
## Où se tenir, au cœur, face à la dernière toile.
const COEUR_FACE := Vector3(6, 0, -18.5)
## La caméra du premier plan, devant la maison, dehors.
const POINT_PORTE := Vector3(1003.5, 1.6, -1.0)
## Le pinceau, dans la main droite, en bas de l'écran.
var tenue_pinceau := Transform3D(Basis.from_euler(Vector3(-0.9, 0.3, 0.2)), Vector3(0.26, -0.3, -0.55))

var etat := Etat.AVANT
var tentatives := 0
var aspirations := 0
var saluts := 0

var _dit := {}
var _regard_toile := 0.0
var _masque_normal := 0
var _pinceau: RigidBody3D
var _mains: Node3D
var _temps := 0.0
var _vent := 1.0

@onready var _blanc: ColorRect = $Interface/Blanc
@onready var _fissures: Fissures = $Interface/Fissures
@onready var _generique: Label = $Interface/Generique
@onready var _approche: Area3D = $Antichambre/Approche
@onready var _chevalet: Support = $Coeur/Chevalet
@onready var _sortie: Area3D = $Coeur/Sortie


func _ready() -> void:
	Temps.reinitialiser()
	_joueur.camera.cull_mask &= ~(Miroir.COUCHE_REFLET | COUCHE_VRAI)
	_masque_normal = _joueur.camera.cull_mask
	noir_des_yeux = 0.3
	_approche.body_entered.connect(_sur_approche)
	_chevalet.utilise.connect(_sur_chevalet)
	_sortie.body_entered.connect(_sur_sortie)
	for p in find_children("*", "Passant", true, false):
		(p as Passant).salue.connect(_sur_salut)
	_ouvrir_les_yeux("L'atelier… Le vrai, cette fois.")


func _une_fois(cle: String) -> bool:
	if _dit.has(cle):
		return false
	_dit[cle] = true
	return true


func _physics_process(delta: float) -> void:
	_temps += delta
	# Les yeux fermés, on ne voit que ce qui est vrai.
	var vrai := yeux_fermes() and etat != Etat.DEHORS and etat != Etat.GENERIQUE
	_joueur.camera.cull_mask = COUCHE_VRAI if vrai else _masque_normal
	match etat:
		Etat.PEINTRE:
			_dans_le_labyrinthe(delta)
			_le_pinceau()
		Etat.DEHORS, Etat.GENERIQUE:
			_animer_les_papillons()
	_ecouter_les_pensees()


# --- Devenir le peintre ------------------------------------------------------


func _sur_approche(corps: Node3D) -> void:
	if corps is Player and etat == Etat.AVANT:
		devenir_le_peintre()


## Thomas entre dans le vieil homme : ses mains, son pinceau, ses yeux plus
## bas, son pas plus lent.
func devenir_le_peintre() -> void:
	etat = Etat.DEVENIR
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	var place: Marker3D = $Antichambre/Place_du_peintre
	var t := create_tween()
	t.tween_property(_joueur, "global_position", place.global_position, 1.2).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_joueur, "rotation:y", place.global_rotation.y, 1.2)
	t.parallel().tween_property(_joueur.head, "position:y", TETE_PEINTRE, 1.2)
	t.tween_property(_blanc, "color:a", 1.0, 0.3)
	t.tween_callback(func() -> void:
		$Antichambre/Peintre.visible = false
		_mettre_les_mains(true)
		_joueur.facteur_vitesse = VITESSE_PEINTRE
		_joueur.set_anchor(place.global_transform)
		_joueur.set_physics_process(true)
		etat = Etat.PEINTRE
		penser("Ces mains… ce sont les miennes.")
		penser("C'est moi, le peintre. Depuis le début.")
		penser("Elle est quelque part, au milieu de toutes ces toiles."))
	t.tween_property(_blanc, "color:a", 0.0, 0.8)


## Les vieilles mains de Thomas, en bas de l'écran, et le pinceau.
func _mettre_les_mains(avec_pinceau: bool) -> void:
	if _mains == null:
		_mains = Node3D.new()
		_mains.name = "Mains"
		_joueur.camera.add_child(_mains)
		for m in [["Main_droite", Vector3(0.24, -0.36, -0.5)], ["Main_gauche", Vector3(-0.3, -0.4, -0.55)]]:
			var b := BoxMesh.new()
			b.size = Vector3(0.09, 0.05, 0.14)
			var mi := MeshInstance3D.new()
			mi.name = m[0]
			mi.mesh = b
			mi.position = m[1]
			mi.rotation.x = -0.4
			mi.material_override = Style.materiau(Color("e0b48e"))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_mains.add_child(mi)
	if avec_pinceau and _pinceau == null:
		_pinceau = RigidBody3D.new()
		_pinceau.name = "Pinceau"
		_pinceau.set_meta("tenue", tenue_pinceau)
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = Vector3(0.04, 0.04, 0.4)
		forme.shape = boite
		_pinceau.add_child(forme)
		for b in [["Manche", Vector3(0, 0, 0.02), Vector3(0.018, 0.018, 0.34), Color("8d6346")],
				["Poils", Vector3(0, 0, -0.18), Vector3(0.025, 0.025, 0.06), Color("e63946")]]:
			var m := BoxMesh.new()
			m.size = b[2]
			var mi := MeshInstance3D.new()
			mi.name = b[0]
			mi.mesh = m
			mi.position = b[1]
			mi.material_override = Style.materiau(b[3])
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_pinceau.add_child(mi)
		add_child(_pinceau)
		_joueur.prendre(_pinceau)


# --- Les mille toiles --------------------------------------------------------


## La toile du labyrinthe que Thomas regarde de près, ou null.
func toile_regardee() -> Node3D:
	if yeux_fermes():
		return null
	var cam := _joueur.camera
	var o := cam.global_position
	var d := -cam.global_basis.z
	for n in get_tree().get_nodes_in_group("toiles_mille"):
		var t := n as Node3D
		if not is_ancestor_of(t) or not t.visible:
			continue
		var c := t.global_position
		c.y = o.y
		# Le point du mur le plus proche du regard, sur sa face.
		var normale := t.global_basis.z
		var face := c + normale * signf(normale.dot(o - c)) * 0.06
		if o.distance_to(face) > ASPIRE_DISTANCE:
			continue
		if rad_to_deg(d.angle_to(face - o)) > ASPIRE_ANGLE:
			continue
		if _visible(o, face):
			return t
	return null


func _dans_le_labyrinthe(delta: float) -> void:
	var t := toile_regardee()
	_regard_toile = _regard_toile + delta if t != null else 0.0
	if _regard_toile >= ASPIRE_TEMPS:
		_regard_toile = 0.0
		aspirer()


## La toile aspire Thomas : il revient à l'entrée du labyrinthe.
func aspirer() -> void:
	aspirations += 1
	var entree: Marker3D = $Labyrinthe/Entree
	_joueur.velocity = Vector3.ZERO
	_joueur.teleport(entree.global_transform)
	_blanc.color.a = 0.8
	create_tween().tween_property(_blanc, "color:a", 0.0, 0.6)
	penser(PENSEES_ASPIRE[mini(aspirations, PENSEES_ASPIRE.size()) - 1])


# --- Peindre, ou poser le pinceau --------------------------------------------


func _sur_chevalet(objet: Node3D) -> void:
	if objet == _pinceau and etat == Etat.PEINTRE:
		peindre()


## Peindre ne marche jamais : la toile se finit (Juliette reste), puis se
## fissure, et tout recommence à l'entrée du labyrinthe.
func peindre() -> void:
	etat = Etat.PEINT
	tentatives += 1
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	var parfaite: Node3D = $Coeur/Version_parfaite
	parfaite.visible = true
	parfaite.scale = Vector3(1, 0.01, 1)
	penser("Cette fois… elle reste.")
	var t := create_tween()
	t.tween_property(parfaite, "scale:y", 1.0, 3.0)
	t.tween_interval(1.0)
	t.tween_property(_fissures, "progres", 1.0, 2.0)
	t.tween_property(_blanc, "color:a", 1.0, 0.6)
	t.tween_callback(func() -> void:
		parfaite.visible = false
		_fissures.progres = 0.0
		var k := mini(tentatives, 4)
		get_node("Antichambre/Tentative_%d" % k).visible = true
		_joueur.teleport(($Labyrinthe/Entree as Marker3D).global_transform)
		_joueur.set_physics_process(true)
		etat = Etat.PEINTRE
		penser(PENSEES_TENTATIVES[mini(tentatives, PENSEES_TENTATIVES.size()) - 1]))
	t.tween_property(_blanc, "color:a", 0.0, 1.0)


## Le pinceau lâché (E sans viser le chevalet). Avant d'avoir essayé de
## peindre, Thomas le reprend.
func _le_pinceau() -> void:
	if _pinceau == null or _joueur.held == _pinceau:
		return
	if tentatives == 0:
		_joueur.prendre(_pinceau)
		if _une_fois("reprend"):
			penser("Non… Pas encore. Je peux encore la sauver.")
		return
	poser_le_pinceau()


## Il pose le pinceau. La dernière toile change toute seule : Juliette qui
## rit, au lac. Les toiles tombent, la porte d'entrée apparaît.
func poser_le_pinceau() -> void:
	etat = Etat.POSE
	_chevalet.actif = false
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	penser("Je pose le pinceau.")
	var t := create_tween()
	t.tween_property(_blanc, "color:a", 1.0, 1.0)
	t.tween_callback(func() -> void:
		if _pinceau != null:
			_pinceau.visible = false
		for n in get_tree().get_nodes_in_group("toiles_mille"):
			if is_ancestor_of(n):
				(n as Node3D).visible = false
				n.process_mode = Node.PROCESS_MODE_DISABLED
		var face := Transform3D(Basis(), COEUR_FACE)
		_joueur.teleport(face)
		_joueur.head.rotation.x = 0.1
		$Coeur/Derniere_toile.visible = false
		$Coeur/Vrai_souvenir.visible = true)
	t.tween_property(_blanc, "color:a", 0.0, 2.5)
	t.tween_callback(penser.bind("Elle riait. Je me souviens d'elle comme elle était."))
	t.tween_callback(penser.bind("Je ne peux pas changer ce qui est arrivé."))
	t.tween_interval(9.0)
	t.tween_callback(func() -> void:
		$Coeur/Porte.visible = true
		_sortie.monitoring = true
		_joueur.set_physics_process(true)
		penser("La porte d'entrée… Elle est là."))


# --- Dehors : la cinématique -------------------------------------------------


func _sur_sortie(corps: Node3D) -> void:
	if corps is Player and etat == Etat.POSE:
		sortir()


## Dehors : la nature en couleurs, un soleil, un ciel bleu. Toute la scène
## est une cinématique : on regarde Thomas, vieux, sortir de chez lui,
## marcher, saluer les passants et monter la colline.
func sortir() -> void:
	etat = Etat.DEHORS
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	_joueur.set_process_unhandled_input(false)
	var t := create_tween()
	t.tween_property(_blanc, "color:a", 1.0, 1.0)
	t.tween_callback(func() -> void:
		var ciel := ProceduralSkyMaterial.new()
		ciel.sky_top_color = Color("4ea8de")
		ciel.sky_horizon_color = Color("caf0f8")
		ciel.ground_horizon_color = Color("caf0f8")
		ciel.ground_bottom_color = Color("7cb518")
		var sky := Sky.new()
		sky.sky_material = ciel
		var env: Environment = ($WorldEnvironment as WorldEnvironment).environment
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_color = Color("fff1c9")
		env.ambient_light_energy = 0.55
		var soleil := DirectionalLight3D.new()
		soleil.name = "Soleil"
		soleil.rotation_degrees = Vector3(-50, 30, 0)
		soleil.shadow_enabled = true
		soleil.light_color = Color("fff1c9")
		add_child(soleil)
		for g in ["Antichambre", "Labyrinthe", "Coeur"]:
			get_node(g).visible = false
		$Dehors.visible = true
		noir_des_yeux = 0.0
		cinematique = true
		_cinema.current = true
		_cinematique())
	t.tween_property(_blanc, "color:a", 0.0, 2.5)


## Les étapes de la cinématique : [plan, point où marcher, arrêt (s), passant
## à saluer]. Les plans : « porte » (de loin, devant la maison), « suivi » (de
## côté, derrière lui), « face » (face à lui, pendant qu'il salue),
## « colline » (derrière lui, puis la caméra s'élève).
const ETAPES := [
	["porte", Vector3(0, 0, 3.0), 1.5, ""],
	["suivi", Vector3(2.0, 0, -8.0), 0.0, ""],
	["face", Vector3(2.6, 0, -11.5), 5.0, "Jardiniere"],
	["suivi", Vector3(-1.5, 0, -20.0), 0.0, ""],
	["face", Vector3(-3.0, 0, -27.5), 4.5, "Promeneur"],
	["suivi", Vector3(0.0, 0, -36.0), 0.0, ""],
	["face", Vector3(1.8, 0, -41.5), 5.0, "Enfant"],
	["suivi", Vector3(0.0, 0, -51.5), 0.0, ""],
	["colline", Vector3(0.0, 3.0, -64.0), 0.0, ""],
	["colline", Vector3(0.0, 3.0, -67.0), 0.0, ""],
]
const PAS := 1.4
## Le milieu du chemin, dehors.
const DEHORS_X := 1000.0

var _plan := "porte"
var _passant: Node3D
var _cinema_cible := Vector3.ZERO
var _grue := 0.0

@onready var _thomas: Node3D = $Dehors/Thomas
@onready var _cinema: Camera3D = $Dehors/Camera


func _cinematique() -> void:
	penser("Dehors… Je n'étais pas sorti depuis si longtemps.")
	var t := create_tween()
	t.tween_interval(1.5)
	var depart := _thomas.position
	for e in ETAPES:
		var vers: Vector3 = e[1]
		var duree := depart.distance_to(vers) / PAS
		t.tween_callback(func() -> void:
			_plan = e[0]
			var d := vers - _thomas.position
			_thomas.rotation.y = atan2(-d.x, -d.z))
		t.tween_property(_thomas, "position", vers, duree)
		if e[3] != "":
			var passant: Passant = get_node("Dehors/" + e[3])
			t.tween_callback(func() -> void:
				var d := passant.position - _thomas.position
				_thomas.rotation.y = atan2(-d.x, -d.z)
				_passant = passant
				passant.activer())
		if e[2] > 0.0:
			t.tween_interval(e[2])
		depart = vers
	t.tween_callback(finir)


func _process(delta: float) -> void:
	super._process(delta)
	if etat != Etat.DEHORS and etat != Etat.GENERIQUE:
		return
	# Thomas marche : un léger balancement.
	_thomas.get_node("Blouse").position.y = 1.1 + 0.03 * absf(sin(_temps * 5.0))
	var tete := _thomas.global_position + Vector3(0, 1.5, 0)
	var devant := -_thomas.global_basis.z
	var cote := _thomas.global_basis.x
	var voulu := tete
	match _plan:
		"porte":
			voulu = POINT_PORTE
		"suivi":
			voulu = tete + cote * 2.6 - devant * 3.2 + Vector3(0, 0.4, 0)
		"face":
			# De côté, pour voir Thomas et le passant ensemble, du côté du
			# chemin.
			var autre := _passant.global_position if _passant != null else tete + devant * 2.0
			var milieu := (tete + autre + Vector3(0, 1.4, 0)) / 2.0
			var travers := (autre - _thomas.global_position).cross(Vector3.UP).normalized()
			if absf((milieu + travers).x - DEHORS_X) > absf((milieu - travers).x - DEHORS_X):
				travers = -travers
			voulu = milieu + travers * 4.5 + Vector3(0, 0.3, 0)
			tete = milieu
		"colline":
			_grue = minf(_grue + delta * 0.6, 12.0) if etat == Etat.GENERIQUE else _grue
			voulu = tete - devant * 5.0 + cote * 1.5 + Vector3(0, 1.2 + _grue, _grue * 0.8)
	_cinema.global_position = _cinema.global_position.lerp(voulu, clampf(delta * 1.5, 0.0, 1.0))
	_cinema_cible = _cinema_cible.lerp(tete if _grue < 1.0 else tete + Vector3(0, 0, -15.0), clampf(delta * 2.0, 0.0, 1.0))
	if _cinema.global_position.distance_to(_cinema_cible) > 0.1:
		_cinema.look_at(_cinema_cible, Vector3.UP)


func _sur_salut(p: Passant) -> void:
	saluts += 1
	dire("Thomas", "Bonjour.")
	for r in p.repliques:
		dire(p.nom, r)
	if saluts == 1:
		penser("J'ai osé. Comme elle aurait voulu.")
	elif p.name == "Enfant":
		penser("Un cerf-volant… comme ceux que je regardais, du grenier.")


func _animer_les_papillons() -> void:
	var i := 0
	for p in $Dehors/Papillons.get_children():
		var n := p as Node3D
		var a := _temps * (0.8 + 0.1 * (i % 4)) * _vent + i
		n.position += Vector3(cos(a), 0.3 * sin(a * 2.0), sin(a)) * 0.02 * _vent
		var battement := 0.9 * sin(_temps * 18.0 + i)
		n.get_node("Aile_g").rotation.z = battement
		n.get_node("Aile_d").rotation.z = -battement
		i += 1


## Au sommet de la colline, le vent se lève, la caméra s'élève. Puis le
## générique.
func finir() -> void:
	etat = Etat.GENERIQUE
	Histoire.chapitre = maxi(Histoire.chapitre, 6)
	create_tween().tween_property(self, "_vent", 4.0, 3.0)
	penser("Le vent… comme dans ses cheveux.")
	penser("Je ne peux pas changer ce qui est arrivé.")
	penser("Mais je peux vivre ce qui vient.")
	var t := create_tween()
	t.tween_interval(14.0)
	t.tween_property(_noir, "color:a", 1.0, 3.0)
	t.tween_callback(func() -> void:
		_generique.visible = true
		_generique.modulate.a = 0.0)
	t.tween_property(_generique, "modulate:a", 1.0, 2.0)
