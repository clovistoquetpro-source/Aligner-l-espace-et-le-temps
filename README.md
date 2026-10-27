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
| Prendre ou poser un objet | E | E |
| Basculer d'époque | Tab ou clic droit | Tab ou clic droit |
| Libérer la souris | Échap | Échap |

## Tests

`./run_tests.sh` (il faut la commande `godot` dans le PATH, ou la variable `GODOT`).

## Le niveau « La maison »

`scenes/maison.tscn` est construit par le code de `tools/constructeur_maison.gd` :
`godot --headless --path . -s res://tools/construire_maison.gd`.
Si tu retouches la maison dans l'éditeur Godot, ne relance plus cette commande : elle écraserait tes retouches.
