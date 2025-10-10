# PROJECT FLOW: ARKADATA Scripts
Generated: 2025-10-10 20:52:51
Root: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts

## Project Structure

```
└── ReArkitekt/
    ├── Region_Playlist/
    │   ├── app/
    │   │   ├── config.lua         # (200 lines)
    │   │   ├── gui.lua         # (771 lines)
    │   │   ├── shortcuts.lua         # (82 lines)
    │   │   ├── state.lua         # (593 lines)
    │   │   └── status.lua         # (58 lines)
    │   └── ARK_Region_Playlist.lua         # (51 lines)
    ├── app/
    │   ├── config.lua         # (85 lines)
    │   ├── icon.lua         # (123 lines)
    │   ├── runtime.lua         # (68 lines)
    │   ├── shell.lua         # (247 lines)
    │   ├── titlebar.lua         # (418 lines)
    │   └── window.lua         # (557 lines)
    ├── core/
    │   ├── colors.lua         # (514 lines)
    │   ├── json.lua         # (120 lines)
    │   ├── lifecycle.lua         # (80 lines)
    │   ├── math.lua         # (51 lines)
    │   ├── settings.lua         # (118 lines)
    │   └── undo_manager.lua         # (69 lines)
    ├── features/
    │   └── region_playlist/
    │       ├── engine/
    │       │   ├── engine.lua         # (167 lines)
    │       │   ├── quantize.lua         # (336 lines)
    │       │   ├── state.lua         # (147 lines)
    │       │   ├── transitions.lua         # (210 lines)
    │       │   └── transport.lua         # (238 lines)
    │       ├── controls_widget.lua         # (150 lines)
    │       ├── coordinator_bridge.lua         # (170 lines)
    │       ├── engine.lua         # (672 lines)
    │       ├── playback.lua         # (102 lines)
    │       ├── playlist_controller.lua         # (362 lines)
    │       ├── shortcuts.lua         # (82 lines)
    │       ├── state.lua         # (151 lines)
    │       └── undo_bridge.lua         # (90 lines)
    ├── gui/
    │   ├── fx/
    │   │   ├── animation/
    │   │   │   ├── rect_track.lua         # (135 lines)
    │   │   │   └── track.lua         # (52 lines)
    │   │   ├── animations/
    │   │   │   ├── destroy.lua         # (148 lines)
    │   │   │   └── spawn.lua         # (57 lines)
    │   │   ├── dnd/
    │   │   │   ├── config.lua         # (90 lines)
    │   │   │   ├── drag_indicator.lua         # (218 lines)
    │   │   │   └── drop_indicator.lua         # (112 lines)
    │   │   ├── easing.lua         # (93 lines)
    │   │   ├── effects.lua         # (53 lines)
    │   │   ├── marching_ants.lua         # (141 lines)
    │   │   ├── tile_fx.lua         # (169 lines)
    │   │   ├── tile_fx_config.lua         # (78 lines)
    │   │   └── tile_motion.lua         # (57 lines)
    │   ├── systems/
    │   │   ├── height_stabilizer.lua         # (73 lines)
    │   │   ├── playback_manager.lua         # (21 lines)
    │   │   ├── reorder.lua         # (126 lines)
    │   │   ├── responsive_grid.lua         # (228 lines)
    │   │   ├── selection.lua         # (141 lines)
    │   │   └── tile_utilities.lua         # (48 lines)
    │   ├── widgets/
    │   │   ├── chip_list/
    │   │   │   └── list.lua         # (302 lines)
    │   │   ├── component/
    │   │   │   └── chip.lua         # (243 lines)
    │   │   ├── controls/
    │   │   │   ├── context_menu.lua         # (105 lines)
    │   │   │   ├── dropdown.lua         # (355 lines)
    │   │   │   ├── scrollbar.lua         # (238 lines)
    │   │   │   └── tooltip.lua         # (128 lines)
    │   │   ├── displays/
    │   │   │   └── status_pad.lua         # (191 lines)
    │   │   ├── grid/
    │   │   │   ├── animation.lua         # (100 lines)
    │   │   │   ├── core.lua         # (549 lines)
    │   │   │   ├── dnd_state.lua         # (112 lines)
    │   │   │   ├── drop_zones.lua         # (276 lines)
    │   │   │   ├── grid_bridge.lua         # (218 lines)
    │   │   │   ├── input.lua         # (236 lines)
    │   │   │   ├── layout.lua         # (100 lines)
    │   │   │   └── rendering.lua         # (89 lines)
    │   │   ├── navigation/
    │   │   │   └── menutabs.lua         # (268 lines)
    │   │   ├── overlay/
    │   │   │   ├── config.lua         # (138 lines)
    │   │   │   ├── manager.lua         # (163 lines)
    │   │   │   └── sheet.lua         # (124 lines)
    │   │   ├── package_tiles/
    │   │   │   ├── grid.lua         # (226 lines)
    │   │   │   ├── micromanage.lua         # (126 lines)
    │   │   │   └── renderer.lua         # (233 lines)
    │   │   ├── region_tiles/
    │   │   │   ├── renderers/
    │   │   │   │   ├── active.lua         # (186 lines)
    │   │   │   │   ├── base.lua         # (186 lines)
    │   │   │   │   └── pool.lua         # (147 lines)
    │   │   │   ├── active_grid_factory.lua         # (212 lines)
    │   │   │   ├── config.lua         # (295 lines)
    │   │   │   ├── coordinator.lua         # (512 lines)
    │   │   │   ├── coordinator_render.lua         # (189 lines)
    │   │   │   ├── pool_grid_factory.lua         # (185 lines)
    │   │   │   └── selector.lua         # (97 lines)
    │   │   ├── sliders/
    │   │   │   └── hue.lua         # (275 lines)
    │   │   ├── tiles_container/
    │   │   │   ├── modes/
    │   │   │   │   ├── search_sort.lua         # (251 lines)
    │   │   │   │   ├── tabs.lua         # (478 lines)
    │   │   │   │   └── temp_search.lua         # (1 lines)
    │   │   │   ├── background.lua         # (60 lines)
    │   │   │   ├── content.lua         # (43 lines)
    │   │   │   ├── header.lua         # (41 lines)
    │   │   │   ├── init.lua         # (547 lines)
    │   │   │   └── tab_animator.lua         # (106 lines)
    │   │   ├── transport/
    │   │   │   ├── transport_container.lua         # (136 lines)
    │   │   │   └── transport_fx.lua         # (106 lines)
    │   │   ├── selection_rectangle.lua         # (98 lines)
    │   │   ├── status_bar.lua         # (329 lines)
    │   │   └── tiles_container_old.lua         # (752 lines)
    │   ├── draw.lua         # (113 lines)
    │   ├── images.lua         # (284 lines)
    │   └── style.lua         # (173 lines)
    ├── input/
    │   └── wheel_guard.lua         # (42 lines)
    ├── reaper/
    │   ├── regions.lua         # (82 lines)
    │   ├── timing.lua         # (112 lines)
    │   └── transport.lua         # (96 lines)
    ├── demo.lua         # (271 lines)
    ├── demo2.lua         # (182 lines)
    ├── demo3.lua         # (120 lines)
    ├── demo_modal_overlay.lua         # (423 lines)
    └── widget_demo.lua         # (222 lines)
```

## Overview
- **Total Files**: 107
- **Total Lines**: 20,994
- **Code Lines**: 16,535
- **Public Functions**: 309
- **Classes**: 77
- **Modules**: 234

## Folder Structure
### ReArkitekt/
  - Files: 107
  - Lines: 16,535
  - Exports: 309

## Execution Flow Patterns

### Entry Points (Not Imported by Others)
- **`ReArkitekt/app/config.lua`**
- **`ReArkitekt/gui/images.lua`**
- **`ReArkitekt/core/settings.lua`**
  → Imports: json
- **`ReArkitekt/gui/widgets/overlay/manager.lua`**
  → Imports: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.style (+1 more)
- **`ReArkitekt/app/icon.lua`**
- **`ReArkitekt/gui/widgets/navigation/menutabs.lua`**
- **`ReArkitekt/features/region_playlist/engine.lua`**
  → Imports: ReArkitekt.reaper.regions, ReArkitekt.reaper.transport
- **`ReArkitekt/gui/widgets/tiles_container/modes/temp_search.lua`**
- **`ReArkitekt/gui/widgets/tiles_container/init.lua`**
  → Imports: ReArkitekt.gui.widgets.tiles_container.header, ReArkitekt.gui.widgets.tiles_container.content, ReArkitekt.gui.widgets.tiles_container.background (+3 more)
- **`ReArkitekt/demo_modal_overlay.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.overlay.sheet, ReArkitekt.gui.widgets.chip_list.list (+1 more)

### Orchestration Pattern
**`ReArkitekt/gui/widgets/grid/core.lua`** composes 13 modules:
  layout + rect_track + colors + selection + selection_rectangle (+8 more)
**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** composes 11 modules:
  config + coordinator_render + draw + colors + tile_motion (+6 more)
**`ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`** composes 7 modules:
  draw + colors + tile_fx + tile_fx_config + marching_ants (+2 more)
**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** composes 6 modules:
  core + colors + tile_motion + renderer + micromanage (+1 more)
**`ReArkitekt/gui/widgets/tiles_container/init.lua`** composes 6 modules:
  header + content + background + tab_animator + scrollbar (+1 more)

## Module API Surface

### `ReArkitekt/Region_Playlist/app/config.lua`
> Region_Playlist/app/config.lua

**Modules**: `M`
**Public API**:
  - `M.get_region_tiles_config(layout_mode)`

### `ReArkitekt/Region_Playlist/app/gui.lua`
> Region_Playlist/app/gui.lua

**Modules**: `M, GUI, filtered`
**Classes**: `GUI, M` (stateful objects)
**Public API**:
  - `M.create(State, Config, settings)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.core.colors, Region_Playlist.app.shortcuts, ReArkitekt.features.region_playlist.playlist_controller, ReArkitekt.gui.widgets.transport.transport_container, (+1 more)`

### `ReArkitekt/Region_Playlist/app/shortcuts.lua`
> Region_Playlist/app/shortcuts.lua

**Modules**: `M`
**Public API**:
  - `M.handle_keyboard_shortcuts(ctx, state, region_tiles)`
**Dependencies**: `Region_Playlist.app.state`

### `ReArkitekt/Region_Playlist/app/state.lua`
> Region_Playlist/app/state.lua

**Modules**: `M, tabs, result, reversed, all_deps, visited, pool_playlists, filtered, reversed, new_path, path_array`
**Public API**:
  - `M.initialize(settings)`
  - `M.load_project_state()`
  - `M.reload_project_data()`
  - `M.get_active_playlist()`
  - `M.get_playlist_by_id(playlist_id)`
  - `M.get_tabs()`
  - `M.refresh_regions()`
  - `M.sync_playlist_to_engine()`
  - `M.persist()`
  - `M.persist_ui_prefs()`
**Private Functions**: 9 helpers
**Dependencies**: `ReArkitekt.features.region_playlist.coordinator_bridge, ReArkitekt.features.region_playlist.state, ReArkitekt.core.undo_manager, ReArkitekt.features.region_playlist.undo_bridge, ReArkitekt.core.colors`

### `ReArkitekt/Region_Playlist/app/status.lua`
> Region_Playlist/app/status.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(State, Style)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.status_bar`

### `ReArkitekt/app/config.lua`
> ReArkitekt/app/config.lua

**Modules**: `M, keys`
**Public API**:
  - `M.get_defaults()`
  - `M.get(path)`

### `ReArkitekt/app/icon.lua`
> ReArkitekt/app/icon.lua

**Modules**: `M`
**Public API**:
  - `M.draw_rearkitekt(ctx, x, y, size, color)`
  - `M.draw_rearkitekt_v2(ctx, x, y, size, color)`
  - `M.draw_simple_a(ctx, x, y, size, color)`

### `ReArkitekt/app/runtime.lua`
> ReArkitekt/app/runtime.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/app/shell.lua`
> ReArkitekt/app/shell.lua

**Modules**: `M, DEFAULTS`
**Public API**:
  - `M.run(opts)`
**Private Functions**: 4 helpers
**Dependencies**: `ReArkitekt.app.runtime, ReArkitekt.app.window`

### `ReArkitekt/app/titlebar.lua`
> ReArkitekt/app/titlebar.lua

**Modules**: `M, DEFAULTS`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/app/window.lua`
> ReArkitekt/app/window.lua

**Modules**: `M, DEFAULTS`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/core/colors.lua`
> ReArkitekt/core/colors.lua

**Modules**: `M`
**Public API**:
  - `M.rgba_to_components(color)`
  - `M.components_to_rgba(r, g, b, a)`
  - `M.with_alpha(color, alpha)`
  - `M.adjust_brightness(color, factor)`
  - `M.desaturate(color, amount)`
  - `M.saturate(color, amount)`
  - `M.luminance(color)`
  - `M.lerp_component(a, b, t)`
  - `M.lerp(color_a, color_b, t)`
  - `M.auto_text_color(bg_color)`

### `ReArkitekt/core/json.lua`
> core/json.lua - tiny JSON encode/decode (UTF-8, numbers, strings, booleans, nil, arrays, objects)

**Modules**: `M, out, obj, arr`
**Public API**:
  - `M.encode(t)`
  - `M.decode(str)`
**Private Functions**: 5 helpers

### `ReArkitekt/core/lifecycle.lua`
> core/lifecycle.lua

**Modules**: `M, Group`
**Classes**: `Group, M` (stateful objects)
**Public API**:
  - `M.new()` → Instance

### `ReArkitekt/core/math.lua`
> ReArkitekt/core/math.lua

**Modules**: `M`
**Public API**:
  - `M.lerp(a, b, t)`
  - `M.clamp(value, min, max)`
  - `M.remap(value, in_min, in_max, out_min, out_max)`
  - `M.snap(value, step)`
  - `M.smoothdamp(current, target, velocity, smoothtime, maxspeed, dt)`
  - `M.approximately(a, b, epsilon)`

### `ReArkitekt/core/settings.lua`
> core/settings.lua - debounced settings store in /cache/settings.json

**Modules**: `Settings, out, M, t`
**Classes**: `Settings` (stateful objects)
**Public API**:
  - `M.open(cache_dir, filename)`
**Private Functions**: 7 helpers
**Dependencies**: `json`

### `ReArkitekt/core/undo_manager.lua`
> ReArkitekt/core/undo_manager.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/demo.lua`
> ReArkitekt/demo.lua

**Modules**: `result`
**Private Functions**: 8 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage, ReArkitekt.gui.widgets.tiles_container, ReArkitekt.gui.widgets.selection_rectangle`

### `ReArkitekt/demo3.lua`
> demo3.lua – Status Pads Widget Demo (Reworked)

**Modules**: `pads`
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.displays.status_pad, ReArkitekt.gui.widgets.status_bar`

### `ReArkitekt/demo_modal_overlay.lua`
> ReArkitekt/demo_modal_overlay.lua

**Modules**: `selected_tag_items`
**Private Functions**: 7 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.overlay.sheet, ReArkitekt.gui.widgets.chip_list.list, ReArkitekt.gui.widgets.overlay.config`

### `ReArkitekt/features/region_playlist/controls_widget.lua`
> ReArkitekt/features/region_playlist/controls_widget.lua

**Modules**: `M`
**Public API**:
  - `M.draw_transport_controls(ctx, bridge, x, y)`
  - `M.draw_quantize_selector(ctx, bridge, x, y, width)`
  - `M.draw_playback_info(ctx, bridge, x, y, width)`
  - `M.draw_complete_controls(ctx, bridge, x, y, available_width)`

### `ReArkitekt/features/region_playlist/coordinator_bridge.lua`
> ReArkitekt/features/region_playlist/coordinator_bridge.lua

**Modules**: `M, order, regions`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(opts)` → Instance
**Dependencies**: `ReArkitekt.features.region_playlist.engine.engine, ReArkitekt.features.region_playlist.playback, ReArkitekt.features.region_playlist.state`

### `ReArkitekt/features/region_playlist/engine.lua`
> ReArkitekt/features/region_playlist/engine.lua

**Modules**: `M, Engine`
**Classes**: `Engine, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Private Functions**: 7 helpers
**Dependencies**: `ReArkitekt.reaper.regions, ReArkitekt.reaper.transport`

### `ReArkitekt/features/region_playlist/engine/engine.lua`
> ReArkitekt/features/region_playlist/engine/engine.lua

**Modules**: `M, Engine`
**Classes**: `Engine, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.features.region_playlist.engine.state, ReArkitekt.features.region_playlist.engine.transport, ReArkitekt.features.region_playlist.engine.transitions, ReArkitekt.features.region_playlist.engine.quantize`

### `ReArkitekt/features/region_playlist/engine/quantize.lua`
> ReArkitekt/features/region_playlist/engine/quantize.lua

**Modules**: `M, Quantize`
**Classes**: `Quantize, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/features/region_playlist/engine/state.lua`
> ReArkitekt/features/region_playlist/engine/state.lua

**Modules**: `M, State`
**Classes**: `State, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.reaper.regions, ReArkitekt.reaper.transport`

### `ReArkitekt/features/region_playlist/engine/transitions.lua`
> ReArkitekt/features/region_playlist/engine/transitions.lua

**Modules**: `M, Transitions`
**Classes**: `Transitions, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/features/region_playlist/engine/transport.lua`
> ReArkitekt/features/region_playlist/engine/transport.lua

**Modules**: `M, Transport`
**Classes**: `Transport, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/features/region_playlist/playback.lua`
> ReArkitekt/features/region_playlist/playback.lua

**Modules**: `M, Playback`
**Classes**: `Playback, M` (stateful objects)
**Public API**:
  - `M.new(engine, opts)` → Instance
**Dependencies**: `ReArkitekt.reaper.transport`

### `ReArkitekt/features/region_playlist/playlist_controller.lua`
> ReArkitekt/features/region_playlist/playlist_controller.lua

**Modules**: `M, Controller, keys, keys, keys_set, new_items, keys_set, keys_set`
**Classes**: `Controller, M` (stateful objects)
**Public API**:
  - `M.new(state_module, settings, undo_manager)` → Instance
**Dependencies**: `ReArkitekt.features.region_playlist.state`

### `ReArkitekt/features/region_playlist/shortcuts.lua`
> Region_Playlist/app/shortcuts.lua

**Modules**: `M`
**Public API**:
  - `M.handle_keyboard_shortcuts(ctx, state, region_tiles)`
**Dependencies**: `Region_Playlist.app.state`

### `ReArkitekt/features/region_playlist/state.lua`
> ReArkitekt/features/region_playlist/state.lua

**Modules**: `M, default_items`
**Public API**:
  - `M.save_playlists(playlists, proj)`
  - `M.load_playlists(proj)`
  - `M.save_active_playlist(playlist_id, proj)`
  - `M.load_active_playlist(proj)`
  - `M.save_settings(settings, proj)`
  - `M.load_settings(proj)`
  - `M.clear_all(proj)`
  - `M.get_or_create_default_playlist(playlists, regions)` → Instance
  - `M.generate_chip_color()`
**Dependencies**: `ReArkitekt.core.json, ReArkitekt.core.colors`

### `ReArkitekt/features/region_playlist/undo_bridge.lua`
> ReArkitekt/features/region_playlist/undo_bridge.lua

**Modules**: `M, restored_playlists`
**Public API**:
  - `M.capture_snapshot(playlists, active_playlist_id)`
  - `M.restore_snapshot(snapshot, region_index)`
  - `M.should_capture(old_playlists, new_playlists)`

### `ReArkitekt/gui/draw.lua`
> ReArkitekt/gui/draw.lua

**Modules**: `M`
**Public API**:
  - `M.snap(x)`
  - `M.centered_text(ctx, text, x1, y1, x2, y2, color)`
  - `M.rect(dl, x1, y1, x2, y2, color, rounding, thickness)`
  - `M.rect_filled(dl, x1, y1, x2, y2, color, rounding)`
  - `M.line(dl, x1, y1, x2, y2, color, thickness)`
  - `M.text(dl, x, y, color, text)`
  - `M.text_right(ctx, x, y, color, text)`
  - `M.point_in_rect(x, y, x1, y1, x2, y2)`
  - `M.rects_intersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)`
  - `M.text_clipped(ctx, text, x, y, max_width, color)`

### `ReArkitekt/gui/fx/animation/rect_track.lua`
> ReArkitekt/gui/fx/animation/rect_track.lua

**Modules**: `M, RectTrack`
**Classes**: `RectTrack, M` (stateful objects)
**Public API**:
  - `M.new(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)` → Instance
**Dependencies**: `ReArkitekt.core.math`

### `ReArkitekt/gui/fx/animation/track.lua`
> ReArkitekt/gui/fx/animation/track.lua

**Modules**: `M, Track`
**Classes**: `Track, M` (stateful objects)
**Public API**:
  - `M.new(initial_value, speed)` → Instance
**Dependencies**: `ReArkitekt.core.math`

### `ReArkitekt/gui/fx/animations/destroy.lua`
> ReArkitekt/gui/fx/animations/destroy.lua

**Modules**: `M, DestroyAnim, completed`
**Classes**: `DestroyAnim, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.fx.easing`

### `ReArkitekt/gui/fx/animations/spawn.lua`
> ReArkitekt/gui/fx/animations/spawn.lua

**Modules**: `M, SpawnTracker`
**Classes**: `SpawnTracker, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.fx.easing`

### `ReArkitekt/gui/fx/dnd/config.lua`
> ReArkitekt/gui/fx/dnd/config.lua

**Modules**: `M`
**Public API**:
  - `M.get_mode_config(config, is_copy, is_delete)`

### `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
> ReArkitekt/gui/fx/dnd/drag_indicator.lua

**Modules**: `M`
**Public API**:
  - `M.draw_badge(ctx, dl, mx, my, count, config, is_copy_mode, is_delete_mode)`
  - `M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)`
**Private Functions**: 5 helpers
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.dnd.config`

### `ReArkitekt/gui/fx/dnd/drop_indicator.lua`
> ReArkitekt/gui/fx/dnd/drop_indicator.lua

**Modules**: `M`
**Public API**:
  - `M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)`
  - `M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)`
  - `M.draw(ctx, dl, config, is_copy_mode, orientation, ...)`
**Dependencies**: `ReArkitekt.gui.fx.dnd.config`

### `ReArkitekt/gui/fx/easing.lua`
> ReArkitekt/gui/fx/easing.lua

**Modules**: `M`
**Public API**:
  - `M.linear(t)`
  - `M.ease_in_quad(t)`
  - `M.ease_out_quad(t)`
  - `M.ease_in_out_quad(t)`
  - `M.ease_in_cubic(t)`
  - `M.ease_out_cubic(t)`
  - `M.ease_in_out_cubic(t)`
  - `M.ease_in_sine(t)`
  - `M.ease_out_sine(t)`
  - `M.ease_in_out_sine(t)`

### `ReArkitekt/gui/fx/effects.lua`
> ReArkitekt/gui/fx/effects.lua

**Modules**: `M`
**Public API**:
  - `M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)`
  - `M.soft_glow(dl, x1, y1, x2, y2, color, intensity, radius)`
  - `M.pulse_glow(dl, x1, y1, x2, y2, color, time, speed, radius)`

### `ReArkitekt/gui/fx/marching_ants.lua`
> ReArkitekt/gui/fx/marching_ants.lua

**Modules**: `M`
**Public API**:
  - `M.draw(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)`

### `ReArkitekt/gui/fx/tile_fx.lua`
> ReArkitekt/gui/fx/tile_fx.lua

**Modules**: `M`
**Public API**:
  - `M.render_base_fill(dl, x1, y1, x2, y2, rounding)`
  - `M.render_color_fill(dl, x1, y1, x2, y2, base_color, opacity, saturation, brightness, rounding)`
  - `M.render_gradient(dl, x1, y1, x2, y2, base_color, intensity, opacity, rounding)`
  - `M.render_specular(dl, x1, y1, x2, y2, base_color, strength, coverage, rounding)`
  - `M.render_inner_shadow(dl, x1, y1, x2, y2, strength, rounding)`
  - `M.render_playback_progress(dl, x1, y1, x2, y2, base_color, progress, fade_alpha, rounding)`
  - `M.render_border(dl, x1, y1, x2, y2, base_color, saturation, brightness, opacity, thickness, rounding, is_selected, glow_strength, glow_layers)`
  - `M.render_complete(dl, x1, y1, x2, y2, base_color, config, is_selected, hover_factor, playback_progress, playback_fade)`
**Dependencies**: `ReArkitekt.core.colors`

### `ReArkitekt/gui/fx/tile_fx_config.lua`
> ReArkitekt/gui/fx/tile_fx_config.lua

**Modules**: `M, config`
**Public API**:
  - `M.get()`
  - `M.override(overrides)`

### `ReArkitekt/gui/fx/tile_motion.lua`
> ReArkitekt/gui/fx/tile_motion.lua

**Modules**: `M, TileAnimator`
**Classes**: `TileAnimator, M` (stateful objects)
**Public API**:
  - `M.new(default_speed)` → Instance
**Dependencies**: `ReArkitekt.gui.fx.animation.track`

### `ReArkitekt/gui/images.lua`
> core/image_cache.lua

**Modules**: `M, Cache`
**Classes**: `Cache, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Private Functions**: 9 helpers

## State Ownership

### Stateful Modules (Classes/Objects)
- **`runtime.lua`**: M
- **`titlebar.lua`**: M
- **`window.lua`**: M
- **`lifecycle.lua`**: Group, M
- **`settings.lua`**: Settings
- **`undo_manager.lua`**: M
- **`coordinator_bridge.lua`**: M
- **`engine.lua`**: Engine, M
- **`quantize.lua`**: Quantize, M
- **`state.lua`**: State, M
- ... and 35 more

### Stateless Modules (Pure Functions)
- **53** stateless modules
- **32** with no dependencies (pure utility modules)

## Integration Essentials

### Module Creators
- `M.new(opts)` in `runtime.lua`
- `M.new(opts)` in `titlebar.lua`
- `M.new(opts)` in `window.lua`
- `M.new()` in `lifecycle.lua`
- `M.new(opts)` in `undo_manager.lua`
- `M.create(opts)` in `coordinator_bridge.lua`
- `M.new(opts)` in `engine.lua`
- `M.new(opts)` in `quantize.lua`
- ... and 41 more

### Callback-Based APIs
- `M.find_drop_target()` expects: key_fn
- `M.find_external_drop_target()` expects: key_fn
- `Sheet.render()` expects: content_fn
- `M.render()` expects: on_repeat_cycle
- `M.render_region()` expects: on_repeat_cycle
- ... and 7 more

## Module Classification

**Pure Modules** (no dependencies): 51
  - `ReArkitekt/app/config.lua`
  - `ReArkitekt/app/icon.lua`
  - `ReArkitekt/app/runtime.lua`
  - `ReArkitekt/app/titlebar.lua`
  - `ReArkitekt/app/window.lua`
  - ... and 46 more

**Class Modules** (OOP with metatables): 45
  - `runtime.lua`: M
  - `titlebar.lua`: M
  - `window.lua`: M
  - `lifecycle.lua`: Group, M
  - `settings.lua`: Settings
  - ... and 40 more

## Top 10 Largest Files

1. `ReArkitekt/Region_Playlist/app/gui.lua` (771 lines)
2. `ReArkitekt/gui/widgets/tiles_container_old.lua` (752 lines)
3. `ReArkitekt/features/region_playlist/engine.lua` (672 lines)
4. `ReArkitekt/Region_Playlist/app/state.lua` (593 lines)
5. `ReArkitekt/app/window.lua` (557 lines)
6. `ReArkitekt/gui/widgets/grid/core.lua` (549 lines)
7. `ReArkitekt/gui/widgets/tiles_container/init.lua` (547 lines)
8. `ReArkitekt/core/colors.lua` (514 lines)
9. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua` (512 lines)
10. `ReArkitekt/gui/widgets/tiles_container/modes/tabs.lua` (478 lines)

## Dependency Analysis

### Forward Dependencies (What Each File Imports)

**`ReArkitekt/gui/widgets/grid/core.lua`** imports 13 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/animation/rect_track.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/dnd/drop_indicator.lua`
  → `ReArkitekt/gui/systems/selection.lua`
  → `ReArkitekt/gui/widgets/grid/animation.lua`
  → `ReArkitekt/gui/widgets/grid/dnd_state.lua`
  → ... and 5 more

**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** imports 10 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/systems/height_stabilizer.lua`
  → `ReArkitekt/gui/widgets/grid/grid_bridge.lua`
  → `ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`
  → `ReArkitekt/gui/widgets/region_tiles/config.lua`
  → `ReArkitekt/gui/widgets/region_tiles/coordinator_render.lua`
  → ... and 2 more

**`ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`** imports 7 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`
  → `ReArkitekt/gui/widgets/component/chip.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** imports 6 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/systems/height_stabilizer.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/gui/widgets/tiles_container/init.lua`** imports 6 modules:
  → `ReArkitekt/gui/widgets/controls/scrollbar.lua`
  → `ReArkitekt/gui/widgets/tiles_container/background.lua`
  → `ReArkitekt/gui/widgets/tiles_container/content.lua`
  → `ReArkitekt/gui/widgets/tiles_container/header.lua`
  → `ReArkitekt/gui/widgets/tiles_container/modes/tabs.lua`
  → `ReArkitekt/gui/widgets/tiles_container/tab_animator.lua`

**`ReArkitekt/Region_Playlist/app/gui.lua`** imports 6 modules:
  → `ReArkitekt/Region_Playlist/app/shortcuts.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/features/region_playlist/playlist_controller.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  → `ReArkitekt/gui/widgets/transport/transport_container.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** imports 5 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/playback_manager.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** imports 5 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`

**`ReArkitekt/Region_Playlist/app/state.lua`** imports 5 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/core/undo_manager.lua`
  → `ReArkitekt/features/region_playlist/coordinator_bridge.lua`
  → `ReArkitekt/features/region_playlist/state.lua`
  → `ReArkitekt/features/region_playlist/undo_bridge.lua`

**`ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`** imports 5 modules:
  → `ReArkitekt/Region_Playlist/app/config.lua`
  → `ReArkitekt/Region_Playlist/app/gui.lua`
  → `ReArkitekt/Region_Playlist/app/state.lua`
  → `ReArkitekt/Region_Playlist/app/status.lua`
  → `ReArkitekt/app/shell.lua`

**`ReArkitekt/demo.lua`** imports 4 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`

**`ReArkitekt/demo_modal_overlay.lua`** imports 4 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/chip_list/list.lua`
  → `ReArkitekt/gui/widgets/overlay/config.lua`
  → `ReArkitekt/gui/widgets/overlay/sheet.lua`

**`ReArkitekt/features/region_playlist/engine/engine.lua`** imports 4 modules:
  → `ReArkitekt/features/region_playlist/engine/quantize.lua`
  → `ReArkitekt/features/region_playlist/engine/state.lua`
  → `ReArkitekt/features/region_playlist/engine/transitions.lua`
  → `ReArkitekt/features/region_playlist/engine/transport.lua`

**`ReArkitekt/gui/widgets/component/chip.lua`** imports 4 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`

**`ReArkitekt/gui/widgets/displays/status_pad.lua`** imports 4 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`

**`ReArkitekt/gui/widgets/overlay/manager.lua`** imports 4 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/style.lua`
  → `ReArkitekt/gui/widgets/overlay/config.lua`

**`ReArkitekt/gui/widgets/overlay/sheet.lua`** imports 4 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/style.lua`
  → `ReArkitekt/gui/widgets/overlay/config.lua`

**`ReArkitekt/gui/widgets/region_tiles/coordinator_render.lua`** imports 4 modules:
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/systems/responsive_grid.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/demo3.lua`** imports 3 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/displays/status_pad.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`

**`ReArkitekt/features/region_playlist/coordinator_bridge.lua`** imports 3 modules:
  → `ReArkitekt/features/region_playlist/engine/engine.lua`
  → `ReArkitekt/features/region_playlist/playback.lua`
  → `ReArkitekt/features/region_playlist/state.lua`

### Reverse Dependencies (What Imports Each File)

**`ReArkitekt/core/colors.lua`** is imported by 19 files:
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/app/state.lua`
  ← `ReArkitekt/features/region_playlist/state.lua`
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/fx/tile_fx.lua`
  ← `ReArkitekt/gui/widgets/component/chip.lua`
  ← `ReArkitekt/gui/widgets/displays/status_pad.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← ... and 11 more

**`ReArkitekt/gui/draw.lua`** is imported by 16 files:
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/widgets/component/chip.lua`
  ← `ReArkitekt/gui/widgets/displays/status_pad.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/grid/input.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/overlay/manager.lua`
  ← `ReArkitekt/gui/widgets/overlay/sheet.lua`
  ← ... and 8 more

**`ReArkitekt/app/shell.lua`** is imported by 6 files:
  ← `ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/demo3.lua`
  ← `ReArkitekt/demo_modal_overlay.lua`
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/fx/tile_fx_config.lua`** is imported by 5 files:
  ← `ReArkitekt/gui/widgets/component/chip.lua`
  ← `ReArkitekt/gui/widgets/displays/status_pad.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/fx/tile_motion.lua`** is imported by 4 files:
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`

**`ReArkitekt/features/region_playlist/state.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/app/state.lua`
  ← `ReArkitekt/features/region_playlist/coordinator_bridge.lua`
  ← `ReArkitekt/features/region_playlist/playlist_controller.lua`

**`ReArkitekt/gui/fx/easing.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/fx/animations/destroy.lua`
  ← `ReArkitekt/gui/fx/animations/spawn.lua`
  ← `ReArkitekt/gui/widgets/tiles_container/tab_animator.lua`

**`ReArkitekt/gui/fx/marching_ants.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`

**`ReArkitekt/gui/fx/tile_fx.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/component/chip.lua`
  ← `ReArkitekt/gui/widgets/displays/status_pad.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`

**`ReArkitekt/gui/widgets/component/chip.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/chip_list/list.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/gui/widgets/tiles_container/modes/tabs.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua`

**`ReArkitekt/gui/widgets/overlay/config.lua`** is imported by 3 files:
  ← `ReArkitekt/demo_modal_overlay.lua`
  ← `ReArkitekt/gui/widgets/overlay/manager.lua`
  ← `ReArkitekt/gui/widgets/overlay/sheet.lua`

**`ReArkitekt/reaper/transport.lua`** is imported by 3 files:
  ← `ReArkitekt/features/region_playlist/engine.lua`
  ← `ReArkitekt/features/region_playlist/engine/state.lua`
  ← `ReArkitekt/features/region_playlist/playback.lua`

**`ReArkitekt/Region_Playlist/app/state.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`
  ← `ReArkitekt/Region_Playlist/app/shortcuts.lua`
  ← `ReArkitekt/features/region_playlist/shortcuts.lua`

**`ReArkitekt/core/json.lua`** is imported by 2 files:
  ← `ReArkitekt/core/settings.lua`
  ← `ReArkitekt/features/region_playlist/state.lua`

### Circular Dependencies

✓ No circular dependencies detected

### Isolated Files (No Imports or Exports)

- `ReArkitekt/app/config.lua`
- `ReArkitekt/app/icon.lua`
- `ReArkitekt/app/titlebar.lua`
- `ReArkitekt/core/lifecycle.lua`
- `ReArkitekt/features/region_playlist/controls_widget.lua`
- `ReArkitekt/gui/images.lua`
- `ReArkitekt/gui/systems/reorder.lua`
- `ReArkitekt/gui/widgets/navigation/menutabs.lua`
- `ReArkitekt/gui/widgets/tiles_container/modes/temp_search.lua`
- `ReArkitekt/input/wheel_guard.lua`
- `ReArkitekt/reaper/timing.lua`

### Dependency Complexity Ranking

1. `ReArkitekt/core/colors.lua`: 0 imports + 19 importers = 19 total
2. `ReArkitekt/gui/draw.lua`: 0 imports + 16 importers = 16 total
3. `ReArkitekt/gui/widgets/grid/core.lua`: 13 imports + 3 importers = 16 total
4. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`: 10 imports + 1 importers = 11 total
5. `ReArkitekt/gui/widgets/region_tiles/renderers/base.lua`: 7 imports + 2 importers = 9 total
6. `ReArkitekt/app/shell.lua`: 2 imports + 6 importers = 8 total
7. `ReArkitekt/Region_Playlist/app/state.lua`: 5 imports + 3 importers = 8 total
8. `ReArkitekt/gui/widgets/component/chip.lua`: 4 imports + 3 importers = 7 total
9. `ReArkitekt/gui/widgets/package_tiles/grid.lua`: 6 imports + 1 importers = 7 total
10. `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`: 5 imports + 2 importers = 7 total

## Important Constraints

### Object Lifecycle
- Classes use metatable pattern: `ClassName.__index = ClassName`
- Constructor functions typically named `new()` or `create()`
- Always call constructor before using instance methods

### Callback Requirements
- 12 modules use callback patterns for extensibility
- Callbacks enable features like event handling and custom behavior
- Check function signatures for `on_*`, `*_callback`, or `*_handler` parameters
