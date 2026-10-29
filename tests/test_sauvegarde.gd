extends RefCounted

## La sauvegarde (Histoire), le menu principal et le menu pause.

const ESSAI := "user://test_sauvegarde.cfg"
const ESSAI_REGLAGES := "user://test_reglages.cfg"

var tree: SceneTree
var _scene: Node


func _preparer() -> void:
	Histoire.simuler = true
	Histoire.chemin_sauvegarde = ESSAI
	Histoire.effacer()
	Histoire.reinitialiser()


func nettoyer() -> void:
	Histoire.effacer()
	Histoire.chemin_sauvegarde = "user://sauvegarde.cfg"
	Histoire.reinitialiser()
	Histoire.simuler = false
	Pause.reprendre()
	Pause.chemin_reglages = "user://reglages.cfg"
	if is_instance_valid(_scene):
		_scene.free()


func test_changer_de_niveau_sauvegarde() -> void:
	_preparer()
	T.ok(not Histoire.peut_continuer(), "pas de partie au début")
	Histoire.chapitre = 3
	Histoire.corrections = 2
	Histoire.vers("res://scenes/ete.tscn")
	var s := Histoire.lire()
	T.eq(s.get("chapitre"), 3, "le chapitre")
	T.eq(s.get("corrections"), 2, "les corrections")
	T.eq(s.get("scene"), "res://scenes/ete.tscn", "le niveau où l'on est")
	T.ok(Histoire.peut_continuer(), "on peut continuer")


func test_continuer_reprend_la_partie() -> void:
	_preparer()
	Histoire.chapitre = 4
	Histoire.corrections = 3
	Histoire.vers("res://scenes/dispute.tscn")
	Histoire.reinitialiser()
	Histoire.continuer()
	T.eq(Histoire.chapitre, 4, "le chapitre revient")
	T.eq(Histoire.corrections, 3, "les corrections reviennent")
	T.eq(Histoire.scene_demandee, "res://scenes/dispute.tscn", "on reprend au début du niveau")


func test_revenir_au_menu_ne_perd_pas_la_partie() -> void:
	_preparer()
	Histoire.chapitre = 2
	Histoire.vers("res://scenes/enfance.tscn")
	Histoire.vers("res://scenes/menu.tscn")
	T.eq(Histoire.lire().get("scene"), "res://scenes/enfance.tscn", "toujours l'enfance")


func test_le_jeu_fini_ne_se_continue_pas() -> void:
	_preparer()
	Histoire.chapitre = Histoire.FIN
	Histoire.vers("res://scenes/menu.tscn")
	T.ok(not Histoire.peut_continuer(), "plus rien à continuer")


func test_le_menu_principal() -> void:
	_preparer()
	_scene = load("res://scenes/menu.tscn").instantiate()
	tree.root.add_child(_scene)
	await tree.process_frame
	T.ok(not (_scene.find_child("Continuer", true, false) as Button).visible, "sans partie, pas de « Continuer »")
	_scene.nouvelle_partie()
	T.eq(Histoire.scene_demandee, _scene.PREMIERE_SCENE, "« Nouvelle partie » lance le jeu")
	T.ok(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/menu.tscn", "F5 lance le menu")


func test_nouvelle_partie_demande_confirmation() -> void:
	_preparer()
	Histoire.chapitre = 3
	Histoire.vers("res://scenes/ete.tscn")
	Histoire.scene_demandee = ""
	_scene = load("res://scenes/menu.tscn").instantiate()
	tree.root.add_child(_scene)
	await tree.process_frame
	T.ok((_scene.find_child("Continuer", true, false) as Button).visible, "« Continuer »")
	_scene.nouvelle_partie()
	T.eq(Histoire.scene_demandee, "", "d'abord, on demande")
	_scene.nouvelle_partie()
	T.eq(Histoire.scene_demandee, _scene.PREMIERE_SCENE, "puis on recommence")
	T.eq(Histoire.chapitre, 1, "au chapitre 1")


func test_le_menu_pause() -> void:
	Pause.chemin_reglages = ESSAI_REGLAGES
	Pause.mettre_en_pause()
	T.ok(tree.paused, "le jeu s'arrête")
	T.ok((Pause.get_node("Panneau") as Control).visible, "le panneau")
	T.ok(Pause.process_mode == Node.PROCESS_MODE_ALWAYS, "le menu marche pendant la pause")
	Pause.changer_sensibilite(1.5)
	T.proche(Pause.sensibilite, 1.5, "la sensibilité")
	var f := ConfigFile.new()
	T.eq(f.load(ESSAI_REGLAGES), OK, "les réglages sont écrits")
	T.proche(float(f.get_value("souris", "sensibilite", 0.0)), 1.5, "et relus")
	Pause.reprendre()
	T.ok(not tree.paused, "on reprend")
	T.ok(not (Pause.get_node("Panneau") as Control).visible, "plus de panneau")
	Pause.changer_sensibilite(1.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ESSAI_REGLAGES))
