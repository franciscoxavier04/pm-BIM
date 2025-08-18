# Copyright Script

The `script/copyright` utility is a fast Ruby script that replaces the legacy `rake copyright` tasks. It provides functionality to check for and fix missing or incorrect copyright headers in source files.

## Features

- **Fast execution**: Significantly faster than the rake task since it doesn't load the Rails environment
- **Check mode**: Default behavior that reports files with missing or incorrect copyright headers
- **Fix mode**: Automatically adds or fixes copyright headers in files
- **Multiple file format support**: Handles Ruby, JavaScript/TypeScript, CSS, ERB, SQL, Markdown, and other file types
- **Flexible usage**: Can process all files, specific files, or directories
- **Smart exclusions**: Respects exclusion patterns for vendor code, node_modules, tmp files, etc.
- **Proper file handling**: Preserves shebangs and frozen_string_literal comments in Ruby files

## Usage

### Basic Usage

```bash
# Check all files for copyright issues (default mode)
script/copyright

# Check specific file or directory
script/copyright app/models/user.rb
script/copyright app/models/

# Fix copyright headers in all files
script/copyright --fix

# Fix copyright headers in specific files/directories
script/copyright --fix app/models/user.rb
script/copyright --fix app/models/

# Show verbose output
script/copyright --verbose
script/copyright --fix --verbose app/models/
```

### Options

- `--check`: Check for missing/incorrect copyright (default)
- `--fix`: Fix copyright headers automatically
- `--verbose`, `-v`: Show verbose output
- `--help`, `-h`: Show help message

## Supported File Types

The script handles these file types with appropriate comment formats:

| File Type | Extensions | Comment Format |
|-----------|------------|----------------|
| Ruby | `.rb`, `.rake`, `.yml`, `Gemfile`, `Rakefile` | `#-- copyright ... #++` |
| JavaScript/TypeScript | `.js`, `.ts`, `.sass`, `.scss` | `//-- copyright ... //++` |
| CSS | `.css` | `/*-- copyright ... ++*/` |
| ERB Templates | `.html.erb`, `.js.erb`, `.css.erb`, etc. | `<%#-- copyright ... ++#%>` |
| SQL | `.sql` | `-- -- copyright ... -- ++` |
| Markdown | `.md` | `<!---- copyright ... ++-->` |
| Other | `.rdoc`, `.atom.builder` | Format-specific |

## Exclusions

The script automatically excludes:

- `frontend/node_modules/` - Node.js dependencies
- `tmp/` - Temporary files
- `modules/gitlab_integration/` - Third-party integration
- `vendor/` - Vendor/third-party code
- `lib_static/plugins/` - Legacy plugins
- `spec/fixtures/` - Test fixtures
- `db/migrate/`, `db/schema.rb` - Database files
- License and copyright files themselves (`LICENSE`, `COPYRIGHT`, etc.)

## Examples

### Checking Files

```bash
# Check all Ruby files in app/
$ script/copyright app/
app/components/add_button_component.rb does not match regexp. Missing copyright notice?
app/models/user_settings.rb does not match regexp. Missing copyright notice?

# Check with verbose output
$ script/copyright --verbose app/models/user.rb
Running in check mode...
Root directory: /path/to/openproject
Copyright file: /path/to/openproject/COPYRIGHT_short

OK: app/models/user.rb
All files have correct copyright headers!
```

### Fixing Files

```bash
# Fix all files in a directory
$ script/copyright --fix app/models/

# Fix with verbose output
$ script/copyright --fix --verbose app/models/user_settings.rb
Running in fix mode...
Root directory: /path/to/openproject
Copyright file: /path/to/openproject/COPYRIGHT_short

Fixing: app/models/user_settings.rb
```

## Integration with Development Workflow

### Pre-commit Hook

You can integrate the copyright checker into your git workflow:

```bash
#!/bin/bash
# .git/hooks/pre-commit
if ! script/copyright; then
    echo "Copyright headers are missing or incorrect. Run 'script/copyright --fix' to fix them."
    exit 1
fi
```

### CI/CD Pipeline

Use in continuous integration to ensure all files have proper copyright headers:

```yaml
# Example GitHub Actions workflow
- name: Check copyright headers
  run: script/copyright
```

## Performance

The Ruby script is significantly faster than the rake equivalent:

- Small directories (5-10 files): ~30ms
- Large directories (1000+ files): ~10-15s
- Full project scan: ~30-60s

Compare this to the rake task which needs to load the entire Rails environment first.

## Migration from Rake Tasks

The script replaces these rake tasks:

| Old Rake Task | New Script Command |
|---------------|-------------------|
| `rake copyright:update` | `script/copyright --fix` |
| `rake copyright:update[path]` | `script/copyright --fix path` |
| `rake copyright:update_rb[path]` | `script/copyright --fix path` (auto-detects Ruby files) |

The script automatically handles all file types that the rake tasks handled individually.