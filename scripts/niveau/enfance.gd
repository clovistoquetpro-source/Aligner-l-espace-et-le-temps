extends Souvenir

## Niveau 2, en formes simples : « L'enfance ». Une journée de Thomas enfant :
## la cour de récré (la peur grossit tout), l'anniversaire vide (les
## invitations, la correction du peintre, la table sans fin) et le grenier qui
## grandit. Voir docs/superpowers/specs/2026-10-28-direction-illusions-design.md.

enum Etape { COUR, MAISON, GRENIER, FIN }

## Hauteur des yeux de Thomas enfant, et quand la peur le fait rapetisser.
const TETE_ENFANT := 1.15
const TETE_PEUR := 0.6
const VITESSE_PEUR := 0.2
## La peur monte vite dans l'ombre d'un enfant, et redescend doucement.
const PEUR_MONTE := 1.5
const PEUR_DESCEND := 0.6
const MASQUE_ENFANTS := 128
## La lampe éclaire « d'en haut » au-dessus de cette hauteur.
const LAMPE_HAUTE := 3.5
## Après la correction, le gâteau reste à cette distance devant Thomas.
const RECUL_GATEAU := 5.0
const FIN_TABLE := -12.0
## Le grenier grandit quand Thomas regarde ses dessins, rétrécit quand il
## regarde dehors, et revient doucement à sa taille sinon (par seconde).
const GRANDIT := 0.12
const RETRECIT := 0.2
const RETOUR := 0.08
const ECHELLE_MIN := 0.5
const ECHELLE_MAX := 2.0

var etape := Etape.COUR
var peur := 0.0
var ombres_vaincues := false
var invitations := 0
var invites_venus := false
var voeu_fait := false
var echelle := 1.0
var yeux_fermes := false

var _yeux_forces := false
## Où sont les invitations au début, pour les remettre si elles tombent.
var _depart_invitations := {}
var _temps_table := 0.0
var _pensee_table := false
var _pensee_gateau := false

@onready var _lampe: RigidBody3D = $Cour/Lampe
@onready var _flou: ColorRect = $Interface/Flou
@onready var _yeux: ColorRect = $Interface/Yeux
@onready var _fente: Area3D = $Maison/Fente
@onready var _fin_table: Node3D = $SalleAManger/Fin
@onready var _voeu: Area3D = $SalleAManger/Fin/Voeu
@onready var _boucle: PorteTrompeuse = $SalleAManger/Boucle
@onready var _zone_salle: Area3D = $SalleAManger/Zone
@onready var _grenier: Node3D = $Grenier
@onready var _lucarne: Area3D = $Grenier/Lucarne


func _ready() -> void:
	Temps.reinitialiser()
	_joueur.camera.cull_mask &= ~Miroir.COUCHE_REFLET
	_joueur.head.position.y = TETE_ENFANT
	_habiller_le_joueur()
	_voeu.body_entered.connect(_sur_voeu)
	_boucle.body_entered.connect(_sur_boucle)
	_lucarne.body_entered.connect(_sur_lucarne)
	_chute.finie.connect(_retour_dans_la_maison_des_etoiles)
	for e in get_tree().get_nodes_in_group("invitations"):
		if is_ancestor_of(e):
			_depart_invitations[e.name] = e.global_transform
	var pensee_depart: Pensee = $Cour/PenseeDepart
	pensee_depart.active = false
	var t := _ouvrir_les_yeux("La récré. Comme toujours, je reste collé au mur.")
	t.tween_callback(func() -> void: pensee_depart.active = true)


## Le corps qu'on voit dans les miroirs : Thomas enfant.
func _habiller_le_joueur() -> void:
	var reflet := Node3D.new()
	reflet.name = "Reflet"
	_joueur.add_child(reflet)
	var corps := CapsuleMesh.new()
	corps.radius = 0.25
	corps.height = 1.25
	_forme_du_reflet(reflet, corps, Vector3(0, 0.63, 0), Color("4ea8de"))
	var tete := SphereMesh.new()
	tete.radius = 0.17
	tete.height = 0.34
	_forme_du_reflet(reflet, tete, Vector3(0, 1.35, 0), Color("f2c6a0"))


func _process(delta: float) -> void:
	super._process(delta)
	_suivre_le_gateau()


func _physics_process(delta: float) -> void:
	yeux_fermes = Input.is_action_pressed("fermer_les_yeux")
	_yeux.color.a = move_toward(_yeux.color.a, 1.0 if yeux_fermes or _yeux_forces else 0.0, delta * 6.0)
	match etape:
		Etape.COUR:
			_dans_la_cour(delta)
		Etape.MAISON:
			_dans_la_maison(delta)
		Etape.GRENIER:
			_dans_le_grenier(delta)
	if etape != Etape.COUR:
		peur = move_toward(peur, 0.0, PEUR_DESCEND * delta)
	_appliquer_la_peur()
	_ecouter_les_pensees()


# --- La cour de récré --------------------------------------------------------


func _dans_la_cour(delta: float) -> void:
	var dans := not ombres_vaincues and dans_l_ombre()
	peur = clampf(peur + (PEUR_MONTE if dans else -PEUR_DESCEND) * delta, 0.0, 1.0)
	if _joueur.held == _lampe:
		$Cour/PenseeTour.active = true
	if not ombres_vaincues and lampe_en_haut():
		vaincre_les_ombres()


## Thomas est dans l'ombre d'un enfant : un enfant est entre lui et la lampe.
func dans_l_ombre() -> bool:
	var pied := _joueur.global_position + Vector3(0, 0.4, 0)
	var lumiere := (_lampe.get_node("Lumiere") as Node3D).global_position
	var q := PhysicsRayQueryParameters3D.create(pied, lumiere, MASQUE_ENFANTS)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func lampe_en_haut() -> bool:
	return _joueur.held != _lampe and _lampe.global_position.y > LAMPE_HAUTE and _lampe.linear_velocity.length() < 0.3


func _appliquer_la_peur() -> void:
	_joueur.facteur_vitesse = lerpf(1.0, VITESSE_PEUR, peur)
	_joueur.head.position.y = lerpf(TETE_ENFANT, TETE_PEUR, peur)
	_flou.visible = peur > 0.01
	(_flou.material as ShaderMaterial).set_shader_parameter("flou", peur)


## La lumière tombe d'en haut : les ombres reprennent leur vraie taille, et
## les enfants apparaissent.
func vaincre_les_ombres() -> void:
	ombres_vaincues = true
	for e in get_tree().get_nodes_in_group("enfants"):
		if is_ancestor_of(e):
			e.get_node("Ombre").visible = false
			e.get_node("Corps").visible = true
	penser("Ce ne sont que des enfants. Comme moi.")
	var t := create_tween()
	t.tween_interval(5.0)
	t.tween_callback(_la_cloche)


func _la_cloche() -> void:
	penser("La cloche. La récré est finie.")
	var porte: Vector3 = $Cour/Rentree.global_position
	var t := create_tween().set_parallel()
	for e in get_tree().get_nodes_in_group("enfants"):
		if is_ancestor_of(e):
			t.tween_property(e, "global_position", porte, 4.0).set_delay(1.0)
	t.chain().tween_callback(func() -> void:
		for e in get_tree().get_nodes_in_group("enfants"):
			if is_ancestor_of(e):
				e.visible = false
		penser("Je n'ai rien dit. Les invitations sont restées dans ma poche."))
	t.tween_interval(6.0)
	t.tween_callback(rentrer_a_la_maison)


func rentrer_a_la_maison() -> void:
	if _joueur.held != null:
		_joueur.poser()
	etape = Etape.MAISON
	peur = 0.0
	_changer_de_lieu($Maison/Depart, "")


## Écran noir, on change de lieu, puis on rouvre les yeux.
func _changer_de_lieu(arrivee: Marker3D, pensee: String) -> void:
	var t := create_tween()
	t.tween_property(_noir, "color:a", 1.0, 1.0)
	t.tween_callback(func() -> void:
		_joueur.teleport(arrivee.global_transform)
		_joueur.set_anchor(arrivee.global_transform)
		_joueur.set_physics_process(true)
		_ouvrir_les_yeux(pensee))


# --- L'anniversaire ----------------------------------------------------------


func _dans_la_maison(delta: float) -> void:
	var tenue := _joueur.held
	# L'invitation du miroir devient visible quand on la tient.
	if tenue != null and tenue.is_in_group("invitations"):
		for m in tenue.find_children("*", "MeshInstance3D", false, false):
			m.layers = 1
	for e in get_tree().get_nodes_in_group("invitations"):
		if is_ancestor_of(e) and e != tenue and e.global_position.y < -3.0:
			e.global_transform = _depart_invitations[e.name]
			(e as RigidBody3D).linear_velocity = Vector3.ZERO
			(e as RigidBody3D).freeze = true
	for corps in _fente.get_overlapping_bodies():
		if corps.is_in_group("invitations") and corps != tenue:
			poster(corps)
	if invites_venus and not voeu_fait:
		_suivre_le_gateau()
		var voulu := not yeux_fermes
		if _boucle.monitoring != voulu:
			_boucle.monitoring = voulu
		if not yeux_fermes and _zone_salle.overlaps_body(_joueur) and _joueur.velocity.z < -0.5:
			_temps_table += delta
			if _temps_table > 6.0 and not _pensee_table:
				_pensee_table = true
				penser("La table… elle n'en finit pas.")


func poster(enveloppe: Node3D) -> void:
	enveloppe.remove_from_group("invitations")
	enveloppe.queue_free()
	invitations += 1
	if invitations == 3:
		faire_venir_les_invites()


## La correction du peintre : les invités arrivent, peints. Et l'espace se
## casse : la table s'allonge sans fin.
func faire_venir_les_invites() -> void:
	invites_venus = true
	Histoire.corrections += 1
	for inv in get_tree().get_nodes_in_group("invites"):
		if is_ancestor_of(inv):
			inv.visible = true
	$SalleAManger/PenseeInvites.active = true
	_boucle.monitoring = true
	penser("Ils sont venus ! Tout le monde est venu !")


## Les yeux ouverts, le gâteau reste à la même distance devant Thomas.
func _suivre_le_gateau() -> void:
	if not invites_venus or voeu_fait or yeux_fermes:
		return
	_fin_table.position.z = minf(FIN_TABLE, _joueur.global_position.z - _fin_table.get_parent().global_position.z - RECUL_GATEAU)


func _sur_boucle(corps: Node3D) -> void:
	if corps is Player:
		_suivre_le_gateau()


func _sur_voeu(corps: Node3D) -> void:
	if not corps is Player or voeu_fait:
		return
	if not invites_venus:
		if not _pensee_gateau:
			_pensee_gateau = true
			penser("Pas sans les autres. Ils vont venir…")
		return
	faire_le_voeu()


## Les yeux fermés, Thomas atteint le gâteau. La table reprend sa vraie
## longueur ; quand il rouvre les yeux, il voit que les invités sont peints.
func faire_le_voeu() -> void:
	voeu_fait = true
	_yeux_forces = true
	_yeux.color.a = 1.0
	_boucle.monitoring = false
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	_fin_table.position.z = FIN_TABLE
	var salle: Vector3 = _fin_table.get_parent().global_position
	_joueur.teleport(Transform3D(Basis(Vector3.UP, PI), salle + Vector3(2.0, 0, FIN_TABLE + 1.4)))
	penser("Je voudrais que quelqu'un vienne.")
	var t := create_tween()
	t.tween_interval(3.0)
	t.tween_callback(func() -> void:
		_yeux_forces = false
		for i in 6:
			_fin_table.get_node("Flamme_%d" % i).visible = false
		_fin_table.get_node("Lueur").visible = false)
	t.tween_interval(2.0)
	t.tween_callback(_les_invites_tombent)
	t.tween_interval(1.5)
	t.tween_callback(penser.bind("Ils sont en carton… Personne n'était venu."))
	t.tween_interval(5.0)
	t.tween_callback(penser.bind("Alors je suis monté au grenier."))
	t.tween_interval(3.5)
	t.tween_callback(monter_au_grenier)


func _les_invites_tombent() -> void:
	var t := create_tween().set_parallel()
	for inv in get_tree().get_nodes_in_group("invites"):
		if is_ancestor_of(inv):
			t.tween_property(inv, "rotation:x", -1.4, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func monter_au_grenier() -> void:
	etape = Etape.GRENIER
	_changer_de_lieu($Grenier/Arrivee, "Ici, personne ne me voit.")


# --- Le grenier --------------------------------------------------------------


func _dans_le_grenier(delta: float) -> void:
	var regarde_dessin := false
	var lucarne_libre := true
	for groupe in ["dessins_lucarne", "dessins"]:
		for d in get_tree().get_nodes_in_group(groupe):
			var dessin := d as Decrochable
			if not dessin.accroche or not is_ancestor_of(dessin):
				continue
			if groupe == "dessins_lucarne":
				lucarne_libre = false
			if not regarde_dessin and _regarde(dessin.global_position, 12.0, 12.0):
				regarde_dessin = true
	var regarde_dehors := lucarne_libre and _regarde(_lucarne.global_position, 15.0, 30.0)
	if regarde_dehors:
		$Grenier/PenseeLucarne.active = true
	var cible := move_toward(echelle, 1.0, RETOUR * delta)
	if regarde_dessin:
		cible = echelle + GRANDIT * delta
	elif regarde_dehors:
		cible = echelle - RETRECIT * delta
	changer_echelle(clampf(cible, ECHELLE_MIN, ECHELLE_MAX))


## Le grenier change de taille autour de Thomas : il reste au même endroit de
## la pièce, et ne traverse jamais un mur.
func changer_echelle(s: float) -> void:
	var k := s / echelle
	if is_equal_approx(k, 1.0):
		return
	var pivot := Vector3(_joueur.global_position.x, _grenier.global_position.y, _joueur.global_position.z)
	var t := _grenier.global_transform
	t.origin = pivot + (t.origin - pivot) * k
	t.basis = t.basis.scaled(Vector3.ONE * k)
	_grenier.global_transform = t
	echelle = s


func _sur_lucarne(corps: Node3D) -> void:
	if corps is Player and etape == Etape.GRENIER:
		sortir_par_la_lucarne()


func sortir_par_la_lucarne() -> void:
	etape = Etape.FIN
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	penser("Dehors, les autres jouaient.")
	penser("Ce jour-là, je suis resté peindre.")
	var t := create_tween()
	t.tween_interval(7.0)
	t.tween_callback(_tomber_dans_les_toiles.bind(_joueur))


func _retour_dans_la_maison_des_etoiles() -> void:
	Histoire.chapitre = maxi(Histoire.chapitre, 3)
	Histoire.vers("res://scenes/illusions.tscn")
