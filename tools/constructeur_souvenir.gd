extends "res://tools/constructeur.gd"

## Base des constructeurs des souvenirs de Thomas (niveau 1, l'enfance…) :
## murs à ouvertures, toiles peintes, pensées, zones, lampes.

const EP := 0.3


## Les toiles du niveau : { nom: { "fond": couleur, "formes": [[x, y, l, h, couleur], …] } }.
func _motifs() -> Dictionary:
	return {}


## Une interface de souvenir : la chute dans les toiles et l'écran noir des
## yeux fermés, sous les messages.
func _interface_souvenir() -> void:
	var ui := _racine.get_node("Interface")
	_ajouter(ui, ChuteToiles.new(), "ChuteToiles")
	var noir := ColorRect.new()
	noir.color = Color.BLACK
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajouter(ui, noir, "Noir")
	# Les pensées s'affichent par-dessus le noir.
	ui.move_child(ui.get_node("Message"), -1)


# --- Petites briques -------------------------------------------------------


func _lampe(g: Node3D, nom: String, pos: Vector3, portee: float, ombres := true, energie := 1.2) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos - g.position
	l.omni_range = portee
	l.light_energy = energie
	l.shadow_enabled = ombres
	return _ajouter(g, l, nom)


## Une zone (Area3D) en coordonnées du monde.
func _zone(g: Node3D, nom: String, centre: Vector3, taille: Vector3) -> Area3D:
	var a := Area3D.new()
	a.position = centre - g.position
	_ajouter(g, a, nom)
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = taille
	forme.shape = boite
	_ajouter(a, forme, "CollisionShape3D")
	return a


func _marque(g: Node3D, nom: String, pos: Vector3, rot_y := 0.0) -> Marker3D:
	var m := Marker3D.new()
	m.position = pos - g.position
	m.rotation.y = rot_y
	return _ajouter(g, m, nom)


func _pensee(g: Node3D, nom: String, pos: Vector3, texte: String, distance := 6.0, angle := 20.0, regard := true, active := true) -> Pensee:
	var p := Pensee.new()
	p.position = pos - g.position
	p.texte = texte
	p.distance = distance
	p.angle_max_deg = angle
	p.regard = regard
	p.active = active
	return _ajouter(g, p, nom)


## Un mur en coordonnées du monde, de `a0` à `a1` le long de X (`le_long_de_x`)
## ou de Z, centré sur `c` (le z ou le x du mur), avec des ouvertures :
## [centre, largeur, hauteur, hauteur du bas (0 pour une porte)].
func _mur(g: Node3D, nom: String, le_long_de_x: bool, c: float, a0: float, a1: float, h: float, couleur: String, trous := []) -> void:
	var tries := trous.duplicate()
	tries.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var morceaux := []
	var debut := a0
	for t in tries:
		var t0: float = t[0] - t[1] / 2.0
		var t1: float = t[0] + t[1] / 2.0
		var bas: float = t[3] if t.size() > 3 else 0.0
		if t0 > debut:
			morceaux.append([debut, t0, 0.0, h])
		if bas > 0.0:
			morceaux.append([t0, t1, 0.0, bas])
		if bas + t[2] < h:
			morceaux.append([t0, t1, bas + t[2], h])
		debut = t1
	if a1 > debut:
		morceaux.append([debut, a1, 0.0, h])
	for i in morceaux.size():
		var m: Array = morceaux[i]
		var milieu: float = (m[0] + m[1]) / 2.0
		var longueur: float = m[1] - m[0]
		var y: float = (m[2] + m[3]) / 2.0
		var hy: float = m[3] - m[2]
		var pos := Vector3(milieu, y, c) if le_long_de_x else Vector3(c, y, milieu)
		var taille := Vector3(longueur, hy, EP) if le_long_de_x else Vector3(EP, hy, longueur)
		var suffixe := "" if morceaux.size() == 1 else "_%d" % (i + 1)
		_boite(g, nom + suffixe, pos - g.position, taille, couleur)


## Le sol et le plafond d'une pièce : [x0, x1] × [z0, z1] en coordonnées du
## monde, murs compris.
func _sol_plafond(g: Node3D, x0: float, x1: float, z0: float, z1: float, h: float, sol := "sol", plafond := "plafond") -> void:
	var centre := Vector3((x0 + x1) / 2, 0, (z0 + z1) / 2) - g.position
	_boite(g, "Sol", centre + Vector3(0, -0.25, 0), Vector3(x1 - x0, 0.5, z1 - z0), sol)
	if plafond != "":
		_boite(g, "Plafond", centre + Vector3(0, h + EP / 2, 0), Vector3(x1 - x0, EP, z1 - z0), plafond)


## Une toile encadrée (motif de MOTIFS), tournée vers le +Z de `rot_y`.
func _toile(g: Node3D, nom: String, centre: Vector3, rot_y: float, taille: Vector2, motif: String, cadre := "cadre_toile") -> Node3D:
	var t := Node3D.new()
	t.position = centre - g.position
	t.rotation.y = rot_y
	_ajouter(g, t, nom)
	var m: Dictionary = _motifs()[motif]
	_boite(t, "Fond", Vector3.ZERO, Vector3(taille.x, taille.y, 0.03), m["fond"], false)
	var b := 0.08
	_boite(t, "Cadre_haut", Vector3(0, (taille.y + b) / 2, 0), Vector3(taille.x + 2 * b, b, 0.06), cadre, false)
	_boite(t, "Cadre_bas", Vector3(0, -(taille.y + b) / 2, 0), Vector3(taille.x + 2 * b, b, 0.06), cadre, false)
	_boite(t, "Cadre_g", Vector3(-(taille.x + b) / 2, 0, 0), Vector3(b, taille.y, 0.06), cadre, false)
	_boite(t, "Cadre_d", Vector3((taille.x + b) / 2, 0, 0), Vector3(b, taille.y, 0.06), cadre, false)
	var formes: Array = m["formes"]
	for i in formes.size():
		var f: Array = formes[i]
		var pos := Vector3((f[0] + f[2] / 2.0 - 0.5) * taille.x, (f[1] + f[3] / 2.0 - 0.5) * taille.y, 0.02 + 0.002 * i)
		_boite(t, "Forme_%d" % i, pos, Vector3(f[2] * taille.x, f[3] * taille.y, 0.01), f[4], false)
	return t


## Une porte fermée, dessinée sur un mur (montants, panneau, poignée).
func _porte_dessinee(g: Node3D, nom: String, centre_bas: Vector3, rot_y: float) -> Node3D:
	var p := Node3D.new()
	p.position = centre_bas - g.position
	p.rotation.y = rot_y
	_ajouter(g, p, nom)
	_boite(p, "Panneau", Vector3(0, 1.2, 0), Vector3(1.0, 2.4, 0.06), "porte", false)
	_boite(p, "Montant_g", Vector3(-0.57, 1.25, 0.02), Vector3(0.14, 2.5, 0.1), "cadre", false)
	_boite(p, "Montant_d", Vector3(0.57, 1.25, 0.02), Vector3(0.14, 2.5, 0.1), "cadre", false)
	_boite(p, "Linteau", Vector3(0, 2.57, 0.02), Vector3(1.28, 0.14, 0.1), "cadre", false)
	_boite(p, "Poignee", Vector3(0.38, 1.05, 0.06), Vector3(0.12, 0.05, 0.06), "poignee", false)
	return p
