extends SceneTree

## Reconstruit scenes/atelier.tscn :
## godot --headless --path . -s res://tools/construire_atelier.gd


func _initialize() -> void:
	_construire.call_deferred()


func _construire() -> void:
	var script: GDScript = load("res://tools/constructeur_atelier.gd")
	if script == null or not script.can_instantiate():
		quit(1)
		return
	var err: int = script.new().construire()
	quit(0 if err == OK else 1)
