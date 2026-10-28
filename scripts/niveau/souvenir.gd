class_name Souvenir
extends Niveau

## Base des niveaux de l'histoire de Thomas : les pensées qui viennent du
## regard, le réveil (l'écran noir qui s'ouvre), la chute dans les toiles et
## le corps qu'on ne voit que dans les miroirs.

const DUREE_REVEIL := 2.5
## Un obstacle plus proche que la pensée (de cette marge) la cache.
const MARGE_VUE := 0.4

var _file: Array[String] = []

@onready var _joueur: Player = $Player
@onready var _chute: ChuteToiles = $Interface/ChuteToiles
@onready var _noir: ColorRect = $Interface/Noir


func _forme_du_reflet(parent: Node3D, mesh: Mesh, pos: Vector3, couleur: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.layers = Miroir.COUCHE_REFLET
	mi.material_override = Style.materiau(couleur)
	parent.add_child(mi)
	return mi


## L'écran noir s'ouvre, puis la pensée s'affiche (si elle n'est pas vide).
func _ouvrir_les_yeux(pensee: String, delai := 0.5) -> Tween:
	_noir.color.a = 1.0
	var t := create_tween()
	t.tween_interval(delai)
	t.tween_property(_noir, "color:a", 0.0, DUREE_REVEIL)
	if pensee != "":
		t.tween_callback(penser.bind(pensee))
	return t


## Affiche une pensée, après celles qui attendent déjà.
func penser(texte: String) -> void:
	_file.append(texte)


func _process(delta: float) -> void:
	super._process(delta)
	if not _file.is_empty() and _reste_message <= 0.3:
		afficher("« %s »" % _file.pop_front())


func _ecouter_les_pensees() -> void:
	var cam := _joueur.camera
	var oeil := cam.global_position
	var regard := -cam.global_basis.z
	for n in get_tree().get_nodes_in_group(Pensee.GROUPE):
		var p := n as Pensee
		if p.dite or not p.active or not is_ancestor_of(p):
			continue
		if not Pensee.vue(oeil, regard, p.global_position, p.distance, p.angle_max_deg, p.regard):
			continue
		if p.regard and not _visible(oeil, p.global_position):
			continue
		p.dite = true
		penser(p.texte)


## Rien de solide ne cache ce point.
func _visible(oeil: Vector3, point: Vector3) -> bool:
	var rayon := PhysicsRayQueryParameters3D.create(oeil, point)
	rayon.exclude = [_joueur.get_rid()]
	var touche := get_world_3d().direct_space_state.intersect_ray(rayon)
	return touche.is_empty() or oeil.distance_to(touche["position"]) >= oeil.distance_to(point) - MARGE_VUE


## Le joueur regarde ce point (à moins de `angle_max` degrés), sans obstacle.
func _regarde(point: Vector3, angle_max: float, distance_max := 30.0) -> bool:
	var cam := _joueur.camera
	return Pensee.vue(cam.global_position, -cam.global_basis.z, point, distance_max, angle_max, true) \
		and _visible(cam.global_position, point)


func _tomber_dans_les_toiles(joueur: Player) -> void:
	joueur.velocity = Vector3.ZERO
	joueur.set_physics_process(false)
	_chute.lancer()
