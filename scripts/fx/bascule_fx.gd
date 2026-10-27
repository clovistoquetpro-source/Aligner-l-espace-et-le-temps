class_name BasculeFx
extends CanvasLayer

## Effet plein écran quand on change d'époque, secousse quand c'est refusé,
## et couleurs du monde propres à chaque époque (`palettes`, réglées par le
## niveau ; celles de la maison par défaut).

const DUREE := 0.5
const DUREE_SECOUSSE := 0.15
const PALETTES := {
	0: { "ciel": Color("ff9ecf"), "ambiance": Color("3ee6d0") },
	1: { "ciel": Color("ffb347"), "ambiance": Color("7b4fd6") },
}

## { époque: { "ciel": Color, "ambiance": Color } }
var palettes := PALETTES:
	set(p):
		palettes = p
		_cible = palettes[Temps.courante]
		_appliquer_couleurs(_t)

var environnement: Environment:
	set(e):
		environnement = e
		_appliquer_couleurs(1.0)

var _t := 1.0
var _t_secousse := 1.0
var _depart := PALETTES[0]
var _cible := PALETTES[0]

@onready var _ecran: ColorRect = $Ecran


func _ready() -> void:
	Temps.epoque_changee.connect(_sur_bascule)
	Temps.bascule_refusee.connect(_sur_refus)
	_cible = palettes[Temps.courante]
	_mettre_a_jour()


func intensite() -> float:
	return 0.0 if _t >= 1.0 else 1.0 - _t


func secousse() -> float:
	return 0.0 if _t_secousse >= 1.0 else 1.0 - _t_secousse


func _sur_bascule(epoque: int) -> void:
	_depart = { "ciel": _couleur("ciel"), "ambiance": _couleur("ambiance") }
	_cible = palettes[epoque]
	_t = 0.0
	_mettre_a_jour()


func _sur_refus() -> void:
	_t_secousse = 0.0
	_mettre_a_jour()


func _process(delta: float) -> void:
	_t = minf(_t + delta / DUREE, 1.0)
	_t_secousse = minf(_t_secousse + delta / DUREE_SECOUSSE, 1.0)
	_mettre_a_jour()


func _mettre_a_jour() -> void:
	var mat := _ecran.material as ShaderMaterial
	mat.set_shader_parameter("intensite", intensite())
	mat.set_shader_parameter("secousse", secousse())
	_ecran.visible = intensite() > 0.0 or secousse() > 0.0
	_appliquer_couleurs(_t)


func _couleur(cle: String) -> Color:
	if environnement == null:
		return _cible[cle]
	return environnement.background_color if cle == "ciel" else environnement.ambient_light_color


func _appliquer_couleurs(t: float) -> void:
	if environnement == null:
		return
	if t >= 1.0:
		_depart = _cible
	environnement.background_color = _depart["ciel"].lerp(_cible["ciel"], t)
	environnement.fog_light_color = environnement.background_color
	environnement.ambient_light_color = _depart["ambiance"].lerp(_cible["ambiance"], t)
