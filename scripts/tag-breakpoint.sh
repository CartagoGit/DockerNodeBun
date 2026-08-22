#!/usr/bin/env bash
# tag-breakpoint.sh — crea un tag breakpoint_v{X.Y.Z} que apunta al mismo
# commit que v{X.Y.Z}. Un "breakpoint" es un marcador estructural del
# repo: indica que ese commit representa una rotura de como funciona
# el repo (refactor mayor, cambio de contrato, nueva arquitectura),
# NO un bump de VERSION rutinario.
#
# Uso:
#   scripts/tag-breakpoint.sh 1.0.1 [mensaje]
#
#   1.0.1         — VERSION obligatoria (sin la v inicial).
#   [mensaje]     — mensaje del tag (opcional). Si no se pasa, se
#                   genera uno neutro: "Breakpoint at v1.0.1".
#
# El script:
#   1. Verifica que existe el tag v{X.Y.Z} localmente.
#   2. Verifica que NO existe ya el tag breakpoint_v{X.Y.Z}.
#   3. Crea el tag breakpoint_v{X.Y.Z} apuntando al mismo commit
#      que v{X.Y.Z}.
#   4. NO pushea automaticamente — eso lo decides tu.
#
# Para pushear ambos tags al remoto:
#   git push origin v1.0.1 breakpoint_v1.0.1

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <X.Y.Z> [message]" >&2
  echo "Example: $0 1.0.1 'New publishing model: tag trigger + manifesto'" >&2
  exit 1
fi

VERSION="$1"
MESSAGE="${2:-Breakpoint at v${VERSION}}"

# Sanity: VERSION debe matchear X.Y.Z estricto
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: VERSION '$VERSION' must match X.Y.Z (e.g. 1.0.1)" >&2
  exit 1
fi

SOURCE_TAG="v${VERSION}"
BP_TAG="breakpoint_v${VERSION}"

# Verificar que el tag source existe
if ! git rev-parse --verify --quiet "refs/tags/${SOURCE_TAG}" >/dev/null; then
  echo "Error: tag '${SOURCE_TAG}' does not exist locally." >&2
  echo "       Create it first:  git tag -a ${SOURCE_TAG} -m '...'" >&2
  exit 1
fi

# Verificar que el breakpoint tag no existe ya
if git rev-parse --verify --quiet "refs/tags/${BP_TAG}" >/dev/null; then
  echo "Error: tag '${BP_TAG}' already exists." >&2
  echo "       To re-point it, delete first:  git tag -d ${BP_TAG}" >&2
  exit 1
fi

# Crear el breakpoint tag en el mismo commit que el source tag
SOURCE_COMMIT=$(git rev-parse "${SOURCE_TAG}^{commit}")
echo "Source tag:  ${SOURCE_TAG} -> ${SOURCE_COMMIT}"
echo "Breakpoint:  ${BP_TAG}  -> (same commit)"

git tag -a "${BP_TAG}" "${SOURCE_COMMIT}" -m "${MESSAGE}"

echo ""
echo "Tag created: ${BP_TAG}"
echo ""
echo "To push both tags:"
echo "  git push origin ${SOURCE_TAG} ${BP_TAG}"
echo ""
echo "To list all breakpoints:"
echo "  git tag -l 'breakpoint_*'"
echo ""
echo "To see all commits marked as breakpoints:"
echo "  git log --oneline --tags='breakpoint_*' --topo-order"
