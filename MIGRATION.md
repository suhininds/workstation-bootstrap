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

## Этап 6 — Восстановить Claude memory (1 мин, опционально)

Если хочешь чтобы Claude Code на новом маке имел всю память со старого:

```bash
cd ~/.local/share/claude-memory-backup
for proj in projects/*/memory; do
  src_proj=$(basename "$(dirname "$proj")")
  mkdir -p ~/.claude/projects/"$src_proj"
  rsync -a "$proj/" ~/.claude/projects/"$src_proj/memory/"
done
```

После этого все project notes / user preferences / feedback из старого мака будут доступны новому Claude Code.

## ✅ Финальный postflight

```bash
~/.local/share/chezmoi/scripts/postflight.sh
```

Должно быть **0 ❌**. Если есть — открой `~/.local/share/chezmoi/scripts/rollback.md`.

## ⚠️ Старый Mac — НЕ выкидываем 30 дней

Включи минимум раз в неделю, проверь что работает. Если новый Mac внезапно сломался — старый твой backup до выяснения.

---

## 🆘 Если что-то непонятно

- **Полный план миграции:** `~/.local/share/chezmoi/docs/migration-plan-v4.2.html` (после bootstrap)
- **Lessons learned (типичные грабли):** там же, секция 16
- **Connect with Claude Code на новом маке** для debug (после `brew install` Claude.app — `brew install --cask claude`)

Удачного переезда! 🎉
