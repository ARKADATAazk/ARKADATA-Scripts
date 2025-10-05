# PROJECT FLOW: ARKADATA Scripts
Generated: 2025-10-06 00:47:08
Root: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts

## Project Structure

```
└── ReArkitekt/
    ├── app/
    │   ├── runtime.lua         # (68 lines)
    │   ├── shell.lua         # (96 lines)
    │   └── window.lua         # (182 lines)
    ├── core/
    │   ├── colors.lua         # (368 lines)
    │   ├── json.lua         # (120 lines)
    │   ├── lifecycle.lua         # (80 lines)
    │   ├── math.lua         # (1 lines)
    │   └── settings.lua         # (118 lines)
    ├── gui/
    │   ├── fx/
    │   │   ├── animations/
    │   │   │   ├── destroy.lua         # (151 lines)
    │   │   │   └── spawn.lua         # (63 lines)
    │   │   ├── dnd/
    │   │   │   ├── config.lua         # (1 lines)
    │   │   │   ├── drag_indicator.lua         # (317 lines)
    │   │   │   └── drop_indicator.lua         # (149 lines)
    │   │   ├── effects.lua         # (25 lines)
    │   │   ├── marching_ants.lua         # (141 lines)
    │   │   ├── motion.lua         # (177 lines)
    │   │   └── tile_motion.lua         # (64 lines)
    │   ├── systems/
    │   │   ├── height_stabilizer.lua         # (73 lines)
    │   │   ├── reorder.lua         # (126 lines)
    │   │   ├── selection.lua         # (141 lines)
    │   │   └── tile_utilities.lua         # (27 lines)
    │   ├── widgets/
    │   │   ├── grid/
    │   │   │   ├── animation.lua         # (100 lines)
    │   │   │   ├── core.lua         # (671 lines)
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
    │   │   │   │   ├── active.lua         # (172 lines)
    │   │   │   │   └── pool.lua         # (116 lines)
    │   │   │   ├── active_grid.lua         # (196 lines)
    │   │   │   ├── coordinator.lua         # (636 lines)
    │   │   │   ├── pool_grid.lua         # (96 lines)
    │   │   │   └── selector.lua         # (97 lines)
    │   │   ├── sliders/
    │   │   │   └── hue.lua         # (260 lines)
    │   │   ├── selection_rectangle.lua         # (98 lines)
    │   │   ├── status_bar.lua         # (196 lines)
    │   │   └── tiles_container.lua         # (249 lines)
    │   ├── draw.lua         # (113 lines)
    │   ├── images.lua         # (284 lines)
    │   └── style.lua         # (173 lines)
    ├── input/
    │   └── wheel_guard.lua         # (42 lines)
    ├── demo.lua         # (299 lines)
    ├── demo2.lua         # (185 lines)
    ├── mock_region_playlist.lua         # (571 lines)
    └── widget_demo.lua         # (222 lines)
```

## Overview
- **Total Files**: 48
- **Total Lines**: 8,507
- **Code Lines**: 6,664
- **Public Functions**: 108
- **Classes**: 34
- **Modules**: 112

## Folder Structure
### ReArkitekt/
  - Files: 48
  - Lines: 6,664
  - Exports: 108

## Execution Flow Patterns

### Entry Points (Not Imported by Others)
- **`ReArkitekt/gui/systems/reorder.lua`**
- **`ReArkitekt/widget_demo.lua`**
  → Imports: ReArkitekt.app.shell, ReArkitekt.gui.widgets.colorblocks, ReArkitekt.gui.draw (+2 more)
- **`ReArkitekt/core/math.lua`**
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

### Orchestration Pattern
**`ReArkitekt/gui/widgets/grid/core.lua`** composes 10 modules:
  layout + motion + selection + selection_rectangle + draw (+5 more)
**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** composes 10 modules:
  draw + colors + tile_motion + drag_indicator + active (+5 more)
**`ReArkitekt/demo.lua`** composes 7 modules:
  shell + menutabs + status_bar + grid + micromanage (+2 more)
**`ReArkitekt/mock_region_playlist.lua`** composes 6 modules:
  shell + status_bar + coordinator + draw + colors (+1 more)
**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** composes 5 modules:
  core + motion + tile_motion + renderer + micromanage

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

### `ReArkitekt/gui/fx/animations/destroy.lua`
> ReArkitekt/gui/systems/destroy_animation.lua

**Modules**: `M, DestroyAnim, completed`
**Classes**: `DestroyAnim, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/fx/animations/spawn.lua`
> ReArkitekt/gui/systems/spawn_animation.lua

**Modules**: `M, SpawnTracker`
**Classes**: `SpawnTracker, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance

### `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
> ReArkitekt/gui/widgets/tiles/ghost_tiles.lua

**Modules**: `M`
**Public API**:
  - `M.draw_badge(ctx, dl, mx, my, count, config, is_copy_mode, is_delete_mode)`
  - `M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)`
**Private Functions**: 6 helpers
**Dependencies**: `ReArkitekt.gui.draw`

### `ReArkitekt/gui/fx/dnd/drop_indicator.lua`
> ReArkitekt/gui/widgets/tiles/dnd.drop_indicator.lua

**Modules**: `M`
**Public API**:
  - `M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)`
  - `M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)`
  - `M.draw(ctx, dl, config, is_copy_mode, orientation, ...)`

### `ReArkitekt/gui/fx/effects.lua`
> ReArkitekt/gui/effects.lua

**Modules**: `M`
**Public API**:
  - `M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)`

### `ReArkitekt/gui/fx/marching_ants.lua`
> ReArkitekt/gui/fx/marching_ants.lua

**Modules**: `M`
**Public API**:
  - `M.draw(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)`

### `ReArkitekt/gui/fx/motion.lua`
> ReArkitekt/gui/systems/motion.lua

**Modules**: `M, Track, RectTrack`
**Classes**: `Track, RectTrack` (stateful objects)
**Public API**:
  - `M.Track(initial_value, speed)`
  - `M.RectTrack(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)`
  - `M.color_lerp(c1, c2, t)`

### `ReArkitekt/gui/fx/tile_motion.lua`
> ReArkitekt/gui/systems/tile_animation.lua

**Modules**: `M, TileAnimator`
**Classes**: `TileAnimator, M` (stateful objects)
**Public API**:
  - `M.new(default_speed)` → Instance

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

### `ReArkitekt/gui/systems/reorder.lua`
> ReArkitekt/gui/systems/reorder.lua

**Modules**: `M, t, base, new_order, new_order, new_order`
**Public API**:
  - `M.insert_relative(order_keys, dragged_keys, target_key, side)`
  - `M.move_up(order_keys, selected_keys)`
  - `M.move_down(order_keys, selected_keys)`

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

**Modules**: `M, Grid, map, non_dragged_items, drop_zones, dragged_set, current_keys, new_keys, rect_map, order, dragged_set, filtered_order, new_order`
**Classes**: `Grid, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.layout, ReArkitekt.gui.fx.motion, ReArkitekt.gui.systems.selection, ReArkitekt.gui.widgets.selection_rectangle, ReArkitekt.gui.draw, (+5 more)`

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
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.fx.motion, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.widgets.package_tiles.renderer, ReArkitekt.gui.widgets.package_tiles.micromanage`

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

### `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
> ReArkitekt/gui/widgets/region_tiles/active_grid.lua

**Modules**: `M, item_map, items_by_key, dragged_items, items_by_key, new_items, spawned_keys`
**Public API**:
  - `M.create_active_grid(rt, config)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.active`

### `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
> ReArkitekt/gui/widgets/region_tiles/coordinator.lua

**Modules**: `M, result, RegionTiles, colors, keys_to_adjust`
**Classes**: `RegionTiles, M` (stateful objects)
**Public API**:
  - `M.create(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.widgets.region_tiles.renderers.active, (+5 more)`

### `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`
> ReArkitekt/gui/widgets/region_tiles/pool_grid.lua

**Modules**: `M, rids, rids`
**Public API**:
  - `M.create_pool_grid(rt, config)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.pool`

### `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/active.lua

**Modules**: `M`
**Public API**:
  - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities`

### `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
> ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua

**Modules**: `M`
**Public API**:
  - `M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities`

### `ReArkitekt/gui/widgets/region_tiles/selector.lua`
> ReArkitekt/gui/widgets/region_tiles/selector.lua

**Modules**: `M, Selector`
**Classes**: `Selector, M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion`

### `ReArkitekt/gui/widgets/selection_rectangle.lua`
> ReArkitekt/gui/widgets/selection_rectangle.lua

**Modules**: `M, SelRect`
**Classes**: `SelRect, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/widgets/sliders/hue.lua`
> ReArkitekt/gui/widgets/hue_slider.lua

**Modules**: `M, _locks`
**Public API**:
  - `M.draw_hue(ctx, id, hue, opt)`
  - `M.draw_saturation(ctx, id, saturation, base_hue, opt)`
  - `M.draw_gamma(ctx, id, gamma, opt)`
  - `M.draw(ctx, id, hue, opt)`

### `ReArkitekt/gui/widgets/status_bar.lua`
> ReArkitekt/gui/widgets/status_bar.lua

**Modules**: `M, right_items, item_widths`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Private Functions**: 4 helpers

### `ReArkitekt/gui/widgets/tiles_container.lua`
> ReArkitekt/gui/widgets/tiles_container.lua

**Modules**: `M, Container`
**Classes**: `Container, M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
  - `M.draw(ctx, id, width, height, content_fn, config)`

### `ReArkitekt/input/wheel_guard.lua`
> ReArkitekt/input/wheel_guard.lua

**Public API**:
  - `M.begin(ctx)`
  - `M.capture_over_last_item(ctx, on_delta)`
  - `M.capture_if(ctx, condition, on_delta)`
  - `M.finish(ctx)`
**Dependencies**: `imgui`

### `ReArkitekt/mock_region_playlist.lua`
> ReArkitekt/mock_region_playlist.lua

**Modules**: `result, new_items, keys_to_delete, new_items, dragged_keys, filtered_items, new_keys`
**Private Functions**: 8 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.gui.draw, ReArkitekt.core.colors, (+1 more)`

### `ReArkitekt/widget_demo.lua`
> demo.lua — ReArkitekt ColorBlocks demo (fixed: numeric gap/min_col_w)

**Modules**: `t, arr`
**Private Functions**: 12 helpers
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.colorblocks, ReArkitekt.gui.draw, ReArkitekt.gui.fx.effects, ReArkitekt.*`

## State Ownership

### Stateful Modules (Classes/Objects)
- **`runtime.lua`**: M
- **`window.lua`**: M
- **`lifecycle.lua`**: Group, M
- **`settings.lua`**: Settings
- **`destroy.lua`**: DestroyAnim, M
- **`spawn.lua`**: SpawnTracker, M
- **`motion.lua`**: Track, RectTrack
- **`tile_motion.lua`**: TileAnimator, M
- **`images.lua`**: Cache, M
- **`height_stabilizer.lua`**: HeightStabilizer, M
- ... and 10 more

### Stateless Modules (Pure Functions)
- **20** stateless modules
- **12** with no dependencies (pure utility modules)

## Integration Essentials

### Module Creators
- `M.new(opts)` in `runtime.lua`
- `M.new(opts)` in `window.lua`
- `M.new()` in `lifecycle.lua`
- `M.new(opts)` in `destroy.lua`
- `M.new(config)` in `spawn.lua`
- `M.new(default_speed)` in `tile_motion.lua`
- `M.new(opts)` in `images.lua`
- `M.new(opts)` in `height_stabilizer.lua`
- ... and 12 more

### Callback-Based APIs
- `M.render()` expects: on_repeat_cycle
- `M.draw()` expects: content_fn
- `M.capture_over_last_item()` expects: on_delta
- `M.capture_if()` expects: on_delta

## Module Classification

**Pure Modules** (no dependencies): 29
  - `ReArkitekt/app/runtime.lua`
  - `ReArkitekt/app/window.lua`
  - `ReArkitekt/core/colors.lua`
  - `ReArkitekt/core/json.lua`
  - `ReArkitekt/core/lifecycle.lua`
  - ... and 24 more

**Class Modules** (OOP with metatables): 20
  - `runtime.lua`: M
  - `window.lua`: M
  - `lifecycle.lua`: Group, M
  - `settings.lua`: Settings
  - `destroy.lua`: DestroyAnim, M
  - ... and 15 more

## Top 10 Largest Files

1. `ReArkitekt/gui/widgets/grid/core.lua` (671 lines)
2. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua` (636 lines)
3. `ReArkitekt/mock_region_playlist.lua` (571 lines)
4. `ReArkitekt/core/colors.lua` (368 lines)
5. `ReArkitekt/gui/fx/dnd/drag_indicator.lua` (317 lines)
6. `ReArkitekt/demo.lua` (299 lines)
7. `ReArkitekt/gui/images.lua` (284 lines)
8. `ReArkitekt/gui/widgets/navigation/menutabs.lua` (268 lines)
9. `ReArkitekt/gui/widgets/sliders/hue.lua` (260 lines)
10. `ReArkitekt/gui/widgets/tiles_container.lua` (249 lines)

## Dependency Analysis

### Forward Dependencies (What Each File Imports)

**`ReArkitekt/gui/widgets/grid/core.lua`** imports 10 modules:
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/dnd/drop_indicator.lua`
  → `ReArkitekt/gui/fx/motion.lua`
  → `ReArkitekt/gui/systems/selection.lua`
  → `ReArkitekt/gui/widgets/grid/animation.lua`
  → `ReArkitekt/gui/widgets/grid/input.lua`
  → `ReArkitekt/gui/widgets/grid/layout.lua`
  → ... and 2 more

**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** imports 10 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/systems/height_stabilizer.lua`
  → `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
  → `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  → ... and 2 more

**`ReArkitekt/demo.lua`** imports 7 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/navigation/menutabs.lua`
  → `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/mock_region_playlist.lua`** imports 6 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** imports 5 modules:
  → `ReArkitekt/gui/fx/motion.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/demo2.lua`** imports 4 modules:
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/sliders/hue.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** imports 4 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** imports 4 modules:
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`

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

**`ReArkitekt/gui/widgets/region_tiles/active_grid.lua`** imports 2 modules:
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`

**`ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`** imports 2 modules:
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/core/settings.lua`** imports 1 modules:
  → `ReArkitekt/core/json.lua`

**`ReArkitekt/gui/fx/dnd/drag_indicator.lua`** imports 1 modules:
  → `ReArkitekt/gui/draw.lua`

**`ReArkitekt/gui/widgets/grid/input.lua`** imports 1 modules:
  → `ReArkitekt/gui/draw.lua`

### Reverse Dependencies (What Imports Each File)

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

**`ReArkitekt/core/colors.lua`** is imported by 7 files:
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`** is imported by 5 files:
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/app/shell.lua`** is imported by 4 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/mock_region_playlist.lua`
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/fx/tile_motion.lua`** is imported by 4 files:
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/status_bar.lua`** is imported by 3 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/fx/dnd/drag_indicator.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/fx/marching_ants.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/gui/fx/motion.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/systems/tile_utilities.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/widgets/package_tiles/micromanage.lua`** is imported by 2 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** is imported by 2 files:
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`

**`ReArkitekt/gui/widgets/selection_rectangle.lua`** is imported by 2 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/tiles_container.lua`** is imported by 2 files:
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`

### Circular Dependencies

✓ No circular dependencies detected

### Isolated Files (No Imports or Exports)

- `ReArkitekt/core/lifecycle.lua`
- `ReArkitekt/core/math.lua`
- `ReArkitekt/gui/fx/dnd/config.lua`
- `ReArkitekt/gui/images.lua`
- `ReArkitekt/gui/style.lua`
- `ReArkitekt/gui/systems/reorder.lua`
- `ReArkitekt/input/wheel_guard.lua`

### Dependency Complexity Ranking

1. `ReArkitekt/gui/widgets/grid/core.lua`: 10 imports + 5 importers = 15 total
2. `ReArkitekt/gui/draw.lua`: 0 imports + 11 importers = 11 total
3. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`: 10 imports + 1 importers = 11 total
4. `ReArkitekt/core/colors.lua`: 0 imports + 7 importers = 7 total
5. `ReArkitekt/demo.lua`: 7 imports + 0 importers = 7 total
6. `ReArkitekt/app/shell.lua`: 2 imports + 4 importers = 6 total
7. `ReArkitekt/gui/widgets/package_tiles/grid.lua`: 5 imports + 1 importers = 6 total
8. `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`: 4 imports + 2 importers = 6 total
9. `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`: 4 imports + 2 importers = 6 total
10. `ReArkitekt/mock_region_playlist.lua`: 6 imports + 0 importers = 6 total

## Important Constraints

### Object Lifecycle
- Classes use metatable pattern: `ClassName.__index = ClassName`
- Constructor functions typically named `new()` or `create()`
- Always call constructor before using instance methods

### Callback Requirements
- 4 modules use callback patterns for extensibility
- Callbacks enable features like event handling and custom behavior
- Check function signatures for `on_*`, `*_callback`, or `*_handler` parameters
