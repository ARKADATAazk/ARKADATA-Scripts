# PROJECT FLOW: ARKADATA Scripts
Generated: 2025-10-07 04:14:17
Root: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts

## Project Structure

```
└── ReArkitekt/
    ├── Region_Playlist/
    │   ├── app/
    │   │   ├── config.lua         # (122 lines)
    │   │   ├── gui.lua         # (475 lines)
    │   │   ├── shortcuts.lua         # (65 lines)
    │   │   ├── state.lua         # (308 lines)
    │   │   └── status.lua         # (58 lines)
    │   └── ARK_Region_Playlist.lua         # (52 lines)
    ├── app/
    │   ├── runtime.lua         # (68 lines)
    │   ├── shell.lua         # (95 lines)
    │   └── window.lua         # (182 lines)
    ├── core/
    │   ├── colors.lua         # (428 lines)
    │   ├── json.lua         # (120 lines)
    │   ├── lifecycle.lua         # (80 lines)
    │   ├── math.lua         # (51 lines)
    │   ├── settings.lua         # (118 lines)
    │   └── undo_manager.lua         # (85 lines)
    ├── features/
    │   └── region_playlist/
    │       ├── controls_widget.lua         # (150 lines)
    │       ├── coordinator_bridge.lua         # (128 lines)
    │       ├── engine.lua         # (239 lines)
    │       ├── playback.lua         # (102 lines)
    │       ├── shortcuts.lua         # (68 lines)
    │       ├── state.lua         # (100 lines)
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
    │   │   ├── responsive_grid.lua         # (127 lines)
    │   │   ├── selection.lua         # (141 lines)
    │   │   └── tile_utilities.lua         # (48 lines)
    │   ├── widgets/
    │   │   ├── controls/
    │   │   │   └── dropdown.lua         # (263 lines)
    │   │   ├── grid/
    │   │   │   ├── animation.lua         # (100 lines)
    │   │   │   ├── core.lua         # (549 lines)
    │   │   │   ├── dnd_state.lua         # (112 lines)
    │   │   │   ├── drop_zones.lua         # (249 lines)
    │   │   │   ├── grid_bridge.lua         # (218 lines)
    │   │   │   ├── input.lua         # (236 lines)
    │   │   │   ├── layout.lua         # (100 lines)
    │   │   │   └── rendering.lua         # (89 lines)
    │   │   ├── navigation/
    │   │   │   └── menutabs.lua         # (268 lines)
    │   │   ├── package_tiles/
    │   │   │   ├── grid.lua         # (196 lines)
    │   │   │   ├── micromanage.lua         # (126 lines)
    │   │   │   └── renderer.lua         # (232 lines)
    │   │   ├── region_tiles/
    │   │   │   ├── renderers/
    │   │   │   │   ├── active.lua         # (234 lines)
    │   │   │   │   └── pool.lua         # (146 lines)
    │   │   │   ├── active_grid_factory.lua         # (213 lines)
    │   │   │   ├── coordinator.lua         # (767 lines)
    │   │   │   ├── pool_grid_factory.lua         # (122 lines)
    │   │   │   └── selector.lua         # (97 lines)
    │   │   ├── sliders/
    │   │   │   └── hue.lua         # (260 lines)
    │   │   ├── selection_rectangle.lua         # (98 lines)
    │   │   ├── status_bar.lua         # (196 lines)
    │   │   └── tiles_container.lua         # (495 lines)
    │   ├── draw.lua         # (113 lines)
    │   ├── images.lua         # (284 lines)
    │   └── style.lua         # (173 lines)
    ├── input/
    │   └── wheel_guard.lua         # (42 lines)
    ├── reaper/
    │   ├── regions.lua         # (76 lines)
    │   ├── timing.lua         # (112 lines)
    │   └── transport.lua         # (97 lines)
    ├── demo.lua         # (299 lines)
    ├── demo2.lua         # (185 lines)
    └── widget_demo.lua         # (222 lines)
```

## Overview
- **Total Files**: 74
- **Total Lines**: 12,092
- **Code Lines**: 9,431
- **Public Functions**: 218
- **Classes**: 53
- **Modules**: 159

## Folder Structure
### ReArkitekt/
  - Files: 74
  - Lines: 9,431
  - Exports: 218

## Execution Flow Patterns

### Entry Points (Not Imported by Others)
- **`ReArkitekt/gui/systems/reorder.lua`**
- **`ReArkitekt/widget_demo.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.colorblocks, ReArkitekt.gui.draw (+2 more)
- **`ReArkitekt/demo2.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.sliders.hue, ReArkitekt.gui.widgets.status_bar (+1 more)
- **`ReArkitekt/demo.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.navigation.menutabs, ReArkitekt.gui.widgets.status_bar (+4 more)
- **`ReArkitekt/input/wheel_guard.lua`**
  → Imports: imgui
- **`ReArkitekt/features/region_playlist/shortcuts.lua`**
- **`ReArkitekt/core/settings.lua`**
  → Imports: json
- **`ReArkitekt/core/lifecycle.lua`**
- **`ReArkitekt/gui/images.lua`**
- **`ReArkitekt/gui/style.lua`**

### Orchestration Pattern
**`ReArkitekt/gui/widgets/grid/core.lua`** composes 13 modules:
  layout + rect_track + colors + selection + selection_rectangle (+8 more)
**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** composes 13 modules:
  draw + colors + tile_motion + drag_indicator + active (+8 more)
**`ReArkitekt/demo.lua`** composes 7 modules:
  shell + menutabs + status_bar + grid + micromanage (+2 more)
**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** composes 7 modules:
  draw + colors + tile_fx + tile_fx_config + marching_ants (+2 more)
**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** composes 6 modules:
  draw + colors + tile_fx + tile_fx_config + marching_ants (+1 more)

## Module API Surface

### `ReArkitekt/Region_Playlist/app/config.lua`
> Region_Playlist/app/config.lua

**Modules**: `M`
**Public API**:
  - `M.get_region_tiles_config(layout_mode)`

### `ReArkitekt/Region_Playlist/app/gui.lua`
> Region_Playlist/app/gui.lua

**Modules**: `M, GUI, new_items, keys_to_delete, new_items, dragged_keys, filtered_items, new_keys`
**Classes**: `GUI, M` (stateful objects)
**Public API**:
  - `M.create(State, Config, settings)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.core.colors, ReArkitekt.features.region_playlist.state, Region_Playlist.app.shortcuts, ReArkitekt.gui.fx.tile_motion`

### `ReArkitekt/Region_Playlist/app/shortcuts.lua`
> Region_Playlist/app/shortcuts.lua

**Modules**: `M`
**Public API**:
  - `M.handle_keyboard_shortcuts(ctx, state, region_tiles)`
**Dependencies**: `Region_Playlist.app.state`

### `ReArkitekt/Region_Playlist/app/state.lua`
> Region_Playlist/app/state.lua

**Modules**: `M, result, reversed`
**Public API**:
  - `M.initialize(settings)`
  - `M.load_project_state()`
  - `M.get_active_playlist()`
  - `M.refresh_regions()`
  - `M.sync_playlist_to_engine()`
  - `M.capture_undo_snapshot()`
  - `M.apply_undo_snapshot(snapshot)`
  - `M.get_filtered_pool_regions()`
  - `M.cleanup_deleted_regions()`
  - `M.check_for_project_changes()`
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.features.region_playlist.coordinator_bridge, ReArkitekt.features.region_playlist.state, ReArkitekt.core.undo_manager, ReArkitekt.features.region_playlist.undo_bridge, ReArkitekt.core.colors`

### `ReArkitekt/Region_Playlist/app/status.lua`
> Region_Playlist/app/status.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(State, Style)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.status_bar`

### `ReArkitekt/app/runtime.lua`
> ReArkitekt/app/runtime.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/app/shell.lua`
> ReArkitekt/app/shell.lua

**Modules**: `M`
**Public API**:
  - `M.run(opts)`
**Dependencies**: `ReArkitekt.app.runtime, ReArkitekt.app.window`

### `ReArkitekt/app/window.lua`
> ReArkitekt/app/window.lua

**Modules**: `M`
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
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.navigation.menutabs, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage, (+2 more)`

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
**Dependencies**: `ReArkitekt.features.region_playlist.engine, ReArkitekt.features.region_playlist.playback, ReArkitekt.features.region_playlist.state`

### `ReArkitekt/features/region_playlist/engine.lua`
> ReArkitekt/features/region_playlist/engine.lua

**Modules**: `M, Engine`
**Classes**: `Engine, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.reaper.regions, ReArkitekt.reaper.transport, ReArkitekt.reaper.timing`

### `ReArkitekt/features/region_playlist/playback.lua`
> ReArkitekt/features/region_playlist/playback.lua

**Modules**: `M, Playback`
**Classes**: `Playback, M` (stateful objects)
**Public API**:
  - `M.new(engine, opts)` → Instance
**Dependencies**: `ReArkitekt.reaper.transport`

### `ReArkitekt/features/region_playlist/shortcuts.lua`
> ReArkitekt/features/region_playlist/shortcuts.lua

**Modules**: `M`
**Public API**:
  - `M.handle_shortcuts(ctx, bridge)`

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
**Dependencies**: `ReArkitekt.core.json`

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

### `ReArkitekt/gui/style.lua`
> style.lua

**Modules**: `M`
**Public API**:
  - `M.with_alpha(col, a)`
  - `M.PushMyStyle(ctx)`
  - `M.PopMyStyle(ctx)`

### `ReArkitekt/gui/systems/height_stabilizer.lua`
> ReArkitekt/gui/systems/height_stabilizer.lua

**Modules**: `M, HeightStabilizer`
**Classes**: `HeightStabilizer, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/systems/playback_manager.lua`
> ReArkitekt/gui/systems/playback_manager.lua

**Modules**: `M`
**Public API**:
  - `M.compute_fade_alpha(progress, fade_in_ratio, fade_out_ratio)`

### `ReArkitekt/gui/systems/reorder.lua`
> ReArkitekt/gui/systems/reorder.lua

**Modules**: `M, t, base, new_order, new_order, new_order`
**Public API**:
  - `M.insert_relative(order_keys, dragged_keys, target_key, side)`
  - `M.move_up(order_keys, selected_keys)`
  - `M.move_down(order_keys, selected_keys)`

### `ReArkitekt/gui/systems/responsive_grid.lua`
> ReArkitekt/gui/systems/responsive_grid.lua

**Modules**: `M`
**Public API**:
  - `M.calculate_scaled_gap(tile_height, base_gap, base_height, min_height, responsive_config)`
  - `M.calculate_responsive_tile_height(opts)`
  - `M.calculate_grid_metrics(opts)`
  - `M.should_show_scrollbar(grid_height, available_height, buffer)`
  - `M.create_default_config()` → Instance

### `ReArkitekt/gui/systems/selection.lua`
> ReArkitekt/gui/systems/selection.lua

**Modules**: `M, Selection, out, out`
**Classes**: `Selection, M` (stateful objects)
**Public API**:
  - `M.new()` → Instance

### `ReArkitekt/gui/systems/tile_utilities.lua`
> ReArkitekt/gui/systems/tile_utilities.lua

**Modules**: `M`
**Public API**:
  - `M.format_bar_length(start_time, end_time, proj)`

### `ReArkitekt/gui/widgets/controls/dropdown.lua`
> ReArkitekt/gui/widgets/controls/dropdown.lua

**Modules**: `M, Dropdown`
**Classes**: `Dropdown, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/widgets/grid/animation.lua`
> ReArkitekt/gui/widgets/grid/animation.lua

**Modules**: `M, AnimationCoordinator`
**Classes**: `AnimationCoordinator, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.fx.animations.spawn, ReArkitekt.gui.fx.animations.destroy`

### `ReArkitekt/gui/widgets/grid/core.lua`
> ReArkitekt/gui/widgets/grid/core.lua

**Modules**: `M, Grid, current_keys, new_keys, rect_map, rect_map, order, filtered_order, new_order`
**Classes**: `Grid, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.layout, ReArkitekt.gui.fx.animation.rect_track, ReArkitekt.core.colors, ReArkitekt.gui.systems.selection, ReArkitekt.gui.widgets.selection_rectangle, (+8 more)`

### `ReArkitekt/gui/widgets/grid/dnd_state.lua`
> ReArkitekt/gui/widgets/grid/dnd_state.lua

**Modules**: `M, DnDState`
**Classes**: `DnDState, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

## State Ownership

### Stateful Modules (Classes/Objects)
- **`runtime.lua`**: M
- **`window.lua`**: M
- **`lifecycle.lua`**: Group, M
- **`settings.lua`**: Settings
- **`undo_manager.lua`**: M
- **`coordinator_bridge.lua`**: M
- **`engine.lua`**: Engine, M
- **`playback.lua`**: Playback, M
- **`rect_track.lua`**: RectTrack, M
- **`track.lua`**: Track, M
- ... and 22 more

### Stateless Modules (Pure Functions)
- **36** stateless modules
- **25** with no dependencies (pure utility modules)

## Integration Essentials

### Module Creators
- `M.new(opts)` in `runtime.lua`
- `M.new(opts)` in `window.lua`
- `M.new()` in `lifecycle.lua`
- `M.new(opts)` in `undo_manager.lua`
- `M.create(opts)` in `coordinator_bridge.lua`
- `M.new(opts)` in `engine.lua`
- `M.new(engine, opts)` in `playback.lua`
- `M.get_or_create_default_playlist(playlists, regions)` in `state.lua`
- ... and 26 more

### Callback-Based APIs
- `M.find_drop_target()` expects: key_fn
- `M.find_external_drop_target()` expects: key_fn
- `M.render()` expects: on_repeat_cycle
- `M.draw()` expects: content_fn, on_search_changed, on_sort_changed
- `M.capture_over_last_item()` expects: on_delta
- ... and 1 more

## Module Classification

**Pure Modules** (no dependencies): 39
  - `ReArkitekt/app/runtime.lua`
  - `ReArkitekt/app/window.lua`
  - `ReArkitekt/core/colors.lua`
  - `ReArkitekt/core/json.lua`
  - `ReArkitekt/core/lifecycle.lua`
  - ... and 34 more

**Class Modules** (OOP with metatables): 32
  - `runtime.lua`: M
  - `window.lua`: M
  - `lifecycle.lua`: Group, M
  - `settings.lua`: Settings
  - `undo_manager.lua`: M
  - ... and 27 more

## Top 10 Largest Files

1. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua` (767 lines)
2. `ReArkitekt/gui/widgets/grid/core.lua` (549 lines)
3. `ReArkitekt/gui/widgets/tiles_container.lua` (495 lines)
4. `ReArkitekt/Region_Playlist/app/gui.lua` (475 lines)
5. `ReArkitekt/core/colors.lua` (428 lines)
6. `ReArkitekt/Region_Playlist/app/state.lua` (308 lines)
7. `ReArkitekt/demo.lua` (299 lines)
8. `ReArkitekt/gui/images.lua` (284 lines)
9. `ReArkitekt/gui/widgets/navigation/menutabs.lua` (268 lines)
10. `ReArkitekt/gui/widgets/controls/dropdown.lua` (263 lines)

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

**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** imports 13 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/systems/height_stabilizer.lua`
  → `ReArkitekt/gui/systems/responsive_grid.lua`
  → `ReArkitekt/gui/widgets/grid/grid_bridge.lua`
  → `ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`
  → ... and 5 more

**`ReArkitekt/demo.lua`** imports 7 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/navigation/menutabs.lua`
  → `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** imports 7 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/playback_manager.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** imports 6 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** imports 5 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/Region_Playlist/app/gui.lua`** imports 5 modules:
  → `ReArkitekt/Region_Playlist/app/shortcuts.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/features/region_playlist/state.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

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

**`ReArkitekt/demo2.lua`** imports 4 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/sliders/hue.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/features/region_playlist/coordinator_bridge.lua`** imports 3 modules:
  → `ReArkitekt/features/region_playlist/engine.lua`
  → `ReArkitekt/features/region_playlist/playback.lua`
  → `ReArkitekt/features/region_playlist/state.lua`

**`ReArkitekt/features/region_playlist/engine.lua`** imports 3 modules:
  → `ReArkitekt/reaper/regions.lua`
  → `ReArkitekt/reaper/timing.lua`
  → `ReArkitekt/reaper/transport.lua`

**`ReArkitekt/gui/fx/dnd/drag_indicator.lua`** imports 3 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/config.lua`

**`ReArkitekt/gui/widgets/grid/rendering.lua`** imports 3 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`

**`ReArkitekt/gui/widgets/package_tiles/renderer.lua`** imports 3 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`

**`ReArkitekt/gui/widgets/region_tiles/selector.lua`** imports 3 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`

**`ReArkitekt/widget_demo.lua`** imports 3 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/effects.lua`

**`ReArkitekt/app/shell.lua`** imports 2 modules:
  → `ReArkitekt/app/runtime.lua`
  → `ReArkitekt/app/window.lua`

**`ReArkitekt/gui/widgets/grid/animation.lua`** imports 2 modules:
  → `ReArkitekt/gui/fx/animations/destroy.lua`
  → `ReArkitekt/gui/fx/animations/spawn.lua`

**`ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`** imports 2 modules:
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`

### Reverse Dependencies (What Imports Each File)

**`ReArkitekt/core/colors.lua`** is imported by 12 files:
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/app/state.lua`
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/fx/tile_fx.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← ... and 4 more

**`ReArkitekt/gui/draw.lua`** is imported by 10 files:
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/grid/input.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
  ← ... and 2 more

**`ReArkitekt/app/shell.lua`** is imported by 4 files:
  ← `ReArkitekt/Region_Playlist/ARK_Region_Playlist.lua`
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/fx/marching_ants.lua`** is imported by 4 files:
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/fx/tile_motion.lua`** is imported by 4 files:
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`

**`ReArkitekt/features/region_playlist/state.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/app/gui.lua`
  ← `ReArkitekt/Region_Playlist/app/state.lua`
  ← `ReArkitekt/features/region_playlist/coordinator_bridge.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua`

**`ReArkitekt/gui/widgets/status_bar.lua`** is imported by 3 files:
  ← `ReArkitekt/Region_Playlist/app/status.lua`
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`

**`ReArkitekt/gui/widgets/tiles_container.lua`** is imported by 3 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/core/json.lua`** is imported by 2 files:
  ← `ReArkitekt/core/settings.lua`
  ← `ReArkitekt/features/region_playlist/state.lua`

**`ReArkitekt/core/math.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/fx/animation/rect_track.lua`
  ← `ReArkitekt/gui/fx/animation/track.lua`

**`ReArkitekt/gui/fx/dnd/config.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/fx/dnd/drop_indicator.lua`

**`ReArkitekt/gui/fx/dnd/drag_indicator.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/fx/easing.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/fx/animations/destroy.lua`
  ← `ReArkitekt/gui/fx/animations/spawn.lua`

**`ReArkitekt/gui/fx/tile_fx.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

### Circular Dependencies

✓ No circular dependencies detected

### Isolated Files (No Imports or Exports)

- `ReArkitekt/core/lifecycle.lua`
- `ReArkitekt/features/region_playlist/controls_widget.lua`
- `ReArkitekt/features/region_playlist/shortcuts.lua`
- `ReArkitekt/gui/images.lua`
- `ReArkitekt/gui/style.lua`
- `ReArkitekt/gui/systems/reorder.lua`
- `ReArkitekt/input/wheel_guard.lua`

### Dependency Complexity Ranking

1. `ReArkitekt/gui/widgets/grid/core.lua`: 13 imports + 3 importers = 16 total
2. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`: 13 imports + 1 importers = 14 total
3. `ReArkitekt/core/colors.lua`: 0 imports + 12 importers = 12 total
4. `ReArkitekt/gui/draw.lua`: 0 imports + 10 importers = 10 total
5. `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`: 7 imports + 2 importers = 9 total
6. `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`: 6 imports + 2 importers = 8 total
7. `ReArkitekt/demo.lua`: 7 imports + 0 importers = 7 total
8. `ReArkitekt/Region_Playlist/app/state.lua`: 5 imports + 2 importers = 7 total
9. `ReArkitekt/app/shell.lua`: 2 imports + 4 importers = 6 total
10. `ReArkitekt/gui/widgets/package_tiles/grid.lua`: 5 imports + 1 importers = 6 total

## Important Constraints

### Object Lifecycle
- Classes use metatable pattern: `ClassName.__index = ClassName`
- Constructor functions typically named `new()` or `create()`
- Always call constructor before using instance methods

### Callback Requirements
- 6 modules use callback patterns for extensibility
- Callbacks enable features like event handling and custom behavior
- Check function signatures for `on_*`, `*_callback`, or `*_handler` parameters
