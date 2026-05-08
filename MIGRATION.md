# 🚀 Migration Day Checklist

Пошаговая инструкция для миграции на новый Mac. Открывай эту страницу через Safari на новом маке — нужно будет переключаться между шагами.

**URL:** https://github.com/suhininds/workstation-bootstrap/blob/main/MIGRATION.md

---

## ⏱️ Тайминг
- Wall-clock: ~60-90 минут
- Активного участия: ~15-20 минут (остальное — ждём установки)

---

## Этап 0 — Preconditions (15 мин активно)

Это делаем **до** запуска bootstrap.

- [ ] **Apple ID** — войти в Системные настройки → Apple ID
- [ ] **iCloud Drive** включить (для синка `~/Documents`, `~/Desktop`)
- [ ] **FileVault** включить: Системные настройки → Конфиденциальность → FileVault → Включить
  - Сохрани recovery key
- [ ] **App Store** — войти под Apple ID (нужно для `mas install` через `brew bundle`)
- [ ] **Свободное место** ≥ 50 ГБ: `df -h /`
- [ ] **Установить 1Password.app** через сайт https://1password.com/downloads/mac/
- [ ] Залогиниться в 1Password.app (master password или Secret Key + email)
- [ ] **1Password Settings → Developer** → ✓ **Integrate with 1Password CLI** → Save
  - Это критично для bootstrap.sh
- [ ] Проверить что Vault `Mac Setup` подтянулся в 1Password.app (10 items)
- [ ] **Rosetta** (если нужно для Office / некоторых apps):
  ```bash
  softwareupdate --install-rosetta --agree-to-license
  ```

## Этап 1 — Bootstrap (10 мин wall-clock, 2 мин активно)

Открой Terminal на новом маке, скопируй и запусти **одной строкой**:

```bash
curl -fsSL https://raw.githubusercontent.com/suhininds/workstation-bootstrap/main/bootstrap.sh -o /tmp/bootstrap.sh && chmod +x /tmp/bootstrap.sh && /tmp/bootstrap.sh
```

> **Почему так, а не через `| bash`:** Homebrew installer внутри попросит admin-пароль (sudo). Через pipe `| bash` stdin не интерактивный → sudo не сможет принять пароль. Сначала скачиваем, потом запускаем — пароль вводится нормально.

Что произойдёт:
1. Установится Xcode CLI tools (откроется окно — "Install" → "Agree")
2. Установится Homebrew
3. Установится `1password-cli`, `chezmoi`, `gh`
4. **Touch ID** для авторизации `op` (через desktop integration)
5. Достанется GitHub PAT из vault `Mac Setup`, авторизуется `gh`
6. Клонируется `workstation-dotfiles` через HTTPS
7. `chezmoi apply` развернёт SSH ключи + все templated configs (Claude settings.json, .mcp.json и т.д.)
8. Run-once script разворачивает `~/.config/secrets.env` и `~/.config/yandex-cloud/config.yaml`
9. Remote переключится на SSH (с уже развёрнутым ключом)

**После завершения** будет сказано: `Bootstrap фаза 0 завершена.`

### Если что-то падает

| Симптом | Решение |
|---|---|
| `op whoami` возвращает ошибку | 1Password.app не разблокирован или Settings → Developer → Integrate with 1Password CLI не включена |
| `gh auth login` падает с network | проверить интернет, повторить |
| `xcode-select --install` уже стоит | пропусти, перезапусти скрипт |
| `op item get "GitHub PAT"` не находит | Vault не Mac Setup, или item title не "GitHub PAT" — проверь в 1Password.app |

## Этап 2 — Apply (40-60 мин wall-clock, 5 мин активно)

```bash
cd "$(chezmoi source-path)"
./scripts/preflight.sh   # ~10 секунд, диагностика
./scripts/apply.sh       # 30-60 минут, ставит всё
```

Что делает `apply.sh`:
- `brew bundle` ставит ~25 cask (1Password, Claude, Cursor, Telegram, Bitrix24, Office, ngrok и т.д.)
- macOS defaults: Dock, Finder, скриншоты, клавиатура
- Загружает оба LaunchAgent (drift + memory)

Активное участие:
- При установке Office может попросить admin password
- Touch ID для разворачивания секретов через `op`

После завершения проверь:
```bash
./scripts/postflight.sh
```

Все строки должны быть ✅.

## Этап 3 — Manual installs (15-30 мин)

Открой `~/.local/share/chezmoi/manual-installs.md` или https://github.com/suhininds/workstation-dotfiles/blob/main/manual-installs.md и пройди по списку:

- [ ] **Госплагин** (gosuslugi.ru) если используешь
- [ ] **CryptoPro CSP + cptools** (cryptopro.ru) если используешь ЭЦП
- [ ] **Chromium-Gost** (github.com/deemru/chromium-gost) если работаешь с ГОСТ-сертификатами
- [ ] **VK WorkSpace** (workspace.vk.com) корпоративный пакет
- [ ] **Microsoft Defender Shim** через корпоративный MDM (если есть) или microsoft.com
- [ ] **Copyosity** (github.com/vkovalskii) утилита Виталия — DMG из releases
- [ ] **VPN-клиент** — выбери ОДИН из:
  - AmneziaVPN (свой VPS, free)
  - Happ (VLESS-подписка, App Store)
  - hidemy.name (платная подписка)
  - sing-box (CLI, github.com/SagerNet/sing-box)

В Brewfile уже стоит `cask "amneziavpn"` opt-in. Если другой — закомменти.

## Этап 4 — Логины приложений (10 мин)

Большинство приложений уже стоят — нужно только залогиниться:

- [ ] **Telegram** — открой → QR-код, отсканируй с телефона
- [ ] **Bitrix24** — войти под корп.учёткой (Google SSO)
- [ ] **Slack** — корп.workspace, через Google
- [ ] **Office** — Word/Excel один раз → войти через Google → лицензия активируется (корпоративная подписка)
- [ ] **Zoom** — войти через SSO
- [ ] **OneDrive / Google Drive** — войти и подождать sync
- [ ] **Claude.app** — войти под Anthropic аккаунтом
- [ ] **Warp** — войти

## Этап 5 — Передача короны memory-backup (1 мин)

memory-backup сейчас бэкапит со старого мака. Передай право новому:

```bash
# На НОВОМ маке:
cd ~/.local/share/claude-memory-backup
scutil --get LocalHostName > .primary-host
git commit -am "rotate primary host to new Mac" && git push origin main
```

```bash
# На СТАРОМ маке (потом, не сейчас):
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.suhininds.dotfiles.memory.plist
# memory-backup на старом маке выключен
```

## Этап 6 — Восстановить Claude memory (3 мин, опционально)

Если хочешь чтобы Claude Code на новом маке имел всю память со старого:

```bash
cd ~/.local/share/claude-memory-backup
for proj in projects/*/memory; do
  src_proj=$(basename "$(dirname "$proj")")
  mkdir -p ~/.claude/projects/"$src_proj"
  rsync -a "$proj/" ~/.claude/projects/"$src_proj/memory/"
done
```

⚠️ **Имена папок зависят от пути юзера.** На старом маке `/Users/d.sukhinin/...` (с точкой) — папки названы `-Users-d-sukhinin-*`. На новом обычно `/Users/dsukhinin/...` (без точки). Claude Code на новом маке будет искать `-Users-dsukhinin-*` — нужно переименовать:

```bash
cd ~/.claude/projects
for d in -Users-d-sukhinin*; do
  new=$(echo "$d" | sed 's/^-Users-d-sukhinin/-Users-dsukhinin/')
  mv -- "$d" "$new"   # `--` обязателен: имена начинаются с `-`
done
```

После этого почисти старые `-d-sukhinin-` пути в репе бэкапа (иначе следующий запуск agent создаст дубликаты):

```bash
cd ~/.local/share/claude-memory-backup
git rm -r projects/-Users-d-sukhinin*
git commit -m "drop old -d-sukhinin- paths after host rename"
git push origin main
launchctl kickstart -k "gui/$(id -u)/com.suhininds.dotfiles.memory"   # синкнёт новые пути
```

## Этап 7 — Перенос рабочих проектов (15-30 мин, опционально)

Если на старом маке остались проекты (`~/projects/...`), забери их через rsync. **На СТАРОМ маке** включи Remote Login:

System Settings → General → **Sharing** → переключи **Remote Login** в ON (не путать с *Remote Management* — это VNC, разные службы). CLI `sudo systemsetup -setremotelogin on` требует Full Disk Access для Terminal — проще через GUI.

Узнай локальный IP старого мака: `ipconfig getifaddr en0` (например `192.168.1.26`).

**На НОВОМ маке** забери проекты:

```bash
mkdir -p ~/projects
rsync -avh --progress --exclude '.venv' --exclude 'venv' --exclude '__pycache__' --exclude 'node_modules' --exclude '.next' --exclude '.DS_Store' --exclude '.claude' <user>@<old-ip>:/Users/<user>/projects/ ~/projects/
```

`.claude/` исключаем чтобы не затереть локальные настройки Claude Code, потом доскачаем точечно:

```bash
rsync -av <user>@<old-ip>:/Users/<user>/projects/.claude/ ~/projects/.claude/
# для каждого проекта с .claude/ внутри:
rsync -av <user>@<old-ip>:/Users/<user>/projects/<path>/.claude/ ~/projects/<path>/.claude/
```

Пересоздай Python venv'ы (системный `python3` на macOS = 3.9, многим пакетам нужен ≥3.10):

```bash
cd ~/projects/<project>
/opt/homebrew/bin/python3.14 -m venv .venv   # явный путь, НЕ `python3 -m venv`
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

Если pip падает на внутреннем пакете без PyPI (типа `vibecode-b24-bot`) — в `requirements.txt` укажи git-source: `<name> @ git+https://github.com/<org>/<repo>.git`.

Для frontend: `npm install` в нужной папке.

## ✅ Финальный postflight

```bash
~/.local/share/chezmoi/scripts/postflight.sh
```

Должно быть **0 ❌**. Если есть — открой `~/.local/share/chezmoi/scripts/rollback.md`.

## ⚠️ Старый Mac — НЕ выкидываем 30 дней

Включи минимум раз в неделю, проверь что работает. Если новый Mac внезапно сломался — старый твой backup до выяснения.

После 30 дней без проблем на новом — выключи Remote Login на старом (System Settings → Sharing → Remote Login OFF) и можешь архивировать.

---

## 📚 Lessons learned (миграция 2026-05)

Грабли, реально сработавшие на этой миграции — на будущее:

- **Mac App Store секция бесполезна.** `Readout` (com.benjitaylor.Readout) и `Google Docs/Sheets/Slides` в Mac App Store не существуют — Readout качается с сайта, Google Docs только web. Закомментированные `mas` строки в Brewfile можно удалить, секцию пропустить.
- **Remote Login ≠ Remote Management.** В System Settings → Sharing это два РАЗНЫХ переключателя. Нужен именно `Remote Login` (Удалённый вход = SSH). `Remote Management` (Удалённое управление = VNC/ARD) для rsync не нужен.
- **`sudo systemsetup -setremotelogin on` требует Full Disk Access для Terminal.** Без неё — `Turning Remote Login on or off requires Full Disk Access privileges.` Через GUI быстрее.
- **SSH ключ с passphrase ломает postflight.** `ssh -o BatchMode=yes` не может ввести passphrase, postflight падает. На новом маке делай ключ без passphrase (`ssh-keygen -N ""`) или используй 1Password SSH agent.
- **Системный `python3` на macOS = 3.9.6.** Многие пакеты требуют ≥3.10. Создавай venv через явный `/opt/homebrew/bin/python3.14`, не через `python3 -m venv`.
- **Внутренние pip-пакеты без PyPI.** Если в `requirements.txt` имя без git URL (например `vibecode-b24-bot>=0.2.0`) — `pip install -r` упадёт. Замени на `<name> @ git+https://github.com/<org>/<repo>.git`.
- **rsync проектов с `--exclude '.claude'`.** Иначе перетрёшь локальные настройки Claude Code на новом маке. После основного rsync доскачай `.claude/` папки точечно (отдельным rsync).
- **`mv` с лидирующим `-` в имени.** `mv -Users-...` парсит дефис как опцию → `illegal option -- U`. Используй `mv -- "$d" "$new"`.
- **memory-папки зависят от пути юзера.** Старый Mac: `/Users/d.sukhinin/` → `-Users-d-sukhinin-*`. Новый: `/Users/dsukhinin/` → `-Users-dsukhinin-*`. После восстановления memory обязательно переименовать (см. Этап 6).
- **zsh + копипаст многострочной команды.** Line continuation `\` часто ломается, команда исполняется построчно с ошибками. Запускай критичные блоки одной строкой через `&&`.
- **zsh без `setopt interactive_comments`** парсит `# текст` после команды как аргумент. Добавь `setopt interactive_comments` в `~/.zshrc` или не пиши инлайн-комментарии.
- **1Password.app должен быть разлочен при `git commit`.** Если коммиты подписаны через `op-ssh-sign` (`gpg.format=ssh` + 1Password), и app залочен — коммит падает с `1Password: failed to fill whole buffer`. Touch ID на 1Password.app перед commit.
- **GitHub PAT scopes.** `gh auth login --with-token` валидирует scopes и требует минимум `repo + read:org`. Только `repo` не пройдёт. Удобный костыль на время — `export GH_TOKEN=$(op read "op://Mac Setup/GitHub PAT/credential")`, чтобы не передавать токен через `--with-token`.
- **microsoft-office cask конфликтует с onedrive cask** — Office уже включает OneDrive. Не ставь оба, иначе при `apply.sh` свалится конфликт.
- **AmneziaVPN — Intel-only pkg.** На Apple Silicon требует Rosetta 2. До установки Rosetta — закомментируй cask, иначе `brew bundle` упадёт.
- **`brew bundle check` Ruby ошибка `undefined method 'to_sym' for nil`** — лечится `brew update` (баг парсера в старой версии Homebrew).
- **op binary с quarantine xattr.** На свежем маке `op` может быть убит Gatekeeper с exit 137. Лечится `xattr -d com.apple.quarantine /opt/homebrew/Caskroom/1password-cli/<ver>/op`.

---

## 🆘 Если что-то непонятно

- **Полный план миграции:** `~/.local/share/chezmoi/docs/migration-plan-v4.2.html` (после bootstrap)
- **Connect with Claude Code на новом маке** для debug (после `brew install --cask claude`) — у него в memory лежит `project_mac_migration_followup.md` с punch-list незакрытых хвостов.

Удачного переезда! 🎉
