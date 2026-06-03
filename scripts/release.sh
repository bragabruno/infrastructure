#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION_FILE="$ROOT/VERSION"
CURRENT=$(cat "$VERSION_FILE" | tr -d '[:space:]')

log() { echo "[release] $*"; }
fail() { echo "[release] FAIL: $*" >&2; exit 1; }

usage() {
  echo "Usage: $0 <major|minor|patch|version>"
  echo ""
  echo "  major   Bump major version (1.0.0 -> 2.0.0)"
  echo "  minor   Bump minor version (1.0.0 -> 1.1.0)"
  echo "  patch   Bump patch version (1.0.0 -> 1.0.1)"
  echo "  version Set specific version (e.g., 2.0.0)"
  echo ""
  echo "Current version: $CURRENT"
  exit 1
}

[[ $# -lt 1 ]] && usage

case "$1" in
  major)
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  minor)
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  patch)
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
  *.*.*)
    NEW_VERSION="$1"
    ;;
  *)
    usage
    ;;
esac

log "Bumping version: $CURRENT -> $NEW_VERSION"

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"
log "Updated VERSION file"

# Tag all repos if they exist
REPOS=("backend" "ml-service" "frontend")
for repo in "${REPOS[@]}"; do
  REPO_DIR="$ROOT/../$repo"
  if [[ -d "$REPO_DIR/.git" ]]; then
    log "Tagging $repo..."
    (cd "$REPO_DIR" && git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION" 2>/dev/null || log "  $repo: tag may already exist")
  else
    log "Skipping $repo (not a git repo)"
  fi
done

# Tag infrastructure repo
log "Tagging infrastructure..."
git add VERSION
git commit -m "chore: bump version to $NEW_VERSION" 2>/dev/null || true
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION" 2>/dev/null || log "  infrastructure: tag may already exist"

log "Release v$NEW_VERSION prepared."
log ""
log "Next steps:"
log "  1. Push tags: git push origin --tags"
log "  2. Create GitHub release: gh release create v$NEW_VERSION"
log "  3. Update CHANGELOG.md"
