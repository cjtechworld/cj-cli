# CJ CLI — A tiny, developer-friendly PHP helper

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://cjtechworld.github.io/cj-cli/)

CJ CLI is a small PHP command-line utility to speed up common PHP project tasks: creating PHP files with strict types, scaffolding PSR‑4 classes (class/interface/trait/abstract/enum), and safely deleting files/directories (moves to a `.trash` folder with undo/restore support).

---

## ⚙️ Requirements

- PHP 7.4+ (or compatible)
- A POSIX-like shell (Linux / macOS) or PowerShell on Windows for installer commands

---

## 🚀 Installation

Clone the repo and install the `cj` script where you'll use it.

```bash
# clone the repo (creates a cj-cli folder)
git clone https://github.com/cjtechworld/cj-cli.git
```

Important: cloning creates a `cj-cli/` directory. The `cj` script uses its own directory as the base (it calls `__DIR__` internally). For commands like `php cj` or `php cj:make` to create files in _your project_, move the `cj` script into your project root (or install it globally).

Examples:

Linux / macOS

```bash
# move into your project root and make executable
mv cj-cli/cj .
chmod +x cj

# Or install globally
sudo mv cj /usr/local/bin/cj
```

Windows (PowerShell)

```powershell
Copy-Item .\cj-cli\cj -Destination .\ -Force
# then run with
php cj --help
```

---

## 📘 Usage — quick reference

Create one or more PHP files with strict types:

```bash
php cj foo.php bar/baz.php
```

Generate PSR‑4 scaffolding (class/interface/abstract/trait/enum):

```bash
php cj:make class app Path/ClassName [extends Base] [implements InterfaceA,InterfaceB]
php cj:make interface app Path/MyInterface
php cj:make trait app Path/MyTrait
php cj:make abstract app Path/MyAbstract
php cj:make enum app Path/MyEnum
```

Safe delete / trash / undo:

```bash
php cj delete path/to/file_or_directory
php cj undo
php cj trash
php cj trash restore
```

Show the help message:

```bash
php cj --help
```

---

## 🔧 Options / Flags

- `--help` — show help and examples
- `--yes`, `-y`, `--force` — **skip confirmation prompts** (non-interactive). Useful in CI or when you know what you're doing.

Note: If you run commands while `cj` is still inside `cj-cli/`, the script detects this and warns you (it may prompt to continue). Use `--yes` to skip that prompt when you intentionally want to proceed.

---

## 💡 Examples

Create a class:

```bash
php cj:make class app Example/ClassExample
# created: app/Example/ClassExample.php
```

Create files quickly:

```bash
php cj index.php config.php
# Created file: index.php
# Created file: config.php
```

Delete safely with confirmation:

```bash
php cj delete temp/test.php
# moved to .trash/...
```

Restore from trash interactively:

```bash
php cj trash restore
```

---

## ❗ Quick Troubleshooting

- Files created in the wrong folder? You most likely ran `cj` while the script still resided inside the cloned `cj-cli` directory.
  - Move the `cj` script into your project root and re-run: `mv cj-cli/cj . && chmod +x cj`
  - Or install it globally `sudo mv cj /usr/local/bin/cj` so it can be run from any project.
  - If files were already created in the wrong folder, move them into your project or remove and re-run from the correct location.
- Want to skip the confirmation prompt? Add `--yes` (or `-y` / `--force`) to the command: `php cj:make class app Example/ClassExample --yes`.

---

## 🧪 Scripts & Behavior Notes

- File creation mode: pass `*.php` file paths to create minimal PHP files with `declare(strict_types=1)` at top.
- `cj:make` generates a minimal PSR‑4-compliant PHP file using the `App\` base namespace and puts the file under `app/...`.
- Deleting is _safe_ — files are moved to a `.trash` folder with a `.trashlog.json` ledger used by `trash`, `trash restore`, and `undo` commands.

---

## 🤝 Contributing

Contributions welcome.

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes and add tests where possible
4. Open a Pull Request with a clear description

Please follow the existing style and keep commits small and focused.

---

## 📄 License

This project is released under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 cjtechworld

---

## 📬 Contact / Links

- Repository: https://github.com/cjtechworld/cj-cli
- Documentation: https://cjtechworld.github.io/cj-cli/ — Hosted docs (GitHub Pages)
- Issues: use the GitHub issues page for feature requests and bug reports

---

If you'd like, I can also:

- Add a `LICENSE` file (MIT) and commit it, or
- Add a small `CONTRIBUTING.md` with PR and code style guidelines, or
- Add a sample `composer.json` if you'd like to distribute via Composer.

Tell me which of those you want me to add next.
