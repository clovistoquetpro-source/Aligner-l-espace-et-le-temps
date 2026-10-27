extends SceneTree

## Reconstruit scenes/maison.tscn :
## godot --headless --path . -s res://tools/construire_maison.gd
## Le constructeur est chargé après les autoloads (il utilise Temps).


func _initialize() -> void:
	_construire.call_deferred()


func _construire() -> void:
	var script: GDScript = load("res://tools/constructeur_maison.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var err: int = script.new().construire()
	quit(0 if err == OK else 1)
