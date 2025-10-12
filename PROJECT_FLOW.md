# PROJECT FLOW: ARKADATA Scripts
Generated: 2025-10-12 17:36:52
Root: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts

## Project Structure

```
└── ReArkitekt/
    ├── ColorPalette/
    │   ├── app/
    │   │   ├── controller.lua         # (234 lines)
    │   │   ├── gui.lua         # (442 lines)
    │   │   └── state.lua         # (272 lines)
    │   ├── widgets/
    │   │   └── color_grid.lua         # (142 lines)
    │   └── ARK_Color_Palette.lua         # (89 lines)
    ├── Region_Playlist/
    │   ├── app/
    │   │   ├── config.lua         # (343 lines)
    │   │   ├── controller.lua         # (362 lines)
    │   │   ├── gui.lua         # (891 lines)
    │   │   ├── shortcuts.lua         # (82 lines)
    │   │   ├── state.lua         # (596 lines)
    │   │   └── status.lua         # (58 lines)
    │   ├── engine/
    │   │   ├── coordinator_bridge.lua         # (170 lines)
    │   │   ├── core.lua         # (167 lines)
    │   │   ├── playback.lua         # (102 lines)
    │   │   ├── quantize.lua         # (336 lines)
    │   │   ├── state.lua         # (147 lines)
    │   │   ├── transitions.lua         # (210 lines)
    │   │   └── transport.lua         # (238 lines)
    │   ├── storage/
    │   │   ├── state.lua         # (151 lines)
    │   │   └── undo_bridge.lua         # (90 lines)
    │   ├── widgets/
    │   │   ├── controls/
    │   │   │   └── controls_widget.lua         # (150 lines)
    │   │   └── region_tiles/
    │   │       ├── renderers/
    │   │       │   ├── active.lua         # (186 lines)
    │   │       │   ├── base.lua         # (186 lines)
    │   │       │   └── pool.lua         # (147 lines)
    │   │       ├── active_grid_factory.lua         # (212 lines)
    │   │       ├── coordinator.lua         # (502 lines)
    │   │       ├── coordinator_render.lua         # (189 lines)
    │   │       ├── pool_grid_factory.lua         # (185 lines)
    │   │       └── selector.lua         # (97 lines)
    │   └── ARK_Region_Playlist.lua         # (51 lines)
    ├── app/
    │   ├── chrome/
    │   │   └── status_bar/
    │   │       ├── config.lua         # (139 lines)
    │   │       ├── init.lua         # (2 lines)
    │   │       └── widget.lua         # (318 lines)
    │   ├── config.lua         # (85 lines)
    │   ├── icon.lua         # (123 lines)
    │   ├── runtime.lua         # (68 lines)
    │   ├── shell.lua         # (255 lines)
    │   ├── titlebar.lua         # (453 lines)
    │   └── window.lua         # (559 lines)
    ├── core/
    │   ├── colors.lua         # (549 lines)
    │   ├── json.lua         # (120 lines)
    │   ├── lifecycle.lua         # (80 lines)
    │   ├── math.lua         # (51 lines)
    │   ├── settings.lua         # (118 lines)
    │   └── undo_manager.lua         # (69 lines)
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
    │   │   │   └── chip.lua         # (332 lines)
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
    │   │   │   ├── manager.lua         # (177 lines)
    │   │   │   └── sheet.lua         # (124 lines)
    │   │   ├── package_tiles/
    │   │   │   ├── grid.lua         # (226 lines)
    │   │   │   ├── micromanage.lua         # (126 lines)
    │   │   │   └── renderer.lua         # (266 lines)
    │   │   ├── panel/
    │   │   │   ├── header/
    │   │   │   │   ├── button.lua         # (104 lines)
    │   │   │   │   ├── dropdown_field.lua         # (78 lines)
    │   │   │   │   ├── init.lua         # (35 lines)
    │   │   │   │   ├── layout.lua         # (297 lines)
    │   │   │   │   ├── search_field.lua         # (118 lines)
    │   │   │   │   ├── separator.lua         # (32 lines)
    │   │   │   │   └── tab_strip.lua         # (730 lines)
    │   │   │   ├── modes/
    │   │   │   │   ├── search_sort.lua         # (224 lines)
    │   │   │   │   ├── tabs.lua         # (646 lines)
    │   │   │   │   └── temp_search.lua         # (1 lines)
    │   │   │   ├── background.lua         # (60 lines)
    │   │   │   ├── config.lua         # (232 lines)
    │   │   │   ├── content.lua         # (43 lines)
    │   │   │   ├── header.lua         # (41 lines)
    │   │   │   ├── init.lua         # (405 lines)
    │   │   │   └── tab_animator.lua         # (106 lines)
    │   │   ├── sliders/
    │   │   │   └── hue.lua         # (275 lines)
    │   │   ├── transport/
    │   │   │   ├── transport_container.lua         # (136 lines)
    │   │   │   └── transport_fx.lua         # (106 lines)
    │   │   ├── selection_rectangle.lua         # (98 lines)
    │   │   └── tiles_container_old.lua         # (752 lines)
    │   ├── draw.lua         # (113 lines)
    │   ├── images.lua         # (284 lines)
    │   └── style.lua         # (145 lines)
    ├── input/
    │   └── wheel_guard.lua         # (42 lines)
    ├── reaper/
    │   ├── regions.lua         # (82 lines)
    │   ├── timing.lua         # (112 lines)
    │   └── transport.lua         # (96 lines)
    ├── demo.lua         # (355 lines)
    ├── demo2.lua         # (182 lines)
    ├── demo3.lua         # (120 lines)
    ├── demo_modal_overlay.lua         # (423 lines)
    └── widget_demo.lua         # (222 lines)
```

## Overview
- **Total Files**: 119
- **Total Lines**: 23,407
- **Code Lines**: 18,302
- **Public Functions**: 348
- **Classes**: 81
- **Modules**: 255

## Folder Structure
### ReArkitekt/
  - Files: 119
  - Lines: 18,302
  - Exports: 348

## Execution Flow Patterns

### Entry Points (Not Imported by Others)
- **`ReArkitekt/input/wheel_guard.lua`**
  → Imports: imgui
- **`ReArkitekt/ColorPalette/ARK_Color_Palette.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.ColorPalette.app.state, ReArkitekt.ColorPalette.app.gui (+2 more)
- **`ReArkitekt/demo_modal_overlay.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.overlay.sheet, ReArkitekt.gui.widgets.chip_list.list (+1 more)
- **`ReArkitekt/app/chrome/status_bar/init.lua`**
  → Imports: ReArkitekt.app.chrome.status_bar.widget
- **`ReArkitekt/demo3.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.displays.status_pad, ReArkitekt.app.chrome.status_bar
- **`ReArkitekt/gui/systems/reorder.lua`**
- **`ReArkitekt/demo2.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.sliders.hue, ReArkitekt.gui.widgets.panel
- **`ReArkitekt/Region_Playlist/widgets/controls/controls_widget.lua`**
- **`ReArkitekt/gui/widgets/panel/modes/temp_search.lua`**
- **`ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`**
  → Imports: ReArkitekt.app.shell, Region_Playlist.app.config, Region_Playlist.app.state (+2 more)

### Orchestration Pattern
**`ReArkitekt/gui/widgets/grid/core.lua`** composes 13 modules:
  layout + rect_track + colors + selection + selection_rectangle (+8 more)
**`ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`** composes 12 modules:
  config + coordinator_render + draw + colors + tile_motion (+7 more)
**`ReArkitekt/Region_Playlist/app/gui.lua`** composes 9 modules:
  coordinator + colors + shortcuts + controller + transport_container (+4 more)
**`ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`** composes 7 modules:
  draw + colors + tile_fx + tile_fx_config + marching_ants (+2 more)
**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** composes 6 modules:
  core + colors + tile_motion + renderer + micromanage (+1 more)

## Module API Surface

### `ReArkitekt/ColorPalette/app/controller.lua`
> ReArkitekt/ColorPalette/app/controller.lua

**Modules**: `M, Controller, targets, colors`
**Classes**: `Controller, M` (stateful objects)
**Public API**:
  - `M.new()` → Instance

### `ReArkitekt/ColorPalette/app/gui.lua`
> ReArkitekt/ColorPalette/app/gui.lua

**Modules**: `M, GUI`
**Classes**: `GUI, M` (stateful objects)
**Public API**:
  - `M.create(State, settings, overlay_manager)` → Instance
**Dependencies**: `ReArkitekt.core.colors, ReArkitekt.gui.draw, ReArkitekt.ColorPalette.widgets.color_grid, ReArkitekt.ColorPalette.app.controller, ReArkitekt.gui.widgets.overlay.sheet`

### `ReArkitekt/ColorPalette/app/state.lua`
> ReArkitekt/ColorPalette/app/state.lua

**Modules**: `M`
**Public API**:
  - `M.initialize(settings)`
  - `M.recalculate_palette()`
  - `M.get_palette_colors()`
  - `M.get_palette_config()`
  - `M.get_target_type()`
  - `M.set_target_type(index)`
  - `M.get_action_type()`
  - `M.set_action_type(index)`
  - `M.set_auto_close(value)`
  - `M.get_auto_close()`
**Dependencies**: `ReArkitekt.core.colors`

### `ReArkitekt/ColorPalette/widgets/color_grid.lua`
> ReArkitekt/ColorPalette/widgets/color_grid.lua

**Modules**: `M, ColorGrid`
**Classes**: `ColorGrid, M` (stateful objects)
**Public API**:
  - `M.new()` → Instance
**Dependencies**: `ReArkitekt.core.colors, ReArkitekt.gui.draw`

### `ReArkitekt/Region_Playlist/app/config.lua`
> Region_Playlist/app/config.lua

**Modules**: `M`
**Public API**:
  - `M.get_active_container_config(callbacks)`
  - `M.get_pool_container_config(callbacks)`
  - `M.get_region_tiles_config(layout_mode)`

### `ReArkitekt/Region_Playlist/app/controller.lua`
> ReArkitekt/features/region_playlist/playlist_controller.lua

**Modules**: `M, Controller, keys, keys, keys_set, new_items, keys_set, keys_set`
**Classes**: `Controller, M` (stateful objects)
**Public API**:
  - `M.new(state_module, settings, undo_manager)` → Instance
**Dependencies**: `Region_Playlist.storage.state`

### `ReArkitekt/Region_Playlist/app/gui.lua`
> Region_Playlist/app/gui.lua

**Modules**: `M, GUI, tab_items, selected_ids, filtered`
**Classes**: `GUI, M` (stateful objects)
**Public API**:
  - `M.create(State, AppConfig, settings)` → Instance
**Dependencies**: `Region_Playlist.widgets.region_tiles.coordinator, ReArkitekt.core.colors, Region_Playlist.app.shortcuts, Region_Playlist.app.controller, ReArkitekt.gui.widgets.transport.transport_container, (+4 more)`

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
**Dependencies**: `Region_Playlist.engine.coordinator_bridge, Region_Playlist.storage.state, ReArkitekt.core.undo_manager, Region_Playlist.storage.undo_bridge, ReArkitekt.core.colors`

### `ReArkitekt/Region_Playlist/app/status.lua`
> Region_Playlist/app/status.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(State, Style)` → Instance
**Dependencies**: `ReArkitekt.app.chrome.status_bar`

### `ReArkitekt/Region_Playlist/engine/coordinator_bridge.lua`
> ReArkitekt/features/region_playlist/coordinator_bridge.lua

**Modules**: `M, order, regions`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(opts)` → Instance
**Dependencies**: `Region_Playlist.engine.core, Region_Playlist.engine.playback, Region_Playlist.storage.state`

### `ReArkitekt/Region_Playlist/engine/core.lua`
> ReArkitekt/features/region_playlist/engine/engine.lua

**Modules**: `M, Engine`
**Classes**: `Engine, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `Region_Playlist.engine.state, Region_Playlist.engine.transport, Region_Playlist.engine.transitions, Region_Playlist.engine.quantize`

### `ReArkitekt/Region_Playlist/engine/playback.lua`
> ReArkitekt/features/region_playlist/playback.lua

**Modules**: `M, Playback`
**Classes**: `Playback, M` (stateful objects)
**Public API**:
  - `M.new(engine, opts)` → Instance
**Dependencies**: `ReArkitekt.reaper.transport`

### `ReArkitekt/Region_Playlist/engine/quantize.lua`
> ReArkitekt/features/region_playlist/engine/quantize.lua

**Modules**: `M, Quantize`
**Classes**: `Quantize, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/Region_Playlist/engine/state.lua`
> ReArkitekt/features/region_playlist/engine/state.lua

**Modules**: `M, State`
**Classes**: `State, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.reaper.regions, ReArkitekt.reaper.transport`

### `ReArkitekt/Region_Playlist/engine/transitions.lua`
> ReArkitekt/features/region_playlist/engine/transitions.lua

**Modules**: `M, Transitions`
**Classes**: `Transitions, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/Region_Playlist/engine/transport.lua`
> ReArkitekt/features/region_playlist/engine/transport.lua

**Modules**: `M, Transport`
**Classes**: `Transport, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/Region_Playlist/storage/state.lua`
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

### `ReArkitekt/Region_Playlist/storage/undo_bridge.lua`
> ReArkitekt/features/region_playlist/undo_bridge.lua

**Modules**: `M, restored_playlists`
**Public API**:
  - `M.capture_snapshot(playlists, active_playlist_id)`
  - `M.restore_snapshot(snapshot, region_index)`
  - `M.should_capture(old_playlists, new_playlists)`

### `ReArkitekt/Region_Playlist/widgets/controls/controls_widget.lua`
> ReArkitekt/features/region_playlist/controls_widget.lua

**Modules**: `M`
**Public API**:
  - `M.draw_transport_controls(ctx, bridge, x, y)`
  - `M.draw_quantize_selector(ctx, bridge, x, y, width)`
  - `M.draw_playback_info(ctx, bridge, x, y, width)`
  - `M.draw_complete_controls(ctx, bridge, x, y, available_width)`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/active_grid_factory.lua`
> ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua

**Modules**: `M, item_map, items_by_key, dragged_items, items_by_key, new_items`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(rt, config)` → Instance
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, Region_Playlist.widgets.region_tiles.renderers.active`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`
> ReArkitekt/gui/widgets/region_tiles/coordinator.lua

**Modules**: `M, RegionTiles, playlist_cache, spawned_keys, payload, colors`
**Classes**: `RegionTiles, M` (stateful objects)
**Public API**:
  - `M.create(opts)` → Instance
**Dependencies**: `Region_Playlist.app.config, Region_Playlist.widgets.region_tiles.coordinator_render, ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, (+7 more)`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator_render.lua`
> ReArkitekt/gui/widgets/region_tiles/coordinator_render.lua

**Modules**: `M, keys_to_adjust`
**Public API**:
  - `M.draw_selector(self, ctx, playlists, active_id, height)`
  - `M.draw_active(self, ctx, playlist, height)`
  - `M.draw_pool(self, ctx, regions, height)`
  - `M.draw_ghosts(self, ctx)`
**Dependencies**: `ReArkitekt.gui.fx.dnd.drag_indicator, Region_Playlist.widgets.region_tiles.renderers.active, Region_Playlist.widgets.region_tiles.renderers.pool, ReArkitekt.gui.systems.responsive_grid`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/pool_grid_factory.lua`
> ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua

**Modules**: `M, items_by_key, filtered_keys, rids, rids, items_by_key`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(rt, config)` → Instance
**Private Functions**: 5 helpers
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, Region_Playlist.widgets.region_tiles.renderers.pool`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/active.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/active.lua

**Modules**: `M, right_elements, right_elements`
**Public API**:
  - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge, get_playlist_by_id)`
  - `M.render_region(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge)`
  - `M.render_playlist(ctx, rect, item, state, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, get_playlist_by_id)`
**Dependencies**: `ReArkitekt.core.colors, ReArkitekt.gui.draw, ReArkitekt.gui.fx.tile_fx_config, Region_Playlist.widgets.region_tiles.renderers.base, ReArkitekt.gui.systems.playback_manager`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/base.lua

**Modules**: `M`
**Public API**:
  - `M.calculate_right_elements_width(ctx, elements)`
  - `M.create_element(visible, width, margin)` → Instance
  - `M.calculate_text_right_bound(ctx, x2, text_margin, right_elements)`
  - `M.draw_base_tile(dl, rect, base_color, fx_config, state, hover_factor, playback_progress, playback_fade)`
  - `M.draw_marching_ants(dl, rect, color, fx_config)`
  - `M.draw_region_text(ctx, dl, pos, region, base_color, text_alpha, right_bound_x)`
  - `M.draw_playlist_text(ctx, dl, pos, playlist_data, state, text_alpha, right_bound_x, name_color_override)`
  - `M.draw_length_display(ctx, dl, rect, region, base_color, text_alpha)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config, ReArkitekt.gui.fx.marching_ants, (+2 more)`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/pool.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua

**Modules**: `M, right_elements, right_elements`
**Public API**:
  - `M.render(ctx, rect, item, state, animator, hover_config, tile_height, border_thickness)`
  - `M.render_region(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
  - `M.render_playlist(ctx, rect, playlist, state, animator, hover_config, tile_height, border_thickness)`
**Dependencies**: `ReArkitekt.core.colors, ReArkitekt.gui.draw, ReArkitekt.gui.fx.tile_fx_config, ReArkitekt.gui.systems.tile_utilities, Region_Playlist.widgets.region_tiles.renderers.base`

### `ReArkitekt/Region_Playlist/widgets/region_tiles/selector.lua`
> ReArkitekt/gui/widgets/region_tiles/selector.lua

**Modules**: `M, Selector`
**Classes**: `Selector, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion`

### `ReArkitekt/app/chrome/status_bar/config.lua`
> ReArkitekt/app/chrome/status_bar/config.lua

**Modules**: `M, result`
**Public API**:
  - `M.deep_merge(base, override)`
  - `M.merge(user_config, preset_name)`
**Dependencies**: `ReArkitekt.gui.widgets.component.chip`

### `ReArkitekt/app/chrome/status_bar/widget.lua`
> ReArkitekt/app/chrome/status_bar/widget.lua

**Modules**: `M, right_items`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.gui.widgets.component.chip, ReArkitekt.app.chrome.status_bar.config`

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
  - `M.hexrgb(hex_string)`
  - `M.rgba_to_components(color)`
  - `M.components_to_rgba(r, g, b, a)`
  - `M.with_alpha(color, alpha)`
  - `M.adjust_brightness(color, factor)`
  - `M.desaturate(color, amount)`
  - `M.saturate(color, amount)`
  - `M.luminance(color)`
  - `M.lerp_component(a, b, t)`
  - `M.lerp(color_a, color_b, t)`

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
**Dependencies**: `ReArkitekt.core.json`

### `ReArkitekt/core/undo_manager.lua`
> ReArkitekt/core/undo_manager.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/demo.lua`
> ReArkitekt/demo.lua

**Modules**: `result, conflicts, asset_providers`
**Private Functions**: 8 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage, ReArkitekt.gui.widgets.panel, ReArkitekt.gui.widgets.selection_rectangle`

### `ReArkitekt/demo3.lua`
> demo3.lua – Status Pads Widget Demo (Reworked)

**Modules**: `pads`
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.displays.status_pad, ReArkitekt.app.chrome.status_bar`

### `ReArkitekt/demo_modal_overlay.lua`
> ReArkitekt/demo_modal_overlay.lua

**Modules**: `selected_tag_items`
**Private Functions**: 7 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.overlay.sheet, ReArkitekt.gui.widgets.chip_list.list, ReArkitekt.gui.widgets.overlay.config`

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

## State Ownership

### Stateful Modules (Classes/Objects)
- **`widget.lua`**: M
- **`runtime.lua`**: M
- **`titlebar.lua`**: M
- **`window.lua`**: M
- **`controller.lua`**: Controller, M
- **`gui.lua`**: GUI, M
- **`color_grid.lua`**: ColorGrid, M
- **`lifecycle.lua`**: Group, M
- **`settings.lua`**: Settings
- **`undo_manager.lua`**: M
- ... and 37 more

### Stateless Modules (Pure Functions)
- **60** stateless modules
- **33** with no dependencies (pure utility modules)

## Integration Essentials

### Module Creators
- `M.new(config)` in `widget.lua`
- `M.new(opts)` in `runtime.lua`
- `M.new(opts)` in `titlebar.lua`
- `M.new(opts)` in `window.lua`
- `M.new()` in `controller.lua`
- `M.create(State, settings, overlay_manager)` in `gui.lua`
- `M.initialize(settings)` in `state.lua`
- `M.new()` in `color_grid.lua`
- ... and 44 more

### Callback-Based APIs
- `M.find_drop_target()` expects: key_fn
- `M.find_external_drop_target()` expects: key_fn
- `Sheet.render()` expects: content_fn
- `M.draw()` expects: content_fn
- `M.draw()` expects: on_mode_changed
- ... and 9 more

## Module Classification

**Pure Modules** (no dependencies): 54
  - `ReArkitekt/app/config.lua`
  - `ReArkitekt/app/icon.lua`
  - `ReArkitekt/app/runtime.lua`
  - `ReArkitekt/app/titlebar.lua`
  - `ReArkitekt/app/window.lua`
  - ... and 49 more

**Class Modules** (OOP with metatables): 47
  - `widget.lua`: M
  - `runtime.lua`: M
  - `titlebar.lua`: M
  - `window.lua`: M
  - `controller.lua`: Controller, M
  - ... and 42 more

## Top 10 Largest Files

1. `ReArkitekt/Region_Playlist/app/gui.lua` (891 lines)
2. `ReArkitekt/gui/widgets/tiles_container_old.lua` (752 lines)
3. `ReArkitekt/gui/widgets/panel/header/tab_strip.lua` (730 lines)
4. `ReArkitekt/gui/widgets/panel/modes/tabs.lua` (646 lines)
5. `ReArkitekt/Region_Playlist/app/state.lua` (596 lines)
6. `ReArkitekt/app/window.lua` (559 lines)
7. `ReArkitekt/core/colors.lua` (549 lines)
8. `ReArkitekt/gui/widgets/grid/core.lua` (549 lines)
9. `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua` (502 lines)
10. `ReArkitekt/app/titlebar.lua` (453 lines)

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

**`ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`** imports 11 modules:
  → `ReArkitekt/Region_Playlist/app/config.lua`
  → `ReArkitekt/Region_Playlist/app/state.lua`
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/active_grid_factory.lua`
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator_render.lua`
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/pool_grid_factory.lua`
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/selector.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → ... and 3 more

**`ReArkitekt/Region_Playlist/app/gui.lua`** imports 9 modules:
  → `ReArkitekt/Region_Playlist/app/config.lua`
  → `ReArkitekt/Region_Playlist/app/controller.lua`
  → `ReArkitekt/Region_Playlist/app/shortcuts.lua`
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/chip_list/list.lua`
  → `ReArkitekt/gui/widgets/overlay/sheet.lua`
  → ... and 1 more

**`ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`** imports 7 modules:
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

**`ReArkitekt/gui/widgets/panel/init.lua`** imports 6 modules:
  → `ReArkitekt/gui/widgets/controls/scrollbar.lua`
  → `ReArkitekt/gui/widgets/panel/background.lua`
  → `ReArkitekt/gui/widgets/panel/config.lua`
  → `ReArkitekt/gui/widgets/panel/content.lua`
  → `ReArkitekt/gui/widgets/panel/header.lua`
  → `ReArkitekt/gui/widgets/panel/tab_animator.lua`

**`ReArkitekt/ColorPalette/app/gui.lua`** imports 5 modules:
  → `ReArkitekt/ColorPalette/app/controller.lua`
  → `ReArkitekt/ColorPalette/widgets/color_grid.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/widgets/overlay/sheet.lua`

**`ReArkitekt/ColorPalette/ARK_Color_Palette.lua`** imports 5 modules:
  → `ReArkitekt/ColorPalette/app/gui.lua`
  → `ReArkitekt/ColorPalette/app/state.lua`
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/core/settings.lua`
  → `ReArkitekt/gui/widgets/overlay/manager.lua`

**`ReArkitekt/gui/widgets/panel/header/layout.lua`** imports 5 modules:
  → `ReArkitekt/gui/widgets/panel/header/button.lua`
  → `ReArkitekt/gui/widgets/panel/header/dropdown_field.lua`
  → `ReArkitekt/gui/widgets/panel/header/search_field.lua`
  → `ReArkitekt/gui/widgets/panel/header/separator.lua`
  → `ReArkitekt/gui/widgets/panel/header/tab_strip.lua`

**`ReArkitekt/Region_Playlist/app/state.lua`** imports 5 modules:
  → `ReArkitekt/Region_Playlist/engine/coordinator_bridge.lua`
  → `ReArkitekt/Region_Playlist/storage/state.lua`
  → `ReArkitekt/Region_Playlist/storage/undo_bridge.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/core/undo_manager.lua`

**`ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`** imports 5 modules:
  → `ReArkitekt/Region_Playlist/app/config.lua`
  → `ReArkitekt/Region_Playlist/app/gui.lua`
  → `ReArkitekt/Region_Playlist/app/state.lua`
  → `ReArkitekt/Region_Playlist/app/status.lua`
  → `ReArkitekt/app/shell.lua`

**`ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/active.lua`** imports 5 modules:
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/playback_manager.lua`

**`ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/pool.lua`** imports 5 modules:
  → `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`

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

**`ReArkitekt/Region_Playlist/engine/core.lua`** imports 4 modules:
  → `ReArkitekt/Region_Playlist/engine/quantize.lua`
  → `ReArkitekt/Region_Playlist/engine/state.lua`
  → `ReArkitekt/Region_Playlist/engine/transitions.lua`
  → `ReArkitekt/Region_Playlist/engine/transport.lua`

### Reverse Dependencies (What Imports Each File)

**`ReArkitekt/core/colors.lua`** is imported by 23 files:
  ← `ReArkitekt/ColorPalette/app/gui.lua`
  ← `ReArkitekt/ColorPalette/app/state.lua`
  ← `ReArkitekt/ColorPalette/widgets/color_grid.lua`
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/app/state.lua`
  ← `ReArkitekt/Region_Playlist/storage/state.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/active.lua`
  ← ... and 15 more

**`ReArkitekt/gui/draw.lua`** is imported by 18 files:
  ← `ReArkitekt/ColorPalette/app/gui.lua`
  ← `ReArkitekt/ColorPalette/widgets/color_grid.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/pool.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← ... and 10 more

**`ReArkitekt/app/shell.lua`** is imported by 7 files:
  ← `ReArkitekt/ColorPalette/ARK_Color_Palette.lua`
  ← `ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/demo3.lua`
  ← `ReArkitekt/demo_modal_overlay.lua`
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/widgets/component/chip.lua`** is imported by 6 files:
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/app/chrome/status_bar/config.lua`
  ← `ReArkitekt/app/chrome/status_bar/widget.lua`
  ← `ReArkitekt/gui/widgets/chip_list/list.lua`
  ← `ReArkitekt/gui/widgets/panel/header/tab_strip.lua`
  ← `ReArkitekt/gui/widgets/panel/modes/tabs.lua`

**`ReArkitekt/gui/fx/tile_fx_config.lua`** is imported by 5 files:
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/pool.lua`
  ← `ReArkitekt/gui/widgets/component/chip.lua`
  ← `ReArkitekt/gui/widgets/displays/status_pad.lua`

**`ReArkitekt/gui/fx/tile_motion.lua`** is imported by 4 files:
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/fx/easing.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/fx/animations/destroy.lua`
  ← `ReArkitekt/gui/fx/animations/spawn.lua`
  ← `ReArkitekt/gui/widgets/panel/tab_animator.lua`

**`ReArkitekt/gui/fx/marching_ants.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/gui/fx/tile_fx.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`
  ← `ReArkitekt/gui/widgets/component/chip.lua`
  ← `ReArkitekt/gui/widgets/displays/status_pad.lua`

**`ReArkitekt/gui/widgets/controls/dropdown.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/panel/header/dropdown_field.lua`
  ← `ReArkitekt/gui/widgets/panel/modes/search_sort.lua`
  ← `ReArkitekt/gui/widgets/tiles_container_old.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/active_grid_factory.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/pool_grid_factory.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/widgets/overlay/config.lua`** is imported by 3 files:
  ← `ReArkitekt/demo_modal_overlay.lua`
  ← `ReArkitekt/gui/widgets/overlay/manager.lua`
  ← `ReArkitekt/gui/widgets/overlay/sheet.lua`

**`ReArkitekt/gui/widgets/overlay/sheet.lua`** is imported by 3 files:
  ← `ReArkitekt/ColorPalette/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/demo_modal_overlay.lua`

**`ReArkitekt/Region_Playlist/app/config.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/Region_Playlist/app/state.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`
  ← `ReArkitekt/Region_Playlist/app/shortcuts.lua`
  ← `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`

### Circular Dependencies

✓ No circular dependencies detected

### Isolated Files (No Imports or Exports)

- `ReArkitekt/app/config.lua`
- `ReArkitekt/app/icon.lua`
- `ReArkitekt/app/titlebar.lua`
- `ReArkitekt/core/lifecycle.lua`
- `ReArkitekt/gui/images.lua`
- `ReArkitekt/gui/systems/reorder.lua`
- `ReArkitekt/gui/widgets/navigation/menutabs.lua`
- `ReArkitekt/gui/widgets/panel/modes/temp_search.lua`
- `ReArkitekt/input/wheel_guard.lua`
- `ReArkitekt/reaper/timing.lua`
- `ReArkitekt/Region_Playlist/widgets/controls/controls_widget.lua`

### Dependency Complexity Ranking

1. `ReArkitekt/core/colors.lua`: 0 imports + 23 importers = 23 total
2. `ReArkitekt/gui/draw.lua`: 0 imports + 18 importers = 18 total
3. `ReArkitekt/gui/widgets/grid/core.lua`: 13 imports + 3 importers = 16 total
4. `ReArkitekt/Region_Playlist/widgets/region_tiles/coordinator.lua`: 11 imports + 1 importers = 12 total
5. `ReArkitekt/gui/widgets/component/chip.lua`: 4 imports + 6 importers = 10 total
6. `ReArkitekt/Region_Playlist/app/gui.lua`: 9 imports + 1 importers = 10 total
7. `ReArkitekt/app/shell.lua`: 2 imports + 7 importers = 9 total
8. `ReArkitekt/Region_Playlist/widgets/region_tiles/renderers/base.lua`: 7 imports + 2 importers = 9 total
9. `ReArkitekt/Region_Playlist/app/state.lua`: 5 imports + 3 importers = 8 total
10. `ReArkitekt/gui/widgets/overlay/sheet.lua`: 4 imports + 3 importers = 7 total

## Important Constraints

### Object Lifecycle
- Classes use metatable pattern: `ClassName.__index = ClassName`
- Constructor functions typically named `new()` or `create()`
- Always call constructor before using instance methods

### Callback Requirements
- 14 modules use callback patterns for extensibility
- Callbacks enable features like event handling and custom behavior
- Check function signatures for `on_*`, `*_callback`, or `*_handler` parameters
