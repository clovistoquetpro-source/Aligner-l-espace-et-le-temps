extends Node3D

## La cinématique du début (environ 45 s), en formes simples : la maison sur
## Terre ; un peintre, de dos, qui repeint ses souvenirs ; il peint la maison
## au milieu des étoiles, et elle s'arrache du sol ; la maison dans les
## étoiles, et le titre. On ne voit jamais le visage du peintre. Espace,
## Échap, E ou un clic la passent.

const SUITE := "res://scenes/illusions.tscn"
const FONDU := 1.0
const TEXTES := [
	"Avant, la maison était sur Terre.",
	"Un peintre repeignait ses souvenirs. Encore, et encore.",
	"Un jour, il a peint la maison au milieu des étoiles.",
]
## La hauteur où la maison finit, dans les étoiles.
const HAUT := 60.0

var fini := false
## Le plan en cours : « maison », « atelier », « envol », « etoiles ».
var plan := ""

var _temps := 0.0
var _secousse := 0.0
var _orbite := 0.0

@onready var _camera: Camera3D = $Camera
@onready var _noir: ColorRect = $Interface/Noir
@onready var _texte: Label = $Interface/Texte
@onready var _titre: Label = $Interface/Titre
@onready var _passer: Label = $Interface/Passer
@onready var _maison: Node3D = $Terre/Maison
@onready var _peintre: Node3D = $Atelier/Peintre
@onready var _env: Environment = ($WorldEnvironment as WorldEnvironment).environment


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_le_ciel("jour")
	create_tween().tween_property(_passer, "modulate:a", 0.6, 1.0).set_delay(1.5)
	var t := create_tween()
	# 1. La maison sur Terre.
	t.tween_callback(_plan_maison)
	t.tween_property(_noir, "color:a", 0.0, 2.0)
	t.tween_callback(_dire.bind(TEXTES[0]))
	t.tween_interval(6.0)
	t.tween_property(_noir, "color:a", 1.0, FONDU)
	# 2. Le peintre, de dos.
	t.tween_callback(_plan_atelier)
	t.tween_property(_noir, "color:a", 0.0, FONDU)
	t.tween_callback(_dire.bind(TEXTES[1]))
	t.tween_interval(5.0)
	t.tween_callback(_peindre_les_etoiles)
	t.tween_callback(_dire.bind(TEXTES[2]))
	t.tween_interval(4.0)
	t.tween_property(_noir, "color:a", 1.0, FONDU)
	# 3. La maison s'arrache du sol.
	t.tween_callback(_plan_envol)
	t.tween_property(_noir, "color:a", 0.0, FONDU)
	t.tween_interval(11.0)
	t.tween_property(_noir, "color:a", 1.0, FONDU)
	# 4. La maison dans les étoiles, et le titre.
	t.tween_callback(_plan_etoiles)
	t.tween_property(_noir, "color:a", 0.0, 1.5)
	t.tween_property(_titre, "modulate:a", 1.0, 2.0)
	t.tween_interval(4.0)
	t.tween_property(_titre, "modulate:a", 0.0, 1.5)
	t.tween_property(_noir, "color:a", 1.0, 1.5)
	t.tween_callback(passer)


func _dire(texte: String) -> void:
	_texte.text = texte
	_texte.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_texte, "modulate:a", 1.0, 0.8)
	t.tween_interval(3.4)
	t.tween_property(_texte, "modulate:a", 0.0, 0.8)


## Le ciel : « jour » (bleu), « soir » (orange et violet), « etoiles ».
func _le_ciel(quand: String) -> void:
	var sky := Sky.new()
	if quand == "etoiles":
		var etoiles := ShaderMaterial.new()
		etoiles.shader = load("res://shaders/ciel_etoiles.gdshader")
		sky.sky_material = etoiles
		_env.ambient_light_energy = 0.15
	else:
		var ciel := ProceduralSkyMaterial.new()
		ciel.sky_top_color = Color("4ea8de") if quand == "jour" else Color("3c096c")
		ciel.sky_horizon_color = Color("ffd6a5") if quand == "jour" else Color("ff8fab")
		ciel.ground_horizon_color = ciel.sky_horizon_color
		ciel.ground_bottom_color = Color("2d6a4f")
		sky.sky_material = ciel
		_env.ambient_light_energy = 0.5 if quand == "jour" else 0.3
	_env.sky = sky


func _plan_maison() -> void:
	plan = "maison"
	var depart: Marker3D = $Terre/Plan_maison
	_camera.global_transform = depart.global_transform
	_camera.look_at(_maison.global_position + Vector3(0, 2.5, 0))
	# Un lent travelling vers la maison.
	create_tween().tween_property(_camera, "global_position", depart.global_position.lerp(_maison.global_position + Vector3(0, 2.5, 0), 0.25), 8.0).set_trans(Tween.TRANS_SINE)


## Toujours de dos : la caméra reste derrière lui.
func _plan_atelier() -> void:
	plan = "atelier"
	var dos: Marker3D = $Atelier/Plan_dos
	_camera.global_position = dos.global_position
	_camera.look_at(($Atelier/Toile as Node3D).global_position)
	create_tween().tween_property(_camera, "global_position", dos.global_position.lerp(($Atelier/Toile as Node3D).global_position, 0.3), 10.0).set_trans(Tween.TRANS_SINE)
	# Le pinceau va et vient.
	var bras: Node3D = _peintre.get_node("Bras")
	var t := create_tween().set_loops(12)
	t.tween_property(bras, "rotation:x", 0.35, 0.45).set_trans(Tween.TRANS_SINE)
	t.tween_property(bras, "rotation:x", -0.1, 0.45).set_trans(Tween.TRANS_SINE)


func _peindre_les_etoiles() -> void:
	($Atelier/Toile/Nuit as Node3D).visible = true


func _plan_envol() -> void:
	plan = "envol"
	_le_ciel("soir")
	var depart: Marker3D = $Terre/Plan_envol
	_camera.global_transform = depart.global_transform
	_secousse = 1.0
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func() -> void:
		_secousse = 0.4
		($Terre/Trou as Node3D).visible = true)
	t.tween_property(_maison, "position:y", 24.0, 7.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_maison, "rotation:z", 0.12, 7.0)
	t.parallel().tween_property(self, "_secousse", 0.0, 7.0)
	t.tween_callback(_le_ciel.bind("etoiles"))
	t.tween_property(_maison, "position:y", 40.0, 2.5)


func _plan_etoiles() -> void:
	plan = "etoiles"
	_le_ciel("etoiles")
	($Terre/Sol as Node3D).visible = false
	for n in $Terre.get_children():
		if n is Node3D and n != _maison:
			(n as Node3D).visible = n is DirectionalLight3D
	_maison.position.y = HAUT
	_maison.rotation = Vector3(0.05, 0.0, 0.08)
	_orbite = 0.0


func _process(delta: float) -> void:
	_temps += delta
	match plan:
		"envol":
			# La caméra suit la maison qui monte ; le sol tremble.
			var cible := _maison.global_position + Vector3(0, 2.0, 0)
			var bruit := Vector3(sin(_temps * 37.0), sin(_temps * 29.0 + 1.0), 0.0) * 0.08 * _secousse
			_camera.look_at(cible + bruit)
		"etoiles":
			# La maison flotte ; la caméra tourne lentement autour d'elle.
			_orbite += delta * 0.12
			var centre := _maison.global_position + Vector3(0, 2.0, 0)
			_maison.position.y = HAUT + 0.4 * sin(_temps * 0.8)
			_camera.global_position = centre + Vector3(sin(_orbite) * 22.0, -3.0, cos(_orbite) * 22.0)
			_camera.look_at(centre)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sauter") or event.is_action_pressed("liberer_souris") or event.is_action_pressed("interagir") \
			or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		passer()


## La fin de la cinématique (ou on la passe) : le niveau 1.
func passer() -> void:
	if fini:
		return
	fini = true
	Histoire.vers(SUITE)
