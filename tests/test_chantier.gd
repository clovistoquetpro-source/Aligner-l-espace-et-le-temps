extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()


## Un chantier de test : un alignement de 8 blocs (2 par zone) vu depuis
## (0, 0, 5), et une caméra posée sur le point de vue.
func _monde() -> Array:
	var monde := Node3D.new()
	tree.root.add_child(monde)
	_noeuds.append(monde)
	var pyramide := Alignement.new()
	pyramide.name = "Pyramide"
	monde.add_child(pyramide)
	pyramide.set_physics_process(false)
	for i in 8:
		var bloc := CSGBox3D.new()
		bloc.position = Vector3(i - 3.5, 0, 0)
		bloc.set_meta("zone", Chantier.ZONES[i / 2])
		pyramide.add_child(bloc)
	var vue := Marker3D.new()
	vue.position = Vector3(0, 0, 5)
	monde.add_child(vue)
	pyramide.point_de_vue = pyramide.get_path_to(vue)
	var chantier := Chantier.new()
	chantier.duree_vol = 0.05
	chantier.alignement = NodePath("../Pyramide")
	monde.add_child(chantier)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, 5)
	monde.add_child(cam)
	await tree.physics_frame
	return [chantier, pyramide, cam]


func _visibles(pyramide: Alignement) -> int:
	var n := 0
	for b in pyramide.get_children():
		if b.visible:
			n += 1
	return n


func test_au_depart_rien() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	T.eq(chantier.revenus(), 0, "aucune zone")
	T.eq(_visibles(r[1]), 0, "blocs cachés")
	T.ok(not r[1].actif, "alignement final inactif")


func test_une_zone() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	var recus := []
	chantier.groupe_revenu.connect(func(z: String, n: int) -> void: recus.append([z, n]))
	chantier.zone_reussie("carriere")
	T.eq(_visibles(r[1]), 2, "les 2 blocs de la carrière reviennent")
	T.eq(chantier.revenus(), 1, "une zone")
	T.eq(recus, [["carriere", 1]], "signal groupe_revenu")


func test_deux_fois_la_meme_zone() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	var recus := []
	chantier.groupe_revenu.connect(func(z: String, n: int) -> void: recus.append(z))
	chantier.zone_reussie("rampe")
	chantier.zone_reussie("rampe")
	T.eq(chantier.revenus(), 1, "comptée une fois")
	T.eq(recus.size(), 1, "un seul signal")


func test_zone_inconnue() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	chantier.zone_reussie("plage")
	T.eq(chantier.revenus(), 0, "zone inconnue ignorée")
	T.eq(_visibles(r[1]), 0, "rien ne revient")


func test_complet() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	var fois := [0]
	chantier.complet.connect(func() -> void: fois[0] += 1)
	for z in Chantier.ZONES:
		chantier.zone_reussie(z)
	chantier.zone_reussie("carriere")
	T.eq(fois[0], 1, "complet émis une fois")
	T.ok(chantier.est_complet(), "chantier complet")
	T.ok(r[1].actif, "alignement final actif")
	T.eq(_visibles(r[1]), 8, "tous les blocs sont là")


func test_vue_avant_la_fin() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	var pyramide: Alignement = r[1]
	for z in ["carriere", "rampe", "camp"]:
		chantier.zone_reussie(z)
	pyramide.verifier(r[2])
	T.ok(not pyramide.est_resolu, "3 zones : pas encore")
	chantier.zone_reussie("temple")
	pyramide.verifier(r[2])
	T.ok(pyramide.est_resolu, "4 zones : résolu")


func test_les_blocs_volent_depuis_le_cartouche() -> void:
	var r: Array = await _monde()
	var chantier: Chantier = r[0]
	var bloc: CSGBox3D = r[1].get_child(0)
	var place := bloc.position
	for z in Chantier.ZONES:
		chantier.zone_reussie(z, Vector3(30, 0, 0))
	T.ok(bloc.position.distance_to(place) > 1.0, "le bloc part du cartouche")
	T.ok(not r[1].actif, "pas d'alignement pendant le vol")
	await tree.create_timer(0.2).timeout
	T.proche(bloc.position, place, "le bloc est arrivé")
	T.ok(r[1].actif, "alignement actif à l'arrivée")
