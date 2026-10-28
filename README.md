# Aligner l'espace et le temps

Un jeu d'énigmes à la première personne pour PC. Tu traverses les époques de la Terre et tu réalignes l'espace et le temps pour retrouver ta vie paisible.

Fiche du jeu : `docs/superpowers/specs/`. Plan en cours : `docs/superpowers/plans/`.

## Jouer au prototype

1. Installe [Godot 4.6](https://godotengine.org/download/windows/) (version standard, pas .NET).
2. Récupère le dépôt avec [GitHub Desktop](https://desktop.github.com/) : **File → Clone repository**, puis `Aligner-l-espace-et-le-temps`. Ensuite, à chaque nouveauté, clique sur **Fetch origin**, puis sur **Pull origin** s'il apparaît.
   Pour essayer une nouveauté pas encore acceptée (une pull request), choisis sa branche dans le menu **Current branch** en haut (par exemple `prototype-maison`).
3. Dans Godot, clique sur **Importer**, choisis le fichier `project.godot` du dossier, puis **Importer et modifier**.
4. Appuie sur **F5** pour jouer.

## Touches

| Action | AZERTY | QWERTY |
| --- | --- | --- |
| Avancer, reculer | Z, S | W, S |
| Aller à gauche, à droite | Q, D | A, D |
| Regarder | Souris | Souris |
| Sauter | Espace | Espace |
| Prendre ou poser un objet (vise loin pour l'agrandir, près pour le rétrécir) | E | E |
| Basculer d'époque | Tab ou clic droit | Tab ou clic droit |
| Libérer la souris | Échap | Échap |

## Tests

`./run_tests.sh` (il faut la commande `godot` dans le PATH, ou la variable `GODOT`).

## Le niveau « La maison »

`scenes/maison.tscn` est construit par le code de `tools/constructeur_maison.gd` :
`godot --headless --path . -s res://tools/construire_maison.gd`.
Si tu retouches la maison dans l'éditeur Godot, ne relance plus cette commande : elle écraserait tes retouches.

## Le niveau « L'Égypte »

`scenes/egypte.tscn` est construit par `tools/constructeur_egypte.gd` :
`godot --headless --path . -s res://tools/construire_egypte.gd`.
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
