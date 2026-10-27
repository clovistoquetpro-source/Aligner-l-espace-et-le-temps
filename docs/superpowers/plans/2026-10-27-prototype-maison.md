# Prototype « La maison » : plan de développement

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** une zone jouable (la maison) qui prouve les 3 mécaniques : porte trompeuse, double époque, alignement.

**Architecture :** la logique de chaque mécanique vit dans une fonction pure, testée sans scène (`scripts/**/` en `static func`). Un nœud fin l'attache à la scène. Un autoload `Temps` porte l'époque courante. Le niveau `scenes/maison.tscn` assemble le tout en CSG coloré.

**Tech Stack :** Godot 4.6 (GDScript, Forward+). Tests : petit lanceur maison, `godot --headless --path . -s res://tests/run_tests.gd`.

**Spec :** `docs/superpowers/specs/2026-10-27-prototype-maison-design.md`

## Global Constraints

- Godot 4.6, GDScript typé (`var x: float`), indentation par tabulations.
- PC uniquement. Contrôles en `physical_keycode` : Z/Q/S/D sur AZERTY = W/A/S/D sur QWERTY.
- Contrôles : déplacement ZQSD, souris pour regarder, Espace pour sauter, E pour prendre ou poser, Tab ou clic droit pour basculer d'époque, Échap pour libérer la souris.
- Époques du prototype : `0 = PRESENT`, `1 = PASSE`.
- Pas de mort : sous `y < -20`, retour au dernier point d'ancrage.
- Textes visibles par le joueur en français.
- Le lanceur de tests sort avec le code 1 si un test échoue.

## Review Focus

1. **Bascule d'époque quand le joueur se tient là où un mur apparaît** : la bascule est refusée (petit effet « bloqué »), le joueur n'est jamais coincé. Test dans la tâche 3.
2. **Chute hors du niveau** (traverser un trou du passé puis rebasculer) : retour au point d'ancrage. Test dans la tâche 2.
3. **Traverser la porte trompeuse en portant un objet** : l'objet suit le joueur. Test dans la tâche 4.
4. **Alignement vu à travers un mur ou de dos** : il ne compte pas. Test dans la tâche 5.
5. **Clavier AZERTY** : ZQSD fonctionne sans réglage. Test dans la tâche 1.

---

### Task 1 : Projet Godot, contrôles et lanceur de tests

**Files :**
- Create : `project.godot`, `.gitignore`, `.gitattributes`, `icon.svg`, `README.md`
- Create : `tests/run_tests.gd`, `tests/test_input_map.gd`

**Interfaces :**
- Produces : actions `avancer`, `reculer`, `gauche`, `droite`, `sauter`, `interagir`, `basculer`, `liberer_souris`. Le lanceur exécute chaque `tests/test_*.gd` (classe `extends RefCounted`) et chaque méthode `test_*`. Les assertions passent par `T.eq(a, b, msg)` et `T.ok(cond, msg)` (`tests/t.gd`).

- [ ] Écrire `tests/test_input_map.gd` : `test_avancer_est_touche_physique_w()` vérifie qu'un `InputEventKey` de `physical_keycode == KEY_W` est dans `InputMap.action_get_events("avancer")`. Même chose pour `gauche` → `KEY_A`, et pour `basculer` → `KEY_TAB` et `MOUSE_BUTTON_RIGHT`.
- [ ] Lancer les tests : ils échouent (actions absentes).
- [ ] Écrire `project.godot` (nom « Aligner l'espace et le temps », scène principale `res://scenes/maison.tscn`, input map ci-dessus ; l'autoload `Temps` sera ajouté à la tâche 3), le lanceur et `.gitignore` (`.godot/`).
- [ ] Lancer les tests : ils passent.
- [ ] `README.md` en français : installer Godot 4.6 et GitHub Desktop, cloner, ouvrir, appuyer sur F5, liste des touches.
- [ ] Commit `chore: projet Godot, contrôles et tests`.

### Task 2 : Joueur à la première personne

**Files :**
- Create : `scripts/player/player.gd`, `scenes/player.tscn`, `tests/test_player.gd`

**Interfaces :**
- Produces : `class_name Player extends CharacterBody3D` avec `static func wish_direction(input: Vector2, yaw: float) -> Vector3`, `var anchor: Transform3D`, `func set_anchor(t: Transform3D) -> void`, `func respawn() -> void`, `var held: RigidBody3D` (objet porté, `null` si rien), `func teleport(t: Transform3D) -> void` (garde `held` à la même position relative). Constantes : `SPEED = 5.0`, `JUMP = 4.5`, `MOUSE_SENS = 0.0025`, `KILL_Y = -20.0`.
- La caméra est `$Head/Camera3D`.

- [ ] Tests : `wish_direction(Vector2(0, -1), 0.0)` vaut `Vector3(0, 0, -1)` ; avec `yaw = PI / 2` vaut `Vector3(-1, 0, 0)` (à 0.001 près). `test_respawn_sous_kill_y` : un joueur instancié à `y = -25` revient à `anchor.origin` après un `_physics_process(0.016)`. `test_teleport_garde_objet_porte` : objet porté à 1,5 m devant, après `teleport`, toujours à 1,5 m devant.
- [ ] Lancer : échec.
- [ ] Implémenter (prise et pose avec E par raycast de 2,5 m ; l'objet porté suit un point à 1,5 m devant la caméra).
- [ ] Lancer : succès.
- [ ] Commit `feat: joueur FPS`.

### Task 3 : Double époque

**Files :**
- Modify : `project.godot` (ajouter l'autoload `Temps`)
- Create : `scripts/time/temps.gd` (autoload), `scripts/time/epoch_member.gd`, `tests/test_temps.gd`

**Interfaces :**
- Produces : autoload `Temps` avec `enum Epoque { PRESENT, PASSE }`, `var courante: int`, `signal epoque_changee(nouvelle: int)`, `signal bascule_refusee`, `func basculer(joueur: Node3D) -> bool`.
- `class_name EpochMember extends Node` : enfant d'un `CSGShape3D` ou d'un `CollisionObject3D`. `@export var epoque: int`. Son parent est visible et solide seulement dans son époque.
- `static func bascule_possible(joueur_aabb: AABB, solides_futurs: Array[AABB]) -> bool`.

- [ ] Tests : `basculer` fait passer de `PRESENT` à `PASSE` et émet `epoque_changee(1)`. Un `EpochMember(epoque = PASSE)` cache son parent et coupe sa collision au présent. `bascule_possible` renvoie `false` si l'AABB du joueur croise un solide de l'autre époque, et dans ce cas `basculer` émet `bascule_refusee` sans changer d'époque (Review Focus 1).
- [ ] Lancer : échec.
- [ ] Implémenter.
- [ ] Lancer : succès.
- [ ] Commit `feat: bascule entre présent et passé`.

### Task 4 : Porte trompeuse

**Files :**
- Create : `scripts/portal/porte_trompeuse.gd`, `scenes/porte_trompeuse.tscn`, `tests/test_porte.gd`

**Interfaces :**
- Consumes : `Player.teleport`.
- Produces : `class_name PorteTrompeuse extends Area3D` avec `@export var destinations: Array[NodePath]` (des `Marker3D`), `@export var cible_regard: NodePath` (le `Node3D` à regarder, la photo), `@export var angle_max_deg := 15.0`, `@export var index_si_regard := 1`, `@export var index_sinon := 0`.
- `static func choisir(dir_regard: Vector3, vers_cible: Vector3, angle_max_deg: float, si_regard: int, sinon: int) -> int`.
- `static func transfert(entree: Transform3D, sortie: Transform3D, joueur: Transform3D) -> Transform3D` : garde la position et l'orientation du joueur relatives à la porte.

- [ ] Tests : `choisir` renvoie `si_regard` à 10° de la cible et `sinon` à 20°. `transfert` d'un joueur à 1 m devant l'entrée donne 1 m devant la sortie, même orientation relative. Le test de la tâche 2 couvre déjà l'objet porté (Review Focus 3) ; on ajoute un test qui le vérifie à travers la porte.
- [ ] Lancer : échec.
- [ ] Implémenter (à l'entrée du joueur dans l'aire : choisir puis `teleport`).
- [ ] Lancer : succès.
- [ ] Commit `feat: porte trompeuse`.

### Task 5 : Énigme d'alignement

**Files :**
- Create : `scripts/puzzle/alignement.gd`, `tests/test_alignement.gd`

**Interfaces :**
- Produces : `class_name Alignement extends Node3D` avec `@export var point_de_vue: NodePath` (`Marker3D`), `@export var distance_max := 0.6`, `@export var angle_max_deg := 6.0`, `signal resolu`, `var est_resolu: bool`.
- `static func aligne(cam_pos: Vector3, cam_dir: Vector3, vue_pos: Vector3, vue_dir: Vector3, dist_max: float, angle_max_deg: float) -> bool`.
- Vérifie aussi par raycast que rien ne bloque entre la caméra et le centre des morceaux.

- [ ] Tests : `aligne` est vrai à 0,3 m et 3°, faux à 1 m, faux à 10°, faux de dos (Review Focus 4). Le nœud émet `resolu` une seule fois.
- [ ] Lancer : échec.
- [ ] Implémenter.
- [ ] Lancer : succès.
- [ ] Commit `feat: énigme d'alignement`.

### Task 6 : Effet visuel de bascule et couleurs

**Files :**
- Create : `shaders/bascule.gdshader`, `scripts/fx/bascule_fx.gd`, `scenes/bascule_fx.tscn`, `tests/test_fx.gd`

**Interfaces :**
- Consumes : `Temps.epoque_changee`, `Temps.bascule_refusee`.
- Produces : `CanvasLayer` plein écran. Paramètre shader `intensite` (0 à 1) animé en 0,5 s : ondulation de l'écran et décalage rouge et bleu. Pour une bascule refusée : petite secousse de 0,15 s. `WorldEnvironment` : teinte par époque (présent rose et turquoise, passé ambre et violet).

- [ ] Test : la scène se charge en headless sans erreur, et `intensite` vaut 0 au repos et plus de 0 juste après `epoque_changee`.
- [ ] Lancer : échec, puis implémenter, puis succès.
- [ ] Commit `feat: effet de bascule`.

### Task 7 : Niveau « La maison »

**Files :**
- Create : `scenes/maison.tscn`, `tests/test_maison.gd`

**Interfaces :**
- Consumes : tout ce qui précède.
- Parcours : entrée → couloir qui boucle (porte trompeuse, on en sort en regardant la photo) → salon qui bascule (le passage vers la suite n'existe que dans le passé) → atelier avec l'alignement, qui ouvre la porte de sortie → message « Époque réparée ! ». Un point d'ancrage par pièce (`Area3D` qui appelle `set_anchor`).

- [ ] Test de fumée : charger la scène, simuler 300 frames, aucune erreur dans le journal. Vérifier qu'il y a 1 `Player`, au moins 1 `PorteTrompeuse`, 1 `Alignement` et au moins 1 `EpochMember` de chaque époque.
- [ ] Lancer : échec, puis construire la scène, puis succès.
- [ ] Commit `feat: niveau la maison`.
- [ ] Ouvrir la pull request et demander à clo de jouer.
