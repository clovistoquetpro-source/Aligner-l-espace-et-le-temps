extends Niveau

## Niveau « La maison » : relie l'énigme, la sortie et les messages.

@onready var _enigme: Alignement = $Atelier/Horloge
@onready var _sortie: CSGShape3D = $Atelier/PorteSortie


func _ready() -> void:
	Temps.reinitialiser()
	$BasculeFx.environnement = $WorldEnvironment.environment
	_enigme.resolu.connect(_horloge_realignee)
	$Jardin/Fin.body_entered.connect(_fin)
	afficher("Ta maison n'est plus tout à fait ta maison…")


func _horloge_realignee() -> void:
	var or_mat := Style.materiau(Color("ffd700"), true)
	for piece in _enigme.get_children():
		if piece is CSGShape3D:
			piece.material = or_mat
	_sortie.visible = false
	_sortie.use_collision = false
	afficher("La réalité se recolle… La sortie est ouverte !")


func _fin(corps: Node3D) -> void:
	if corps is Player:
		afficher("Époque réparée ! Fin du prototype. Merci d'avoir joué.", 1000.0)
