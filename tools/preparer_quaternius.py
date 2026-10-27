"""Copie des modèles glTF de Quaternius dans le projet, en version légère.

Le pack « Fantasy Props MegaKit » (CC0) partage 4 grandes textures (2048 px)
entre tous ses modèles, chacune en trois versions (couleur, relief, ORM).
On ne garde que la couleur, réduite à 1024 px : le rendu cartoon n'a pas
besoin du reste.

Usage :
    python3 -I tools/preparer_quaternius.py <Exports/glTF> <Textures> <destination> Nom1 Nom2 ...
"""

import json
import shutil
import sys
from pathlib import Path

from PIL import Image

TAILLE_TEXTURE = 1024


def preparer(source: Path, textures: Path, dest: Path, nom: str) -> set[str]:
    d = json.loads((source / f"{nom}.gltf").read_text())
    for m in d.get("materials", []):
        m.pop("normalTexture", None)
        m.pop("occlusionTexture", None)
        m.get("pbrMetallicRoughness", {}).pop("metallicRoughnessTexture", None)
    # Ne garder que les textures encore utilisées, et les renuméroter.
    utilisees = sorted({
        m["pbrMetallicRoughness"]["baseColorTexture"]["index"]
        for m in d.get("materials", [])
        if "baseColorTexture" in m.get("pbrMetallicRoughness", {})
    })
    nouvel_index = {ancien: i for i, ancien in enumerate(utilisees)}
    textures_gardees = [d["textures"][i] for i in utilisees]
    images_gardees = []
    for t in textures_gardees:
        images_gardees.append(d["images"][t["source"]])
        t["source"] = len(images_gardees) - 1
    for m in d.get("materials", []):
        pbr = m.get("pbrMetallicRoughness", {})
        if "baseColorTexture" in pbr:
            pbr["baseColorTexture"]["index"] = nouvel_index[pbr["baseColorTexture"]["index"]]
    if textures_gardees:
        d["textures"] = textures_gardees
        d["images"] = images_gardees
    else:
        d.pop("textures", None)
        d.pop("images", None)
    for b in d.get("buffers", []):
        shutil.copy(source / b["uri"], dest / b["uri"])
    (dest / f"{nom}.gltf").write_text(json.dumps(d, indent=1))
    return {img["uri"] for img in images_gardees}


def main() -> None:
    source, textures, dest = (Path(a) for a in sys.argv[1:4])
    dest.mkdir(parents=True, exist_ok=True)
    images: set[str] = set()
    for nom in sys.argv[4:]:
        images |= preparer(source, textures, dest, nom)
    for uri in sorted(images):
        img = Image.open(textures / uri)
        img.thumbnail((TAILLE_TEXTURE, TAILLE_TEXTURE))
        img.save(dest / uri, optimize=True)
    print(f"{len(sys.argv) - 4} modèles, textures : {sorted(images)}")


if __name__ == "__main__":
    main()
