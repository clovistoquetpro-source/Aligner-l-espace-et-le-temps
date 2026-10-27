# Aligner l'espace et le temps : fiche et prototype

Fiche complète (document vivant, modifiée par clo) : https://claude.ai/artifact/Xx4FR2bPvWfGPt4Sn1TqnP
Ce fichier en garde les décisions utiles au code. Date : 2026-10-27.

## Le jeu

- Jeu d'énigmes à la première personne, **PC uniquement**.
- Visuel façon **Superliminal** : formes simples et propres, couleurs vives et saturées, touche barrée.
- Le héros, un humain ordinaire, traverse des époques de la Terre. Dans chacune, il réaligne l'espace et le temps et remet l'histoire dans l'ordre, pour retrouver sa vie paisible.
- Pas de combat ni de mort. Si on tombe ou qu'on se perd, on revient au dernier **point d'ancrage**.

## Mécaniques

1. **Le regard trompeur** : une porte mène ailleurs selon l'angle d'où on la regarde.
2. **La double époque** : on bascule le même lieu entre deux époques (présent et passé). Ce qui existe dans une époque peut ne pas exister dans l'autre.
3. **L'alignement** : des morceaux éparpillés forment une seule image quand on se place au bon point de vue. Ça résout l'énigme.
4. Perspective forcée (plus tard, pas dans le prototype).
5. Objets anachroniques à rapporter à leur époque (plus tard). Idées de clo : soldats de la Seconde Guerre mondiale et dinosaure en Égypte, soirée électro avec musique à l'envers au château, Romains dans le parc à Paris en 1889.

## Époques prévues

0 maison (tutoriel), 1 Égypte, 2 château médiéval, 3 Paris 1889, 4 ville flottante du futur, 5 retour à la maison.

## Prototype (ce qu'on construit maintenant)

Une seule zone : **l'époque 0, la maison**.

- Déplacement FPS : marcher, regarder à la souris, sauter, prendre et poser un objet. Clavier AZERTY et QWERTY.
- Un couloir qui boucle (porte trompeuse) tant qu'on ne le traverse pas en regardant la bonne photo.
- Une pièce qui bascule entre présent et passé (touche dédiée), avec un passage qui n'existe que dans le passé.
- Une énigme d'alignement qui ouvre la sortie.
- Un style coloré par époque et un effet visuel de bascule (déformation et aberration de couleur).
- Hors prototype : menus, histoire racontée, sauvegarde, sons.

## Technique

- Godot 4.6 (GDScript), renderer Forward+.
- Dépôt GitHub `clovistoquetpro-source/aligner-l-espace-et-le-temps`. Chaque étape arrive par une pull request que clo teste dans Godot.
