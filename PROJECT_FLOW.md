# PROJECT FLOW: ARKADATA Scripts
Generated: 2025-10-06 14:58:51
Root: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts

## Project Structure

```
└── ReArkitekt/
    ├── app/
    │   ├── runtime.lua         # (68 lines)
    │   ├── shell.lua         # (96 lines)
    │   └── window.lua         # (182 lines)
    ├── core/
    │   ├── colors.lua         # (428 lines)
    │   ├── json.lua         # (120 lines)
    │   ├── lifecycle.lua         # (80 lines)
    │   ├── math.lua         # (51 lines)
    │   └── settings.lua         # (118 lines)
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
    │   │   ├── playback_manager.lua         # (109 lines)
    │   │   ├── reorder.lua         # (126 lines)
    │   │   ├── responsive_grid.lua         # (127 lines)
    │   │   ├── selection.lua         # (141 lines)
    │   │   └── tile_utilities.lua         # (27 lines)
    │   ├── widgets/
    │   │   ├── grid/
    │   │   │   ├── animation.lua         # (100 lines)
    │   │   │   ├── core.lua         # (555 lines)
    │   │   │   ├── dnd_state.lua         # (112 lines)
    │   │   │   ├── drop_zones.lua         # (240 lines)
    │   │   │   ├── grid_bridge.lua         # (218 lines)
    │   │   │   ├── input.lua         # (232 lines)
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
    │   │   │   │   ├── active.lua         # (221 lines)
    │   │   │   │   └── pool.lua         # (142 lines)
    │   │   │   ├── active_grid_factory.lua         # (222 lines)
    │   │   │   ├── coordinator.lua         # (748 lines)
    │   │   │   ├── pool_grid_factory.lua         # (122 lines)
    │   │   │   └── selector.lua         # (97 lines)
    │   │   ├── sliders/
    │   │   │   └── hue.lua         # (260 lines)
    │   │   ├── selection_rectangle.lua         # (98 lines)
    │   │   ├── status_bar.lua         # (196 lines)
    │   │   └── tiles_container.lua         # (480 lines)
    │   ├── draw.lua         # (113 lines)
    │   ├── images.lua         # (284 lines)
    │   └── style.lua         # (173 lines)
    ├── input/
    │   └── wheel_guard.lua         # (42 lines)
    ├── demo.lua         # (299 lines)
    ├── demo2.lua         # (185 lines)
    ├── mock_region_playlist.lua         # (676 lines)
    └── widget_demo.lua         # (222 lines)
```

## Overview
- **Total Files**: 57
- **Total Lines**: 10,197
- **Code Lines**: 7,942
- **Public Functions**: 157
- **Classes**: 44
- **Modules**: 131

## Folder Structure
### ReArkitekt/
  - Files: 57
  - Lines: 7,942
  - Exports: 157

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
- **`ReArkitekt/mock_region_playlist.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.region_tiles.coordinator (+3 more)
- **`ReArkitekt/core/settings.lua`**
  → Imports: json
- **`ReArkitekt/core/lifecycle.lua`**
- **`ReArkitekt/gui/images.lua`**
- **`ReArkitekt/gui/style.lua`**

### Orchestration Pattern
**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** composes 14 modules:
  draw + colors + playback_manager + tile_motion + drag_indicator (+9 more)
**`ReArkitekt/gui/widgets/grid/core.lua`** composes 13 modules:
  layout + rect_track + colors + selection + selection_rectangle (+8 more)
**`ReArkitekt/demo.lua`** composes 7 modules:
  shell + menutabs + status_bar + grid + micromanage (+2 more)
**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** composes 6 modules:
  draw + colors + tile_fx + tile_fx_config + marching_ants (+1 more)
**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** composes 6 modules:
  draw + colors + tile_fx + tile_fx_config + marching_ants (+1 more)

## Module API Surface

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

### `ReArkitekt/demo.lua`
> ReArkitekt/demo.lua

**Modules**: `result`
**Private Functions**: 8 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.navigation.menutabs, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage, (+2 more)`

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

**Modules**: `M, PlaybackManager`
**Classes**: `PlaybackManager, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance

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
  - `M.format_bar_length(seconds, project_bpm, project_time_sig_num)`

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

### `ReArkitekt/gui/widgets/grid/drop_zones.lua`
> ReArkitekt/gui/widgets/grid/drop_zones.lua

**Modules**: `M, non_dragged, zones, zones, rows, sequential_items, set`
**Public API**:
  - `M.find_drop_target(mx, my, items, key_fn, dragged_set, rect_track, is_single_column, grid_bounds)`
  - `M.find_external_drop_target(mx, my, items, key_fn, rect_track, is_single_column, grid_bounds)`
  - `M.build_dragged_set(dragged_ids)`
**Private Functions**: 4 helpers

### `ReArkitekt/gui/widgets/grid/grid_bridge.lua`
> ReArkitekt/gui/widgets/grid/grid_bridge.lua

**Modules**: `M, GridBridge`
**Classes**: `GridBridge, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance

### `ReArkitekt/gui/widgets/grid/input.lua`
> ReArkitekt/gui/widgets/grid/input.lua

**Modules**: `M, keys_to_adjust, order, order`
**Public API**:
  - `M.is_external_drag_active(grid)`
  - `M.is_mouse_in_exclusion(grid, ctx, item, rect)`
  - `M.find_hovered_item(grid, ctx, items)`
  - `M.is_shortcut_pressed(ctx, shortcut, state)`
  - `M.reset_shortcut_states(ctx, state)`
  - `M.handle_shortcuts(grid, ctx)`
  - `M.handle_wheel_input(grid, ctx, items)`
  - `M.handle_tile_input(grid, ctx, item, rect)`
  - `M.check_start_drag(grid, ctx)`
**Dependencies**: `ReArkitekt.gui.draw`

### `ReArkitekt/gui/widgets/grid/layout.lua`
> ReArkitekt/gui/widgets.grid.layout.lua

**Modules**: `M, rects`
**Public API**:
  - `M.calculate(avail_w, min_col_w, gap, n_items, origin_x, origin_y, fixed_tile_h)`
  - `M.get_height(rows, tile_h, gap)`

### `ReArkitekt/gui/widgets/grid/rendering.lua`
> ReArkitekt/gui/widgets/grid/rendering.lua

**Modules**: `M`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.marching_ants`

### `ReArkitekt/gui/widgets/navigation/menutabs.lua`
> ReArkitekt/gui/widgets/menutabs.lua

**Modules**: `M, o, o, edges`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Private Functions**: 4 helpers

### `ReArkitekt/gui/widgets/package_tiles/grid.lua`
> ReArkitekt/gui/widgets/package_tiles/grid.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(pkg, settings, theme)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.widgets.package_tiles.renderer, ReArkitekt.gui.widgets.package_tiles.micromanage`

### `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
> ReArkitekt/gui/widgets/package_tiles/micromanage.lua

**Modules**: `M`
**Public API**:
  - `M.open(pkg_id)`
  - `M.close()`
  - `M.is_open()`
  - `M.get_package_id()`
  - `M.draw_window(ctx, pkg, settings)`
  - `M.reset()`

### `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
> ReArkitekt/gui/widgets/package_tiles/renderer.lua

**Modules**: `M`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.gui.fx.marching_ants, ReArkitekt.core.colors`

### `ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`
> ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua

**Modules**: `M, item_map, items_by_key, dragged_items, items_by_key, new_items`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(rt, config)` → Instance
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.active`

### `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
> ReArkitekt/gui/widgets/region_tiles/coordinator.lua

**Modules**: `M, result, RegionTiles, copy, spawned_keys, rids, colors, keys_to_adjust`
**Classes**: `RegionTiles, M` (stateful objects)
**Public API**:
  - `M.create(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.systems.playback_manager, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.fx.dnd.drag_indicator, (+9 more)`

### `ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua`
> ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua

**Modules**: `M, rids, rids`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.create(rt, config)` → Instance
**Private Functions**: 4 helpers
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.pool`

### `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/active.lua

**Modules**: `M`
**Public API**:
  - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, playback_manager)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config, ReArkitekt.gui.fx.marching_ants, (+1 more)`

### `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua

**Modules**: `M`
**Public API**:
  - `M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config, ReArkitekt.gui.fx.marching_ants, (+1 more)`

### `ReArkitekt/gui/widgets/region_tiles/selector.lua`
> ReArkitekt/gui/widgets/region_tiles/selector.lua

**Modules**: `M, Selector`
**Classes**: `Selector, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion`

## State Ownership

### Stateful Modules (Classes/Objects)
- **`runtime.lua`**: M
- **`window.lua`**: M
- **`lifecycle.lua`**: Group, M
- **`settings.lua`**: Settings
- **`rect_track.lua`**: RectTrack, M
- **`track.lua`**: Track, M
- **`destroy.lua`**: DestroyAnim, M
- **`spawn.lua`**: SpawnTracker, M
- **`tile_motion.lua`**: TileAnimator, M
- **`images.lua`**: Cache, M
- ... and 16 more

### Stateless Modules (Pure Functions)
- **25** stateless modules
- **17** with no dependencies (pure utility modules)

## Integration Essentials

### Module Creators
- `M.new(opts)` in `runtime.lua`
- `M.new(opts)` in `window.lua`
- `M.new()` in `lifecycle.lua`
- `M.new(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)` in `rect_track.lua`
- `M.new(initial_value, speed)` in `track.lua`
- `M.new(opts)` in `destroy.lua`
- `M.new(config)` in `spawn.lua`
- `M.new(default_speed)` in `tile_motion.lua`
- ... and 18 more

### Callback-Based APIs
- `M.find_drop_target()` expects: key_fn
- `M.find_external_drop_target()` expects: key_fn
- `M.render()` expects: on_repeat_cycle
- `M.draw()` expects: content_fn, on_search_changed, on_sort_changed
- `M.capture_over_last_item()` expects: on_delta
- ... and 1 more

## Module Classification

**Pure Modules** (no dependencies): 31
  - `ReArkitekt/app/runtime.lua`
  - `ReArkitekt/app/window.lua`
  - `ReArkitekt/core/colors.lua`
  - `ReArkitekt/core/json.lua`
  - `ReArkitekt/core/lifecycle.lua`
  - ... and 26 more

**Class Modules** (OOP with metatables): 26
  - `runtime.lua`: M
  - `window.lua`: M
  - `lifecycle.lua`: Group, M
  - `settings.lua`: Settings
  - `rect_track.lua`: RectTrack, M
  - ... and 21 more

## Top 10 Largest Files

1. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua` (748 lines)
2. `ReArkitekt/mock_region_playlist.lua` (676 lines)
3. `ReArkitekt/gui/widgets/grid/core.lua` (555 lines)
4. `ReArkitekt/gui/widgets/tiles_container.lua` (480 lines)
5. `ReArkitekt/core/colors.lua` (428 lines)
6. `ReArkitekt/demo.lua` (299 lines)
7. `ReArkitekt/gui/images.lua` (284 lines)
8. `ReArkitekt/gui/widgets/navigation/menutabs.lua` (268 lines)
9. `ReArkitekt/gui/widgets/sliders/hue.lua` (260 lines)
10. `ReArkitekt/gui/widgets/grid/drop_zones.lua` (240 lines)

## Dependency Analysis

### Forward Dependencies (What Each File Imports)

**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** imports 14 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/systems/height_stabilizer.lua`
  → `ReArkitekt/gui/systems/playback_manager.lua`
  → `ReArkitekt/gui/systems/responsive_grid.lua`
  → `ReArkitekt/gui/widgets/grid/grid_bridge.lua`
  → ... and 6 more

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

**`ReArkitekt/demo.lua`** imports 7 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/navigation/menutabs.lua`
  → `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** imports 6 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** imports 6 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`
  → `ReArkitekt/gui/fx/tile_fx.lua`
  → `ReArkitekt/gui/fx/tile_fx_config.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`

**`ReArkitekt/mock_region_playlist.lua`** imports 6 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** imports 5 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/demo2.lua`** imports 4 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/sliders/hue.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

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

**`ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua`** imports 2 modules:
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/core/settings.lua`** imports 1 modules:
  → `ReArkitekt/core/json.lua`

**`ReArkitekt/gui/fx/animation/rect_track.lua`** imports 1 modules:
  → `ReArkitekt/core/math.lua`

**`ReArkitekt/gui/fx/animation/track.lua`** imports 1 modules:
  → `ReArkitekt/core/math.lua`

### Reverse Dependencies (What Imports Each File)

**`ReArkitekt/core/colors.lua`** is imported by 11 files:
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/fx/tile_fx.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← ... and 3 more

**`ReArkitekt/gui/draw.lua`** is imported by 11 files:
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/grid/input.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
  ← ... and 3 more

**`ReArkitekt/app/shell.lua`** is imported by 4 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/mock_region_playlist.lua`
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/fx/marching_ants.lua`** is imported by 4 files:
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/fx/tile_motion.lua`** is imported by 4 files:
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`** is imported by 3 files:
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid_factory.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid_factory.lua`

**`ReArkitekt/gui/widgets/status_bar.lua`** is imported by 3 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/tiles_container.lua`** is imported by 3 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

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

**`ReArkitekt/gui/fx/tile_fx_config.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/systems/tile_utilities.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

### Circular Dependencies

✓ No circular dependencies detected

### Isolated Files (No Imports or Exports)

- `ReArkitekt/core/lifecycle.lua`
- `ReArkitekt/gui/images.lua`
- `ReArkitekt/gui/style.lua`
- `ReArkitekt/gui/systems/reorder.lua`
- `ReArkitekt/input/wheel_guard.lua`

### Dependency Complexity Ranking

1. `ReArkitekt/gui/widgets/grid/core.lua`: 13 imports + 3 importers = 16 total
2. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`: 14 imports + 1 importers = 15 total
3. `ReArkitekt/core/colors.lua`: 0 imports + 11 importers = 11 total
4. `ReArkitekt/gui/draw.lua`: 0 imports + 11 importers = 11 total
5. `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`: 6 imports + 2 importers = 8 total
6. `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`: 6 imports + 2 importers = 8 total
7. `ReArkitekt/demo.lua`: 7 imports + 0 importers = 7 total
8. `ReArkitekt/app/shell.lua`: 2 imports + 4 importers = 6 total
9. `ReArkitekt/gui/widgets/package_tiles/grid.lua`: 5 imports + 1 importers = 6 total
10. `ReArkitekt/mock_region_playlist.lua`: 6 imports + 0 importers = 6 total

## Important Constraints

### Object Lifecycle
- Classes use metatable pattern: `ClassName.__index = ClassName`
- Constructor functions typically named `new()` or `create()`
- Always call constructor before using instance methods

### Callback Requirements
- 6 modules use callback patterns for extensibility
- Callbacks enable features like event handling and custom behavior
- Check function signatures for `on_*`, `*_callback`, or `*_handler` parameters
