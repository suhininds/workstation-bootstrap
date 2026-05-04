#!/usr/bin/env bash
# bootstrap.sh — фаза 0: минимальный путь до манифеста на новом Mac.
# Запускается ОДИН РАЗ:
#   curl -fsSL https://raw.githubusercontent.com/suhininds/workstation-bootstrap/main/bootstrap.sh | bash
# (или скачать руками и запустить)
#
# Что делает:
#   1. Проверка / установка Xcode CLI tools, Homebrew (Apple Silicon + Intel)
#   2. brew install 1password-cli chezmoi gh
#   3. Проверка op (desktop integration), без принудительного `op signin`
#   4. gh auth через PAT из 1Password (ephemeral в shell, persisted в keychain)
#   5. chezmoi init по HTTPS, после применения SSH-ключи развёрнуты — переключение remote на SSH

set -euo pipefail

GH_USER="suhininds"

echo "[1/6] Xcode CLI tools"
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "→ Жди пока установятся, потом перезапусти этот скрипт"
  exit 0
fi

echo "[2/6] Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Поддержка Apple Silicon И Intel Mac
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "FAIL: brew установлен, но не найден ни в /opt/homebrew, ни в /usr/local"
    exit 1
  fi
fi

echo "[3/6] Минимальные зависимости (op + chezmoi + gh)"
brew install --quiet 1password-cli chezmoi gh

echo "[4/6] Проверка 1Password CLI"
if ! op whoami &>/dev/null; then
  cat <<'EOF'
✗ 1Password CLI не авторизован.
  Открой 1Password.app, разблокируй (master password / Touch ID).
  Settings → Developer → ✓ "Integrate with 1Password CLI" → Save.
  Потом перезапусти этот скрипт.

  Fallback: запусти вручную
    eval "$(op signin)"
  и снова запусти bootstrap.sh.
EOF
  exit 1
fi
echo "✓ op: $(op whoami)"

echo "[5/6] GitHub auth + clone dotfiles по HTTPS"

need_login=1
# Машинно-читаемая проверка: gh auth status --active + gh api user (оба self-contained, --hostname явный)
if gh auth status --hostname github.com --active &>/dev/null; then
  current_user=$(gh api --hostname github.com user -q .login 2>/dev/null || echo "")
  if [[ "$current_user" == "$GH_USER" ]]; then
    echo "✓ gh уже залогинен как ${GH_USER}, пропускаем login"
    need_login=0
  else
    # Чистый перелогин: explicit logout, потом login.
    echo "⚠ gh залогинен как '$current_user', но ожидался '$GH_USER' — explicit logout + перелогин"
    gh auth logout --hostname github.com 2>/dev/null || true
  fi
fi

if (( need_login == 1 )); then
  GITHUB_PAT=$(op item get "GitHub PAT" --vault "Mac Setup" --field credential --reveal)
  # --git-protocol https делает login неинтерактивным и явно соответствует HTTPS-клону.
  gh auth login --with-token --git-protocol https <<< "$GITHUB_PAT"
  unset GITHUB_PAT
fi
gh auth setup-git --hostname github.com  # идемпотентно

# clone — без токена в URL, gh-credentials helper сам подставит
chezmoi init --apply "https://github.com/${GH_USER}/workstation-dotfiles.git"

echo "[6/6] Подмена remote на SSH (SSH-ключ уже развёрнут chezmoi'ем через op inject)"
cd "$(chezmoi source-path)"
git remote set-url origin "git@github.com:${GH_USER}/workstation-dotfiles.git"

# ~/.ssh готовится корректно + дедупликация known_hosts
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
ssh-keygen -R github.com 2>/dev/null || true
ssh-keyscan -H github.com 2>/dev/null >> ~/.ssh/known_hosts
ssh -T git@github.com || true

echo "✅ Bootstrap фаза 0 завершена."
echo "   Теперь запусти: cd \$(chezmoi source-path) && ./scripts/apply.sh"
