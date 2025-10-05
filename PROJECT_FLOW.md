# PROJECT FLOW: ARKADATA Scripts
Generated: 2025-10-05 16:20:20
Root: D:/Dropbox/REAPER/Scripts/ARKADATA Scripts

## Overview
- **Folders Analyzed**: 1
- **Total Files**: 48
- **Total Code Lines**: 6,708
- **Public Functions**: 102
- **Classes (Metatables)**: 18

## Folder Structure
### ReArkitekt/
  - Files: 48
  - Lines: 6,708
  - Exports: 102

## Execution Flow Patterns

### Entry Points (Nothing Imports These)
**`settings.lua`**
  → Initializes: json

**`demo.lua`**
  → Initializes: ReArkitekt.app.shell, ReArkitekt.gui.widgets.menutabs, ReArkitekt.gui.widgets.status_bar (+3 more)

**`demo2.lua`**
  → Initializes: ReArkitekt.app.shell, ReArkitekt.gui.widgets.hue_slider, ReArkitekt.gui.widgets.status_bar (+1 more)

### Orchestration Pattern
**`core.lua`** composes 10 modules:
  layout_grid + motion + selection + selection_rectangle + draw (+5 more)

**`coordinator.lua`** composes 10 modules:
  draw + colors + tile_motion + drag_indicator + active (+5 more)

**`demo.lua`** composes 6 modules:
  shell + menutabs + status_bar + package_tiles + tiles_container (+1 more)

## Module API Surface

### `ReArkitekt/app/runtime.lua`
> ReArkitekt/app/runtime.lua

**Modules**: `M`
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
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/core/colors.lua`
> ReArkitekt/gui/colors.lua

**Modules**: `M`
**Public API**:
  - `M.rgba_to_components(color)`
  - `M.components_to_rgba(r, g, b, a)`
  - `M.with_alpha(color, alpha)`
  - `M.adjust_brightness(color, factor)`
  - `M.desaturate(color, amount)`
  - `M.saturate(color, amount)`
  - `M.luminance(color)`
  - `M.generate_border(base_color, desaturate_amt, brightness_factor)`
  - `M.generate_hover(base_color, brightness_factor)`
  - `M.generate_active_border(base_color, saturation_boost, brightness_boost)`
  - `M.generate_selection_color(base_color, brightness_boost, saturation_boost)`
  - `M.generate_marching_ants_color(base_color, brightness_factor, saturation_factor)`
  - `M.auto_text_color(bg_color)`
  - `M.lerp_component(a, b, t)`
  - `M.lerp(color_a, color_b, t)`
  - `M.auto_palette(base_color)`
  - `M.flashy_palette(base_color)`

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
**Classes**: `Group` (stateful objects)
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
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.menutabs, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.package_tiles, ReArkitekt.gui.widgets.tiles_container, ReArkitekt.gui.widgets.selection_rectangle`

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

### `ReArkitekt/gui/effects.lua`
> ReArkitekt/gui/effects.lua

**Modules**: `M`
**Public API**:
  - `M.marching_ants_rounded(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)`
  - `M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)`
  - `M.drop_line(dl, x, y1, y2, color, thickness, cap_radius)`
  - `M.selection_overlay(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)`
  - `M.ghost_rect(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)`
  - `M.dim_rect(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)`

### `ReArkitekt/gui/fx/animations/destroy.lua`
> ReArkitekt/gui/systems/destroy_animation.lua

**Modules**: `M, DestroyAnim, completed`
**Classes**: `DestroyAnim` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/fx/animations/spawn.lua`
> ReArkitekt/gui/systems/spawn_animation.lua

**Modules**: `M, SpawnTracker`
**Classes**: `SpawnTracker` (stateful objects)
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
**Classes**: `TileAnimator` (stateful objects)
**Public API**:
  - `M.new(default_speed)` → Instance

### `ReArkitekt/gui/images.lua`
> core/image_cache.lua

**Modules**: `M, Cache`
**Classes**: `Cache` (stateful objects)
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
**Classes**: `HeightStabilizer` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/widgets.grid.layout.lua`
> ReArkitekt/gui/widgets.grid.layout.lua

**Modules**: `M, rects`
**Public API**:
  - `M.calculate(avail_w, min_col_w, gap, n_items, origin_x, origin_y, fixed_tile_h)`
  - `M.get_height(rows, tile_h, gap)`

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
**Classes**: `Selection` (stateful objects)
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
**Classes**: `AnimationCoordinator` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.fx.animations.spawn, ReArkitekt.gui.fx.animations.destroy`

### `ReArkitekt/gui/widgets/grid/core.lua`
> ReArkitekt/gui/widgets/grid/core.lua

**Modules**: `M, Grid, map, non_dragged_items, drop_zones, dragged_set, current_keys, new_keys, rect_map, order, dragged_set, filtered_order, new_order`
**Classes**: `Grid` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.layout, ReArkitekt.gui.fx.motion, ReArkitekt.gui.systems.selection, ReArkitekt.gui.widgets.selection_rectangle, ReArkitekt.gui.draw, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.fx.dnd.drop_indicator, ReArkitekt.gui.widgets.grid.rendering, ReArkitekt.gui.widgets.grid.animation, ReArkitekt.gui.widgets.grid.input`

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

### `ReArkitekt/gui/widgets/grid/rendering.lua`
> ReArkitekt/gui/widgets/grid/rendering.lua

**Modules**: `M`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.effects`

### `ReArkitekt/gui/widgets/hue_slider.lua`
> ReArkitekt/gui/widgets/hue_slider.lua

**Modules**: `M, _locks`
**Public API**:
  - `M.draw_hue(ctx, id, hue, opt)`
  - `M.draw_saturation(ctx, id, saturation, base_hue, opt)`
  - `M.draw_gamma(ctx, id, gamma, opt)`
  - `M.draw(ctx, id, hue, opt)`

### `ReArkitekt/gui/widgets/menutabs.lua`
> ReArkitekt/gui/widgets/menutabs.lua

**Modules**: `M, o, o, edges`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance
**Private Functions**: 4 helpers

### `ReArkitekt/gui/widgets/package_tiles.lua`
> ReArkitekt/gui/widgets/package_tiles.lua

**Modules**: `M`
**Public API**:
  - `M.draw_micromanage_window(ctx, pkg, settings)`
**Dependencies**: `ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage`

### `ReArkitekt/gui/widgets/package_tiles/grid.lua`
> ReArkitekt/gui/widgets/package_tiles/grid.lua

**Modules**: `M`
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
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.gui.effects, ReArkitekt.core.colors`

### `ReArkitekt/gui/widgets/region_tiles.lua`
> ReArkitekt/gui/widgets/region_tiles.lua

**Modules**: `M`
**Dependencies**: `ReArkitekt.gui.widgets.region_tiles.coordinator`

### `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
> ReArkitekt/gui/widgets/region_tiles/active_grid.lua

**Modules**: `M, item_map, items_by_key, dragged_items, items_by_key, new_items, spawned_keys`
**Public API**:
  - `M.create_active_grid(rt, config)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.active`

### `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
> ReArkitekt/gui/widgets/region_tiles/coordinator.lua

**Modules**: `M, result, RegionTiles, colors, keys_to_adjust`
**Classes**: `RegionTiles` (stateful objects)
**Public API**:
  - `M.create(opts)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.widgets.region_tiles.renderers.active, ReArkitekt.gui.widgets.region_tiles.renderers.pool, ReArkitekt.gui.systems.height_stabilizer, ReArkitekt.gui.widgets.region_tiles.selector, ReArkitekt.gui.widgets.region_tiles.active_grid, ReArkitekt.gui.widgets.region_tiles.pool_grid`

### `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`
> ReArkitekt/gui/widgets/region_tiles/pool_grid.lua

**Modules**: `M, rids, rids`
**Public API**:
  - `M.create_pool_grid(rt, config)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.pool`

### `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
> ReArkitekt/gui/widgets/tiles/active_tile.lua

**Modules**: `M`
**Public API**:
  - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities`

### `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
> ReArkitekt/gui/widgets/tiles/pool_tile.lua

**Modules**: `M`
**Public API**:
  - `M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities`

### `ReArkitekt/gui/widgets/region_tiles/selector.lua`
> ReArkitekt/gui/widgets/region_tiles/selector.lua

**Modules**: `M, Selector`
**Classes**: `Selector` (stateful objects)
**Public API**:
  - `M.new(config)` → Instance
**Dependencies**: `ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion`

### `ReArkitekt/gui/widgets/selection_rectangle.lua`
> ReArkitekt/gui/widgets/selection_rectangle.lua

**Modules**: `M, SelRect`
**Classes**: `SelRect` (stateful objects)
**Public API**:
  - `M.new(opts)` → Instance

### `ReArkitekt/gui/widgets/status_bar.lua`
> ReArkitekt/gui/widgets/status_bar.lua

**Modules**: `M, right_items, item_widths`
**Public API**:
  - `M.new(config)` → Instance
**Private Functions**: 4 helpers

### `ReArkitekt/gui/widgets/tabs.lua`
> ReArkitekt/gui/widgets/tabs.lua

**Modules**: `M`
**Classes**: `M` (stateful objects)
**Public API**:
  - `M.new(id, opts)` → Instance
**Dependencies**: `ReArkitekt.gui.widgets.tabs`

### `ReArkitekt/gui/widgets/tiles_container.lua`
> ReArkitekt/gui/widgets/tiles_container.lua

**Modules**: `M, Container`
**Classes**: `Container` (stateful objects)
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
**Dependencies**: `ReArkitekt.app.shell, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion`

### `ReArkitekt/widget_demo.lua`
> demo.lua — ReArkitekt ColorBlocks demo (fixed: numeric gap/min_col_w)

**Modules**: `t, arr`
**Private Functions**: 12 helpers
**Dependencies**: `ReArkitekt.*, ReArkitekt.app.shell, ReArkitekt.gui.widgets.colorblocks, ReArkitekt.gui.draw, ReArkitekt.gui.effects`

## State Ownership

### Stateful Modules (Classes/Objects)
- **`lifecycle.lua`**: Group
- **`settings.lua`**: Settings
- **`destroy.lua`**: DestroyAnim
- **`spawn.lua`**: SpawnTracker
- **`motion.lua`**: Track, RectTrack
- **`tile_motion.lua`**: TileAnimator
- **`images.lua`**: Cache
- **`height_stabilizer.lua`**: HeightStabilizer
- **`selection.lua`**: Selection
- **`animation.lua`**: AnimationCoordinator
- ... and 7 more

### Stateless Modules (Pure Functions)
- **24** stateless modules
- **14** with no dependencies (pure utility modules)

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
- ... and 13 more

### Callback-Based APIs
- `M.render()` expects: on_repeat_cycle
- `M.draw()` expects: content_fn
- `M.capture_over_last_item()` expects: on_delta
- `M.capture_if()` expects: on_delta

## Top 10 Largest Files

1. `ReArkitekt/gui/widgets/grid/core.lua` (559 lines, 1 exports)
2. `ReArkitekt/gui/widgets/region_tiles/coordinator.lua` (517 lines, 1 exports)
3. `ReArkitekt/mock_region_playlist.lua` (472 lines, 0 exports)
4. `ReArkitekt/gui/fx/dnd/drag_indicator.lua` (256 lines, 2 exports)
5. `ReArkitekt/demo.lua` (247 lines, 0 exports)
6. `ReArkitekt/gui/images.lua` (239 lines, 1 exports)
7. `ReArkitekt/gui/widgets/menutabs.lua` (228 lines, 1 exports)
8. `ReArkitekt/gui/widgets/hue_slider.lua` (199 lines, 4 exports)
9. `ReArkitekt/gui/widgets/package_tiles/renderer.lua` (188 lines, 0 exports)
10. `ReArkitekt/gui/widgets/grid/input.lua` (186 lines, 9 exports)

## Module Classification

**Pure Modules** (no dependencies): 25
  - `runtime.lua`
  - `window.lua`
  - `colors.lua`
  - `json.lua`
  - `lifecycle.lua`
  - ... and 20 more

**Class Modules** (OOP with metatables): 17
  - `lifecycle.lua`: Group
  - `settings.lua`: Settings
  - `destroy.lua`: DestroyAnim
  - `spawn.lua`: SpawnTracker
  - `motion.lua`: Track, RectTrack
  - ... and 12 more

## Dependency Graph

**`ReArkitekt/app/shell.lua`**
  → `ReArkitekt/app/runtime.lua`
  → `ReArkitekt/app/window.lua`

**`ReArkitekt/demo.lua`**
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/menutabs.lua`
  → `ReArkitekt/gui/widgets/package_tiles.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/demo2.lua`**
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/hue_slider.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/gui/fx/dnd/drag_indicator.lua`**
  → `ReArkitekt/gui/draw.lua`

**`ReArkitekt/gui/widgets/grid/animation.lua`**
  → `ReArkitekt/gui/fx/animations/destroy.lua`
  → `ReArkitekt/gui/fx/animations/spawn.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`**
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/dnd/drop_indicator.lua`
  → `ReArkitekt/gui/fx/motion.lua`
  → `ReArkitekt/gui/widgets.grid.layout.lua`
  → `ReArkitekt/gui/systems/selection.lua`
  → `ReArkitekt/gui/widgets/grid/animation.lua`
  → `ReArkitekt/gui/widgets/grid/input.lua`
  → `ReArkitekt/gui/widgets/grid/rendering.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`

**`ReArkitekt/gui/widgets/grid/input.lua`**
  → `ReArkitekt/gui/draw.lua`

**`ReArkitekt/gui/widgets/grid/rendering.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/effects.lua`

**`ReArkitekt/gui/widgets/package_tiles.lua`**
  → `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`**
  → `ReArkitekt/gui/fx/motion.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/gui/widgets/package_tiles/renderer.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/effects.lua`

**`ReArkitekt/gui/widgets/region_tiles.lua`**
  → `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/widgets/region_tiles/active_grid.lua`**
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`

**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/systems/height_stabilizer.lua`
  → `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
  → `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
  → `ReArkitekt/gui/widgets/region_tiles/selector.lua`

**`ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`**
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/systems/tile_utilities.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/region_tiles/selector.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`

**`ReArkitekt/gui/widgets/tabs.lua`**
  → `ReArkitekt/gui/widgets/tabs.lua`

**`ReArkitekt/mock_region_playlist.lua`**
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`

**`ReArkitekt/widget_demo.lua`**
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/effects.lua`

## Circular Dependencies

**Cycle 1**: `ReArkitekt/gui/widgets/tabs.lua` → `ReArkitekt/gui/widgets/tabs.lua`

## Important Constraints

### Object Lifecycle
- Classes use metatable pattern: `ClassName.__index = ClassName`
- Constructor functions typically named `new()` or `create()`
- Always call constructor before using instance methods

### Callback Requirements
- 4 modules use callback patterns for extensibility
- Callbacks enable features like event handling and custom behavior
- Check function signatures for `on_*`, `*_callback`, or `*_handler` parameters
