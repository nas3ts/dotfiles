#!/bin/bash
set -euo pipefail

# doctor.sh — Health check for the dotfiles setup.
# Validates symlinks, tools, secrets, and overall config integrity.
#
# Usage:
#   doctor.sh              # full check
#   doctor.sh --quick      # skip slow checks (zsh sourcing, package list)
#   doctor.sh --json       # output as JSON (for scripting)

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$DOTFILES_DIR/configs"

QUICK=0
JSON=0
for arg in "$@"; do
  [[ "$arg" == "--quick" ]] && QUICK=1
  [[ "$arg" == "--json" ]] && JSON=1
done

HAS_GUM=0
command -v gum &>/dev/null && HAS_GUM=1

# Counters
PASS=0
WARN=0
FAIL=0
checks=()

check() {
  local status="$1" label="$2" detail="${3:-}"
  case "$status" in
    pass) PASS=$((PASS + 1)) ;;
    warn) WARN=$((WARN + 1)) ;;
    fail) FAIL=$((FAIL + 1)) ;;
  esac

  if [[ $JSON -eq 1 ]]; then
    checks+=("{\"status\":\"$status\",\"label\":\"$label\",\"detail\":\"$detail\"}")
  else
    case "$status" in
      pass) icon="OK" ;;
      warn) icon="!!" ;;
      fail) icon="XX" ;;
    esac
    printf "  [%s] %s" "$icon" "$label"
    [[ -n "$detail" ]] && printf " — %s" "$detail"
    echo
  fi
}

if [[ $JSON -eq 0 ]]; then
  echo "Dotfiles Doctor"
  echo "==============="
  echo
fi

# === SYMLINKS ===
if [[ $JSON -eq 0 ]]; then
  echo "Symlinks:"
fi

skip_dirs=("omarchy" "git")
omarchy_managed=("kitty" "hypr" "git" "foot" "ghostty" "alacritty" "tmux" "lazygit" "btop" "obsidian" "imv" "herdr" "wireplumber" "xournalpp" "chromium" "fcitx5")

is_skip() {
  for skip in "${skip_dirs[@]}"; do
    [[ "$1" == "$skip" ]] && return 0
  done
  return 1
}

is_omarchy_managed() {
  for app in "${omarchy_managed[@]}"; do
    [[ "$1" == "$app" ]] && return 0
  done
  return 1
}

for app_dir in "$CONFIG_DIR"/*; do
  [[ -d "$app_dir" ]] || continue
  app_name=$(basename "$app_dir")
  target="$XDG_CONFIG_HOME/$app_name"

  is_skip "$app_name" && continue
  is_omarchy_managed "$app_name" && continue

  if [[ -L "$target" ]]; then
    if [[ -e "$target" ]]; then
      check pass "$app_name" "linked"
    else
      link_target=$(readlink "$target")
      check fail "$app_name" "BROKEN → $link_target"
    fi
  elif [[ -e "$target" ]]; then
    check warn "$app_name" "real file (not managed)"
  else
    check warn "$app_name" "missing"
  fi
done

# Top-level dotfiles
for pair in ".vimrc:$HOME/.vimrc" "AGENTS.md:$XDG_CONFIG_HOME/AGENTS.md"; do
  name="${pair%%:*}"
  target="${pair#*:}"
  if [[ -L "$target" ]]; then
    if [[ -e "$target" ]]; then
      check pass "$name" "linked"
    else
      check fail "$name" "BROKEN"
    fi
  elif [[ -e "$target" ]]; then
    check warn "$name" "real file (not managed)"
  else
    check warn "$name" "missing"
  fi
done

echo

# === TOOLS ===
if [[ $JSON -eq 0 ]]; then
  echo "Tools:"
fi

tools=(
  "oh-my-posh:prompt"
  "aliae:shell aliases"
  "zoxide:smart cd"
  "lsd:modern ls"
  "zinit:plugin manager"
  "fzf:fuzzy finder"
  "glow:markdown viewer"
  "yt-dlp:video downloader"
  "jfsh:jfsh"
  "yazi:file manager"
  "spf:superfile"
  "dunst:notifications"
  "zathura:pdf viewer"
  "git:version control"
  "zsh:shell"
)

for entry in "${tools[@]}"; do
  cmd="${entry%%:*}"
  label="${entry#*:}"
  if command -v "$cmd" &>/dev/null; then
    version=$("$cmd" --version 2>/dev/null | head -1 || echo "installed")
    check pass "$cmd ($label)" "$version"
  else
    check fail "$cmd ($label)" "NOT INSTALLED"
  fi
done

echo

# === SECRETS ===
if [[ $JSON -eq 0 ]]; then
  echo "Secrets:"
fi

SECRETS_DIR="$HOME/.local/share/dotfiles-secrets"
SECRETS_FILE="$SECRETS_DIR/env.sh"

if [[ -f "$SECRETS_FILE" ]]; then
  perms=$(stat -c '%a' "$SECRETS_FILE" 2>/dev/null || stat -f '%A' "$SECRETS_FILE" 2>/dev/null || echo "unknown")
  if [[ "$perms" == "600" ]]; then
    check pass "secrets file" "mode $perms"
  else
    check warn "secrets file" "mode $perms (expected 600)"
  fi

  # Check if vars are populated
  sourced_count=0
  empty_count=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^export\ ([A-Z_]+)=\"\"$ ]]; then
      empty_count=$((empty_count + 1))
    elif [[ "$line" =~ ^export\ [A-Z_]+=.+ ]]; then
      sourced_count=$((sourced_count + 1))
    fi
  done < "$SECRETS_FILE"

  if [[ $empty_count -gt 0 ]]; then
    check warn "secrets vars" "$sourced_count set, $empty_count empty"
  else
    check pass "secrets vars" "$sourced_count set"
  fi
else
  check warn "secrets file" "NOT FOUND — qti/qui/managarr will fail"
fi

echo

# === YAZI PACKAGES ===
if [[ $JSON -eq 0 ]]; then
  echo "Yazi:"
fi

YAZI_DIR="$XDG_CONFIG_HOME/yazi"
if [[ -f "$YAZI_DIR/package.toml" ]]; then
  expected=$(grep -c '^\[\[plugin.deps\]\]' "$YAZI_DIR/package.toml" 2>/dev/null || echo 0)
  if [[ -d "$YAZI_DIR/plugins" ]]; then
    installed=$(ls -1 "$YAZI_DIR/plugins" 2>/dev/null | wc -l)
    if [[ $installed -ge $expected ]]; then
      check pass "yazi packages" "$installed/$expected installed"
    else
      check warn "yazi packages" "$installed/$expected installed (run 'ya pkg install')"
    fi
  else
    check fail "yazi packages" "plugins/ dir missing (run 'ya pkg install')"
  fi
else
  check warn "yazi config" "no package.toml found"
fi

echo

# === GIT CONFIG ===
if [[ $JSON -eq 0 ]]; then
  echo "Git:"
fi

if git -C "$DOTFILES_DIR" remote -v &>/dev/null; then
  remote=$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || echo "unknown")
  check pass "dotfiles remote" "$remote"
else
  check warn "dotfiles remote" "no remote configured"
fi

branch=$(git -C "$DOTFILES_DIR" branch --show-current 2>/dev/null || echo "unknown")
check pass "dotfiles branch" "$branch"

echo

# === ZSH (skip in --quick mode) ===
if [[ $QUICK -eq 0 ]]; then
  if [[ $JSON -eq 0 ]]; then
    echo "Zsh:"
  fi

  ZSHRC="$HOME/.zshrc"
  DOTFILES_ZSHRC="$DOTFILES_DIR/.zshrc"

  if [[ -f "$ZSHRC" ]]; then
    if grep -qF "source $DOTFILES_ZSHRC" "$ZSHRC" 2>/dev/null; then
      check pass ".zshrc sources dotfiles" "found"
    else
      check warn ".zshrc sources dotfiles" "NOT FOUND — run install.sh"
    fi
  else
    check warn ".zshrc" "NOT FOUND"
  fi

  if [[ -f "$DOTFILES_ZSHRC" ]]; then
    # Basic syntax check: try to parse with zsh -n (dry run)
    if zsh -n "$DOTFILES_ZSHRC" 2>/dev/null; then
      check pass "dotfiles .zshrc syntax" "valid"
    else
      check warn "dotfiles .zshrc syntax" "parse error"
    fi
  else
    check warn "dotfiles .zshrc" "NOT FOUND at $DOTFILES_ZSHRC"
  fi
fi

echo

# === SUMMARY ===
total=$((PASS + WARN + FAIL))

if [[ $JSON -eq 1 ]]; then
  printf '{"pass":%d,"warn":%d,"fail":%d,"total":%d,"checks":[%s]}\n' \
    "$PASS" "$WARN" "$FAIL" "$total" "$(IFS=,; echo "${checks[*]}")"
else
  echo "Summary: $PASS pass, $WARN warn, $FAIL fail ($total total)"
  if [[ $FAIL -gt 0 ]]; then
    echo
    echo "Run 'install.sh --link-only' to fix broken symlinks."
    echo "Run 'ya pkg install' to install missing yazi packages."
  elif [[ $WARN -gt 0 ]]; then
    echo
    echo "No critical issues. Warnings are informational."
  else
    echo
    echo "All checks passed!"
  fi
fi
