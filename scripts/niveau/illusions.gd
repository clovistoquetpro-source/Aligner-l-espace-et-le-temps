extends Niveau

## Prototype gris « Le musée des illusions » : le couloir sans fin, puis la
## salle du miroir et la chute dans les toiles.

## Secondes passées dans le couloir pour que l'angoisse soit au plus fort.
const MONTEE := 25.0
## Le champ de vision s'élargit avec l'angoisse : le couloir s'étire.
const FOV_EN_PLUS := 18.0
## La porte de la salle du miroir n'apparaît que dans le dos du joueur.
const ANGLE_DOS_DEG := 100.0

## Fois où le couloir a ramené le joueur en arrière sans qu'il le voie.
var tours := 0
var angoisse := 0.0
var porte_ouverte := false

var _temps_couloir := 0.0
var _fov_base := 80.0

@onready var _joueur: Player = $Player
@onready var _zone_couloir: Area3D = $Couloir/Zone
@onready var _boucle: PorteTrompeuse = $Couloir/Boucle
@onready var _zone_hall: Area3D = $Hall/Zone
@onready var _porte_miroir: CSGBox3D = $Hall/PorteMiroir
@onready var _passage: PassageReflet = $SalleMiroir/Passage
@onready var _arrivee: Marker3D = $Suite/Arrivee
@onready var _chute: ChuteToiles = $Interface/ChuteToiles


func _ready() -> void:
	Temps.reinitialiser()
	_fov_base = _joueur.camera.fov
	_joueur.camera.cull_mask &= ~Miroir.COUCHE_REFLET
	_habiller_le_joueur()
	_boucle.body_entered.connect(_sur_boucle)
	_passage.franchi.connect(_tomber_dans_les_toiles)
	_chute.finie.connect(_atterrir)


## Une lanterne qu'on porte (le couloir n'a pas d'autre lumière) et un corps
## qu'on ne voit que dans le miroir.
func _habiller_le_joueur() -> void:
	var lanterne := OmniLight3D.new()
	lanterne.name = "Lanterne"
	lanterne.omni_range = 8.0
	lanterne.light_energy = 0.8
	lanterne.omni_attenuation = 1.5
	_joueur.head.add_child(lanterne)
	var corps := MeshInstance3D.new()
	corps.name = "Reflet"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	corps.mesh = capsule
	corps.position.y = 0.9
	corps.layers = Miroir.COUCHE_REFLET
	corps.material_override = Style.materiau(Color("4a4a55"))
	_joueur.add_child(corps)


func _sur_boucle(corps: Node3D) -> void:
	if corps is Player:
		tours += 1


func _physics_process(delta: float) -> void:
	if _zone_couloir.overlaps_body(_joueur):
		_temps_couloir += delta
	else:
		_temps_couloir = maxf(_temps_couloir - delta * 3.0, 0.0)
	angoisse = 0.0 if _temps_couloir <= 0.0 else clampf(0.2 + _temps_couloir / MONTEE, 0.0, 1.0)
	var fov := _fov_base + FOV_EN_PLUS * angoisse * angoisse
	_joueur.camera.fov = move_toward(_joueur.camera.fov, fov, delta * 10.0)
	if not porte_ouverte and tours > 0 and _zone_hall.overlaps_body(_joueur) and _dans_le_dos(_porte_miroir.global_position):
		ouvrir_la_salle_du_miroir()


func _dans_le_dos(point: Vector3) -> bool:
	var cam := _joueur.camera
	var vers := point - cam.global_position
	vers.y = 0.0
	var regard := -cam.global_basis.z
	regard.y = 0.0
	return rad_to_deg(regard.angle_to(vers)) > ANGLE_DOS_DEG


## Une ouverture apparaît dans le hall, là où il y avait un mur.
func ouvrir_la_salle_du_miroir() -> void:
	porte_ouverte = true
	_porte_miroir.visible = false
	_porte_miroir.use_collision = false


func _tomber_dans_les_toiles(joueur: Player) -> void:
	joueur.velocity = Vector3.ZERO
	joueur.set_physics_process(false)
	_chute.lancer()


func _atterrir() -> void:
	_joueur.teleport(_arrivee.global_transform)
	_joueur.set_anchor(_arrivee.global_transform)
	_joueur.set_physics_process(true)
	afficher("Tu es passé de l'autre côté du miroir.\nFin du test : la suite, on l'invente ensemble.", 8.0)
