#!/usr/bin/env bash
# File de lots Codex Sol (effort high) : enchaîne les prompts de docs/codex-lots/*.md dans l'ordre.
# Si Codex répond « usage limit ... try again at H:MM AM/PM », attend jusqu'à cette heure (+2 min) et relance le même lot.
S="$(cd "$(dirname "$0")/../.." && pwd)"   # racine du dépôt
REPO="$(cygpath -w "$S" 2>/dev/null || echo "$S")"
JOURNAL="$S/tools/codex/journal.txt"
cd "$S" || exit 1
# relit le dossier à chaque tour : un lot ajouté pendant que la file tourne est pris aussi
while :; do
	p=""
	for q in "$S"/docs/codex-lots/*.md; do
		[ "$(basename "$q")" = "journal.txt" ] && continue
		[ -f "$S/tools/codex/$(basename "$q" .md).fait" ] && continue
		p="$q"; break
	done
	[ -z "$p" ] && break
	nom=$(basename "$p" .md)
	essai=0
	while :; do
		essai=$((essai + 1))
		echo "$(date '+%F %T') début $nom (essai $essai)" >> "$JOURNAL"
		codex exec -m gpt-6.2-sol -c model_reasoning_effort='"high"' -s workspace-write -C "$REPO" - < "$p" > "$S/tools/codex/$nom.log" 2>&1
		code=$?
		jetons=$(grep -A1 "tokens used" "$S/tools/codex/$nom.log" | tail -1)
		if grep -q "usage limit" "$S/tools/codex/$nom.log"; then
			heure=$(grep -o "try again at [0-9:]* *[AP]M" "$S/tools/codex/$nom.log" | tail -1 | sed 's/try again at //')
			cible=$(date -d "$heure" +%s 2>/dev/null)
			maint=$(date +%s)
			[ -z "$cible" ] && cible=$((maint + 3600))
			[ "$cible" -le "$maint" ] && cible=$((cible + 86400))
			echo "$(date '+%F %T') limite d'usage sur $nom (jetons: $jetons) → reprise à $heure" >> "$JOURNAL"
			sleep $((cible - maint + 120))
			continue
		fi
		echo "$(date '+%F %T') fin $nom code=$code jetons=$jetons" >> "$JOURNAL"
		touch "$S/tools/codex/$nom.fait"
		break
	done
done
echo "$(date '+%F %T') FILE TERMINÉE" >> "$JOURNAL"
