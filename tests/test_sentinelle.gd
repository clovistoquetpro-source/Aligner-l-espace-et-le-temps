extends RefCounted

var tree: SceneTree
var _noeuds: Array[Node] = []


func nettoyer() -> void:
	for n in _noeuds:
		if is_instance_valid(n):
			n.free()


func _ajouter(n: Node) -> Node:
	tree.root.add_child(n)
	_noeuds.append(n)
	return n


## Une sentinelle en (2, 0, 0), son alignement et la porte antique.
func _monde() -> Sentinelle:
	var monde: Node3D = _ajouter(Node3D.new())
	var ankh := Alignement.new()
	ankh.name = "Ankh"
	ankh.set_physics_process(false)
	monde.add_child(ankh)
	var porte := CSGBox3D.new()
	porte.name = "PorteAntique"
	monde.add_child(porte)
	var s := Sentinelle.new()
	s.position = Vector3(2, 0, 0)
	s.alignement = NodePath("../Ankh")
	s.porte_antique = NodePath("../PorteAntique")
	s.duree = 0.05
	var approche := Area3D.new()
	approche.name = "Approche"
	s.add_child(approche)
	monde.add_child(s)
	return s


func test_refuse_avant_le_mot_de_passe() -> void:
	var s := _monde()
	var fois := [0]
	s.refuse.connect(func() -> void: fois[0] += 1)
	var joueur: Player = _ajouter(load("res://scenes/player.tscn").instantiate())
	s._joueur_approche(joueur)
	T.eq(fois[0], 1, "« non » de la tête")
	T.proche(s.position, Vector3(2, 0, 0), "il ne bouge pas")
	s._joueur_approche(_ajouter(Node3D.new()))
	T.eq(fois[0], 1, "seul le joueur compte")


func test_s_ecarte_apres_l_alignement() -> void:
	var s := _monde()
	var porte := s.get_node(s.porte_antique)
	var fois := [0]
	s.refuse.connect(func() -> void: fois[0] += 1)
	(s.get_node(s.alignement) as Alignement).resolu.emit()
	await tree.create_timer(0.2).timeout
	T.proche(s.position, Vector3(3.5, 0, 0), "il s'est écarté")
	T.ok(not is_instance_valid(porte) or porte.is_queued_for_deletion(), "la porte antique s'ouvre")
	T.ok(s.a_laisse_passer, "il laisse passer")
	s._joueur_approche(_ajouter(load("res://scenes/player.tscn").instantiate()))
	T.eq(fois[0], 0, "il ne refuse plus")


func test_absente_ne_refuse_pas() -> void:
	var s := _monde()
	var fois := [0]
	s.refuse.connect(func() -> void: fois[0] += 1)
	s.visible = false
	s._joueur_approche(_ajouter(load("res://scenes/player.tscn").instantiate()))
	T.eq(fois[0], 0, "pas de sentinelle dans cette époque : pas de « non »")
