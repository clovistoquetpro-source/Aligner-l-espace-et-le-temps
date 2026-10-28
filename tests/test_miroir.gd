extends RefCounted

## Le miroir, le passage qu'on ne voit que dans le reflet et la chute dans les
## toiles.


func test_camera_au_reflet_de_l_oeil() -> void:
	var c := Miroir.camera_reflet(Transform3D(), Vector3(1, 0.5, 2), Vector2(3, 2.4))
	var t: Transform3D = c["transform"]
	T.proche(t.origin, Vector3(1, 0.5, -2), "derrière le miroir, à la même distance")
	T.proche(-t.basis.z, Vector3(0, 0, 1), "regarde vers le miroir")
	T.proche(c["near"], 2.0, "l'image commence au miroir")
	T.proche(c["decalage"], Vector2(1, -0.5), "cadrée sur le miroir")
	T.proche(c["hauteur"], 2.4, "de la hauteur du miroir")


func test_camera_d_un_miroir_tourne() -> void:
	var m := Transform3D(Basis(Vector3.UP, PI / 2), Vector3(5, 1, 0))
	var oeil := m * Vector3(0.5, 0, 3)
	var c := Miroir.camera_reflet(m, oeil, Vector2(3, 2.4))
	var t: Transform3D = c["transform"]
	T.proche(t.origin, m * Vector3(0.5, 0, -3), "reflet dans le repère du miroir")
	T.proche(-t.basis.z, m.basis.z, "regarde vers le miroir")


func test_pas_de_reflet_derriere_le_miroir() -> void:
	T.ok(Miroir.camera_reflet(Transform3D(), Vector3(0, 0, -1), Vector2(3, 2.4)).is_empty(), "œil derrière le miroir")


func test_franchir_en_reculant_les_yeux_sur_le_miroir() -> void:
	var vers_miroir := Vector3(0, 0, -6)
	var mur := Vector3(0, 0, 1)
	T.ok(PassageReflet.franchit(Vector3(0, 0, -1), vers_miroir, Vector3(0, 0, 5), mur, 35.0, 1.5), "on recule en regardant le miroir")
	T.ok(not PassageReflet.franchit(Vector3(0, 0, 1), vers_miroir, Vector3(0, 0, 5), mur, 35.0, 1.5), "on fonce en regardant le mur")
	T.ok(not PassageReflet.franchit(Vector3(0, 0, -1), vers_miroir, Vector3(0, 0, 0.5), mur, 35.0, 1.5), "on se colle au mur sans foncer")
	T.ok(not PassageReflet.franchit(Vector3(0, 0, -1), vers_miroir, Vector3(0, 0, -5), mur, 35.0, 1.5), "on s'éloigne du mur")


func test_chaque_toile_plus_petite_que_la_precedente() -> void:
	T.proche(ChuteToiles.echelle(0, 0.0), 1.0, "la première remplit l'écran")
	T.proche(ChuteToiles.echelle(1, 0.0), ChuteToiles.RAPPORT, "la suivante est plus petite")
	T.proche(ChuteToiles.echelle(1, 1.0 / ChuteToiles.VITESSE), 1.0, "puis remplit l'écran à son tour")

