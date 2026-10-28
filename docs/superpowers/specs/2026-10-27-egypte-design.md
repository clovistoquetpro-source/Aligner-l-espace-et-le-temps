# Époque 1 : l'Égypte, design du prototype

Date : 2026-10-27. Décisions prises avec clo dans le fil « Créer le prototype de l'Égypte ».
Fiche du jeu : https://claude.ai/artifact/Xx4FR2bPvWfGPt4Sn1TqnP. Prototype précédent : `2026-10-27-prototype-maison-design.md`.

## Ce qu'on veut

Un niveau complet et jouable de bout en bout, qui fait suite à la maison : un chantier de pyramide dans l'Égypte ancienne, en orange et turquoise, avec 6 énigmes. Le joueur doit y retrouver les 4 mécaniques apprises dans la maison, en plus difficile.

Réussi si :
- on passe de la maison à l'Égypte sans quitter le jeu ;
- les 6 énigmes se résolvent sans aide extérieure (indices dans le décor) ;
- on finit le niveau en 15 à 25 minutes ;
- le style est clairement différent de la maison (autre pack, autre palette), avec le même contour BD.

Hors prototype : menus, sauvegarde, sons, histoire racontée, niveau du château.

## Ce qui cloche en Égypte

- Les blocs de la pyramide flottent dans le désordre au-dessus du chantier.
- Des soldats de 1942 (bataille d'El Alamein) sont arrivés dans l'Antiquité, et l'inverse.
- Un spinosaure (dinosaure qui vivait vraiment en Égypte) dort dans la carrière.

Les soldats et le dinosaure sont **au cœur des énigmes** : chacun bloque quelque chose.

## Les deux époques

Tab bascule entre **l'Antiquité** (époque « passé » du code) et **1942** (époque « présent »). On garde l'autoload `Temps` à deux états.

- Antiquité : pyramide en chantier, rampes de construction, couleurs saturées.
- 1942 : pyramide finie et ensablée, camp militaire, couleurs un peu passées.
- Le spinosaure est présent dans les deux époques (on ne peut pas le contourner en basculant).
- On arrive en Égypte dans l'Antiquité. `Temps.reinitialiser` prend l'époque de départ en paramètre (la maison garde le présent).
- Règle générale : aucune énigme ne doit pouvoir se contourner en basculant. Ce qui bloque un passage le bloque dans les deux époques, sous deux formes différentes.

## Plan du niveau : un chantier central

```
                 N  La rampe (3)
                       |
 La carrière (2) -- CHANTIER -- Le camp de 1942 (4)
                    (6, pyramide)
                       |      \
                 Sphinx (vue)  Le temple (5)
                       |
                 S  Le mirage (1), arrivée
```

- Au centre, la base de la pyramide et le **nuage de blocs** qui flottent au-dessus.
- Quatre zones autour, faisables dans n'importe quel ordre. Chacune finit par un **cartouche doré** : quand on le touche, la zone est réussie et son groupe de blocs s'envole rejoindre le nuage.
- Le point de vue final est sur la tête du sphinx, au sud du chantier.

## Les 6 énigmes

1. **Le mirage** (arrivée, porte trompeuse). On arrive près d'un obélisque. Le chemin de dunes vers le chantier boucle et ramène au départ, sauf si on le traverse en regardant le bout de l'ombre de l'obélisque. L'ombre est peinte au sol, dans l'axe du soleil, et son bout est un peu décalé du chemin : il faut tourner la tête.
2. **Le spinosaure** (carrière, perspective forcée). Le spinosaure dort en travers de l'entrée de la carrière. Au bord du Nil (eau et papyrus), on trouve un petit poisson qu'on peut prendre. Le dinosaure ne se réveille que pour un très gros poisson. Si on pose le poisson agrandi (taille ≥ 1,5 m) sur la grande pierre plate devant lui, il se lève, va le manger un peu plus loin et libère l'entrée. Un petit poisson le fait juste renifler (« Trop petit… »).
3. **La rampe en pointillés** (nord, bascule). Une rampe monte vers une terrasse à 8 m. En Antiquité, il manque des tronçons de rampe (les blocs flottent). En 1942, la rampe est entière, mais les soldats ont posé des tranchées en sacs de sable qui la barrent. On monte en basculant au bon endroit : on traverse les trous en 1942 et on passe les sacs de sable en Antiquité. Les trous sont trop longs pour être sautés (plus de 5 m) et les sacs trop hauts (plus de 1,2 m). La règle actuelle de la bascule s'applique : elle est refusée si un mur apparaîtrait sur le joueur.
4. **La sentinelle** (est, alignement). Le camp de 1942 est installé dans une ancienne enceinte en briques, présente dans les deux époques. Sa seule entrée est gardée par un soldat qui fait « non » de la tête et demande le mot de passe. En Antiquité, cette entrée est fermée par une lourde porte en bois : on ne peut pas entrer par là non plus. Le mot de passe est un hiéroglyphe (l'ânkh ☥) peint en morceaux sur des caisses éparpillées dans le camp. Il n'apparaît entier que depuis le haut du mirador, à l'extérieur de l'enceinte. Une fois aligné, la sentinelle fait « oui » et s'écarte, et la porte antique s'ouvre aussi. Les tentes, les caisses et les soldats n'existent qu'en 1942 ; le cartouche, au fond de l'enceinte, est là dans les deux époques.
5. **Le temple qui boucle** (sud-est, porte trompeuse et bascule). La salle des colonnes du temple ramène au début, sauf si on passe en regardant le bon hiéroglyphe parmi les dalles des murs. Le seul indice est une carte des soldats punaisée sur une colonne, où la bonne dalle (le scarabée) est entourée en rouge. Cette carte n'existe qu'en 1942, mais les dalles sont là dans les deux époques.
6. **La pyramide** (centre, alignement final). Le nuage n'est complet que quand les 4 groupes de blocs sont revenus. Depuis la tête du sphinx, les blocs s'alignent alors en une pyramide à degrés. La réalité se recolle : les blocs se posent pour de vrai, la pyramide devient solide et une porte s'ouvre à sa base. Si on la franchit, le prototype se termine (« Bientôt : le château… »).

Tant que le nuage est incomplet, l'alignement final ne se déclenche pas. Un message l'explique (« Il manque encore des blocs… »).

## Passage depuis la maison

À la fin de la maison, le jardin mène à l'Égypte : on traverse le portail du fond du jardin en regardant l'obélisque, et on charge la scène de l'Égypte. Un message remplace « Fin du prototype ». La scène principale reste la maison. Pour tester l'Égypte seule, on ouvre `scenes/egypte.tscn` dans Godot et on lance la scène courante (F6).

## Technique

Même organisation que la maison :
- `scenes/egypte.tscn` est généré par `tools/constructeur_egypte.gd` (`godot --headless --path . -s res://tools/construire_egypte.gd`). Les fonctions communes aux deux constructeurs (`_boite`, `_texte`, `_groupe`, `_ajouter`, `_mat`, `_ancrage`…) passent dans une classe de base `tools/constructeur.gd`.
- `scripts/niveau/egypte.gd` relie les énigmes, le chantier, les messages et la fin.

Nouveaux morceaux, chacun avec ses tests :
- **`Chantier`** (`scripts/puzzle/chantier.gd`) : retient les zones réussies, fait voler chaque groupe de blocs vers le nuage, et n'active l'alignement final qu'avec les 4 groupes. Signal `complet`.
- **`Cartouche`** (`scripts/puzzle/cartouche.gd`) : une zone qu'on touche une seule fois. Signal `touche`.
- **`Spinosaure`** (`scripts/egypte/spinosaure.gd`) : il dort ; il surveille une zone d'appât ; quand un objet perspectif non porté y est posé avec une taille suffisante, il marche vers lui, le mange et se recouche plus loin. Son corps solide se déplace avec lui.
- **`Sentinelle`** (`scripts/egypte/sentinelle.gd`) : elle bloque l'entrée, fait « non » quand le joueur approche, puis « oui » et s'écarte quand son alignement est résolu.
- **`PassageTemporel`** (`scripts/portal/passage_temporel.gd`) : une zone qui charge une autre scène si on la traverse en regardant une cible. Le choix du regard réutilise `PorteTrompeuse.choisir`.
- **Le poisson** : une scène `poisson.tscn` qui réutilise `ObjetPerspectif`. Petit changement : le nœud `Mesh` de l'objet peut être n'importe quel `Node3D` (le poisson est fait de formes simples).
- **`BasculeFx`** : les palettes du ciel et de l'ambiance par époque deviennent un réglage du niveau (aujourd'hui elles sont écrites pour la maison).
- Les tests du rendu de la maison (pas de murs qui se chevauchent, plinthes, contour) servent aussi pour l'Égypte.

L'alignement réutilise `Alignement` tel quel (morceaux placés sur les rayons depuis le point de vue, comme l'horloge). La porte trompeuse réutilise `PorteTrompeuse` tel quel.

## Modèles et style

Chaque monde a son pack. Ceux de l'Égypte, fournis par clo :
- **Low Poly Egypt Pack** (reodesuxz) : pyramide, sphinx, obélisque, pylône, colonnes, statues, dalles de hiéroglyphes, palmiers, papyrus, dunes, barque. En GLB, à l'échelle réelle, sans texture. Licence : gratuit, sans attribution, mais **interdiction de redistribuer les fichiers**. On l'utilise seulement si le dépôt GitHub passe en privé (question posée à clo). Sinon, on construit ces formes en CSG.
- **Toon Shooter Game Kit** (Quaternius, CC0) : `Character_Soldier` (animations Idle, Walk, Yes, No, Wave), tranchées en sacs de sable, caisses, barrières, panneaux, château d'eau qui sert de mirador. Recolorés en kaki et sable.
- **Animated Dinosaur Pack** (Quaternius, CC0) : le T-rex, auquel on ajoute une voile dorsale pour en faire un spinosaure.
- **Tank Pack** (Quaternius, CC0) : un tank à moitié ensablé dans le camp de 1942.

Style : on garde le rendu cartoon (`Style`, `HabillageCartoon`) et le contour à l'écran. Palette orange et turquoise : sable orangé, pierre ocre, ciel turquoise, or des cartouches. 1942 est un peu plus terne. Soleil de désert bas, pour de longues ombres.

## Tests

- Tests unitaires de `Chantier`, `Cartouche`, `Spinosaure`, `Sentinelle`, `PassageTemporel` et du poisson.
- Tests du niveau : la scène se charge, les 4 cartouches et l'alignement final existent, aucune boîte de structure ne se chevauche, la rampe a bien des trous en Antiquité et des sacs de sable en 1942, le spinosaure bloque l'entrée de la carrière au départ.
- `./run_tests.sh` lance aussi la scène de l'Égypte 300 images sans erreur.
- Captures d'écran de chaque zone, dans les deux époques, pour régler les couleurs.
