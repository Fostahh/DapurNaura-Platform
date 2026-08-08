#!/usr/bin/env bash
#
# bootstrap.sh — clone the Dapur Naura project repositories into this workspace.
#
# This umbrella repo tracks docs/ only. The actual projects are independent git
# repositories; this script fetches them into the layout the tooling expects.
#
# Safe to re-run: anything already present is left completely untouched.
#
#   ./bootstrap.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Sanity check: refuse to run from anywhere but the umbrella root.
[[ -f "$ROOT/CLAUDE.md" && -d "$ROOT/docs" ]] \
  || { echo "✗ This does not look like the DapurNaura-Platform root: $ROOT" >&2; exit 1; }

command -v git >/dev/null || { echo "✗ git is not installed." >&2; exit 1; }

# ---------------------------------------------------------------------------
# The repositories.  Format: "<target-path>|<git-url>"
# Add the Android app and DapurNaura here once they have remotes.
# ---------------------------------------------------------------------------
REPOS=(
  "DNLibrary|https://github.com/Fostahh/DNLibrary.git"
  "ios/DapurNaura|https://github.com/Fostahh/DapurNaura-iOS.git"
  "ios/SPMDNLibrary|https://github.com/Fostahh/SPMDNLibrary.git"
)

# Projects that exist locally but have no remote yet — reported, never touched.
NO_REMOTE_YET=(
  "android|Native Android app — not created yet"
)

echo "Bootstrapping Dapur Naura workspace at $ROOT"
echo

for entry in "${REPOS[@]}"; do
  path="${entry%%|*}"
  url="${entry##*|}"

  if [[ -d "$path/.git" ]]; then
    echo "✓ $path — already cloned, skipping"
    continue
  fi

  if [[ -e "$path" ]]; then
    echo "! $path — exists but is not a git repo. Leaving it alone; resolve by hand." >&2
    continue
  fi

  echo "→ cloning $url into $path"
  mkdir -p "$(dirname "$path")"
  git clone "$url" "$path"
done

echo
for entry in "${NO_REMOTE_YET[@]}"; do
  path="${entry%%|*}"
  note="${entry##*|}"
  if [[ -d "$path/.git" ]]; then
    echo "✓ $path — present locally ($note)"
  else
    echo "· $path — not present. $note"
  fi
done

# ---------------------------------------------------------------------------
# Install the commit-msg hook (DN-007) into every repo present — including this
# one. The DN-XXX convention is the only cross-repo link between a commit and
# its ticket. Hooks live in .git/hooks/ (per-clone, never committed), so
# installation happens here and is safe to repeat.
#
# The umbrella is passed explicitly rather than added to REPOS, because REPOS is
# "things to clone" and the umbrella is the thing you are standing in. Until
# DN-028 it was in neither list, so the one repository that stores the hook and
# receives every ticket and docs commit was the only one not checked against the
# convention it defines.
# ---------------------------------------------------------------------------
HOOK_SRC="$ROOT/hooks/commit-msg"

install_hook() {  # $1 = repo dir, $2 = label
  [[ -d "$1/.git" ]] || return 0
  mkdir -p "$1/.git/hooks"
  install -m 0755 "$HOOK_SRC" "$1/.git/hooks/commit-msg"
  echo "✓ $2 — commit-msg hook installed"
}

echo
install_hook "$ROOT" "DapurNaura-Platform (umbrella)"
for entry in "${REPOS[@]}" "${NO_REMOTE_YET[@]}"; do
  path="${entry%%|*}"
  install_hook "$path" "$path"
done

cat <<'EOF'

Done.

Next:
  1. Read README.md, then docs/ARCHITECTURE-AND-WORKFLOW.md
  2. Build the data layer:   cd DNLibrary && ./gradlew :sharedLogic:check
  3. The iOS app is opened from ios/DapurNaura in Xcode — Gradle alone cannot build it.

Note: the iOS app depends on a locally built XCFramework (ios/DNLibraryLocal) during
development. That folder is a build artifact and is never committed — generate it with
DNLibrary/scripts/publish-spm.sh before building the app.
EOF
