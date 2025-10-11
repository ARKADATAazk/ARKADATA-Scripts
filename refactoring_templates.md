# Refactoring Guide

## Structure Pattern: Feature → Standalone App

```
ReArkitekt/features/FEATURE/ → AppName/
  ├── app/          # controllers, gui, main state
  ├── engine/       # processing, core.lua (not engine.lua!), bridges, playback
  ├── storage/      # state, persistence, undo
  └── widgets/      # UI components
```

## Mapping Template

```
# App
ReArkitekt.features.FEATURE.controller → AppName.app.controller

# Engine (directories first!)
ReArkitekt.features.FEATURE.engine → AppName.engine
ReArkitekt.features.FEATURE.coordinator_bridge → AppName.engine.coordinator_bridge
ReArkitekt.features.FEATURE.playback → AppName.engine.playback

# Storage
ReArkitekt.features.FEATURE.state → AppName.storage.state
ReArkitekt.features.FEATURE.undo_bridge → AppName.storage.undo_bridge

# Widgets (shared from gui/)
ReArkitekt.gui.widgets.WIDGET → AppName.widgets.WIDGET

# Widgets (feature-specific)
ReArkitekt.features.FEATURE.controls_widget → AppName.widgets.controls.controls_widget
```

## Rules

1. **Never** file + directory with same name (`engine.lua` + `engine/` ❌)
2. **Longest paths first** in mappings
3. Always ask for file tree before generating mappings

## When User Says: "Refactor X to Y"

1. Ask: "Show me file structure for X"
2. Check: file/dir conflicts, nested paths
3. Generate: category-grouped mappings (app, engine, storage, widgets)
4. Validate: preview first
