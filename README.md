# workstation-bootstrap

Минимальный публичный entrypoint для развёртывания workstation на новом Mac.

## Что это

Один shell-скрипт, который:

1. Ставит **Xcode CLI tools** + **Homebrew** (Apple Silicon или Intel)
2. Ставит **`chezmoi`**, **`gh`**, **`1Password CLI`** через brew
3. Достаёт **GitHub PAT** из локального **1Password vault `Mac Setup`** (через CLI integration)
4. Делает `chezmoi init --apply` на приватный репо [`suhininds/workstation-dotfiles`](https://github.com/suhininds/workstation-dotfiles), который дальше разворачивает всё окружение через `op inject` для секретов

## Требования

Перед запуском на новом Mac:

- Apple ID, iCloud Drive включены
- **FileVault** включён (System Settings → Privacy → FileVault)
- Mac App Store: вход выполнен под Apple ID
- **1Password.app** установлен, разблокирован, в Settings → Developer включена опция **Integrate with 1Password CLI**
- В 1Password есть private vault **`Mac Setup`** с item **`GitHub PAT`** (classic PAT, scope `repo`)

## Запуск

```sh
curl -fsSL https://raw.githubusercontent.com/suhininds/workstation-bootstrap/main/bootstrap.sh -o /tmp/bootstrap.sh && chmod +x /tmp/bootstrap.sh && /tmp/bootstrap.sh
```

> Версия с `| bash` тоже работает, но Homebrew installer внутри требует admin-пароль через sudo, и pipe ломает интерактивный ввод. Сначала скачать, потом запустить — пароль вводится нормально.

После завершения — продолжить:

```sh
cd "$(chezmoi source-path)"
./scripts/preflight.sh   # проверки окружения
./scripts/apply.sh       # развернуть всё (brew bundle, mas, dotfiles, LaunchAgent)
```

## Безопасность

- GitHub PAT передаётся в `gh auth login --with-token --git-protocol https` через here-string и сразу `unset` — не светится в `ps` / scrollback / `set -x`
- Дальше `gh` использует токен из macOS Keychain (через `gh auth setup-git`)
- Никакой URL вида `https://user:token@github.com` — токены не попадают в URL/логи git

## Связанные репозитории

| Репо | Visibility | Что внутри |
|---|---|---|
| [`workstation-dotfiles`](https://github.com/suhininds/workstation-dotfiles) | private | Brewfile, scripts, dotfiles, secrets.tpl |
| [`workstation-claude-memory`](https://github.com/suhininds/workstation-claude-memory) | private | Backup `~/.claude/projects/*/memory/` |
| **workstation-bootstrap** (этот репо) | public | Голый bootstrap.sh для `curl` |

## Лицензия

MIT — пользуйтесь, форкайте, адаптируйте под себя. Sensible defaults для разработчика-одиночки на macOS.
