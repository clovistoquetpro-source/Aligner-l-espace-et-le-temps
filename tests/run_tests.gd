extends SceneTree

## Lance chaque tests/test_*.gd et chaque méthode test_*.
## godot --headless --path . -s res://tests/run_tests.gd


func _initialize() -> void:
	_lancer.call_deferred()


func _lancer() -> void:
	var fichiers := DirAccess.get_files_at("res://tests")
	var total := 0
	for f in fichiers:
		if not (f.begins_with("test_") and f.ends_with(".gd")):
			continue
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			T.echecs.append("%s : le script ne se charge pas" % f)
			print("ECHEC " + f)
			continue
		for m in script.get_script_method_list():
			var nom: String = m["name"]
			if not nom.begins_with("test_"):
				continue
			var obj: Object = script.new()
			if "tree" in obj:
				obj.tree = self
			T.test_courant = "%s::%s" % [f, nom]
			var avant := T.echecs.size()
			await obj.call(nom)
			total += 1
			print(("OK    " if T.echecs.size() == avant else "ECHEC ") + T.test_courant)
			if obj.has_method("nettoyer"):
				obj.nettoyer()
	for e in T.echecs:
		printerr("ECHEC: " + e)
	print("%d tests, %d échecs" % [total, T.echecs.size()])
	quit(1 if T.echecs.size() > 0 else 0)
