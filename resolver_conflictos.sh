#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   ./resolver_conflictos.sh <rama_pr>
# Ejemplo:
#   ./resolver_conflictos.sh codex/design-digital-system-for-voice-note-playback-qloguc

PR_BRANCH="${1:-}"
if [[ -z "$PR_BRANCH" ]]; then
  echo "Uso: $0 <rama_pr>"
  exit 1
fi

echo "[1/7] Traer cambios remotos"
git fetch origin

echo "[2/7] Ir a main y actualizar"
git checkout main
git pull origin main

echo "[3/7] Ir a rama del PR"
git checkout "$PR_BRANCH"
git pull origin "$PR_BRANCH" || true

echo "[4/7] Merge main -> rama PR"
set +e
git merge main
MERGE_CODE=$?
set -e

if [[ $MERGE_CODE -ne 0 ]]; then
  echo "[5/7] Hay conflictos. Abre y resuelve estos archivos:"
  echo "  - CIRCUITOS_LOGISIM.md"
  echo "  - README.md"
  echo "  - index.html"
  echo "  - main.py"
  echo
  echo "Luego ejecuta:"
  echo "  git add CIRCUITOS_LOGISIM.md README.md index.html main.py styles.css"
  echo "  git commit -m \"Resolve merge conflicts\""
else
  echo "[5/7] Merge sin conflictos, creando commit automático"
fi

echo "[6/7] Verificar que no queden marcadores"
rg -n "^(<<<<<<<|=======|>>>>>>>)" CIRCUITOS_LOGISIM.md README.md index.html main.py styles.css || true

echo "[7/7] Push"
git push origin "$PR_BRANCH"

echo "Listo. Regresa al PR y debería dejarte mergear."
