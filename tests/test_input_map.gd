extends RefCounted


func _a_touche(action: String, code: Key) -> bool:
	if not InputMap.has_action(action):
		return false
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.physical_keycode == code:
			return true
	return false


func test_avancer_est_touche_physique_w() -> void:
	T.ok(_a_touche("avancer", KEY_W), "avancer = W physique (Z en AZERTY)")


func test_deplacements_physiques() -> void:
	T.ok(_a_touche("gauche", KEY_A), "gauche = A physique (Q en AZERTY)")
	T.ok(_a_touche("reculer", KEY_S), "reculer = S")
	T.ok(_a_touche("droite", KEY_D), "droite = D")
	T.ok(_a_touche("sauter", KEY_SPACE), "sauter = Espace")
	T.ok(_a_touche("interagir", KEY_E), "interagir = E")
	T.ok(_a_touche("liberer_souris", KEY_ESCAPE), "liberer_souris = Échap")
	T.ok(_a_touche("fermer_les_yeux", KEY_F), "fermer_les_yeux = F")


func test_basculer_tab_et_clic_droit() -> void:
	T.ok(_a_touche("basculer", KEY_TAB), "basculer = Tab")
	var clic := false
	if InputMap.has_action("basculer"):
		for e in InputMap.action_get_events("basculer"):
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
				clic = true
	T.ok(clic, "basculer = clic droit")
