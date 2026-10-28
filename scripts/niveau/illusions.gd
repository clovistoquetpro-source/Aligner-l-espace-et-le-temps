extends Niveau

## Niveau 1, en formes simples : « La maison dans les étoiles ».
## On se réveille et on veut sortir, mais la porte d'entrée recule au bout
## d'un couloir sans fin. Le miroir de la salle de bain montre un passage, et
## soi-même plus vieux. On tombe dans les toiles, jusqu'à la galerie : la
## porte d'entrée est sur un balcon, et il faut aller chercher dans la toile
## tournante (la chambre d'enfant) de quoi y monter. La porte ramène… dans
## la chambre.

## Secondes passées dans le couloir pour que l'angoisse soit au plus fort.
const MONTEE := 25.0
## Le champ de vision s'élargit avec l'angoisse : le couloir s'étire.
const FOV_EN_PLUS := 18.0
## La porte de la salle de bain n'apparaît que dans le dos du joueur.
const ANGLE_DOS_DEG := 100.0
## La porte d'entrée reste toujours à cette distance devant le joueur.
const RECUL_PORTE := 18.0
const PORTE_Z_MAX := -22.0
const DUREE_REVEIL := 2.5
## Les pensées du couloir, selon le temps qu'on y a passé (en secondes).
const PENSEES_COULOIR := [[8.0, "Elle ne se rapproche pas…"], [20.0, "Je ne sortirai pas par là."]]
## Un obstacle plus proche que la pensée (de cette marge) la cache.
const MARGE_VUE := 0.4

## Fois où le couloir a ramené le joueur en arrière sans qu'il le voie.
var tours := 0
var angoisse := 0.0
var porte_ouverte := false
var fini := false

var _temps_couloir := 0.0
var _pensees_couloir := 0
var _fin_annoncee := false
var _fov_base := 80.0
var _file: Array[String] = []

@onready var _joueur: Player = $Player
@onready var _zone_couloir: Area3D = $Couloir/Zone
@onready var _boucle: PorteTrompeuse = $Couloir/Boucle
@onready var _porte_entree: Node3D = $Couloir/PorteEntree
@onready var _zone_salon: Area3D = $Salon/Zone
@onready var _porte_sdb: CSGBox3D = $Salon/PorteSdb
@onready var _pensee_porte: Pensee = $Salon/PenseePorte
@onready var _passage: PassageReflet = $SalleDeBain/Passage
@onready var _arrivee: Marker3D = $Galerie/Arrivee
@onready var _fin: PorteTrompeuse = $Galerie/PorteFin
@onready var _piece: Node3D = $ToilePeinte/Chambre
@onready var _cube: ObjetPerspectif = $ToilePeinte/Chambre/Cube
@onready var _chute: ChuteToiles = $Interface/ChuteToiles
@onready var _noir: ColorRect = $Interface/Noir


func _ready() -> void:
	Temps.reinitialiser()
	_fov_base = _joueur.camera.fov
	_joueur.camera.cull_mask &= ~Miroir.COUCHE_REFLET
	_habiller_le_joueur()
	_boucle.body_entered.connect(_sur_boucle)
	_passage.franchi.connect(_tomber_dans_les_toiles)
	_chute.finie.connect(_atterrir)
	# Connecté après la porte elle-même : le joueur est déjà dans la chambre.
	_fin.body_entered.connect(_sur_fin)
	_ouvrir_les_yeux("Quel drôle de rêve…")


## Une lanterne qu'on porte (le couloir n'a pas d'autre lumière), et le corps
## qu'on ne voit que dans le miroir : soi-même plus vieux, en peintre (blouse,
## béret, pinceau).
func _habiller_le_joueur() -> void:
	var lanterne := OmniLight3D.new()
	lanterne.name = "Lanterne"
	lanterne.omni_range = 8.0
	lanterne.light_energy = 0.8
	lanterne.omni_attenuation = 1.5
	_joueur.head.add_child(lanterne)
	var reflet := Node3D.new()
	reflet.name = "Reflet"
	_joueur.add_child(reflet)
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	_forme_du_reflet(reflet, capsule, Vector3(0, 0.88, 0), Color("4a4a55"))
	var blouse := CylinderMesh.new()
	blouse.top_radius = 0.34
	blouse.bottom_radius = 0.46
	blouse.height = 1.0
	_forme_du_reflet(reflet, blouse, Vector3(0, 0.75, 0), Color("dcdcdc"))
	var beret := CylinderMesh.new()
	beret.top_radius = 0.24
	beret.bottom_radius = 0.26
	beret.height = 0.08
	_forme_du_reflet(reflet, beret, Vector3(0.04, 1.78, 0), Color("d1495b"))
	var pinceau := CylinderMesh.new()
	pinceau.top_radius = 0.02
	pinceau.bottom_radius = 0.015
	pinceau.height = 0.5
	var p := _forme_du_reflet(reflet, pinceau, Vector3(0.45, 1.05, -0.15), Color("8d6346"))
	p.rotation.x = -0.6


func _forme_du_reflet(parent: Node3D, mesh: Mesh, pos: Vector3, couleur: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.layers = Miroir.COUCHE_REFLET
	mi.material_override = Style.materiau(couleur)
	parent.add_child(mi)
	return mi


func _ouvrir_les_yeux(pensee: String) -> void:
	_noir.color.a = 1.0
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(_noir, "color:a", 0.0, DUREE_REVEIL)
	t.tween_callback(penser.bind(pensee))


## Affiche une pensée, après celles qui attendent déjà.
func penser(texte: String) -> void:
	_file.append(texte)


func _process(delta: float) -> void:
	super._process(delta)
	_suivre_la_porte()
	if not _file.is_empty() and _reste_message <= 0.3:
		afficher("« %s »" % _file.pop_front())


func _sur_boucle(corps: Node3D) -> void:
	if corps is Player:
		tours += 1
		# Le couloir vient de ramener le joueur en arrière : la porte aussi.
		_suivre_la_porte()


## La porte d'entrée reste toujours à la même distance devant le joueur.
func _suivre_la_porte() -> void:
	_porte_entree.position.z = minf(PORTE_Z_MAX, _joueur.global_position.z - RECUL_PORTE)


func _physics_process(delta: float) -> void:
	var dans_le_couloir := _zone_couloir.overlaps_body(_joueur)
	if dans_le_couloir:
		_temps_couloir += delta
	else:
		_temps_couloir = maxf(_temps_couloir - delta * 3.0, 0.0)
	angoisse = 0.0 if _temps_couloir <= 0.0 else clampf(0.2 + _temps_couloir / MONTEE, 0.0, 1.0)
	var fov := _fov_base + FOV_EN_PLUS * angoisse * angoisse
	_joueur.camera.fov = move_toward(_joueur.camera.fov, fov, delta * 10.0)
	_suivre_la_porte()
	if dans_le_couloir and _pensees_couloir < PENSEES_COULOIR.size() and _temps_couloir > PENSEES_COULOIR[_pensees_couloir][0]:
		penser(PENSEES_COULOIR[_pensees_couloir][1])
		_pensees_couloir += 1
	if not porte_ouverte and tours > 0 and _zone_salon.overlaps_body(_joueur) and _dans_le_dos(_porte_sdb.global_position):
		ouvrir_la_salle_de_bain()
	# Le cube sort de la toile avec le joueur : il ne tourne plus avec elle.
	if _cube.get_parent() == _piece and _joueur.held == _cube:
		_cube.reparent(self)
	_ecouter_les_pensees()
	if fini and not _fin_annoncee and $Chambre/PenseeFin.dite and _file.is_empty() and _reste_message <= 0.0:
		_fin_annoncee = true
		afficher("Fin du niveau 1 (prototype en formes simples).", 8.0)


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


func _dans_le_dos(point: Vector3) -> bool:
	var cam := _joueur.camera
	var vers := point - cam.global_position
	vers.y = 0.0
	var regard := -cam.global_basis.z
	regard.y = 0.0
	return rad_to_deg(regard.angle_to(vers)) > ANGLE_DOS_DEG


## Une porte apparaît dans le salon, là où il y avait un mur.
func ouvrir_la_salle_de_bain() -> void:
	porte_ouverte = true
	_porte_sdb.visible = false
	_porte_sdb.use_collision = false
	_pensee_porte.active = true


func _tomber_dans_les_toiles(joueur: Player) -> void:
	joueur.velocity = Vector3.ZERO
	joueur.set_physics_process(false)
	_chute.lancer()


func _atterrir() -> void:
	_joueur.teleport(_arrivee.global_transform)
	_joueur.set_anchor(_arrivee.global_transform)
	_joueur.set_physics_process(true)


## La porte d'entrée de la galerie ramène dans la chambre, et la toile
## au-dessus du lit a changé.
func _sur_fin(corps: Node3D) -> void:
	if not corps is Player or fini:
		return
	fini = true
	_joueur.set_anchor($Chambre/Reveil.global_transform)
	$Chambre/Toile_lit.visible = false
	$Chambre/Toile_lit_fin.visible = true
	$Chambre/PenseeFin.active = true
	_ouvrir_les_yeux("Je ne suis pas sorti… Je suis revenu dans ma chambre.")
