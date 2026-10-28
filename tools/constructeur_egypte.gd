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
	"lapis": "183da0", "papier": "efe3c2", "rouge": "d62828", "encre": "2b2118",
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



## Énigme 5 : la salle des colonnes du temple (x de 27 à 47, z de 32 à 38)
## ramène à son début, sauf si on passe la porte du fond en regardant la
## dalle du scarabée. Seule une carte des soldats de 1942 le dit.
func _temple() -> void:
	var t := _groupe("Temple")
	# Le pylône (décor) devant le mur de l'entrée ; ses tours sont des murs
	# invisibles, pour que le passage reste libre même avec le modèle du pack.
	_m.egypte(t, "Pylone", "temple_gate_pylon", Vector3(25.44, 0, 35), -PI / 2, 1.2, false)
	_mur_invisible(t, "TourNord", Vector3(25.44, 3.1, 32.72), Vector3(1.92, 6.2, 2.64))
	_mur_invisible(t, "TourSud", Vector3(25.44, 3.1, 37.28), Vector3(1.92, 6.2, 2.64))
	for i in 2:
		_m.egypte(t, "Statue%d" % (i + 1), "pharaoh_statue", Vector3(22.8, 0, 32.4 + 5.2 * i), -PI / 2)
	# Les murs (5,5 m) et les plafonds de la salle et du sanctuaire.
	_boite(t, "MurNord", Vector3(40.3, 2.75, 31.7), Vector3(27.8, 5.5, 0.6), "pierre")
	_boite(t, "MurSud", Vector3(40.3, 2.75, 38.3), Vector3(27.8, 5.5, 0.6), "pierre")
	_boite(t, "MurOuestNord", Vector3(26.7, 2.75, 33.02), Vector3(0.6, 5.5, 2.04), "pierre")
	_boite(t, "MurOuestSud", Vector3(26.7, 2.75, 36.98), Vector3(0.6, 5.5, 2.04), "pierre")
	_boite(t, "MurOuestHaut", Vector3(26.7, 5.09, 35), Vector3(0.6, 0.82, 1.92), "pierre")
	_boite(t, "MurFondNord", Vector3(47.3, 2.75, 32.875), Vector3(0.6, 5.5, 1.75), "pierre")
	_boite(t, "MurFondSud", Vector3(47.3, 2.75, 37.125), Vector3(0.6, 5.5, 1.75), "pierre")
	_boite(t, "MurFondHaut", Vector3(47.3, 4.375, 35), Vector3(0.6, 2.25, 2.5), "pierre")
	_boite(t, "MurEst", Vector3(53.9, 2.75, 35), Vector3(0.6, 5.5, 6), "pierre")
	_boite(t, "PlafondSalle", Vector3(37, 5.25, 35), Vector3(20, 0.5, 6), "pierre_fonce")
	_boite(t, "PlafondSanctuaire", Vector3(50.6, 5.25, 35), Vector3(6, 0.5, 6), "pierre_fonce")
	_boite(t, "Pavement", Vector3(39.05, 0.01, 35), Vector3(29.1, 0.02, 6), "pierre_fonce", false)
	# Deux rangées de 4 colonnes ; elles touchent le plafond.
	for i in 4:
		for k in 2:
			_m.egypte(t, "Colonne%d" % (2 * i + k), "column_papyrus", Vector3(30.5 + 4 * i, 0, 33.2 + 3.6 * k), 0.0, 5.0 / 4.93)
	# Les dalles : trois par mur ; le scarabée et le serpent sont au-delà de
	# la porte, au bout de la salle.
	var dalles := [["Oeil", 32.5, 0], ["Plume", 36.5, 0], ["Scarabee", 45.5, 0], ["Soleil", 32.5, 1], ["Ankh", 36.5, 1], ["Serpent", 45.5, 1]]
	for d: Array in dalles:
		var sud: bool = d[2] == 1
		_dalle(t, d[0], Vector3(d[1], 0, 38.0 if sud else 32.0), PI if sud else 0.0)
	for x in [28.6, 40.5]:
		_torche(t, "TorcheNord%d" % x, Vector3(x, 2.4, 32), 0.0)
		_torche(t, "TorcheSud%d" % x, Vector3(x, 2.4, 38), PI)
	# La porte du fond : un cadre, et la porte trompeuse qui couvre toute la
	# salle. Tout droit, on revient au début ; en regardant le scarabée, on
	# passe (Sanctuaire = la porte elle-même : pas de saut visible).
	_boite(t, "MontantNord", Vector3(43.5, 2.5, 32.2), Vector3(0.5, 5, 0.4), "pierre_fonce")
	_boite(t, "MontantSud", Vector3(43.5, 2.5, 37.8), Vector3(0.5, 5, 0.4), "pierre_fonce")
	_boite(t, "Linteau", Vector3(43.5, 4.6, 35), Vector3(0.5, 0.8, 5.2), "pierre_fonce")
	_boite(t, "Frise", Vector3(43.24, 4.6, 35), Vector3(0.02, 0.2, 5.2), "or", false)
	var porte := _porte_trompeuse(t, "Boucle", Vector3(43.5, 0, 35), Vector3(6, 5, 0.4), PI / 2)
	for m: Array in [["Debut", 28.3], ["Sanctuaire", 43.5]]:
		var repere := Marker3D.new()
		repere.position = Vector3(m[1], 0, 35)
		repere.rotation.y = PI / 2
		_ajouter(t, repere, m[0])
	porte.cible_regard = NodePath("../DalleScarabee")
	porte.destinations = [NodePath("../Debut"), NodePath("../Sanctuaire")]
	porte.index_sinon = 0
	porte.index_si_regard = 1
	porte.angle_max_deg = 15.0
	# Le sanctuaire : une statue, deux torches et le cartouche.
	_m.egypte(t, "Statue", "pharaoh_statue", Vector3(52.6, 0, 35), -PI / 2)
	for z in [33.0, 37.0]:
		_torche(t, "TorcheSanctuaire%d" % z, Vector3(53.6, 2.4, z), -PI / 2)
	var cartouche: Cartouche = load("res://scenes/cartouche.tscn").instantiate()
	cartouche.position = Vector3(50.4, 0, 35)
	cartouche.zone = "temple"
	_ajouter(t, cartouche, "Cartouche")
	_carte_soldats(t)


## Une dalle de hiéroglyphes contre un mur, en `pos` (au sol, contre le mur),
## qui regarde vers `rot_y`. Le nœud est au centre de son grand symbole :
## c'est le point que la porte trompeuse vise.
func _dalle(t: Node3D, sorte: String, pos: Vector3, rot_y: float) -> Node3D:
	var d := Node3D.new()
	d.position = pos + Basis(Vector3.UP, rot_y) * Vector3(0, 1.15, 0.34)
	d.rotation.y = rot_y
	_ajouter(t, d, "Dalle" + sorte)
	_m.egypte(d, "Pierre", "hieroglyph_slab", Vector3(0, -1.15, -0.17))
	_symbole(d, "Symbole", sorte, "lapis", "or")
	return d


## Une torche fixée au mur en `pos`, tournée vers `rot_y`.
func _torche(t: Node3D, nom: String, pos: Vector3, rot_y: float) -> void:
	var p: CSGCombiner3D = _m.prop(t, nom, pos, rot_y, false)
	_m.cube(p, Vector3(0, 0, 0.12), Vector3(0.08, 0.08, 0.24), "ocre_fonce")
	_m.cyl(p, Vector3(0, 0.08, 0.26), 0.12, 0.18, "or", 8, true, Vector3(PI, 0, 0))
	_m.cyl(p, Vector3(0, 0.3, 0.26), 0.09, 0.3, "flamme", 6, true)
	_m.lumiere(p, Vector3(0, 0.5, 0.5), 7.0, 1.1, Color("ff9f1c"))


## La carte des soldats de 1942, punaisée sur la première colonne du côté
## sud, face à l'entrée : le scarabée entouré de rouge.
func _carte_soldats(t: Node3D) -> void:
	var carte: CSGCombiner3D = _m.prop(t, "CarteSoldats", Vector3(30.03, 1.55, 36.8), -PI / 2, false, PRESENT)
	_boite(carte, "Papier", Vector3.ZERO, Vector3(0.6, 0.8, 0.01), "papier", false)
	var dessin := _symbole(carte, "Scarabee", "Scarabee", "encre", "papier")
	dessin.position = Vector3(0, 0.12, 0.006)
	dessin.scale = Vector3(0.24, 0.24, 0.1)
	_anneau(carte, Vector3(0, 0.12, 0.009), 0.17, 0.2, "rouge").name = "Cercle"
	_ovale(carte, Vector3(0, 0.36, 0.008), Vector2(0.025, 0.025), "rouge").name = "Punaise"
	var texte := _texte(carte, "Texte", Vector3(0, -0.22, 0.008), "Pour sortir :\nle scarabée", 0.0, 0.001)
	texte.modulate = Color(COULEURS["encre"])
	texte.outline_size = 0


## Un hiéroglyphe en relief d'environ 1 m de haut, dans le plan XY, tourné
## vers +Z : `couleur` pour le dessin, `detail` pour ce qui ressort dessus.
func _symbole(parent: Node3D, nom: String, sorte: String, couleur: String, detail: String) -> CSGCombiner3D:
	var s := CSGCombiner3D.new()
	_ajouter(parent, s, nom)
	match sorte:
		"Scarabee":
			_ovale(s, Vector3(0, -0.08, 0), Vector2(0.26, 0.34), couleur)
			_ovale(s, Vector3(0, 0.33, 0), Vector2(0.14, 0.1), couleur)
			_trait(s, Vector3(0, -0.1, 0.03), Vector2(0.025, 0.5), 0.0, detail)
			for cote in [-1, 1]:
				for k in 3:
					_trait(s, Vector3(cote * 0.3, -0.26 + 0.17 * k, 0), Vector2(0.3, 0.045), cote * (0.45 - 0.45 * k), couleur)
				_trait(s, Vector3(cote * 0.12, 0.47, 0), Vector2(0.04, 0.16), -cote * 0.5, couleur)
		"Oeil":
			_ovale(s, Vector3(0, 0.08, 0), Vector2(0.42, 0.17), couleur)
			_ovale(s, Vector3(0, 0.08, 0.02), Vector2(0.3, 0.11), detail)
			_disque(s, Vector3(0, 0.08, 0.06), 0.09, couleur)
			_trait(s, Vector3(0, 0.34, 0), Vector2(0.84, 0.07), -0.08, couleur)
			_trait(s, Vector3(-0.04, -0.22, 0), Vector2(0.06, 0.36), 0.15, couleur)
			_trait(s, Vector3(0.2, -0.16, 0), Vector2(0.4, 0.06), -0.6, couleur)
			_anneau(s, Vector3(0.36, -0.36, 0), 0.07, 0.12, couleur)
		"Ankh":
			_anneau(s, Vector3(0, 0.36, 0), 0.1, 0.19, couleur).scale = Vector3(1, 1, 1.3)
			_trait(s, Vector3(0, 0.06, 0), Vector2(0.6, 0.11), 0.0, couleur)
			_trait(s, Vector3(0, -0.3, 0), Vector2(0.12, 0.62), 0.0, couleur)
		"Plume":
			_ovale(s, Vector3(0.04, 0, 0), Vector2(0.14, 0.48), couleur, -0.15)
			_trait(s, Vector3(0, -0.02, 0.03), Vector2(0.03, 1.0), -0.15, detail)
			_ovale(s, Vector3(0.12, 0.47, 0), Vector2(0.08, 0.06), couleur)
		"Soleil":
			_disque(s, Vector3(0, 0.05, 0), 0.24, couleur)
			_disque(s, Vector3(0, 0.05, 0.03), 0.13, detail)
			for k in 8:
				var a := TAU * k / 8.0
				_trait(s, Vector3(sin(a) * 0.38, 0.05 + cos(a) * 0.38, 0), Vector2(0.06, 0.16), -a, couleur)
		"Serpent":
			for k in 9:
				_ovale(s, Vector3(0.16 * sin(k * 0.9), -0.45 + 0.1 * k, 0), Vector2(0.08, 0.08), couleur)
			_ovale(s, Vector3(0.2, 0.5, 0), Vector2(0.13, 0.09), couleur)
			_disque(s, Vector3(0.24, 0.52, 0.04), 0.025, detail)
			_trait(s, Vector3(0.38, 0.5, 0), Vector2(0.14, 0.025), 0.0, "rouge")
	return s


func _ovale(s: Node3D, pos: Vector3, rayons: Vector2, couleur: String, rot_z := 0.0) -> CSGSphere3D:
	var b := CSGSphere3D.new()
	b.position = pos
	b.rotation.z = rot_z
	b.radius = 1.0
	b.scale = Vector3(rayons.x, rayons.y, 0.05)
	b.radial_segments = 16
	b.rings = 8
	b.material = _mat(couleur)
	return _ajouter(s, b, "Forme%d" % s.get_child_count())


func _trait(s: Node3D, pos: Vector3, taille: Vector2, rot_z: float, couleur: String) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.position = pos
	b.rotation.z = rot_z
	b.size = Vector3(taille.x, taille.y, 0.06)
	b.material = _mat(couleur)
	return _ajouter(s, b, "Forme%d" % s.get_child_count())


func _disque(s: Node3D, pos: Vector3, rayon: float, couleur: String) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.position = pos
	c.rotation.x = PI / 2
	c.radius = rayon
	c.height = 0.06
	c.sides = 20
	c.material = _mat(couleur)
	return _ajouter(s, c, "Forme%d" % s.get_child_count())


func _anneau(s: Node3D, pos: Vector3, interieur: float, exterieur: float, couleur: String) -> CSGTorus3D:
	var a := CSGTorus3D.new()
	a.position = pos
	a.rotation.x = PI / 2
	a.inner_radius = interieur
	a.outer_radius = exterieur
	a.sides = 20
	a.ring_sides = 6
	a.material = _mat(couleur)
	return _ajouter(s, a, "Forme%d" % s.get_child_count())


func _chantier() -> void:
	_groupe("Chantier")
