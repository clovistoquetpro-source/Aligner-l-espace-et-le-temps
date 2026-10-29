extends Souvenir

## Niveau 1, en formes simples : « La maison dans les étoiles ».
## On se réveille et on veut sortir, mais la porte d'entrée recule au bout
## d'un couloir sans fin. Le miroir de la salle de bain montre un passage, et
## soi-même plus vieux. On tombe dans les toiles, jusqu'à la galerie : la
## porte d'entrée est sur un balcon, et il faut aller chercher dans la toile
## tournante (la chambre d'enfant) de quoi y monter. La porte ramène… dans
## la chambre. Ensuite, la toile de l'enfant, au salon, mène au niveau 2 ; au
## retour, la maison s'est abîmée.

## Secondes passées dans le couloir pour que l'angoisse soit au plus fort.
const MONTEE := 25.0
## Le champ de vision s'élargit avec l'angoisse : le couloir s'étire.
const FOV_EN_PLUS := 18.0
## La porte de la salle de bain n'apparaît que dans le dos du joueur.
const ANGLE_DOS_DEG := 100.0
## La porte d'entrée reste toujours à cette distance devant le joueur.
const RECUL_PORTE := 18.0
const PORTE_Z_MAX := -22.0
## Les pensées du couloir, selon le temps qu'on y a passé (en secondes).
const PENSEES_COULOIR := [[4.0, "Elle ne se rapproche pas…"], [15.0, "Je ne sortirai pas par là."]]
## Après ce temps dans le couloir (en tout), la porte de la salle de bain
## peut apparaître : Thomas a vu que la porte d'entrée ne se rapproche pas.
const COULOIR_VU := 4.0

## Fois où le couloir a ramené le joueur en arrière sans qu'il le voie.
var tours := 0
var angoisse := 0.0
var porte_ouverte := false
var fini := false
## La toile de l'enfant mène au niveau 2 (une fois le niveau 1 fini).
var toile_enfant_ouverte := false

var _temps_couloir := 0.0
## Le temps passé dans le couloir, en tout (il ne redescend pas).
var temps_couloir_total := 0.0
var _pensees_couloir := 0
var _fin_annoncee := false
var _fov_base := 80.0
var _vers_enfance := false
## La toile du lac mène au niveau 3 (au retour de l'enfance).
var toile_lac_ouverte := false
var _vers_l_ete := false
## La toile de l'atelier mène au niveau 4 (au retour de l'été).
var toile_atelier_ouverte := false
var _vers_la_pluie := false

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
	if Histoire.chapitre >= 3:
		_retour_de_l_enfance()
	else:
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


func _process(delta: float) -> void:
	super._process(delta)
	_suivre_la_porte()


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
		temps_couloir_total += delta
	else:
		_temps_couloir = maxf(_temps_couloir - delta * 3.0, 0.0)
	angoisse = 0.0 if _temps_couloir <= 0.0 else clampf(0.2 + _temps_couloir / MONTEE, 0.0, 1.0)
	var fov := _fov_base + FOV_EN_PLUS * angoisse * angoisse
	_joueur.camera.fov = move_toward(_joueur.camera.fov, fov, delta * 10.0)
	_suivre_la_porte()
	if dans_le_couloir and _pensees_couloir < PENSEES_COULOIR.size() and _temps_couloir > PENSEES_COULOIR[_pensees_couloir][0]:
		penser(PENSEES_COULOIR[_pensees_couloir][1])
		_pensees_couloir += 1
	var couloir_vu := tours > 0 or temps_couloir_total >= COULOIR_VU
	if not porte_ouverte and couloir_vu and _zone_salon.overlaps_body(_joueur) and _dans_le_dos(_porte_sdb.global_position):
		ouvrir_la_salle_de_bain()
	# Le cube sort de la toile avec le joueur : il ne tourne plus avec elle.
	if _cube.get_parent() == _piece and _joueur.held == _cube:
		_cube.reparent(self)
	_ecouter_les_pensees()
	if fini and not _fin_annoncee and $Chambre/PenseeFin.dite and _file.is_empty() and _reste_message <= 0.0:
		_fin_annoncee = true
		afficher("Fin du niveau 1.", 5.0)
		ouvrir_la_toile_de_l_enfant()
	var toile: Node3D = $Salon/Toile_enfant
	if toile_enfant_ouverte and not _vers_enfance and _regarde(toile.global_position, 25.0, 2.5):
		_vers_enfance = true
		_tomber_dans_les_toiles(_joueur)
	var lac: Node3D = $Salon/Toile_lac
	if toile_lac_ouverte and not _vers_l_ete and _regarde(lac.global_position, 25.0, 2.5):
		_vers_l_ete = true
		_tomber_dans_les_toiles(_joueur)
	var atelier: Node3D = $Salon/Toile_atelier
	if toile_atelier_ouverte and not _vers_la_pluie and _regarde(atelier.global_position, 25.0, 2.5):
		_vers_la_pluie = true
		_tomber_dans_les_toiles(_joueur)


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


func ouvrir_la_toile_de_l_enfant() -> void:
	toile_enfant_ouverte = true
	penser("Tout a commencé quand j'étais petit.")


func _atterrir() -> void:
	if _vers_enfance:
		Histoire.chapitre = maxi(Histoire.chapitre, 2)
		Histoire.vers("res://scenes/enfance.tscn")
		return
	if _vers_l_ete:
		Histoire.vers("res://scenes/ete.tscn")
		return
	if _vers_la_pluie:
		Histoire.vers("res://scenes/dispute.tscn")
		return
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


## De retour d'un souvenir : chaque correction a abîmé la maison. Après
## l'enfance, le mur nord du salon s'est envolé (on voit les étoiles) et les
## meubles flottent ; après l'été, le plafond du salon et un mur de l'entrée
## partent aussi, et la chambre flotte.
func _retour_de_l_enfance() -> void:
	fini = true
	_fin_annoncee = true
	ouvrir_la_salle_de_bain()
	$Chambre/Toile_lit.visible = false
	$Chambre/Toile_lit_fin.visible = true
	var depart := Transform3D(Basis(), Vector3(10.4, 0, -1.2))
	_joueur.teleport(depart)
	_joueur.set_anchor(depart)
	# Les murs disparaissent, mais on ne tombe pas dans le vide.
	var mur: CSGBox3D = $Salon/Mur_nord
	mur.visible = false
	var flottants := ["Salon/Canape", "Salon/Canape_dossier", "Salon/Table_basse", "Salon/Table", "Salon/Chaise_1", "Salon/Chaise_2"]
	if Histoire.chapitre >= 4:
		($Salon/Plafond as CSGBox3D).visible = false
		for n in ["Hall/Mur_ouest_1", "Hall/Mur_ouest_2", "Hall/Mur_ouest_3", "Hall/Mur_ouest_4"]:
			var m := get_node_or_null(n) as CSGBox3D
			if m != null:
				m.visible = false
		flottants.append_array(["Chambre/Armoire", "Chambre/Table_de_nuit", "Hall/Banc"])
	if Histoire.chapitre >= 5:
		for n in ["Hall/Plafond", "Chambre/Plafond", "Chambre/Mur_est_1", "Chambre/Mur_est_2", "Chambre/Mur_est_3", "Chambre/Mur_est_4", "Salon/Mur_sud"]:
			var m := get_node_or_null(n) as CSGBox3D
			if m != null:
				m.visible = false
		flottants.append_array(["Chambre/Lit_tete", "Chambre/Lit_oreiller", "Hall/Portemanteau"])
	var i := 0
	for nom in flottants:
		var m: CSGBox3D = get_node(nom)
		m.use_collision = false
		m.position.y += 1.8 + 0.3 * (i % 6)
		m.rotation = Vector3(0.2 * (i % 3) - 0.2, 0.3 * i, 0.15 * (i % 2))
		var t := create_tween().set_loops()
		t.tween_property(m, "position:y", m.position.y + 0.25, 2.0 + 0.3 * (i % 6)).set_trans(Tween.TRANS_SINE)
		t.tween_property(m, "position:y", m.position.y, 2.0 + 0.3 * (i % 6)).set_trans(Tween.TRANS_SINE)
		i += 1
	if Histoire.chapitre >= 5:
		var t := _ouvrir_les_yeux("Il ne reste presque plus rien de la maison.")
		t.tween_callback(penser.bind("Juliette… Je l'ai repeinte mille fois. Elle tombe toujours."))
		t.tween_interval(9.0)
		t.tween_callback(afficher.bind("Fin du niveau 4. Bientôt : l'atelier du peintre.", 8.0))
		return
	if Histoire.chapitre >= 4:
		toile_atelier_ouverte = true
		var t := _ouvrir_les_yeux("Le plafond… il n'y a plus que les étoiles.")
		t.tween_callback(penser.bind("Chaque souvenir que je répare défait un peu plus la maison."))
		t.tween_callback(penser.bind("L'atelier, au salon… Ce soir de pluie."))
		return
	toile_lac_ouverte = true
	$Salon/Toile_lac.visible = true
	$Salon/PenseeLac.active = true
	var t := _ouvrir_les_yeux("La maison… Elle se défait.")
	t.tween_callback(penser.bind("J'ai changé le souvenir. Et ici, tout s'abîme."))
	t.tween_callback(penser.bind("Un nouveau tableau, au salon…"))
