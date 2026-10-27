class_name Chantier
extends Node3D

## Le chantier de la pyramide : chaque zone réussie renvoie son groupe de
## blocs dans le nuage. L'alignement final ne marche qu'avec les 4 groupes.
## Les blocs sont les morceaux (CSGShape3D) de l'`Alignement`, chacun avec
## la méta "zone".

const ZONES := ["carriere", "rampe", "camp", "temple"]

signal groupe_revenu(zone: String, total: int)
signal complet

@export var alignement: NodePath
@export var duree_vol := 1.5

var _reussies: Array[String] = []
var _complet := false
var _pyramide: Alignement


func _ready() -> void:
	_pyramide = get_node(alignement) as Alignement
	_pyramide.actif = false
	for b in _blocs(""):
		b.visible = false


func revenus() -> int:
	return _reussies.size()


func est_complet() -> bool:
	return _complet


## Renvoie les blocs de `zone` dans le nuage. S'ils partent de `depart`
## (en coordonnées du monde), ils y volent ; avec Vector3.ZERO, ils
## apparaissent à leur place.
func zone_reussie(zone: String, depart := Vector3.ZERO) -> void:
	if not zone in ZONES or zone in _reussies:
		return
	_reussies.append(zone)
	var vol: Tween = null
	for b in _blocs(zone):
		b.visible = true
		if depart != Vector3.ZERO:
			if vol == null:
				vol = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			var place := b.position
			b.position = _pyramide.to_local(depart)
			vol.tween_property(b, "position", place, duree_vol)
	groupe_revenu.emit(zone, revenus())
	if revenus() == ZONES.size():
		if vol != null:
			vol.finished.connect(_activer)
		else:
			_activer()


func _activer() -> void:
	if _complet:
		return
	_complet = true
	_pyramide.actif = true
	complet.emit()


## Les blocs d'une zone, ou tous les blocs si `zone` est vide.
func _blocs(zone: String) -> Array[Node3D]:
	var res: Array[Node3D] = []
	for b in _pyramide.get_children():
		if b is CSGShape3D and (zone == "" or b.get_meta("zone", "") == zone):
			res.append(b)
	return res
