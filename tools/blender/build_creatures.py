"""Build a batch of small creatures from their individual JSON specifications."""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from export_creature import pack
from lib_creatures import recipe


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("specs", nargs="+", type=Path)
    parser.add_argument("--no-render", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    for filename in args.specs:
        filename = filename.resolve(strict=True)
        spec = json.loads(filename.read_text(encoding="utf-8"))
        if filename.parent.name != spec["id"]:
            parser.error(f"{filename} does not match its creature ID")
        build, palette = recipe(spec)
        pack(spec["id"], spec["rarity"], build, palette, filename.parent / "model", 256,
             render=not args.no_render)


if __name__ == "__main__":
    main()
