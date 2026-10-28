extends "res://tools/constructeur.gd"

## Construit scenes/egypte.tscn à partir du code (lancé par construire_egypte.gd).
## Le chantier de la pyramide est au centre ; le mirage et l'arrivée au sud,
## la rampe au nord, la carrière à l'ouest, le camp de 1942 à l'est et le
## temple au sud-est. L'Antiquité est l'époque « passé » du code, 1942 le
## « présent ».

const COULEURS := {
	"sable": "e8955a", "sable_fonce": "c9743f", "pierre": "d2af73", "pierre_fonce": "b99561",
	"brique": "c9744a", "or": "f3c330", "turquoise": "1fb5a8", "eau": "2ec4d6",
	"bois": "8a5a3c", "kaki": "6b7a45", "toile": "c8b48a", "ombre": "b5562a", "fer": "4a3b30",
}

const DEPART := Vector3(0, 0, 70)
## Côté des caisses de Toon Shooter (Crate.gltf), en mètres.
const CAISSE := 0.79
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


## Énigme 3 : une rampe de chantier monte vers une terrasse à 8 m. En
## Antiquité, deux tronçons ne sont pas encore construits (quelques blocs
## flottent à leur place). En 1942, les soldats les ont comblés avec des ponts
## de planches, mais ont barré la rampe de deux tranchées en sacs de sable. On
## monte en basculant : les trous se traversent en 1942, les sacs en Antiquité.
const RAMPE_PIED := -18.0
const RAMPE_LONGUEURS := [6.0, 5.5, 9.0, 5.5, 8.0]
const RAMPE_HAUTEUR := 8.0
const RAMPE_LARGEUR := 3.0
## Épaisseur et hauteur des parapets : plus hauts qu'un saut (1 m), pour
## qu'on ne puisse pas contourner les sacs de sable en marchant dessus.
const PARAPET := Vector2(0.3, 1.2)


func _rampe() -> void:
	var g := _groupe("Rampe")
	var total: float = RAMPE_LONGUEURS.reduce(func(a: float, b: float) -> float: return a + b, 0.0)
	var pente := RAMPE_HAUTEUR / total
	var z := RAMPE_PIED
	for i in RAMPE_LONGUEURS.size():
		var long: float = RAMPE_LONGUEURS[i]
		var pont := i % 2 == 1
		_troncon(g, "Troncon%d" % (i + 1), z, long, pente, pont)
		if pont:
			for k in 3:
				var b := _boite(g, "Flottant%d_%d" % [i + 1, k], Vector3(0.9 * (k - 1), (RAMPE_PIED - z + long * (k + 1) / 4.0) * pente + 0.6 * (k % 2), z - long * (k + 1) / 4.0), Vector3(1.4, 0.7, 1.0), "pierre", false, PASSE)
				b.rotation = Vector3(0.2 * k, 0.5 * k - 0.4, 0.15)
		z -= long
	# Les tranchées, au milieu des tronçons 3 et 5, posées sur la pente.
	for paire in [["SacsA", 2], ["SacsB", 4]]:
		var debut := RAMPE_PIED
		for k in paire[1]:
			debut -= RAMPE_LONGUEURS[k]
		var milieu: float = debut - RAMPE_LONGUEURS[paire[1]] / 2.0
		_m.militaire(g, paire[0], "SackTrench", Vector3(0, (RAMPE_PIED - milieu - 0.46) * pente, milieu))
	# Un soldat dort en travers du premier tronçon, la tête à l'ouest (il
	# laisse 1,2 m pour passer à l'est).
	var dormeur: Node3D = _m.soldat(g, "SoldatDormeur", Vector3(0.3, 1.2 * pente, RAMPE_PIED - 1.2), PI / 2, "Death")
	dormeur.set("pose_finale", true)
	var zzz := _texte(g, "Ronflement", Vector3(-0.8, 1.2 * pente + 0.9, RAMPE_PIED - 1.2), "Z z z", 0.0, 0.008)
	zzz.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var m := EpochMember.new()
	m.epoque = PRESENT
	_ajouter(zzz, m, "EpochMember")
	# La terrasse et son cartouche.
	_boite(g, "Terrasse", Vector3(0, RAMPE_HAUTEUR / 2, z - 5), Vector3(10, RAMPE_HAUTEUR, 10), "brique")
	var cartouche: Cartouche = load("res://scenes/cartouche.tscn").instantiate()
	cartouche.position = Vector3(0, RAMPE_HAUTEUR, z - 6)
	cartouche.zone = "rampe"
	_ajouter(g, cartouche, "Cartouche")


## Un tronçon de rampe de `long` m (le long de -Z, à partir de `z0`), bordé de
## parapets. En briques et plein jusqu'au sol, ou, pour un `pont` de 1942, en
## planches et suspendu (on peut passer dessous).
func _troncon(g: Node3D, nom: String, z0: float, long: float, pente: float, pont: bool) -> CSGCombiner3D:
	var t := CSGCombiner3D.new()
	t.position = Vector3(0, 0, z0)
	# X local = vers le haut de la rampe (-Z du monde), Z local = +X du monde.
	t.rotation.y = PI / 2
	t.use_collision = true
	_ajouter(g, t, nom)
	var h0 := (RAMPE_PIED - z0) * pente
	var h1 := h0 + long * pente
	var demi := RAMPE_LARGEUR / 2 + PARAPET.x
	var dessous := [Vector2(0, h0 - 0.4), Vector2(long, h1 - 0.4)] if pont else [Vector2(0, 0), Vector2(long, 0)]
	var corps := PackedVector2Array(dessous + [Vector2(long, h1), Vector2(0, h0)])
	if not pont and h0 < 0.01:
		corps.remove_at(3)
	_profil(t, "Corps", corps, 2 * demi, demi, "bois" if pont else "brique")
	var bord := PackedVector2Array([Vector2(0, h0), Vector2(long, h1), Vector2(long, h1 + PARAPET.y), Vector2(0, h0 + PARAPET.y)])
	for cote in [-1, 1]:
		var z := demi if cote > 0 else -RAMPE_LARGEUR / 2
		_profil(t, "Parapet" + ("Est" if cote > 0 else "Ouest"), bord, PARAPET.x, z, "kaki" if pont else "pierre_fonce")
	if pont:
		var e := EpochMember.new()
		e.epoque = PRESENT
		_ajouter(t, e, "EpochMember")
	return t


## Un escalier droit de `bas` à `haut`, marches de 25 cm au plus. Le joueur
## ne grimpe pas de marche : une pente invisible passe par le milieu des
## marches (elle commence au sol, une demi-marche avant la première), et la
## dernière marche, au niveau d'arrivée, est solide.
func _escalier(parent: Node3D, nom: String, bas: Vector3, haut: Vector3, largeur: float, couleur: String, epoque := -1, cotes := 0.0) -> StaticBody3D:
	var plat := Vector3(haut.x - bas.x, 0, haut.z - bas.z)
	var long := plat.length()
	var montee := haut.y - bas.y
	var n := ceili(montee / 0.25)
	var marche := long / n
	var corps := StaticBody3D.new()
	# -Z local = le sens de la montée.
	corps.transform = Transform3D(Basis.looking_at(plat), bas - parent.position)
	_ajouter(parent, corps, nom)
	for i in n:
		_boite(corps, "Marche%d" % i, Vector3(0, (i + 1) * montee / n - 0.06, -(i + 0.5) * marche), Vector3(largeur, 0.12, marche + 0.04), couleur, false)
	var angle := atan2(montee, long)
	var hyp := Vector2(long, montee).length()
	for cote in [-1, 1]:
		var limon := _boite(corps, "Limon%d" % (cote + 1), Vector3(cote * (largeur / 2 + 0.06), montee / 2, -long / 2), Vector3(0.12, 0.3, hyp), couleur, false)
		limon.rotation.x = angle
	var pente := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(largeur, 0.2, hyp)
	pente.shape = boite
	pente.rotation.x = angle
	pente.position = Vector3(0, montee / 2 - 0.1 * cos(angle), -(long - marche) / 2 - 0.1 * sin(angle))
	_ajouter(corps, pente, "Pente")
	var palier := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(largeur, 0.2, marche)
	palier.shape = b
	palier.position = Vector3(0, montee - 0.1, -(n - 0.5) * marche)
	_ajouter(corps, palier, "Palier")
	# Côtés fermés (`cotes` m au-dessus des marches) : des panneaux de 0,9 m,
	# prolongés par un mur invisible, pour qu'on ne saute pas de l'escalier.
	if cotes > 0.0:
		for cote in [-1, 1]:
			var x: float = cote * (largeur / 2 + 0.06)
			var panneau := _boite(corps, "Cote%d" % (cote + 1), Vector3(x, montee / 2 + 0.45, -long / 2), Vector3(0.08, 0.9, hyp), couleur, false)
			panneau.rotation.x = angle
			var mur := CollisionShape3D.new()
			var bm := BoxShape3D.new()
			bm.size = Vector3(0.1, cotes, hyp)
			mur.shape = bm
			mur.rotation.x = angle
			mur.position = Vector3(x, montee / 2 + cotes / 2, -long / 2)
			_ajouter(corps, mur, "Mur%d" % (cote + 1))
	if epoque >= 0:
		var e := EpochMember.new()
		e.epoque = epoque
		_ajouter(corps, e, "EpochMember")
	return corps


## Un profil (vu de côté) extrudé sur `epaisseur`, à partir de `z` local.
func _profil(t: Node3D, nom: String, points: PackedVector2Array, epaisseur: float, z: float, couleur: String) -> void:
	var p := CSGPolygon3D.new()
	p.polygon = points
	p.depth = epaisseur
	p.position.z = z
	p.material = _mat(couleur)
	_ajouter(t, p, nom)


## Énigme 4 : le camp de 1942 est installé dans une ancienne enceinte en
## briques (x de 32 à 52, z de -10 à 10), dont la seule entrée, à l'ouest, est
## gardée par une sentinelle (1942) ou fermée par une porte en bois
## (Antiquité). Le mot de passe, l'ânkh, est peint en morceaux sur des piles
## de caisses ; il n'apparaît entier que du haut du mirador, au nord, dehors.
const MIRADOR := Vector3(44, 0, -13.75)
## L'œil du joueur sur le repère du mirador, à 0,6 m du garde-corps sud.
const OEIL_MIRADOR := Vector3(44, 7.6, -13.35)
## L'ânkh est vu 34° sous l'horizon, son centre à 10 m de l'œil ; sa taille
## (1 = 2,85 m de haut dans ce plan) lui donne 28° de haut à l'écran.
const ANKH_PENTE := 0.5934
const ANKH_DISTANCE := 10.0
const ANKH_TAILLE := 1.75


func _camp() -> void:
	var g := _groupe("Camp")
	# L'enceinte : murs de 3 m, une ouverture de 2 m à l'ouest (z de -1 à 1).
	_boite(g, "EnceinteNord", Vector3(42, 1.5, -10), Vector3(20.6, 3, 0.6), "brique")
	_boite(g, "EnceinteSud", Vector3(42, 1.5, 10), Vector3(20.6, 3, 0.6), "brique")
	_boite(g, "EnceinteEst", Vector3(52, 1.5, 0), Vector3(0.6, 3, 19.4), "brique")
	_boite(g, "EnceinteOuestNord", Vector3(32, 1.5, -5.35), Vector3(0.6, 3, 8.7), "brique")
	_boite(g, "EnceinteOuestSud", Vector3(32, 1.5, 5.35), Vector3(0.6, 3, 8.7), "brique")
	var porte := _boite(g, "PorteAntique", Vector3(32, 1.5, 0), Vector3(0.4, 3, 2), "bois", true, PASSE)
	for i in 2:
		_boite(porte, "Ferrure%d" % i, Vector3(0, 0.8 - 1.6 * i, 0), Vector3(0.46, 0.18, 2), "fer")
	_sentinelle(g, Vector3(32, 0, 0))
	_mirador(g)
	_ankh(g)
	# Les tentes, le cartouche au fond, des soldats et un tank ensablé.
	for i in 2:
		var tente := CSGPolygon3D.new()
		tente.polygon = PackedVector2Array([Vector2(-1.6, 0), Vector2(1.6, 0), Vector2(0, 2.3)])
		tente.depth = 4.0
		tente.position = Vector3(48.5, 0, -3 + 10 * i)
		tente.material = _mat("toile")
		tente.use_collision = true
		_ajouter(g, tente, "Tente%d" % (i + 1))
		var e := EpochMember.new()
		e.epoque = PRESENT
		_ajouter(tente, e, "EpochMember")
	var cartouche: Cartouche = load("res://scenes/cartouche.tscn").instantiate()
	cartouche.position = Vector3(49.5, 0, 0)
	cartouche.zone = "camp"
	_ajouter(g, cartouche, "Cartouche")
	_m.soldat(g, "SoldatSalut", Vector3(46.5, 0, -1.5), -PI / 2, "Wave")
	_m.soldat(g, "SoldatRepos", Vector3(26.5, 0, 9), PI * 0.8, "Idle")
	_m.militaire(g, "Tank", "Tank", Vector3(24, -0.6, 12.5), PI * 0.3, 1.2)


## La sentinelle, dans l'ouverture : un soldat derrière une barrière. Elle
## recule dans le camp et longe le mur quand l'ânkh est aligné.
func _sentinelle(g: Node3D, pos: Vector3) -> void:
	var s := Sentinelle.new()
	s.position = pos
	s.ecart = Vector3(1.5, 0, 2.0)
	s.alignement = NodePath("../Ankh")
	s.porte_antique = NodePath("../PorteAntique")
	_ajouter(g, s, "Sentinelle")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(0.6, 3, 2)
	forme.shape = boite
	forme.position = Vector3(0, 1.5, 0)
	_ajouter(s, forme, "CollisionShape3D")
	var e := EpochMember.new()
	e.epoque = PRESENT
	_ajouter(s, e, "EpochMember")
	_m.soldat(s, "SoldatSentinelle", Vector3(0.3, 0, 0), -PI / 2, "Idle")
	_m.militaire(s, "Barriere", "Barrier_Single", Vector3(-0.4, 0, 0), PI / 2, 0.8, false)
	var approche := Area3D.new()
	approche.position = Vector3(-2.5, 1.25, 0)
	_ajouter(s, approche, "Approche")
	var zone := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(4, 2.5, 4)
	zone.shape = b
	_ajouter(approche, zone, "CollisionShape3D")


## Le mirador de 1942, au nord du camp, à 2,5 m du mur : une cabine à 6 m,
## fermée de vitres (des murs invisibles au-dessus d'un garde-corps bas), et
## un escalier aux côtés fermés : on ne saute pas dans le camp. En haut, on ne
## peut pas basculer vers l'Antiquité, où le mirador n'existe pas (on
## tomberait sur le mur) : un volume invisible de l'Antiquité l'empêche.
func _mirador(g: Node3D) -> void:
	var m := CSGCombiner3D.new()
	m.position = MIRADOR
	m.use_collision = true
	_ajouter(g, m, "Mirador")
	for i in 4:
		var coin := Vector3(-1.0 if i % 2 == 0 else 1.0, 0, -1.0 if i < 2 else 1.0)
		_boite(m, "Pied%d" % i, coin * 0.95 + Vector3(0, 3, 0), Vector3(0.25, 6, 0.25), "bois")
		_boite(m, "Poteau%d" % i, coin * 1.05 + Vector3(0, 7.1, 0), Vector3(0.12, 2.2, 0.12), "bois")
	_boite(m, "Plateforme", Vector3(0, 5.85, 0), Vector3(2.2, 0.3, 2.2), "bois")
	_boite(m, "Toit", Vector3(0, 8.25, 0), Vector3(2.6, 0.15, 2.6), "toile")
	# Garde-corps de 0,6 m ; au nord, une ouverture de 1,2 m pour l'escalier.
	_boite(m, "GardeCorpsSud", Vector3(0, 6.3, 1.05), Vector3(2.2, 0.6, 0.1), "kaki")
	for x in [-1.05, 1.05]:
		var cote := "Ouest" if x < 0 else "Est"
		_boite(m, "GardeCorps" + cote, Vector3(x, 6.3, 0), Vector3(0.1, 0.6, 2.0), "kaki")
		_boite(m, "GardeCorpsNord" + cote, Vector3(x * 0.81, 6.3, -1.05), Vector3(0.4, 0.6, 0.1), "kaki")
	_boite(m, "Repere", Vector3(0, 6.01, OEIL_MIRADOR.z - MIRADOR.z), Vector3(0.6, 0.02, 0.6), "or", false)
	var e := EpochMember.new()
	e.epoque = PRESENT
	_ajouter(m, e, "EpochMember")
	var vitres := StaticBody3D.new()
	vitres.position = MIRADOR
	_ajouter(g, vitres, "Vitres")
	# Au sud, la vitre commence à 1,5 m du plancher : on voit le camp sous elle
	# (la fente de 0,9 m est trop basse pour qu'on y passe).
	for v in [[Vector3(0, 7.85, 1.05), Vector3(2.2, 0.7, 0.1)], [Vector3(-1.05, 7.4, 0), Vector3(0.1, 1.6, 2.2)],
			[Vector3(1.05, 7.4, 0), Vector3(0.1, 1.6, 2.2)], [Vector3(-0.85, 7.4, -1.05), Vector3(0.5, 1.6, 0.1)],
			[Vector3(0.85, 7.4, -1.05), Vector3(0.5, 1.6, 0.1)]]:
		var forme := CollisionShape3D.new()
		var boite := BoxShape3D.new()
		boite.size = v[1]
		forme.shape = boite
		forme.position = v[0]
		_ajouter(vitres, forme, "Vitre%d" % vitres.get_child_count())
	var ev := EpochMember.new()
	ev.epoque = PRESENT
	_ajouter(vitres, ev, "EpochMember")
	var bas := MIRADOR + Vector3(0, 0, -11.1)
	_escalier(g, "EscalierMirador", bas, MIRADOR + Vector3(0, 6, -1.1), 1.2, "bois", PRESENT, 2.0)
	var blocage := StaticBody3D.new()
	_ajouter(g, blocage, "BlocageBascule")
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(3.2, 7, MIRADOR.z + 1.1 - bas.z + 0.4)
	forme.shape = boite
	forme.position = Vector3(MIRADOR.x, 2.0 + 3.5, (MIRADOR.z + 1.1 + bas.z) / 2)
	_ajouter(blocage, forme, "CollisionShape3D")
	var eb := EpochMember.new()
	eb.epoque = PASSE
	_ajouter(blocage, eb, "EpochMember")
	var vue := Marker3D.new()
	vue.transform = Transform3D(Basis.looking_at(_centre_ankh() - OEIL_MIRADOR), OEIL_MIRADOR)
	_ajouter(g, vue, "PointDeVueAnkh")


## Le centre de l'image de l'ânkh, vu du mirador.
func _centre_ankh() -> Vector3:
	return OEIL_MIRADOR + Vector3(0, -sin(ANKH_PENTE), cos(ANKH_PENTE)) * ANKH_DISTANCE


## L'ânkh, en anamorphose : 6 morceaux dorés peints sur le dessus de piles de
## caisses de hauteurs différentes. Chaque morceau est un morceau de l'ânkh
## projeté, depuis l'œil du mirador, sur le dessus de sa pile : vus du
## mirador, ils forment un ânkh entier ; d'ailleurs, des taches sans forme.
## Les piles baissent du pied de l'ânkh vers sa boucle (du plus près au plus
## loin du mirador) : ainsi, aucune ne cache un morceau.
func _ankh(g: Node3D) -> void:
	var centre := _centre_ankh()
	var axe := (centre - OEIL_MIRADOR).normalized()
	var droite := axe.cross(Vector3.UP).normalized()
	var haut := droite.cross(axe)
	var ankh := Alignement.new()
	# Le nœud est dans la boucle de l'ânkh, au-dessus des caisses : on le voit
	# du mirador sans que rien ne le cache.
	ankh.position = centre + haut * 0.6 * ANKH_TAILLE
	_ajouter(g, ankh, "Ankh")
	ankh.point_de_vue = NodePath("../PointDeVueAnkh")
	var e := EpochMember.new()
	e.epoque = PRESENT
	_ajouter(ankh, e, "EpochMember")
	# [nom, position dans l'image, taille, rotation, hauteur de la pile]
	# (gauche et droite comme vus du mirador)
	var morceaux := [
		["Tige", Vector2(0, -0.95), Vector2(0.36, 1.3), 0.0, 2.6],
		["BarreGauche", Vector2(-0.62, 0), Vector2(0.75, 0.32), 0.0, 2.0],
		["BarreDroite", Vector2(0.62, 0), Vector2(0.75, 0.32), 0.0, 2.0],
		["BoucleGauche", Vector2(-0.42, 0.585), Vector2(0.26, 0.74), 0.25, 1.6],
		["BoucleDroite", Vector2(0.42, 0.585), Vector2(0.26, 0.74), -0.25, 1.6],
		["BoucleHaut", Vector2(0, 1.12), Vector2(0.62, 0.26), 0.0, 0.6],
	]
	for d in morceaux:
		var nom: String = d[0]
		var dans_image: Vector2 = d[1]
		var taille: Vector2 = d[2]
		var rot: float = d[3]
		var h: float = d[4]
		var coins: Array[Vector3] = []
		for coin in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var q: Vector2 = ((coin * taille / 2).rotated(rot) + dans_image) * ANKH_TAILLE
			var point := centre + droite * q.x + haut * q.y
			coins.append(OEIL_MIRADOR + (point - OEIL_MIRADOR) * (h + 0.02 - OEIL_MIRADOR.y) / (point.y - OEIL_MIRADOR.y))
		var milieu := (coins[0] + coins[1] + coins[2] + coins[3]) / 4
		var morceau := CSGPolygon3D.new()
		morceau.position = milieu - ankh.position
		# Couché : le X et le Y du polygone deviennent le X et le -Z du monde,
		# et l'épaisseur descend jusqu'au dessus de la pile.
		morceau.rotation.x = -PI / 2
		morceau.depth = 0.02
		var polygone := PackedVector2Array()
		for c in coins:
			polygone.append(Vector2(c.x - milieu.x, milieu.z - c.z))
		morceau.polygon = polygone
		morceau.material = _mat("or")
		_ajouter(ankh, morceau, nom)
		# La pile : de 3 cm plus large que le morceau, sauf au fond (côté
		# opposé au mirador), pour ne pas cacher le morceau suivant.
		var x0 := INF
		var x1 := -INF
		var z0 := INF
		var z1 := -INF
		for c in coins:
			x0 = minf(x0, c.x - 0.03)
			x1 = maxf(x1, c.x + 0.03)
			z0 = minf(z0, c.z - 0.03)
			z1 = maxf(z1, c.z)
		var grille := Vector3i(maxi(1, roundi((x1 - x0) / 0.95)), maxi(1, roundi(h / 0.95)), maxi(1, roundi((z1 - z0) / 0.95)))
		var cote := Vector3(x1 - x0, h, z1 - z0) / Vector3(grille)
		var i := 0
		for a in grille.x:
			for b in grille.y:
				for c in grille.z:
					_m.caisse(g, "Caisse%s%d" % [nom, i], Vector3(x0 + (a + 0.5) * cote.x, b * cote.y, z0 + (c + 0.5) * cote.z), cote)
					i += 1



func _temple() -> void:
	_groupe("Temple")


func _chantier() -> void:
	_groupe("Chantier")
