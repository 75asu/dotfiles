#!/usr/bin/env bash
# Read-only drift check for the mac dotfiles + git identity setup.
# Reports where reality has diverged from the dotfiles. Changes nothing unless
# you pass --fix, which then repairs the items that are safe to repair
# (symlinks, git remotes). It never generates SSH keys or logs into gh for you.
#
# Usage:
#   ./mac-doctor.sh         report drift only (exit 1 if any drift)
#   ./mac-doctor.sh --fix   repair symlinks + git remotes, then report
#
# Exit code: 0 = clean (or all drift fixed), 1 = unresolved drift remains.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT/mac/manifest.sh"
DOTFILES="$DOTFILES_MAC"

FIX=0
[ "${1:-}" = "--fix" ] && FIX=1

DRIFT=0
tilde() { echo "${1/#$HOME/~}"; }
ok()    { echo "  ok     $1"; }
bad()   { echo "  DRIFT  $1"; DRIFT=1; }
fixed() { echo "  fixed  $1"; }
todo()  { echo "  todo   $1"; DRIFT=1; }

acct_field() { # <folder> <field-index 2..5> -> value, or empty
  local f="$1" idx="$2" a
  for a in "${GH_ACCOUNTS[@]}"; do
    IFS='|' read -r folder user keyfile alias email <<<"$a"
    if [ "$folder" = "$f" ]; then
      case "$idx" in 2) echo "$user";; 3) echo "$keyfile";; 4) echo "$alias";; 5) echo "$email";; esac
      return
    fi
  done
}

echo "== symlinks =="
for entry in "${DOTFILE_LINKS[@]}"; do
  src="$DOTFILES/${entry%%|*}"; dest="${entry#*|}"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$(tilde "$dest")"
  elif [ "$FIX" -eq 1 ]; then
    mkdir -p "$(dirname "$dest")"
    [ -e "$dest" ] && ! [ -L "$dest" ] && mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    rm -f "$dest"; ln -s "$src" "$dest"; fixed "$(tilde "$dest") -> $(tilde "$src")"
  elif [ -L "$dest" ]; then
    bad "$(tilde "$dest") points to $(readlink "$dest") (expected $(tilde "$src"))"
  elif [ -e "$dest" ]; then
    bad "$(tilde "$dest") is a real file, not a symlink (expected -> $(tilde "$src"))"
  else
    bad "$(tilde "$dest") missing (expected -> $(tilde "$src"))"
  fi
done

echo "== github ssh keys =="
for a in "${GH_ACCOUNTS[@]}"; do
  IFS='|' read -r folder user keyfile alias email <<<"$a"
  if [ -f "$HOME/.ssh/$keyfile" ]; then ok "$keyfile ($user)"
  else todo "$keyfile missing for $user -- run mac-install.sh to generate, then add the .pub to GitHub"; fi
done

echo "== ssh_config host aliases =="
cfg="$HOME/.ssh/config"
for a in "${GH_ACCOUNTS[@]}"; do
  IFS='|' read -r folder user keyfile alias email <<<"$a"
  if grep -qE "^Host[[:space:]]+$alias([[:space:]]|$)" "$cfg" 2>/dev/null && grep -q "$keyfile" "$cfg" 2>/dev/null; then
    ok "$alias -> $keyfile"
  else
    bad "ssh_config missing Host $alias or its IdentityFile $keyfile"
  fi
done

echo "== git identity resolution (includeIf) =="
for a in "${GH_ACCOUNTS[@]}"; do
  IFS='|' read -r folder user keyfile alias email <<<"$a"
  dir="$GH_CLONES_ROOT/$folder"
  [ -d "$dir" ] || { echo "  skip   $folder/ (folder not present on this machine)"; continue; }
  repo=""
  for r in "$dir"/*/; do [ -d "$r/.git" ] && { repo="$r"; break; }; done
  [ -z "$repo" ] && { echo "  skip   $folder/ (no repo cloned to test resolution)"; continue; }
  got="$(git -C "$repo" config user.email 2>/dev/null)"
  if [ "$got" = "$email" ]; then ok "$folder/ resolves to $got"
  else bad "$folder/ resolves to '${got:-<none>}' (expected $email) -- includeIf not firing"; fi
done

echo "== gh cli auth =="
if command -v gh >/dev/null 2>&1; then
  status="$(gh auth status 2>&1 || true)"
  for a in "${GH_ACCOUNTS[@]}"; do
    IFS='|' read -r folder user keyfile alias email <<<"$a"
    if echo "$status" | grep -q "account $user"; then ok "gh authed as $user"
    else todo "gh NOT authed as $user -- run: gh auth login --hostname github.com --git-protocol ssh"; fi
  done
else
  todo "gh not installed"
fi

echo "== git remote protocol audit =="
shopt -s nullglob
for repo in "$GH_CLONES_ROOT"/*/*/; do
  [ -d "$repo/.git" ] || continue
  rel="${repo#$GH_CLONES_ROOT/}"; folder="${rel%%/*}"
  expected_alias="$(acct_field "$folder" 4)"
  [ -z "$expected_alias" ] && continue   # folder not in account table
  url="$(git -C "$repo" remote get-url origin 2>/dev/null)" || continue
  host="$(printf '%s' "$url" | sed -nE 's#^git@([^:]+):.*#\1#p')"
  if [ "$host" = "$expected_alias" ]; then
    ok "${rel%/} ($url)"
  elif [ "$FIX" -eq 1 ]; then
    path="$(printf '%s' "$url" | sed -E 's#^https://github\.com/##; s#^git@[^:]+:##')"
    newurl="git@$expected_alias:$path"
    git -C "$repo" remote set-url origin "$newurl"
    fixed "${rel%/} -> $newurl"
  else
    bad "${rel%/} uses '$url' (expected host $expected_alias)"
  fi
done
shopt -u nullglob

echo ""
if [ "$DRIFT" -eq 0 ]; then echo "RESULT: clean"; else echo "RESULT: drift found (run with --fix to repair symlinks + remotes; keys/gh-auth need manual steps above)"; fi
exit "$DRIFT"
