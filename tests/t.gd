class_name T
extends RefCounted

## Petites assertions pour le lanceur de tests.

static var echecs: Array[String] = []
static var test_courant := ""


static func ok(cond: bool, msg := "") -> void:
	if not cond:
		echecs.append("%s : %s" % [test_courant, msg])


static func eq(a: Variant, b: Variant, msg := "") -> void:
	if a != b:
		echecs.append("%s : %s (obtenu %s, attendu %s)" % [test_courant, msg, a, b])


static func proche(a: Variant, b: Variant, msg := "", eps := 0.001) -> void:
	var ecart: float
	if a is Vector3 or a is Vector2:
		ecart = (a - b).length()
	else:
		ecart = absf(a - b)
	if ecart > eps:
		echecs.append("%s : %s (obtenu %s, attendu %s)" % [test_courant, msg, a, b])
