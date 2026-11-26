"""Génère docs/CARTE.md : index du code et des docs, pour ne lire que ce qu'il faut.

Relancer après un ajout ou un déplacement de fonctions : python tools/carte.py
"""
import re
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
GROS = 30_000  # octets : au-delà, on liste les fonctions avec leur ligne
FONC = re.compile(r"^(?:local\s+)?function\s+([\w.:]+)|^(?:local\s+)?([\w.]+)\s*=\s*function")
SECTION = re.compile(r"^--\s*(?:=+|#+|─+)\s*(.+?)\s*(?:=+|─+)?\s*$")


def but(lignes):
    """Premières lignes de commentaire du fichier = son rôle."""
    out = []
    for l in lignes[:15]:
        s = l.strip()
        if s.startswith("--!"):
            continue
        if s.startswith("--"):
            t = s.lstrip("-").strip()
            if t:
                out.append(t)
            if len(" ".join(out)) > 90:
                break
        elif s and out:
            break
    t = " ".join(out)
    return t if len(t) <= 90 else t[:88].rsplit(" ", 1)[0] + "…"


def main():
    sortie = [
        "# Carte du code et des docs",
        "",
        "Fichier généré par `python tools/carte.py`. Ne pas éditer à la main.",
        "Usage : chercher ici le fichier et la ligne, puis lire **seulement cette plage**",
        "(`sed -n 'A,Bp'` ou Read avec offset/limit). Ne jamais lire un gros fichier en entier.",
        "",
        "## Code (`src/`)",
        "",
    ]
    for f in sorted((RACINE / "src").rglob("*.lua")):
        texte = f.read_text(encoding="utf-8", errors="replace")
        lignes = texte.splitlines()
        rel = f.relative_to(RACINE).as_posix()
        taille = len(texte.encode("utf-8"))
        sortie.append(f"- `{rel}` ({len(lignes)} l.) {but(lignes)}")
        if taille >= GROS:
            items = []
            for i, l in enumerate(lignes, 1):
                m = FONC.match(l)
                if m:
                    items.append(f"{m.group(1) or m.group(2)}:{i}")
                else:
                    s = SECTION.match(l)
                    if s:
                        items.append(f"§{s.group(1)}:{i}")
            if items:
                nom = rel.replace("src/", "").replace("/", "_").replace(".lua", ".md")
                det = RACINE / "docs" / "carte" / nom
                det.parent.mkdir(exist_ok=True)
                corps = "\n".join(f"- {x}" for x in items)
                det.write_text(f"# {rel} — fonctions et lignes\n\n{corps}\n", encoding="utf-8")
                sortie.append(f"  - fonctions : `docs/carte/{nom}`")
    sortie += ["", "## Docs (`docs/`, hors archives)", ""]
    for f in sorted((RACINE / "docs").glob("*.md")):
        if f.name == "CARTE.md":
            continue
        lignes = f.read_text(encoding="utf-8", errors="replace").splitlines()
        titre = next((l.lstrip("# ").strip() for l in lignes if l.startswith("#")), "")
        titres = [f"{l.lstrip('# ').strip()[:50]}:{i}" for i, l in enumerate(lignes, 1) if l.startswith("## ")]
        sortie.append(f"- `docs/{f.name}` ({f.stat().st_size // 1024} Ko) — {titre}")
        if f.stat().st_size >= GROS and titres:
            sortie.append("  - sections : " + " · ".join(titres[:25]))
    (RACINE / "docs" / "CARTE.md").write_text("\n".join(sortie) + "\n", encoding="utf-8")
    print("docs/CARTE.md :", len(sortie), "lignes")


if __name__ == "__main__":
    main()
