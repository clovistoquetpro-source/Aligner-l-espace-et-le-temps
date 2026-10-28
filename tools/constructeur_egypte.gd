extends "res://tools/constructeur.gd"

## Construit scenes/egypte.tscn à partir du code (lancé par construire_egypte.gd).
## Le chantier de la pyramide est au centre ; le mirage et l'arrivée au sud,
## la rampe au nord, la carrière à l'ouest, le camp de 1942 à l'est et le
## temple au sud-est. L'Antiquité est l'époque « passé » du code, 1942 le
## « présent ».

const COULEURS := {
	"sable": "e8955a", "sable_fonce": "c9743f", "pierre": "d2af73", "pierre_fonce": "b99561",
	"brique": "c9744a", "or": "f3c330", "turquoise": "1fb5a8", "eau": "2ec4d6",
	"bois": "8a5a3c", "kaki": "6b7a45", "toile": "c8b48a", "ombre": "b5562a",
}

const DEPART := Vector3(0, 0, 70)
const SOLEIL := Vector3(-25, -30, 0)


func construire() -> int:
	_racine = Node3D.new()
	_racine.name = "Egypte"
	_racine.set_script(load("res://scripts/niveau/egypte.gd"))
	_m = load("res://tools/meubles.gd").new(self)
	_environnement()
	_sol()
	_mirage()
	_carriere()
	_rampe()
	_camp()
	_temple()
	_chantier()
	_joueur_et_interface(DEPART)
	return _enregistrer("res://scenes/egypte.tscn")


func _couleurs() -> Dictionary:
	return COULEURS


func _lumineux() -> Array:
	return ["or"]


func _environnement() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("3ee6d0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffb347")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = env.background_color
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	_ajouter(_racine, we, "WorldEnvironment")
	# Soleil de désert bas : de longues ombres vers le nord-ouest.
	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = SOLEIL
	soleil.light_color = Color("ffe9c4")
	soleil.light_energy = 0.85
	soleil.shadow_enabled = true
	soleil.shadow_blur = 1.5
	soleil.directional_shadow_max_distance = 120.0
	_ajouter(_racine, soleil, "Soleil")


## Le désert, et des murs invisibles tout autour pour ne pas en sortir.
func _sol() -> void:
	_boite(_racine, "Sol", Vector3(0, -0.5, 0), Vector3(240, 1, 240), "sable")
	var bords := _groupe("Bords")
	for i in 4:
		var mur := StaticBody3D.new()
		mur.position = Vector3(0, 10, 0) + Vector3(sin(i * PI / 2), 0, cos(i * PI / 2)) * 100
		mur.rotation.y = i * PI / 2
		_ajouter(bords, mur, "Bord%d" % i)
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = Vector3(200, 20, 1)
		forme.shape = boite
		_ajouter(mur, forme, "CollisionShape3D")


## Direction (horizontale) des ombres, et longueur de l'ombre d'un objet de
## hauteur `h`.
func _ombre(h: float) -> Vector3:
	var lumiere := -Basis.from_euler(SOLEIL * PI / 180.0).z
	var sol := Vector3(lumiere.x, 0, lumiere.z)
	return sol.normalized() * h * sol.length() / -lumiere.y


## Énigme 1 : on arrive sur une place fermée de dunes. Le seul chemin vers le
## chantier boucle (porte trompeuse), sauf si on le traverse en regardant le
## bout de l'ombre de l'obélisque, peinte au sol dans l'axe du soleil.
func _mirage() -> void:
	var g := _groupe("Mirage")
	var obelisque := Vector3(-4.5, 0, 64)
	_m.egypte(g, "Obelisque", "obelisk", obelisque)
	var ombre := _ombre(6.7)
	var bout := obelisque + ombre
	var bande := _boite(g, "Ombre", obelisque + ombre / 2 + Vector3(0, 0.012, 0), Vector3(0.8, 0.02, ombre.length()), "ombre", false)
	bande.rotation.y = atan2(ombre.x, ombre.z)
	var m := Marker3D.new()
	m.position = bout
	_ajouter(g, m, "BoutOmbre")
	# Une stèle donne l'indice, tournée vers l'arrivée.
	var stele := Vector3(-2.2, 0, 66.5)
	var rot := atan2(DEPART.x - stele.x, DEPART.z - stele.z)
	_m.egypte(g, "Stele", "hieroglyph_slab", stele, rot)
	_texte(g, "Indice", stele + Basis(Vector3.UP, rot) * Vector3(0, 1.3, 0.2), "Qui marche droit\ntourne en rond.\nQui suit mon ombre\narrive.", rot, 0.0024)
	# La place d'arrivée et le chemin, fermés par des murs invisibles au pied
	# des dunes.
	var bords := Node3D.new()
	_ajouter(g, bords, "Bords")
	_mur_invisible(bords, "PlaceSud", Vector3(0, 3, 76.1), Vector3(20.4, 6, 0.2))
	_mur_invisible(bords, "PlaceOuest", Vector3(-10.1, 3, 68), Vector3(0.2, 6, 16.4))
	_mur_invisible(bords, "PlaceEst", Vector3(10.1, 3, 68), Vector3(0.2, 6, 16.4))
	_mur_invisible(bords, "PlaceNordOuest", Vector3(-6.6, 3, 59.9), Vector3(7.2, 6, 0.2))
	_mur_invisible(bords, "PlaceNordEst", Vector3(6.6, 3, 59.9), Vector3(7.2, 6, 0.2))
	_mur_invisible(bords, "CheminOuest", Vector3(-3.1, 3, 45), Vector3(0.2, 6, 30))
	_mur_invisible(bords, "CheminEst", Vector3(3.1, 3, 45), Vector3(0.2, 6, 30))
	var dunes: CSGCombiner3D = _m.prop(g, "Dunes", Vector3.ZERO, 0.0, false)
	for z in range(33, 60, 6):
		for x in [-6.6, 6.6]:
			_dune(dunes, Vector3(x, 0, z), Vector3(3.5, 3.0 + 0.4 * (z % 4), 4.2))
	for x in range(-8, 9, 4):
		_dune(dunes, Vector3(x, 0, 79.6), Vector3(3.5, 3.2, 3.5))
	for z in range(63, 76, 4):
		for x in [-13.6, 13.6]:
			_dune(dunes, Vector3(x, 0, z), Vector3(3.5, 3.4, 3.2))
	for x in [-8.0, 8.0]:
		_dune(dunes, Vector3(x, 0, 56.5), Vector3(4.5, 3.2, 3.4))
	_m.egypte(g, "Palmier1", "palm_tree", Vector3(7.5, 0, 72), 0.4)
	_m.egypte(g, "Palmier2", "palm_tree", Vector3(8.2, 0, 66), 2.0)
	_m.egypte(g, "Rocher", "desert_rock", Vector3(-8, 0, 73), 1.0)
	# La porte trompeuse : sans regarder l'ombre, retour sur la place.
	var porte := _porte_trompeuse(g, "Porte", Vector3(0, 0, 56), Vector3(6.2, 4, 0.4))
	var retour := Marker3D.new()
	retour.position = Vector3(0, 0, 66)
	_ajouter(g, retour, "Retour")
	var sortie := Marker3D.new()
	sortie.position = porte.position
	_ajouter(g, sortie, "Sortie")
	porte.cible_regard = NodePath("../BoutOmbre")
	porte.destinations = [NodePath("../Retour"), NodePath("../Sortie")]
	porte.index_sinon = 0
	porte.index_si_regard = 1
	porte.angle_max_deg = 15.0


## Une dune : une demi-boule de sable aplatie, sans collision.
func _dune(p: Node, pos: Vector3, taille: Vector3) -> void:
	var b: CSGSphere3D = _m.boule(p, pos, 1.0, "dune", 8)
	b.scale = taille


## Énigme 2 : la carrière, fermée de falaises, n'a qu'une entrée, et un
## spinosaure dort en travers. Au bord du Nil, un petit poisson : agrandi
## (perspective forcée) et posé sur la pierre plate devant le dinosaure, il le
## réveille ; il va le manger, se recouche plus loin et libère l'entrée.
func _carriere() -> void:
	var g := _groupe("Carriere")
	# Falaises : x de -64 à -36, z de -14 à 14 ; entrée de 4 m à l'est.
	_boite(g, "FalaiseOuest", Vector3(-63, 3, 0), Vector3(2, 6, 28), "pierre_fonce")
	_boite(g, "FalaiseNord", Vector3(-49, 3, -13), Vector3(26, 6, 2), "pierre_fonce")
	_boite(g, "FalaiseSud", Vector3(-49, 3, 13), Vector3(26, 6, 2), "pierre_fonce")
	_boite(g, "FalaiseEstNord", Vector3(-37, 3, -7), Vector3(2, 6, 10), "pierre_fonce")
	_boite(g, "FalaiseEstSud", Vector3(-37, 3, 7), Vector3(2, 6, 10), "pierre_fonce")
	# Des blocs à moitié taillés dans la carrière.
	for i in 5:
		var pos := Vector3(-55 + 3.2 * (i % 3), 0.6 + 1.2 * (i / 3), -8 + 1.3 * (i / 3))
		_boite(g, "Bloc%d" % i, pos, Vector3(2.4, 1.2, 1.2), "pierre")
	_boite(g, "BlocTaille", Vector3(-46, 0.6, 8.5), Vector3(3, 1.2, 1.6), "pierre")
	var cartouche: Cartouche = load("res://scenes/cartouche.tscn").instantiate()
	cartouche.position = Vector3(-58, 0, 0)
	cartouche.zone = "carriere"
	_ajouter(g, cartouche, "Cartouche")
	# Le spinosaure, la pierre plate où poser l'appât, et sa place après le repas.
	_spinosaure(g, Vector3(-34.5, 0, 0.5))
	_boite(g, "PierrePlate", Vector3(-27.5, 0.2, 0.5), Vector3(3, 0.4, 3), "pierre")
	var zone := Area3D.new()
	zone.position = Vector3(-27.5, 1.9, 0.5)
	_ajouter(g, zone, "ZoneAppat")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(3, 3, 3)
	forme.shape = boite
	_ajouter(zone, forme, "CollisionShape3D")
	var repas := Marker3D.new()
	repas.position = Vector3(-24, 0, -10)
	_ajouter(g, repas, "Repas")
	var dino: Spinosaure = g.get_node("Spinosaure")
	dino.zone_appat = NodePath("../ZoneAppat")
	dino.arrivee = NodePath("../Repas")
	# Les soldats de 1942 ont planté un panneau.
	var panneau: Node3D = _m.militaire(g, "Panneau", "Sign", Vector3(-26, 0, 6), PI * 0.62, 2.0, false)
	_texte(panneau, "Texte", Vector3(0, 1.1, 0.28), "DANGER !\nNe pas réveiller\nle monstre.\nIl ne mange que\nles GROS\npoissons.", 0.0, 0.0015)
	_nil(g)


## Le Nil : une bande d'eau au sud de la carrière, bordée de papyrus. Une
## barrière invisible empêche d'y marcher. Le poisson attend sur la rive.
func _nil(g: Node3D) -> void:
	_boite(g, "Eau", Vector3(-56, 0.02, 23.5), Vector3(88, 0.04, 7), "eau", false)
	_mur_invisible(g, "BarriereNil", Vector3(-56, 1.5, 23.5), Vector3(88, 3, 7.4))
	for i in 9:
		var x := -40.0 + 3.0 * i
		if absf(x + 24) < 2.0:
			continue
		_m.egypte(g, "Papyrus%d" % i, "papyrus_reeds", Vector3(x, 0, 19.4 + 0.3 * (i % 2)), 0.5 * i, 1.0, false)
	_m.egypte(g, "PalmierNil1", "palm_tree", Vector3(-18, 0, 17), 1.0, 1.0, false)
	_m.egypte(g, "PalmierNil2", "palm_tree", Vector3(-33, 0, 16.5), 2.5, 1.1, false)
	var poisson: ObjetPerspectif = load("res://scenes/poisson.tscn").instantiate()
	poisson.position = Vector3(-24, 0.2, 17.5)
	poisson.rotation.y = 0.4
	poisson.taille_depart = 0.4
	# Hors de cette zone (et dans le Nil), il revient sur la rive.
	poisson.zone = AABB(Vector3(-64, -2, -20), Vector3(52, 30, 39.5))
	_ajouter(g, poisson, "Poisson")


## Le spinosaure endormi : le T-rex du pack (9 m), couché, avec une boîte de
## collision qui ferme l'entrée de la carrière. Sa voile est ajoutée au
## lancement (scripts/egypte/spinosaure.gd).
func _spinosaure(g: Node3D, pos: Vector3) -> void:
	var dino := Spinosaure.new()
	dino.position = pos
	_ajouter(g, dino, "Spinosaure")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(5, 2.6, 7)
	forme.shape = boite
	forme.position = Vector3(1.0, 1.3, -0.5)
	_ajouter(dino, forme, "CollisionShape3D")
	var habillage := Node3D.new()
	habillage.set_script(_m.HABILLAGE)
	_ajouter(dino, habillage, "Modele")
	var trex: Node3D = load("res://assets/modeles/dinos/Trex.fbx").instantiate()
	trex.scale = Vector3.ONE * 0.3
	_ajouter(habillage, trex, "Trex")
	var z := _texte(dino, "Ronflement", Vector3(4, 2.6, 2), "Z z z", 0.0, 0.012)
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _rampe() -> void:
	_groupe("Rampe")


func _camp() -> void:
	var g := _groupe("Camp")
	_m.soldat(g, "SoldatGuetteur", Vector3(30, 0, 4), -PI / 2, "Idle")


func _temple() -> void:
	_groupe("Temple")


func _chantier() -> void:
	_groupe("Chantier")
