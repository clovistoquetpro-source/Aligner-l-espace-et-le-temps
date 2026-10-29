# Aligner l'espace et le temps

Un jeu d'énigmes à la première personne pour PC. Tu traverses les époques de la Terre et tu réalignes l'espace et le temps pour retrouver ta vie paisible.

Fiche du jeu : `docs/superpowers/specs/`. Plan en cours : `docs/superpowers/plans/`.

## Jouer au prototype

1. Installe [Godot 4.6](https://godotengine.org/download/windows/) (version standard, pas .NET).
2. Récupère le dépôt avec [GitHub Desktop](https://desktop.github.com/) : **File → Clone repository**, puis `Aligner-l-espace-et-le-temps`. Ensuite, à chaque nouveauté, clique sur **Fetch origin**, puis sur **Pull origin** s'il apparaît.
   Pour essayer une nouveauté pas encore acceptée (une pull request), choisis sa branche dans le menu **Current branch** en haut (par exemple `prototype-maison`).
3. Dans Godot, clique sur **Importer**, choisis le fichier `project.godot` du dossier, puis **Importer et modifier**.
4. Appuie sur **F5** pour jouer. F5 ouvre le menu principal : **Nouvelle partie** lance la cinématique du début (Espace pour la passer), puis le niveau 1, en formes simples (voir plus bas). La partie est sauvegardée à chaque changement de niveau : **Continuer** reprend au début du dernier niveau commencé.

## Touches

| Action | AZERTY | QWERTY |
| --- | --- | --- |
| Avancer, reculer | Z, S | W, S |
| Aller à gauche, à droite | Q, D | A, D |
| Regarder | Souris | Souris |
| Sauter | Espace | Espace |
| Prendre ou poser un objet (vise loin pour l'agrandir, près pour le rétrécir), tourner une toile | E | E |
| Basculer d'époque | Tab ou clic droit | Tab ou clic droit |
| Fermer les yeux (en restant appuyé) | F | F |
| Remonter le temps (en restant appuyé, niveau 4, aussi pendant la course) | R | R |
| Pause (reprendre, sensibilité de la souris, plein écran, les touches, retour au menu, quitter) | Échap | Échap |

## Tests

`./run_tests.sh` (il faut la commande `godot` dans le PATH, ou la variable `GODOT`). Pour ne lancer qu'une partie des tests : `TESTS=dispute godot --headless --path . -s res://tests/run_tests.gd`.

## La cinématique du début

`scenes/intro.tscn`, en formes simples : la maison sur Terre, un peintre de dos qui repeint ses souvenirs, la maison qui s'arrache du sol jusque dans les étoiles, puis le titre. Elle est construite par `tools/constructeur_intro.gd` :
`godot --headless --path . -s res://tools/construire_intro.gd`.

## Le niveau 1 : la maison dans les étoiles

`scenes/illusions.tscn` est le niveau 1 de la nouvelle direction, en formes simples (fiche : `docs/superpowers/specs/2026-10-28-direction-illusions-design.md`). On se réveille, on veut sortir, et on passe par le couloir sans fin, le miroir de la salle de bain, la chute dans les toiles et la galerie. Il est construit par `tools/constructeur_illusions.gd` :
`godot --headless --path . -s res://tools/construire_illusions.gd`.
Tab n'y fait rien : il n'y a pas d'époques. E sert aussi à tourner certaines toiles, en visant leur cadre.

## Le niveau 2 : l'enfance

`scenes/enfance.tscn`, en formes simples : la cour de récré, l'anniversaire vide et le grenier. On y arrive par la toile de l'enfant, au salon, une fois le niveau 1 fini ; à la fin, on revient dans la maison des étoiles, abîmée. Il est construit par `tools/constructeur_enfance.gd` :
`godot --headless --path . -s res://tools/construire_enfance.gd`.
Pour l'essayer sans refaire le niveau 1, ouvre `scenes/enfance.tscn` dans Godot et appuie sur **F6**.

## Le niveau 3 : l'été au lac

`scenes/ete.tscn`, en formes simples : Thomas a 16 ans, Juliette lui donne rendez-vous sur l'île au coucher du soleil, et la journée recommence tant que ce n'est pas « parfait ». On y arrive par la toile du lac, au salon, au retour de l'enfance. Il est construit par `tools/constructeur_ete.gd` :
`godot --headless --path . -s res://tools/construire_ete.gd`.
Pour l'essayer directement, ouvre `scenes/ete.tscn` et appuie sur **F6**.

## Le niveau 4 : la pluie

`scenes/dispute.tscn`, en formes simples : d'abord le bonheur (l'atelier à deux au soleil, puis une balade à moto au bord de la mer), puis le soir de la dispute à l'atelier, qu'on remonte dans le temps (R maintenu), puis la course-poursuite derrière Juliette (on avance tout seul : Q et D pour aller à gauche et à droite, Espace pour sauter ; après une chute ou un choc, R remonte la course), avec la rue inondée (on ne voit plus la rue que dans l'eau) et les toiles du peintre (les yeux fermés, F, on voit les vrais murs), puis la chute (Espace, le plus vite possible). On y arrive par la toile de l'atelier, au salon, au retour de l'été. Il est construit par `tools/constructeur_dispute.gd` :
`godot --headless --path . -s res://tools/construire_dispute.gd`.
Pour l'essayer directement, ouvre `scenes/dispute.tscn` et appuie sur **F6**.

## Le niveau 5 : l'atelier du peintre, et dehors

`scenes/atelier.tscn`, en formes simples : on devient le peintre, on traverse le labyrinthe des mille toiles les yeux fermés, puis la salle du miroir (à reculons, les yeux sur le reflet) et la toile qui tourne (quatre portes, une seule vraie), on essaie de peindre, puis on pose le pinceau ; dehors, dans la nature en couleurs, la fin est une cinématique. On y arrive par la toile de la chambre, au retour de la pluie. Il est construit par `tools/constructeur_atelier.gd` :
`godot --headless --path . -s res://tools/construire_atelier.gd`.
Pour l'essayer directement, ouvre `scenes/atelier.tscn` et appuie sur **F6**.

## Le niveau « La maison »

`scenes/maison.tscn` est construit par le code de `tools/constructeur_maison.gd` :
`godot --headless --path . -s res://tools/construire_maison.gd`.
Si tu retouches la maison dans l'éditeur Godot, ne relance plus cette commande : elle écraserait tes retouches.

## Le niveau « L'Égypte »

`scenes/egypte.tscn` est construit par `tools/constructeur_egypte.gd` :
`godot --headless --path . -s res://tools/construire_egypte.gd`.
Pour essayer la maison, ouvre `scenes/maison.tscn` dans Godot et appuie sur **F6**.
Pour essayer l'Égypte sans passer par la maison, ouvre `scenes/egypte.tscn` dans Godot et appuie sur **F6** (lancer la scène courante).
Dans le jeu, on y arrive par le fond du jardin de la maison : passe le portail en regardant l'obélisque qui flotte derrière.

Le niveau tient en six énigmes : le mirage (au sud, l'arrivée), le spinosaure de la carrière (ouest), la rampe en pointillés (nord), la sentinelle du camp de 1942 (est), le temple qui boucle (sud-est) et la pyramide (au centre, vue de la tête du sphinx). Les quatre zones autour du chantier se font dans n'importe quel ordre, et chacune finit par un cartouche doré.

## Modèles 3D

Chaque monde a son propre pack de modèles, pour changer de style d'une époque à l'autre. Tous sont sous licence CC0 (libres, même pour un jeu vendu) :

| Dossier | Pack | Où |
| --- | --- | --- |
| `assets/modeles/maison` | Furniture Kit, de Kenney | https://kenney.nl/assets/furniture-kit |
| `assets/modeles/jardin` | Nature Kit, de Kenney (une sélection) | https://kenney.nl/assets/nature-kit |
| `assets/modeles/chateau` | Fantasy Props MegaKit (version gratuite), de Quaternius (une sélection) | https://quaternius.com/packs/fantasypropsmegakit.html |
| `assets/modeles/militaire` | Toon Shooter Game Kit, de Quaternius (une sélection) | https://quaternius.com |
| `assets/modeles/dinos` | Animated Dinosaur Pack, de Quaternius (le T-rex, transformé en spinosaure) | https://quaternius.com |

Les monuments de l'Égypte peuvent venir du Low Poly Egypt Pack de reodesuxz (gratuit, mais sa licence interdit de redistribuer ses fichiers). Tant que le dépôt est public, il n'est pas dans `assets/modeles/egypte` : le jeu construit à la place des formes simples de même taille (`tools/decor_egypte.gd`). Si le dépôt devient privé, copie ces fichiers du pack dans `assets/modeles/egypte/` : `obelisk.glb`, `sphinx.glb`, `temple_gate_pylon.glb`, `column_papyrus.glb`, `hieroglyph_slab.glb`, `pharaoh_statue.glb`, `palm_tree.glb`, `papyrus_reeds.glb` et `desert_rock.glb`. Relance ensuite la construction du niveau : chaque modèle présent remplace sa forme simple.

Au lancement, chaque modèle prend le style cartoon du jeu (ombres en aplats) grâce à `scripts/fx/habillage_cartoon.gd`. Le contour sombre façon BD est tracé sur tout l’écran par la caméra du joueur (`shaders/contour_ecran.gdshader`). Pour les objets de Quaternius, on ne garde que la texture de couleur, réduite (`tools/preparer_quaternius.py`).
