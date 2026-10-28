class_name Sentinelle
extends AnimatableBody3D

## La sentinelle de 1942 qui garde l'entrée du camp. Elle fait « non » à qui
## s'approche sans le mot de passe. Quand son alignement (le hiéroglyphe) est
## résolu, elle fait « oui », s'écarte, et la porte antique s'ouvre aussi.

signal refuse

@export var alignement: NodePath
@export var porte_antique: NodePath
## Déplacement quand elle laisse passer, depuis sa place de départ.
@export var ecart := Vector3(1.5, 0, 0)
@export var duree := 1.0

var a_laisse_passer := false


func _ready() -> void:
	var approche := get_node_or_null("Approche") as Area3D
	if approche != null:
		approche.body_entered.connect(_joueur_approche)
	var a := get_node_or_null(alignement) as Alignement
	if a != null:
		a.resolu.connect(_laisser_passer)
	Anime.jouer(self, "Idle")


func _joueur_approche(corps: Node3D) -> void:
	# Cachée, la sentinelle n'existe pas dans cette époque.
	if a_laisse_passer or not corps is Player or not is_visible_in_tree():
		return
	Anime.jouer(self, "No")
	refuse.emit()


func _laisser_passer() -> void:
	if a_laisse_passer:
		return
	a_laisse_passer = true
	Anime.jouer(self, "Yes")
	var t := create_tween()
	t.tween_property(self, "position", position + ecart, duree).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_ouvrir_porte)


func _ouvrir_porte() -> void:
	var porte := get_node_or_null(porte_antique)
	if porte != null:
		porte.queue_free()
	Anime.jouer(self, "Idle")
