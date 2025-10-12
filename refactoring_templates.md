# Lua Refactoring Tool

A clean, modern GUI tool for refactoring `require()` paths in Lua projects with file structure management.

## Features

- ✨ Modern GUI using AArkitekt framework
- 🔄 Automatic require path updates across entire projects
- 📁 File and directory creation commands
- 🔀 Automatic file movement based on path mappings
- 💾 Optional backup creation (`.bak` files)
- 📝 Built-in mapping editor with syntax hints
- 📊 Detailed logging and change reports
- 💿 Remembers your last project path
- 🎨 Themed interface with AMEO skin

## Configuration

Settings are automatically saved to:
- **Windows**: `%APPDATA%/AArkitekt/lua_refactor.settings.json`
- **Linux/Mac**: `~/.config/AArkitekt/lua_refactor.settings.json`

The tool remembers:
- Last used project root directory

## Usage

### Running the Tool

```bash
python -m AArkitekt.apps.tools.refactoring.lua
```

### Quick Start

1. **Select Project Root**: Click "Browse..." and select your Lua project folder
   - The path is automatically saved for next time

2. **Paste Mappings**: Copy the mappings I provide and paste them into the text editor

3. **Configure Options**:
   - ✓ "Move files to match new structure" (recommended)
   - ✓ "Create .bak backup files" (recommended for first run)

4. **Execute**: Click "Execute Refactoring" and review the log output

### Command Format

The tool supports three types of commands:

#### 1. Path Mappings
```
old.module.path -> new.module.path
```

#### 2. Create Directories
```
CREATE_DIR: path/to/directory
```

#### 3. Create Files
```
CREATE_FILE: path/to/file.lua
CREATE_FILE: path/to/file.lua | -- Optional initial content
```

**Complete Example:**
```
# Create new directory structure first
CREATE_DIR: Region_Playlist/widgets
CREATE_DIR: Region_Playlist/storage
CREATE_DIR: Region_Playlist/app

# Create stub files
CREATE_FILE: Region_Playlist/__init__.lua | -- Region Playlist module
CREATE_FILE: Region_Playlist/app/controller.lua

# Map old paths to new paths
ReArkitekt.gui.widgets.region_tiles -> Region_Playlist.widgets.region_tiles
ReArkitekt.features.region_playlist.state -> Region_Playlist.storage.state
ReArkitekt.features.region_playlist.playlist_controller -> Region_Playlist.app.controller
```

### Execution Order

The tool processes commands in this order:

1. **Create Directories** - All `CREATE_DIR` commands
2. **Create Files** - All `CREATE_FILE` commands
3. **Move Files** - Based on path mappings (if enabled)
4. **Update require()** - Update all require statements in Lua files
5. **Cleanup** - Remove empty directories (if enabled)

### What It Does

The tool:
1. Creates any specified directories
2. Creates any specified files with optional initial content
3. Recursively finds all `.lua` files in the project
4. Moves files to match new structure (if enabled)
5. Scans for `require()` statements
6. Updates paths based on your mappings
7. Creates backups if enabled
8. Provides detailed change report

### Example Transformation

**Commands:**
```
CREATE_DIR: Region_Playlist/widgets
ReArkitekt.gui.widgets.region_tiles -> Region_Playlist.widgets.region_tiles
```

**Before:**
```lua
local RegionTiles = require("ReArkitekt.gui.widgets.region_tiles.coordinator")
```

**After:**
```lua
local RegionTiles = require("Region_Playlist.widgets.region_tiles.coordinator")
```

## Safety Features

- **Backups**: Creates `.bak` files before modifying (configurable)
- **Preview Mode**: Check what would change before committing
- **Exact Matching**: Only updates exact path matches (no false positives)
- **Thread Safety**: Runs refactoring in background thread (UI stays responsive)
- **Dry Run**: Preview button shows all changes without modifying files

## Tips

- **Test First**: Use Preview mode to see what will happen
- **Use Git**: Commit before refactoring for easy rollback
- **Review Log**: Check the detailed change report before accepting
- **Delete Backups**: After verifying, delete `.bak` files: `find . -name "*.bak" -delete`
- **Create Structure First**: Use `CREATE_DIR` commands to set up your new structure
- **Stub Files**: Use `CREATE_FILE` with initial content for module templates

## File Structure

```
AArkitekt/apps/tools/refactoring/lua/
├── __init__.py                      # Package initialization
├── __main__.py                      # GUI application entry point
├── refactor_engine.py               # Core refactoring logic
├── MAPPINGS_region_playlist.txt     # Example mappings
└── README.md                        # This file
```

## Requirements

- Python 3.7+
- PyQt5
- AArkitekt framework

## License

Part of the AArkitekt framework.