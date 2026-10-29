class_name Souvenir
extends Niveau

## Base des niveaux de l'histoire de Thomas : les pensées qui viennent du
## regard, le réveil (l'écran noir qui s'ouvre), les yeux fermés (F), la chute
## dans les toiles, le corps qu'on ne voit que dans les miroirs, et l'aide sur
## les touches.

const DUREE_REVEIL := 2.5
## Un obstacle plus proche que la pensée (de cette marge) la cache.
const MARGE_VUE := 0.4
## Le panneau des touches reste affiché ce temps après le réveil.
const DUREE_TOUCHES := 10.0
## Couche de ce qui est vrai : on ne la voit que les yeux fermés.
const COUCHE_VRAI := 8
const TOUCHES := "Z Q S D : se déplacer\nSouris : regarder\nEspace : sauter\nE : prendre, poser, utiliser\nF (maintenu) : fermer les yeux\nÉchap : pause et réglages"

## Les yeux restent fermés, même sans F (pendant une scène).
var yeux_forces := false
## Le noir des yeux fermés (1 : tout noir). Au niveau 5, on voit encore ce
## qui est vrai.
var noir_des_yeux := 1.0
## Une ligne de plus dans le panneau des touches, propre au niveau.
var touches_en_plus := ""
## Pendant une cinématique : ni viseur, ni aide sur les touches.
var cinematique := false

var _file: Array[String] = []
var _reste_touches := DUREE_TOUCHES + DUREE_REVEIL

@onready var _joueur: Player = $Player
@onready var _chute: ChuteToiles = $Interface/ChuteToiles
@onready var _noir: ColorRect = $Interface/Noir
@onready var _yeux: ColorRect = $Interface/Yeux
@onready var _action: Label = $Interface/Action
@onready var _touches: Label = $Interface/Touches


## Thomas ferme les yeux (F maintenu) : l'écran devient noir.
func yeux_fermes() -> bool:
	return Input.is_action_pressed("fermer_les_yeux")


## Ce que E ferait maintenant, ou "" : prendre, poser, utiliser…
func action_possible() -> String:
	_joueur.ray.force_raycast_update()
	var cible := _joueur.ray.get_collider()
	if _joueur.held != null:
		if cible != null and cible.has_method("utiliser_avec"):
			return cible.get("action_avec")
		return "poser"
	if cible is RigidBody3D and not (cible as RigidBody3D).is_in_group("fixe"):
		return "prendre"
	if cible != null and cible.has_method("activer"):
		var a = cible.get("action")
		return "utiliser" if a == null else a
	return ""


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
	_file.append("« %s »" % texte)


## Une réplique d'un personnage (Juliette…), après ce qui attend déjà.
func dire(qui: String, texte: String) -> void:
	_file.append("%s : « %s »" % [qui, texte])


func _process(delta: float) -> void:
	super._process(delta)
	if not _file.is_empty() and _reste_message <= 0.3:
		afficher(_file.pop_front())
	_yeux.color.a = move_toward(_yeux.color.a, noir_des_yeux if yeux_fermes() or yeux_forces else 0.0, delta * 6.0)
	var a := action_possible() if _joueur.is_physics_processing() else ""
	_action.text = "E : " + a if a != "" else ""
	# Les touches : au début du niveau, et quand la souris est libérée.
	_reste_touches = maxf(_reste_touches - delta, 0.0)
	var libre := Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless"
	_touches.text = TOUCHES + ("\n" + touches_en_plus if touches_en_plus != "" else "") + ("\n\nClique pour reprendre." if libre else "")
	_touches.visible = not cinematique and (libre or (_reste_touches > 0.0 and _noir.color.a < 0.5))
	($Interface/Viseur as Control).visible = not cinematique
	_touches.modulate.a = 1.0 if libre else clampf(_reste_touches, 0.0, 1.0)


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
