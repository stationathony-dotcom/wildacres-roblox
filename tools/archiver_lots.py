"""Déplace les lots et passages cochés de docs/LOTS.md vers docs/archives/LOTS-FAITS.md.

Garde LOTS.md court : seulement ce qui reste à faire. Relancer en fin de session :
python tools/archiver_lots.py
"""
from datetime import date
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LOTS = RACINE / "docs" / "LOTS.md"
ARCH = RACINE / "docs" / "archives" / "LOTS-FAITS.md"


def main():
    lignes = LOTS.read_text(encoding="utf-8").splitlines()
    garde, faits, section = [], [], ""
    i = 0
    while i < len(lignes):
        l = lignes[i]
        if l.startswith("#"):
            section = l
        if l.lstrip().startswith("- [x]"):
            bloc = [l]
            i += 1
            # lignes de suite : indentées plus que la puce
            retrait = len(l) - len(l.lstrip())
            while i < len(lignes) and lignes[i].strip() and (len(lignes[i]) - len(lignes[i].lstrip())) > retrait:
                bloc.append(lignes[i])
                i += 1
            faits.append((section, bloc))
            continue
        garde.append(l)
        i += 1
    if not faits:
        print("rien à archiver")
        return
    ARCH.parent.mkdir(exist_ok=True)
    ancien = ARCH.read_text(encoding="utf-8") if ARCH.exists() else "# Lots et passages faits (archive)\n\nNe pas lire sauf besoin précis : chercher par numéro de lot (grep).\n"
    ajout = [f"\n## Archivé le {date.today().isoformat()}\n"]
    derniere = None
    for section, bloc in faits:
        if section != derniere:
            ajout.append(f"\n### {section.lstrip('# ')}\n")
            derniere = section
        ajout.extend(bloc)
    ARCH.write_text(ancien.rstrip("\n") + "\n" + "\n".join(ajout) + "\n", encoding="utf-8")
    LOTS.write_text("\n".join(garde) + "\n", encoding="utf-8")
    print(f"{len(faits)} éléments archivés ; LOTS.md : {len(lignes)} -> {len(garde)} lignes")


if __name__ == "__main__":
    main()
