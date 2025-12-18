# cj-cli
PHP CLI tool to generate files, PSR-4 classes, interfaces, traits, enums, and manage safe deletes.
# CJ CLI

CJ CLI is a lightweight, developer-friendly PHP command-line tool designed to speed up PHP project development. It automates repetitive tasks like file creation, PSR-4 class scaffolding, and safe file management.

## Key Features

- **Quick File Creation**: Generate PHP files with `declare(strict_types=1)` automatically.
- **PSR-4 Class Generation**: Create classes, abstract classes, interfaces, traits, and enums with proper namespace and optional `extends` / `implements`.
- **Safe Delete & Undo**: Move files or directories to a `.trash` folder instead of deleting them permanently.
- **Restore from Trash**: Undo deletions or selectively restore items from the project trash.
- **Boilerplate Reduction**: Reduce repetitive code and keep your projects clean and organized.
- **Multiple File Support**: Create several files in one command.
- **CLI-friendly & Interactive**: Confirm deletions, restore interactively, and follow a smooth workflow.
- **PSR-4 Compliant**: Generated classes follow PSR-4 folder and namespace standards.
- **Documentation Included**: Includes a visual HTML documentation with copyable commands and VS Code-style previews.

## Example Commands

```bash
# Create multiple PHP files
php cj foo.php bar.php

# Generate a PSR-4 class
php cj:make class app Example/ClassExample

# Safe delete a file
php cj delete app/Example/ClassExample.php

# Undo last deletion
php cj undo

# View and restore trash
php cj trash
php cj trash restore
