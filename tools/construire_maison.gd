extends SceneTree

## Reconstruit scenes/maison.tscn :
## godot --headless --path . -s res://tools/construire_maison.gd
## Le constructeur est chargé après les autoloads (il utilise Temps).


func _initialize() -> void:
	_construire.call_deferred()


func _construire() -> void:
	var err: int = load("res://tools/constructeur_maison.gd").new().construire()
	quit(0 if err == OK else 1)
