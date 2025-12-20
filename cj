#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * -------------------
 * CLI COLORS
 * -------------------
 */
function color(string $text, string $color): string
{
  $colors = [
    'red' => '0;31',
    'green' => '0;32',
    'yellow' => '1;33',
    'blue' => '0;34',
    'cyan' => '0;36',
    'white' => '1;37',
  ];
  return "\033[" . ($colors[$color] ?? '0') . "m" . $text . "\033[0m";
}

/**
 * -------------------
 * HELP COMMAND
 * -------------------
 */
$allowedTypes = ['class', 'interface', 'abstract', 'trait', 'enum'];
if ($argc === 2 && $argv[1] === '--help') {

  $examples = [];
  foreach ($allowedTypes as $type) {
    $examples[] = "  php cj make:$type app Example/{$type}Example";
    $examples[] = "  php cj make $type app Example/{$type}Example";
  }
  // Multi-target examples
  $examples[] = "  php cj make:class app PaymentGateway/Stripe/Transaction PaymentGateway/Paypal/Transaction
  php cj make:class app PaymentGateway/Stripe/Transaction:extends=Field PaymentGateway/Paypal/Transaction
  php cj make:class app PaymentGateway/Stripe/Transaction:implements=StripeInterface PaymentGateway/Paypal/Transaction:implements=PaypalInterface";
  $examples[] = "  php cj make:class app PaymentGateway/Stripe/Transaction:extends=Field PaymentGateway/Paypal/Transaction";
  $examples[] = "  php cj make:class app PaymentGateway/Stripe/Transaction:implements=StripeInterface PaymentGateway/Paypal/Transaction:implements=PaypalInterface";
  $examplesText = implode("\n", $examples);

  echo <<<HELP
CJ CLI Tool
Usage:
  php cj [file.php]                        Create one or multiple PHP files with strict types
  php cj make:class app Path/ClassName   # or: php cj make class app Path/ClassName
  php cj make:interface app Path/MyInterface
  php cj make:trait app Path/MyTrait
  php cj make:abstract app Path/MyAbstract
  php cj make:enum app Path/MyEnum
                                           Generate a PSR-4 class, interface, trait, abstract class or enum
  php cj delete path/to/file_or_directory  Safely delete file/directory (moves to .trash)
  php cj undo                              Undo last delete
  php cj trash                             List items in trash
  php cj trash restore                     Restore items from trash (selectively or all)
  php cj --help                            Show this help message

Options:
  --yes, -y, --force                       Skip confirmation prompts (non-interactive)

Examples:
$examplesText
  php cj foo/bar.php baz/test.php
  php cj --yes foo/bar.php                 # create files without confirmation
  php cj make:class app Example/ClassExample --yes
  php cj make class app Example/ClassExample --yes
  php cj delete app/Example/ClassExample.php
  php cj undo
  php cj trash restore

HELP;
  exit(0);
}

/**
 * -------------------------
 * SAFE DELETE + Trash/Undo
 * -------------------------
 */
if ($argc >= 2 && $argv[1] === 'delete') {

  $relativePath = implode(DIRECTORY_SEPARATOR, array_slice($argv, 2));
  $target = realpath($relativePath);

  if (!$target) exit(color("❌ Path does not exist: $relativePath\n", 'red'));

  $projectRoot = realpath(__DIR__);
  $protected = [
    $projectRoot,
    realpath("$projectRoot/app"),
    realpath("$projectRoot/src"),
    realpath("$projectRoot/vendor"),
  ];

  $target = rtrim($target, DIRECTORY_SEPARATOR);

  foreach ($protected as $p) {
    if ($p && $target === $p) exit(color("🚨 REFUSED: Cannot delete protected directory:\n$target\n", 'red'));
  }

  if (!str_starts_with($target, $projectRoot)) {
    exit(color("🚨 REFUSED: Target is outside project:\n$target\n", 'red'));
  }

  echo color("⚠️  DELETE CONFIRMATION\n", 'yellow');
  echo "You are deleting:\n  $target\n";
  echo "Type DELETE to confirm: ";
  $confirm = trim(fgets(STDIN));
  if ($confirm !== 'DELETE') exit(color("Aborted.\n", 'yellow'));

  $trashDir = __DIR__ . '/.trash';
  if (!is_dir($trashDir)) mkdir($trashDir, 0755, true);

  $baseName = basename($target);
  $counter = 0;
  $dest = $trashDir . DIRECTORY_SEPARATOR . $baseName;
  while (file_exists($dest)) {
    $counter++;
    $dest = $trashDir . DIRECTORY_SEPARATOR . $baseName . "_$counter";
  }

  rename($target, $dest);

  $logPath = $trashDir . '/.trashlog.json';
  $log = file_exists($logPath) ? json_decode(file_get_contents($logPath), true) : [];
  $log[] = $dest;
  file_put_contents($logPath, json_encode($log, JSON_PRETTY_PRINT));

  echo color("✅ Moved to project trash: $dest\n", 'green');
  exit(0);
}

/**
 * -------------------
 * TRASH COMMAND
 * -------------------
 */
$trashDir = __DIR__ . '/.trash';
$logPath = $trashDir . '/.trashlog.json';
$log = file_exists($logPath) ? json_decode(file_get_contents($logPath), true) : [];

if ($argc === 2 && $argv[1] === 'trash') {
  echo color("🗑  Trash contents:\n", 'cyan');
  foreach ($log as $i => $item) {
    echo "[" . ($i + 1) . "] " . $item . "\n";
  }
  exit(0);
}

if ($argc === 3 && $argv[1] === 'trash' && $argv[2] === 'restore') {
  echo color("🗑  Trash contents:\n", 'cyan');
  foreach ($log as $i => $item) {
    echo "[" . ($i + 1) . "] " . $item . "\n";
  }

  echo "\nEnter the number to restore, 'a' to restore all, or 0 to cancel: ";
  $selection = trim(fgets(STDIN));

  if ($selection === '0') exit(color("Cancelled.\n", 'yellow'));

  if (strtolower($selection) === 'a') {
    foreach ($log as $item) {
      if (!file_exists($item)) continue;
      $restoreTo = __DIR__ . '/' . basename($item);
      $restoreToDir = dirname($restoreTo);
      if (!is_dir($restoreToDir)) mkdir($restoreToDir, 0755, true);
      if (!file_exists($restoreTo)) rename($item, $restoreTo);
      echo color("🔄 Restored: $restoreTo\n", 'green');
    }
    file_put_contents($logPath, json_encode([], JSON_PRETTY_PRINT));
    exit(0);
  }

  $selection = (int)$selection;
  if ($selection < 1 || $selection > count($log)) exit(color("Cancelled or invalid selection.\n", 'yellow'));

  $restorePath = $log[$selection - 1];
  if (!file_exists($restorePath)) {
    echo color("⚠️  Item no longer exists: $restorePath\n", 'red');
    array_splice($log, $selection - 1, 1);
    file_put_contents($logPath, json_encode($log, JSON_PRETTY_PRINT));
    exit(0);
  }

  $restoreTo = __DIR__ . '/' . basename($restorePath);
  $restoreToDir = dirname($restoreTo);
  if (!is_dir($restoreToDir)) mkdir($restoreToDir, 0755, true);
  if (file_exists($restoreTo)) exit(color("⚠️  File already exists at restore location: $restoreTo\n", 'red'));

  rename($restorePath, $restoreTo);
  echo color("🔄 Restored: $restoreTo\n", 'green');

  array_splice($log, $selection - 1, 1);
  file_put_contents($logPath, json_encode($log, JSON_PRETTY_PRINT));
  exit(0);
}

/**
 * -------------------
 * UNDO COMMAND
 * -------------------
 */
if ($argc === 2 && $argv[1] === 'undo') {
  if (!file_exists($logPath)) exit(color("Nothing to undo.\n", 'yellow'));
  $log = json_decode(file_get_contents($logPath), true);
  if (empty($log)) exit(color("Nothing to undo.\n", 'yellow'));

  $last = array_pop($log);
  if ($last && file_exists($last)) {
    $restoreTo = __DIR__ . '/' . basename($last);
    $restoreToDir = dirname($restoreTo);
    if (!is_dir($restoreToDir)) mkdir($restoreToDir, 0755, true);
    rename($last, $restoreTo);
    echo color("🔄 Restored: $restoreTo\n", 'green');
  } else {
    echo color("⚠️ Cannot restore (already removed or moved).\n", 'red');
  }

  file_put_contents($logPath, json_encode($log, JSON_PRETTY_PRINT));
  exit(0);
}

/**
 * -------------------------
 * FILE MODE (multiple files)
 * -------------------------
 */
$fileArgs = array_filter(array_slice($argv, 1), fn($arg) => str_ends_with($arg, '.php'));
if ($fileArgs) {
  foreach ($fileArgs as $filePath) {
    $dir = dirname($filePath);
    if ($dir !== '.' && !is_dir($dir)) mkdir($dir, 0755, true);
    if (file_exists($filePath)) {
      echo color("❌ File already exists: $filePath\n", 'red');
      continue;
    }
    file_put_contents($filePath, "<?php\n\ndeclare(strict_types=1);\n");
    echo color("Created file: $filePath\n", 'green');
  }
  exit(0);
}

/**
 * -------------------------
 * CLASS / INTERFACE / TRAIT / ENUM MODE
 * -------------------------
 */
$allowed = ['class', 'interface', 'abstract', 'trait', 'enum'];

// Accept forms:
//   php cj make:class app Path/ClassName
//   php cj make class app Path/ClassName
//   php cj:make class app Path/ClassName   (legacy)
$looksLikeMake = false;
if ($argc >= 2) {
  if (str_starts_with($argv[1], 'make:')) $looksLikeMake = true;
  elseif ($argv[1] === 'make' && $argc >= 4) $looksLikeMake = true;
  elseif (str_starts_with($argv[1], 'cj:make')) $looksLikeMake = true;
}

if (!$looksLikeMake) {
  echo color("Usage:\n", 'yellow');
  echo "  php cj delete path\n";
  echo "  php cj undo\n";
  echo "  php cj file.php [file2.php ...]\n";
  echo "  php cj make:class app Path/ClassName\n";
  echo "  php cj make class app Path/ClassName\n";
  exit(1);
}

// Warn if script appears to still be inside the cloned repository directory
$scriptDir = realpath(__DIR__);
$cwd = realpath(getcwd());
// non-interactive flag detection
$nonInteractive = in_array('--yes', $argv, true) || in_array('--force', $argv, true) || in_array('-y', $argv, true);
if ($cwd !== $scriptDir && basename($scriptDir) === 'cj-cli') {
  echo color("⚠️ WARNING: It looks like you're running the script from within the cloned 'cj-cli' folder.\n", 'yellow');
  echo "This will create files inside: $scriptDir\n";
  echo "Recommended: move the script to your project root (or install globally) so generated files are created in the right place.\n";
  echo color("Example (move into project root and make executable):\n  mv {$scriptDir}/cj .\n  chmod +x cj\n", 'yellow');
  echo color("Or to install globally:\n  sudo mv {$scriptDir}/cj /usr/local/bin/cj\n", 'yellow');

  if ($nonInteractive) {
    echo color("--yes/--force flag provided; continuing automatically.\n", 'yellow');
  } else {
    echo "Type 'continue' to proceed anyway, or press Enter to abort: ";
    $confirm = trim(fgets(STDIN));
    if (strtolower($confirm) !== 'continue') {
      exit(color("Aborted. Move the script and try again.\n", 'yellow'));
    }
  }
}

// Normalize args and extract type
$args = $argv;
$type = 'class';

if (str_starts_with($args[1], 'make:')) {
  $type = substr($args[1], strlen('make:'));
  array_shift($args); // remove make:class
} elseif ($args[1] === 'make') {
  array_shift($args); // remove 'make'
  if (!empty($args[1]) && in_array($args[1], $allowed, true)) {
    $type = $args[1];
    array_shift($args); // remove type
  }
} elseif (str_starts_with($args[1], 'cj:make')) {
  array_shift($args); // remove 'cj:make'
  if (!empty($args[1]) && in_array($args[1], $allowed, true)) {
    $type = array_shift($args);
  }
}

// Now $args is aligned like: [script, root, target, ...] -> shift to make parsing consistent
// shift off the script name so the rest of the code can use the same pattern
array_shift($args); // remove script name (was originally $argv[0])

$root = array_shift($args);
if ($root !== 'app') exit(color("Only 'app' root is supported for class generation.\n", 'red'));

// Support multiple targets after the root (e.g. `php cj make:class app A B C`)
$targets = [];
$targetsEntries = [];
while ($args && !in_array($args[0], ['extends', 'implements'], true)) {
  $token = array_shift($args);
  // token may be: target[:key=value][:key2=value2]
  $parts = explode(':', $token);
  $base = array_shift($parts);
  $entry = ['target' => $base, 'extends' => null, 'implements' => []];
  foreach ($parts as $p) {
    if (str_contains($p, '=')) {
      [$k, $v] = array_map('trim', explode('=', $p, 2));
      if ($k === 'extends') {
        if ($type === 'interface') {
          $entry['extends'] = array_map('trim', explode(',', $v));
        } else {
          $entry['extends'] = trim($v);
        }
      } elseif ($k === 'implements') {
        $entry['implements'] = array_map('trim', explode(',', $v));
      }
    }
  }
  $targetsEntries[] = $entry;
}
if (empty($targetsEntries)) exit(color("No target specified.\n", 'red'));

// Parse optional global modifiers (apply to all targets without per-target override)
$globalExtends = null;
$globalImplements = [];
if ($args) {
  while ($args) {
    $key = array_shift($args);
    if ($key === 'extends') {
      $val = array_shift($args);
      if ($type === 'interface') {
        $globalExtends = array_map('trim', explode(',', $val));
      } else {
        $globalExtends = trim($val);
      }
    } elseif ($key === 'implements') {
      $globalImplements = array_map('trim', explode(',', array_shift($args)));
    }
  }
}

foreach ($targetsEntries as $entry) {
  $target = $entry['target'];
  // Determine applied modifiers (per-target override global)
  $appliedExtends = $entry['extends'] ?? null;
  $appliedImplements = $entry['implements'] ?? [];
  if ($appliedExtends === null) $appliedExtends = $globalExtends;
  if (empty($appliedImplements)) $appliedImplements = $globalImplements;

  /**
   * PSR-4
   */
  $basePath = __DIR__ . '/app';
  $baseNamespace = 'App';
  $parts = explode('/', $target);
  $className = array_pop($parts);
  $dir = $basePath . ($parts ? '/' . implode('/', $parts) : '');
  $namespace = $baseNamespace . ($parts ? '\\' . implode('\\', $parts) : '');

  if (!is_dir($dir)) mkdir($dir, 0755, true);

  $file = "$dir/$className.php";
  if (file_exists($file)) {
    echo color("❌ File already exists: $file\n", 'red');
    continue;
  }

  // Auto-use imports
  $uses = [];
  $addUse = function ($name) use (&$uses, $namespace) {
    if (!$name) return;
    $names = is_array($name) ? $name : [$name];
    foreach ($names as $n) {
      if (!$n) continue;
      $fqcn = str_contains($n, '\\') ? $n : $namespace . '\\' . $n;
      if (!str_starts_with($fqcn, $namespace)) $uses[$fqcn] = $fqcn;
    }
  };
  $addUse($appliedExtends);
  $addUse($appliedImplements);

  // Helper to get short name for use in signatures
  $short = function ($name) {
    if (is_array($name)) {
      return array_map(fn($n) => ($n === '' ? '' : array_reverse(explode('\\', $n))[0]), $name);
    }
    if (!$name) return '';
    return array_reverse(explode('\\', $name))[0];
  };

  // Build signature
  $signature = match ($type) {
    'interface' => "interface $className",
    'abstract' => "abstract class $className",
    'trait' => "trait $className",
    'enum' => "enum $className",
    default => "class $className",
  };

  if ($type === 'interface') {
    if ($appliedExtends) {
      $extNames = is_array($appliedExtends) ? $appliedExtends : array_map('trim', explode(',', $appliedExtends));
      $shortNames = array_map(fn($n) => $short($n), $extNames);
      $signature .= ' extends ' . implode(', ', $shortNames);
    }
  } else {
    if ($appliedExtends) $signature .= " extends " . $short($appliedExtends);
    if (!empty($appliedImplements) && in_array($type, ['class', 'abstract'], true)) {
      $sigImpls = array_map(fn($n) => $short($n), $appliedImplements);
      $signature .= ' implements ' . implode(', ', $sigImpls);
    }
  }

  $body = match ($type) {
    'interface' => "    // Interface methods\\n",
    'trait' => "    // Trait methods\\n",
    'enum' => "\\n    case EXAMPLE;\\n",
    'abstract' => "    \\n",
    default => "",
  };

  $useBlock = '';
  foreach ($uses as $fqcn) $useBlock .= "use $fqcn;\\n";
  if ($useBlock) $useBlock .= "\\n";

  $template = <<<PHP
<?php

declare(strict_types=1);

namespace $namespace;

$useBlock$signature
{
$body}
PHP;

  file_put_contents($file, $template);
  echo color("Created: $file\n", 'green');
}
echo color("Created: $file\n", 'green');
