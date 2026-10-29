extends Souvenir

## Niveau 4, en formes simples : « La pluie ». D'abord le bonheur : l'atelier
## à deux, un jour de soleil (Juliette cache les clés de la moto, on ne les
## voit que dans le miroir), puis une balade à moto au bord de la mer, cheveux
## au vent. Puis, des années plus tard, le soir de la dispute : on
## arrive à la fin du souvenir, figé (la pluie suspendue). R maintenu remonte
## le temps ; ce que Thomas tient ne remonte pas le temps. Il faut descendre
## de la mezzanine avant que l'étagère ne tombe sur l'escalier, reprendre le
## casque de Juliette avant qu'il ne tombe sous la grille, et sortir quand
## elle part. La correction du peintre : cette fois, Thomas lui court après.
## Au bout de la route, le vide : elle tombe dans tous les cas.
## Voir docs/superpowers/specs/2026-10-28-direction-illusions-design.md.

enum Etat { BONHEUR, BALADE, ATELIER, COURSE, CHUTE, VERITE, FIN }

## La balade : sa vitesse (m/s), et ce que disent Juliette et Thomas.
const VITESSE_BALADE := 9.0
const LONGUEUR_BALADE := 620.0
const PAROLES_BALADE := [
	[3.0, "Juliette", "Accroche-toi !"],
	[12.0, "Juliette", "Tu sens le vent ?"],
	[22.0, "", "Ses cheveux me fouettaient le visage. Elle riait."],
	[32.0, "Juliette", "Ferme les yeux. Juste une seconde."],
	[46.0, "Thomas", "Je voudrais que ça ne s'arrête jamais."],
	[50.0, "Juliette", "Alors on ne s'arrêtera jamais."],
	[60.0, "", "On roulait souvent. Puis, un soir, il a plu."],
]

## La dispute dure 40 s ; on arrive à la fin, quand tout est figé.
const DUREE := 40.0
const VITESSE_REBOURS := 1.5
## Quelques secondes où la porte est ouverte : Juliette part.
const PORTE := [30.6, 33.0]
## Les phrases de la dispute : [t, qui, phrase].
const PHRASES := [
	[2.0, "Juliette", "Tu ne lèves même plus les yeux de tes toiles."],
	[6.0, "Thomas", "Je travaille, Juliette."],
	[10.0, "Juliette", "Tu peins nos souvenirs au lieu de les vivre. Viens rouler avec moi."],
	[14.0, "Thomas", "Il pleut. Et je n'ai pas le temps."],
	[18.0, "Juliette", "Tu n'as jamais le temps."],
	[20.0, "Thomas", "Laisse-moi !"],
	[24.0, "Juliette", "Je pars rouler. Seule."],
	[30.0, "Juliette", "Très bien. Je m'en vais."],
	[31.0, "Thomas", "C'est ça. Va-t'en !"],
]
## La course : Thomas court plus vite qu'il ne marche ; la mobylette reste
## devant lui ; la route se tord un peu.
const VITESSE_COURSE := 1.5
const AVANCE_MOTO := 11.0
const ROULIS := 0.06
## La route de la course (en coordonnées de son groupe ; tools/
## constructeur_dispute.gd la construit à partir d'ici). Trois parties : la
## rue sous la pluie ; la rue inondée, toute noire, où l'on ne voit plus la
## rue que dans l'eau ; puis les toiles du peintre, qui barrent toute la
## route : les yeux fermés, on voit les vrais murs.
const INONDEE := [-160.0, -312.0]
## Les reflets sont un peu sous la surface de l'eau (sinon, elle scintille).
const SOUS_L_EAU := 0.03
const DEBUT_TOILES := -315.0
const FIN_COURSE := -455.0
const VOIES := [-3.0, 0.0, 3.0]
## Les obstacles : [z, type, voies bloquées]. Types : « barriere » (à
## sauter), « mur » (à éviter), « trou » (à sauter, longueur en m),
## « toiles » (trois toiles peintes, et derrière, les vrais murs).
const OBSTACLES := [
	[-20.0, "barriere", 0], [-35.0, "mur", [0, 1]], [-50.0, "mur", [1, 2]], [-62.0, "trou", 3.0],
	[-78.0, "barriere", 0], [-90.0, "mur", [0, 2]], [-105.0, "trou", 3.5], [-118.0, "mur", [0, 1]],
	[-127.0, "barriere", 0], [-140.0, "mur", [1, 2]], [-152.0, "trou", 3.0],
	[-188.0, "mur", [1]], [-202.0, "barriere", 0], [-215.0, "mur", [0, 1]], [-228.0, "mur", [1, 2]],
	[-240.0, "barriere", 0], [-252.0, "mur", [0, 2]], [-264.0, "mur", [0, 1]], [-274.0, "barriere", 0],
	[-286.0, "mur", [1, 2]], [-297.0, "mur", [0, 2]],
	[-335.0, "toiles", [0, 1]], [-355.0, "toiles", [1, 2]], [-372.0, "toiles", [0, 2]], [-388.0, "toiles", [0, 1]],
	[-403.0, "toiles", [1, 2]], [-416.0, "toiles", [0, 2]], [-430.0, "toiles", [0, 1]], [-442.0, "toiles", [1, 2]],
]
## La mobylette regarde ce loin devant elle pour choisir sa voie, et se
## déplace de côté de ce nombre de mètres par mètre parcouru.
const VUE_MOTO := 14.0
const DERIVE_MOTO := 1.2
## Les toiles attendent en l'air, au-dessus de la route, et tombent quand
## Thomas arrive à cette distance (juste après le passage de Juliette).
const HAUT_TOILES := 14.0
const CHUTE_TOILES := [13.0, 10.0]
## Devant les premières toiles, Thomas s'arrête : il faut fermer les yeux.
const PREMIERES_TOILES := -335.0
## La course se remonte, comme le soir de la dispute : on garde les
## dernières secondes. Après un échec, on remonte au moins ce temps.
const MEMOIRE_COURSE := 12.0
const RECUL_MIN := 0.5
## La chute : Juliette est d'abord à 5 m sous Thomas ; chaque appui sur
## Espace la rapproche, la chute l'éloigne.
const ECART_CHUTE := 5.0
const RAPPROCHE := 0.3
const ELOIGNE := 0.55
const ATTRAPEE := 0.8
const DUREE_CHUTE := 9.0

var etat := Etat.BONHEUR
var cles_trouvees := false
var temps_balade := 0.0
## L'instant du souvenir (de 0, avant la dispute, à DUREE, après).
var moment := DUREE
var rembobine := false
var ecart := ECART_CHUTE
var rattrapee := false

var _dit := {}
var _temps_reel := 0.0
## Où en est la mobylette dans la course (coordonnées de la route).
var moto_x := 0.0
var moto_z := -4.0
## La course est arrêtée (après un échec, ou R) : R la remonte.
var course_figee := false
## Devant les premières toiles, Thomas s'arrête.
var arret_toiles := false
var _echec := false
var _passe: Array = []
var _curseur := 0.0
var _yeux_fermes_depuis := 0.0
var _arret_depuis := 0.0
var _moto_dans_l_eau := false
## Images de course depuis le départ ou la reprise : juste après, le dernier
## contact de Thomas date d'avant l'arrêt.
var _depuis_reprise := 0
var _masque_normal := 0
var _toiles_course: Array[Node3D] = []
## Le vrai mur derrière chaque toile (ou rien).
var _vrais_murs := {}
var _temps_chute := 0.0
var _lachee := false
var _temporels: Array[ObjetTemporel] = []

@onready var _cles: RigidBody3D = $Bonheur/Cles
@onready var _juliette_atelier: Node3D = $Bonheur/Juliette
@onready var _moto_bonheur: Node3D = $Bonheur/Mobylette
@onready var _moto_balade: Node3D = $Balade/Mobylette
## Une copie : la course l'assombrit (la rue inondée).
@onready var _env_pluie: Environment = ($WorldEnvironment as WorldEnvironment).environment.duplicate()
@onready var _casque: RigidBody3D = $Atelier/Casque
@onready var _sortie: Area3D = $Atelier/Sortie
@onready var _rebours: ColorRect = $Interface/Rebours
@onready var _blanc: ColorRect = $Interface/Blanc
@onready var _pluie: Pluie = $Rue/Pluie
@onready var _pluie_ouest: Pluie = $Rue/Pluie_ouest
@onready var _moto_course: Node3D = $Course/Mobylette
@onready var _pluie_course: Pluie = $Course/Pluie
@onready var _vide: Area3D = $Course/Vide
@onready var _bord: Area3D = $Course/Bord
@onready var _juliette_chute: Node3D = $Vide/Juliette
@onready var _pluie_chute: Pluie = $Vide/Pluie


var _soleil: DirectionalLight3D


func _ready() -> void:
	Temps.reinitialiser()
	_joueur.camera.cull_mask &= ~(Miroir.COUCHE_REFLET | COUCHE_VRAI)
	_masque_normal = _joueur.camera.cull_mask
	for n in get_tree().get_nodes_in_group("toiles_course"):
		if is_ancestor_of(n):
			_toiles_course.append(n as Node3D)
			_vrais_murs[n] = get_node_or_null("Course/Vrai_" + String(n.name).replace("Toile_", "mur_"))
	for n in find_children("*", "ObjetTemporel", true, false):
		_temporels.append(n as ObjetTemporel)
	_sortie.body_entered.connect(_sur_sortie)
	_vide.body_entered.connect(_sur_vide)
	_bord.body_entered.connect(_sur_bord)
	($Bonheur/Depart_moto as Area3D).body_entered.connect(_sur_la_moto)
	_chute.finie.connect(_retour_dans_la_maison_des_etoiles)
	_appliquer_le_moment()
	_le_soleil(true)
	var t := _ouvrir_les_yeux("Notre atelier, un jour de soleil.")
	t.tween_interval(1.0)
	t.tween_callback(dire.bind("Juliette", "Tu as encore de la peinture sur le nez."))
	t.tween_callback(dire.bind("Juliette", "Il fait si beau… Viens rouler avec moi !"))
	t.tween_callback(dire.bind("Thomas", "D'accord. Je prends les clés."))
	t.tween_callback(dire.bind("Juliette", "Trop tard, je les ai cachées ! Regarde-toi dans le miroir, tu verras."))


## Le soleil du bonheur (ou la pluie du soir de la dispute).
func _le_soleil(beau: bool) -> void:
	var we := $WorldEnvironment as WorldEnvironment
	if not beau:
		we.environment = _env_pluie
		if _soleil != null:
			_soleil.queue_free()
			_soleil = null
		return
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color("4ea8de")
	ciel.sky_horizon_color = Color("ffb38a")
	ciel.ground_horizon_color = Color("ffb38a")
	ciel.ground_bottom_color = Color("3a86ff")
	var sky := Sky.new()
	sky.sky_material = ciel
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffe8c2")
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	we.environment = env
	_soleil = DirectionalLight3D.new()
	_soleil.name = "Soleil"
	_soleil.rotation_degrees = Vector3(-18, -100, 0)
	_soleil.light_color = Color("ffd6a5")
	_soleil.shadow_enabled = true
	add_child(_soleil)


# --- Le bonheur ----------------------------------------------------------------


func _dans_le_bonheur() -> void:
	if _joueur.held == _cles and not cles_trouvees:
		cles_trouvees = true
		for m in _cles.find_children("*", "MeshInstance3D", false, false):
			(m as MeshInstance3D).layers = 1
		penser("Les voilà !")
		dire("Juliette", "Bravo ! Allez, je t'attends dehors.")
		_juliette_atelier.visible = false
		_moto_bonheur.get_node("Juliette").visible = true
	var cheveux: Node3D = _juliette_atelier.get_node("Cheveux")
	cheveux.rotation.x = 0.08 * sin(_temps_reel * 1.5)
	_temps_reel += get_physics_process_delta_time()


func _sur_la_moto(corps: Node3D) -> void:
	if not corps is Player or etat != Etat.BONHEUR:
		return
	if not cles_trouvees:
		if _une_fois("sans_cles"):
			penser("Les clés… Elle les a cachées.")
		return
	commencer_la_balade()


## Thomas monte derrière Juliette ; la moto file au bord de la mer. On peut
## regarder autour de soi, rien de plus.
func commencer_la_balade() -> void:
	etat = Etat.BALADE
	temps_balade = 0.0
	if _joueur.held != null:
		var c := _joueur.held
		_joueur.poser()
		c.visible = false
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	_joueur.head.position.y = 1.7
	_placer_sur_la_moto(0.0)
	_joueur.rotation.y = _moto_balade.rotation.y
	_blanc.color.a = 1.0
	create_tween().tween_property(_blanc, "color:a", 0.0, 1.5)


## Le virage de la route de la balade, à `z` (coordonnées de la balade).
static func virage(z: float) -> float:
	return 25.0 * sin(z / 90.0)


var _cap_balade := 0.0


func _placer_sur_la_moto(t: float) -> void:
	var balade := ($Balade as Node3D).global_position
	var z := -minf(t * VITESSE_BALADE, LONGUEUR_BALADE)
	var avant := Vector3(virage(z - 1.0), 0, z - 1.0)
	var ici := Vector3(virage(z), 0, z)
	var cap := atan2(-(avant.x - ici.x), -(avant.z - ici.z))
	_moto_balade.global_position = balade + ici
	_moto_balade.rotation = Vector3(0, cap, (virage(z - 6.0) - virage(z)) * -0.02)
	# Thomas, assis derrière elle : sa tête suit la moto, il regarde où il veut.
	var regard := _joueur.rotation.y - _cap_balade
	_cap_balade = cap
	# Un peu sur le côté : il regarde la route par-dessus son épaule.
	_joueur.global_position = _moto_balade.global_position + _moto_balade.global_basis * Vector3(0.35, 0.0, 0.85)
	_joueur.rotation.y = cap + clampf(wrapf(regard, -PI, PI), -1.8, 1.8)


func _dans_la_balade(delta: float) -> void:
	var avant := temps_balade
	temps_balade += delta
	_placer_sur_la_moto(temps_balade)
	var cheveux: Node3D = _moto_balade.get_node("Juliette/Cheveux")
	cheveux.rotation.x = 0.5 + 0.2 * sin(temps_balade * 7.0)
	_joueur.camera.fov = 80.0 + 4.0 * sin(temps_balade * 0.6)
	for p in PAROLES_BALADE:
		if avant < p[0] and temps_balade >= p[0]:
			if p[1] == "":
				penser(p[2])
			else:
				dire(p[1], p[2])
	if yeux_fermes() and temps_balade > 30.0 and _une_fois("yeux_balade"):
		penser("Le vent, le soleil, elle.")
	if temps_balade >= LONGUEUR_BALADE / VITESSE_BALADE:
		etat = Etat.ATELIER
		var t := create_tween()
		t.tween_property(_noir, "color:a", 1.0, 2.0)
		t.tween_callback(commencer_la_dispute)


## Des années plus tard, le soir de la dispute, figé : Juliette est partie.
func commencer_la_dispute(fondu := true) -> void:
	etat = Etat.ATELIER
	_le_soleil(false)
	_joueur.camera.fov = 80.0
	_joueur.head.position.y = 1.6
	touches_en_plus = "R (maintenu) : remonter le temps"
	var depart: Marker3D = $Mezzanine/Depart
	_joueur.teleport(depart.global_transform)
	_joueur.set_anchor(depart.global_transform)
	_joueur.set_physics_process(true)
	if not fondu:
		_noir.color.a = 0.0
		return
	var t := _ouvrir_les_yeux("Des années plus tard. Elle est partie. Il pleuvait.")
	t.tween_callback(penser.bind("Tout s'est arrêté, ce soir-là."))
	t.tween_interval(6.0)
	t.tween_callback(penser.bind("Si je pouvais revenir en arrière…"))


func _une_fois(cle: String) -> bool:
	if _dit.has(cle):
		return false
	_dit[cle] = true
	return true


## Une phrase écrite à l'envers, quand on remonte le temps.
static func a_l_envers(texte: String) -> String:
	var r := ""
	for i in range(texte.length() - 1, -1, -1):
		r += texte[i]
	return r


func _physics_process(delta: float) -> void:
	match etat:
		Etat.BONHEUR:
			_dans_le_bonheur()
		Etat.BALADE:
			_dans_la_balade(delta)
		Etat.ATELIER:
			_dans_l_atelier(delta)
		Etat.COURSE:
			_dans_la_course(delta)
		Etat.CHUTE:
			_dans_la_chute(delta)
		Etat.VERITE:
			_temps_reel += delta
			_pluie.temps = _temps_reel
			_pluie_ouest.temps = _temps_reel
			if Input.is_action_pressed("rembobiner") and _une_fois("pas_de_retour"):
				penser("On ne remonte pas le temps.")
	_ecouter_les_pensees()


# --- L'atelier : le temps à rebours ------------------------------------------


func _dans_l_atelier(delta: float) -> void:
	var avant := moment
	rembobine = Input.is_action_pressed("rembobiner")
	if rembobine:
		moment = maxf(moment - delta * VITESSE_REBOURS, 0.0)
		if _une_fois("premier_rebours"):
			penser("Le temps… il recule.")
	else:
		moment = minf(moment + delta, DUREE)
	_rebours.color.a = move_toward(_rebours.color.a, 0.18 if rembobine and moment > 0.0 else 0.0, delta * 2.0)
	if moment != avant:
		_dire_les_phrases(avant, moment)
		_appliquer_le_moment()
	var tenu := _joueur.held == _casque
	if tenu:
		var o: ObjetTemporel = _casque.get_node("Temps")
		if not o.hors_du_temps:
			o.hors_du_temps = true
			penser("Son casque. Je le tiens : il ne remonte plus le temps.")
	$Atelier/PenseeGrille.active = moment > 21.5 and not _casque.get_node("Temps").hors_du_temps


## Les phrases dites entre deux instants : à l'endroit si le temps avance, à
## l'envers s'il recule.
func _dire_les_phrases(avant: float, apres: float) -> void:
	for p in PHRASES:
		var t: float = p[0]
		if avant < t and apres >= t:
			afficher("%s : « %s »" % [p[1], p[2]], 3.5)
		elif avant >= t and apres < t:
			afficher("%s : « %s »" % [p[1], a_l_envers(p[2])], 2.0)


func _appliquer_le_moment() -> void:
	for o in _temporels:
		if o.get_parent() == _casque and _joueur.held == _casque:
			continue
		o.appliquer(moment)
	_pluie.temps = moment
	_pluie_ouest.temps = moment


## La porte est ouverte (Juliette part) : on peut la suivre.
func porte_ouverte() -> bool:
	return moment >= PORTE[0] and moment <= PORTE[1]


func _sur_sortie(corps: Node3D) -> void:
	if not corps is Player or etat != Etat.ATELIER:
		return
	if _joueur.held != _casque:
		if _une_fois("sans_casque"):
			penser("Son casque… Il faut que je lui donne son casque.")
		return
	commencer_la_course()


# --- La course-poursuite : la correction -------------------------------------


## Cette fois, Thomas lui court après, son casque à la main.
func commencer_la_course() -> void:
	etat = Etat.COURSE
	Histoire.corrections += 1
	_rebours.color.a = 0.0
	var depart: Marker3D = $Course/Depart
	_joueur.teleport(depart.global_transform)
	_joueur.set_anchor(depart.global_transform)
	_joueur.avance_auto = true
	_joueur.facteur_vitesse = VITESSE_COURSE
	moto_x = 0.0
	moto_z = depart.global_position.z - ($Course as Node3D).global_position.z - AVANCE_MOTO
	course_figee = false
	arret_toiles = false
	_passe.clear()
	_depuis_reprise = 0
	penser("Cette fois, je te rattrape.")
	dire("Thomas", "Juliette ! Attends !")


## La voie que vise la mobylette à `z` : la plus proche du milieu parmi
## celles que le prochain mur laisse libres.
static func voie_moto(z: float) -> float:
	for o in OBSTACLES:
		if (o[1] != "mur" and o[1] != "toiles") or o[0] > z + 0.8 or o[0] < z - VUE_MOTO:
			continue
		var libres := []
		for v in VOIES.size():
			if not v in o[2]:
				libres.append(VOIES[v])
		libres.sort_custom(func(a: float, b: float) -> bool: return absf(a) < absf(b) or (absf(a) == absf(b) and a > b))
		return libres[0]
	return 0.0


## Un pas de la mobylette : elle avance de `dz` (vers -Z) et glisse vers sa
## voie.
static func pas_moto(x: float, z: float, dz: float) -> float:
	return move_toward(x, voie_moto(z), DERIVE_MOTO * dz)


## La hauteur de la mobylette à `z` : elle saute les barrières et les trous,
## et tombe dans le vide au bout de la route.
static func hauteur_moto(z: float) -> float:
	if z < FIN_COURSE:
		return -0.6 * pow(FIN_COURSE - z, 2.0)
	var y := 0.0
	for o in OBSTACLES:
		var debut: float = o[0] + 2.0
		var fin: float = o[0] - 2.0
		if o[1] == "trou":
			debut = o[0] + 1.5
			fin = o[0] - o[2] - 1.5
		elif o[1] != "barriere":
			continue
		if z <= debut and z >= fin:
			var k := (debut - z) / (debut - fin)
			y = maxf(y, 4.0 * 1.1 * k * (1.0 - k))
	return y


## La nuit de la rue inondée, à `z` (coordonnées de la route) : 0 dehors, 1
## dedans, avec 10 m pour passer de l'un à l'autre.
static func nuit(z: float) -> float:
	return clampf((INONDEE[0] - z) / 10.0, 0.0, 1.0) * clampf((z - INONDEE[1]) / 10.0, 0.0, 1.0)


## La hauteur d'une toile qui attend au-dessus de la route, quand Thomas est
## à `d` mètres devant elle : en l'air, puis elle tombe, puis elle est posée.
static func hauteur_toile(d: float) -> float:
	if d >= CHUTE_TOILES[0]:
		return HAUT_TOILES
	if d <= CHUTE_TOILES[1]:
		return 0.0
	var k := (CHUTE_TOILES[0] - d) / (CHUTE_TOILES[0] - CHUTE_TOILES[1])
	return HAUT_TOILES * (1.0 - k * k)


func _dans_la_course(delta: float) -> void:
	if course_figee:
		_remonter_la_course(delta)
		return
	var p := _joueur.global_position
	var route := ($Course as Node3D).global_position
	if arret_toiles:
		_devant_les_toiles(delta)
	elif _joueur.is_physics_processing():
		_temps_reel += delta
		# La mobylette reste devant : elle évite les murs, saute le reste.
		var z := minf(p.z - route.z - AVANCE_MOTO, 10.0)
		var dz := maxf(moto_z - z, 0.0)
		var pas := 0.0
		while pas < dz:
			var d := minf(0.25, dz - pas)
			moto_x = pas_moto(moto_x, moto_z - pas - d, d)
			pas += d
		moto_z = minf(z, moto_z)
	_le_monde_de_la_course(p, delta)
	if arret_toiles or not _joueur.is_physics_processing():
		return
	_passe.append([p, _joueur.velocity, moto_x, moto_z, _temps_reel])
	if _passe.size() > int(MEMOIRE_COURSE * Engine.physics_ticks_per_second):
		_passe.pop_front()
	_depuis_reprise += 1
	if _depuis_reprise > 1 and _a_echoue():
		figer_la_course(true)
	elif Input.is_action_just_pressed("rembobiner"):
		figer_la_course(false)
	var zr := p.z - route.z
	if zr < INONDEE[0] - 6.0 and _une_fois("nuit"):
		penser("Il fait si noir… Je ne vois plus rien.")
		penser("Dans l'eau… La rue est encore là, dans l'eau.")
	if zr < INONDEE[1] - 4.0 and _une_fois("jour"):
		penser("La lumière… Elle est toujours devant moi.")
	# Devant les premières toiles, Thomas s'arrête.
	if zr < PREMIERES_TOILES + CHUTE_TOILES[1] - 1.0 and _une_fois("arret_toiles"):
		arret_toiles = true
		_arret_depuis = 0.0
		_yeux_fermes_depuis = 0.0
		_joueur.velocity = Vector3.ZERO
		_joueur.set_physics_process(false)
		penser("Des toiles… Elles barrent toute la route.")
		penser("Elle me disait : ferme les yeux. Juste une seconde.")


## La mobylette, la pluie, la nuit, les toiles et les yeux fermés, à
## l'instant de la course où en est Thomas (qui court ou remonte le temps).
func _le_monde_de_la_course(p: Vector3, delta: float) -> void:
	var route := ($Course as Node3D).global_position
	var zr := p.z - route.z
	var avant := _moto_course.global_position.x - route.x
	_moto_course.global_position = route + Vector3(moto_x, hauteur_moto(moto_z), moto_z)
	# Elle penche dans les virages.
	_moto_course.rotation = Vector3(0.0, 0.0, clampf((moto_x - avant) * -3.0, -0.35, 0.35))
	var cheveux: Node3D = _moto_course.get_node("Juliette/Cheveux")
	cheveux.rotation.x = 0.35 + 0.15 * sin(_temps_reel * 6.0)
	# Dans la rue inondée, on ne la voit plus que dans l'eau.
	var dans_l_eau: bool = moto_z < INONDEE[0] and moto_z > INONDEE[1]
	if dans_l_eau != _moto_dans_l_eau:
		_moto_dans_l_eau = dans_l_eau
		for g in _moto_course.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).layers = Miroir.COUCHE_REFLET if dans_l_eau else 1 | COUCHE_VRAI
	var reflet: Node3D = $Course/Reflets/Mobylette
	reflet.visible = dans_l_eau
	reflet.position = Vector3(moto_x, -hauteur_moto(moto_z) - SOUS_L_EAU, moto_z)
	reflet.rotation = _moto_course.rotation * Vector3(1, 1, -1)
	if moto_z < FIN_COURSE and _une_fois("elle_tombe"):
		dire("Thomas", "Juliette !")
	_pluie_course.global_position = p + Vector3(0, 4.0, -6.0)
	_pluie_course.temps = _temps_reel
	var k := nuit(zr)
	_env_pluie.background_energy_multiplier = lerpf(1.0, 0.02, k)
	_env_pluie.ambient_light_energy = lerpf(0.35, 0.1, k)
	_env_pluie.fog_light_color = Color("6c757d").lerp(Color("05060d"), k)
	for t in _toiles_course:
		var d := zr - t.position.z
		t.position.y = hauteur_toile(d)
		# Thomas déchire la toile qu'il traverse : derrière, parfois, un vrai
		# mur.
		t.visible = not (d < 0.9 and absf(p.x - route.x - t.position.x) < 1.6)
		var mur := _vrais_murs[t] as GeometryInstance3D
		if mur != null:
			mur.layers = COUCHE_VRAI if t.visible else 1 | COUCHE_VRAI
	# Les yeux fermés, parmi les toiles, on ne voit que ce qui est vrai.
	var parmi_les_toiles := zr < DEBUT_TOILES
	var vrai := parmi_les_toiles and yeux_fermes()
	noir_des_yeux = 0.3 if parmi_les_toiles else 1.0
	_joueur.camera.cull_mask = COUCHE_VRAI if vrai else _masque_normal
	_env_pluie.background_mode = Environment.BG_COLOR if vrai else Environment.BG_SKY
	_env_pluie.fog_enabled = not vrai
	if not course_figee:
		# Le rêve se tord : la tête roule, le champ de vision respire.
		_joueur.head.rotation.z = ROULIS * sin(_temps_reel * 0.7) * (1.0 + clampf(-zr / 200.0, 0.0, 1.5))
		_joueur.camera.fov = 80.0 + 6.0 * sin(_temps_reel * 1.3)
	if zr < -150.0 and _une_fois("loin"):
		penser("Elle est juste là… Encore un peu.")


## Thomas tombe dans un trou, ou se cogne à un mur ou à une barrière.
func _a_echoue() -> bool:
	if _joueur.global_position.y < -1.2:
		return true
	for i in _joueur.get_slide_collision_count():
		var c := _joueur.get_slide_collision(i)
		var o := c.get_collider() as Node
		if o != null and o.is_in_group("obstacle_course") and c.get_normal().z > 0.6:
			return true
	return false


## Le temps de la course s'arrête : R le remonte.
func figer_la_course(echec: bool) -> void:
	course_figee = true
	_echec = echec
	_curseur = _passe.size() - 1
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	if echec and _une_fois("premier_echec"):
		penser("Non ! … Tout s'est arrêté.")
		penser("Je peux remonter le temps. Comme dans l'atelier.")
	var zr := _joueur.global_position.z - ($Course as Node3D).global_position.z
	if echec and zr < DEBUT_TOILES and _une_fois("vrai_mur"):
		penser("Derrière la toile… un vrai mur.")


## Les images de course remontées depuis l'arrêt.
func recul() -> float:
	return (_passe.size() - 1) - _curseur


func _remonter_la_course(delta: float) -> void:
	var r := Input.is_action_pressed("rembobiner")
	_rebours.color.a = move_toward(_rebours.color.a, 0.18 if r else 0.0, delta * 2.0)
	if r and not _passe.is_empty():
		_curseur = maxf(_curseur - VITESSE_REBOURS * delta * Engine.physics_ticks_per_second, 0.0)
		var e: Array = _passe[int(_curseur)]
		_joueur.global_position = e[0]
		moto_x = e[2]
		moto_z = e[3]
		_temps_reel = e[4]
		_le_monde_de_la_course(e[0], delta)
		return
	if _passe.is_empty() or (_echec and recul() < RECUL_MIN * Engine.physics_ticks_per_second):
		return
	# On repart d'ici : ce qui venait après n'a pas eu lieu.
	var i := int(_curseur)
	_joueur.velocity = _passe[i][1]
	_passe.resize(i + 1)
	_depuis_reprise = 0
	course_figee = false
	_rebours.color.a = 0.0
	_joueur.set_physics_process(true)


## Devant les premières toiles : les yeux fermés, on voit les vrais murs, et
## Thomas repart.
func _devant_les_toiles(delta: float) -> void:
	_arret_depuis += delta
	_yeux_fermes_depuis = _yeux_fermes_depuis + delta if yeux_fermes() else 0.0
	if _yeux_fermes_depuis > 0.6 or _arret_depuis > 25.0:
		arret_toiles = false
		_joueur.set_physics_process(true)
		if _yeux_fermes_depuis > 0.6:
			penser("Les vrais murs… et elle.")
	elif _arret_depuis > 12.0 and _une_fois("toiles_aide"):
		penser("Fermer les yeux… Juste une seconde.")


func _process(delta: float) -> void:
	super._process(delta)
	if course_figee:
		_action.text = "R (maintenu) : remonter le temps"
	elif arret_toiles:
		_action.text = "F (maintenu) : fermer les yeux"


func _sur_vide(corps: Node3D) -> void:
	if corps is Player and etat == Etat.COURSE:
		_joueur.respawn()


## Au bout de la route, le vide. Juliette tombe ; Thomas saute derrière elle.
func _sur_bord(corps: Node3D) -> void:
	if not corps is Player or etat != Etat.COURSE:
		return
	etat = Etat.CHUTE
	noir_des_yeux = 1.0
	_joueur.camera.cull_mask = _masque_normal
	_env_pluie.background_mode = Environment.BG_SKY
	_env_pluie.fog_enabled = true
	_joueur.avance_auto = false
	_joueur.facteur_vitesse = 1.0
	_joueur.head.rotation.z = 0.0
	_joueur.camera.fov = 80.0
	if _joueur.held != null:
		var c := _joueur.held
		_joueur.poser()
		c.visible = false
	_joueur.velocity = Vector3.ZERO
	_joueur.set_physics_process(false)
	var chute: Marker3D = $Vide/Chute
	_joueur.teleport(chute.global_transform)
	_joueur.head.rotation.x = -1.35
	ecart = ECART_CHUTE
	_temps_chute = 0.0
	penser("Elle tombe…")
	penser("Vite ! Espace, Espace !")


## Un appui sur Espace pendant la chute : Thomas tend le bras.
func appuyer() -> void:
	if etat != Etat.CHUTE or rattrapee:
		return
	ecart = maxf(ecart - RAPPROCHE, 0.0)


func _dans_la_chute(delta: float) -> void:
	_temps_chute += delta
	_temps_reel += delta
	if Input.is_action_just_pressed("sauter"):
		appuyer()
	if not rattrapee:
		ecart += ELOIGNE * delta
		if ecart <= ATTRAPEE:
			rattrapee = true
			penser("Je te tiens !")
			var t := create_tween()
			t.tween_interval(2.0)
			t.tween_callback(func() -> void:
				_lachee = true
				penser("Sa main glisse…"))
	if _lachee or (not rattrapee and _temps_chute > DUREE_CHUTE):
		ecart += 6.0 * delta
	var cam := _joueur.camera.global_position
	_juliette_chute.global_position = cam + Vector3(0, -ecart - 1.6, -0.6)
	_pluie_chute.global_position = cam
	_pluie_chute.temps = _temps_reel
	if ecart > 30.0 and _une_fois("disparue"):
		var t := create_tween()
		t.tween_property(_blanc, "color:a", 1.0, 1.5)
		t.tween_callback(verite)
		t.tween_property(_blanc, "color:a", 0.0, 2.0)


# --- La vérité ---------------------------------------------------------------


## L'atelier, après. Le temps ne se remonte plus.
func verite() -> void:
	etat = Etat.VERITE
	_dit.erase("pas_de_retour")
	for p in get_tree().get_nodes_in_group(Pensee.GROUPE):
		if is_ancestor_of(p):
			p.active = false
	moment = DUREE
	for o in _temporels:
		o.hors_du_temps = false
	_appliquer_le_moment()
	$Souvenir.visible = false
	_casque.visible = false
	$Atelier/Telephone.visible = true
	var ecran: Node3D = $Atelier/Telephone/Ecran
	var clignote := create_tween().set_loops()
	clignote.tween_property(ecran, "visible", false, 0.4)
	clignote.tween_property(ecran, "visible", true, 0.4)
	var verite_pos: Marker3D = $Atelier/Verite
	_joueur.teleport(verite_pos.global_transform)
	_joueur.set_anchor(verite_pos.global_transform)
	_joueur.head.rotation.x = 0.0
	_joueur.set_physics_process(true)
	penser("Elle est partie sans son casque. Je ne l'ai pas retenue.")
	penser("Mes derniers mots, c'étaient : va-t'en.")
	penser("Plus tard, le téléphone a sonné.")
	var t := create_tween()
	t.tween_interval(16.0)
	t.tween_callback(func() -> void:
		etat = Etat.FIN
		_tomber_dans_les_toiles(_joueur))


func _retour_dans_la_maison_des_etoiles() -> void:
	Histoire.chapitre = maxi(Histoire.chapitre, 5)
	Histoire.vers("res://scenes/illusions.tscn")
