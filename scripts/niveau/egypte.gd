extends Niveau

## Niveau « L'Égypte » : relie les énigmes, le chantier, les messages et la fin.

const TempsScript := preload("res://scripts/time/temps.gd")

## Couleurs du ciel et de l'ambiance : l'Antiquité, saturée ; 1942, plus terne.
const PALETTES := {
	TempsScript.Epoque.PASSE: { "ciel": Color("3ee6d0"), "ambiance": Color("ffb347") },
	TempsScript.Epoque.PRESENT: { "ciel": Color("9fd8cf"), "ambiance": Color("c9a66b") },
}


## Durée du vol des blocs vers la vraie pyramide, puis de l'ouverture de la porte.
@export var duree_recollage := 2.0
@export var duree_porte := 1.5

@onready var _nuage: Chantier = $Chantier/Nuage
@onready var _pyramide: Alignement = $Chantier/Pyramide


func _ready() -> void:
	$BasculeFx.palettes = PALETTES
	Temps.reinitialiser(Temps.Epoque.PASSE)
	$BasculeFx.environnement = $WorldEnvironment.environment
	for zone in ["Carriere", "Rampe", "Camp", "Temple"]:
		var cartouche: Cartouche = get_node("%s/Cartouche" % zone)
		cartouche.touche.connect(func(z: String) -> void: _nuage.zone_reussie(z, cartouche.global_position))
	_nuage.groupe_revenu.connect(func(_z: String, n: int) -> void:
		afficher("Un groupe de blocs rejoint la pyramide ! (%d/%d)" % [n, Chantier.ZONES.size()]))
	$Chantier/Belvedere.body_entered.connect(_au_belvedere)
	_pyramide.resolu.connect(_recoller)
	$Carriere/Spinosaure.renifle.connect(afficher.bind("Trop petit…"))
	$Camp/Sentinelle.refuse.connect(afficher.bind("Halte ! Le mot de passe ?"))
	$Chantier/Fin.franchi.connect(afficher.bind("Époque réparée ! Bientôt : le château…", 1000.0))
	afficher("L'Égypte… mais quelque chose cloche.")


func _au_belvedere(corps: Node3D) -> void:
	if corps is Player and not _nuage.est_complet():
		afficher("Il manque encore des blocs…")


## La pyramide est alignée : les blocs se posent sur ses faces, elle devient
## solide, puis sa porte s'ouvre.
func _recoller() -> void:
	var vol := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for b in _pyramide.get_children():
		if b is CSGShape3D:
			vol.tween_property(b, "position", _pyramide.to_local(b.get_meta("image")), duree_recollage)
			vol.tween_property(b, "scale", Vector3.ONE, duree_recollage)
	vol.chain().tween_callback(_pyramide_solide)


func _pyramide_solide() -> void:
	_pyramide.visible = false
	var solide: CSGShape3D = $Chantier/PyramideSolide
	solide.visible = true
	solide.use_collision = true
	_hors_de_la_pyramide(solide)
	var porte: CSGBox3D = $Chantier/Porte
	porte.visible = true
	porte.use_collision = true
	var ouverture := create_tween()
	ouverture.tween_property(porte, "position:y", porte.position.y - porte.size.y - 0.1, duree_porte)
	ouverture.tween_callback(_porte_ouverte)


## Si le joueur se trouve là où la pyramide apparaît, il est posé au sol,
## devant sa face sud.
func _hors_de_la_pyramide(solide: CSGShape3D) -> void:
	var j: Player = $Player
	var centre := j.global_position + Vector3(0, 0.9, 0)
	var devant := -INF
	var dedans := false
	for degre in solide.get_children():
		if degre is CSGBox3D and String(degre.name).begins_with("Degre"):
			var b: AABB = degre.global_transform * AABB(-degre.size / 2, degre.size)
			devant = maxf(devant, b.end.z)
			dedans = dedans or b.grow(0.4).has_point(centre)
	if dedans:
		j.teleport(Transform3D(j.global_basis, Vector3(j.global_position.x, 0, devant + 1.0)))
		j.velocity = Vector3.ZERO


func _porte_ouverte() -> void:
	var porte: CSGBox3D = $Chantier/Porte
	porte.use_collision = false
	porte.visible = false
	$Chantier/Fin.set_deferred("monitoring", true)
	afficher("La réalité se recolle…")
