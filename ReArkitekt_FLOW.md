# FOLDER FLOW: ReArkitekt
Generated: 2025-10-06 00:47:08
Location: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts\ReArkitekt

## Overview
- **Files**: 48
- **Total Lines**: 8,507
- **Public Functions**: 108
- **Classes**: 34

## Files

### active.lua (172 lines)
  **Modules**: M
  **Exports**:
    - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities

### active_grid.lua (196 lines)
  **Modules**: M, item_map, items_by_key, dragged_items, items_by_key, new_items, spawned_keys
  **Exports**:
    - `M.create_active_grid(rt, config)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.active

### animation.lua (100 lines)
  **Modules**: M, AnimationCoordinator
  **Classes**: AnimationCoordinator, M
  **Exports**:
    - `M.new(config)`
  **Requires**: ReArkitekt.gui.fx.animations.spawn, ReArkitekt.gui.fx.animations.destroy

### colors.lua (368 lines)
  **Modules**: M
  **Exports**:
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

### config.lua (1 lines)

### coordinator.lua (636 lines)
  **Modules**: M, result, RegionTiles, colors, keys_to_adjust
  **Classes**: RegionTiles, M
  **Exports**:
    - `M.create(opts)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.widgets.region_tiles.renderers.active

### core.lua (671 lines)
  **Modules**: M, Grid, map, non_dragged_items, drop_zones, dragged_set, current_keys, new_keys, rect_map, order, dragged_set, filtered_order, new_order
  **Classes**: Grid, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.widgets.grid.layout, ReArkitekt.gui.fx.motion, ReArkitekt.gui.systems.selection, ReArkitekt.gui.widgets.selection_rectangle, ReArkitekt.gui.draw

### demo.lua (299 lines)
  **Modules**: result
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.navigation.menutabs, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage

### demo2.lua (185 lines)
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.sliders.hue, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.tiles_container

### destroy.lua (151 lines)
  **Modules**: M, DestroyAnim, completed
  **Classes**: DestroyAnim, M
  **Exports**:
    - `M.new(opts)`

### drag_indicator.lua (317 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_badge(ctx, dl, mx, my, count, config, is_copy_mode, is_delete_mode)`
    - `M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)`
  **Requires**: ReArkitekt.gui.draw

### draw.lua (113 lines)
  **Modules**: M
  **Exports**:
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

### drop_indicator.lua (149 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)`
    - `M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)`
    - `M.draw(ctx, dl, config, is_copy_mode, orientation, ...)`

### effects.lua (25 lines)
  **Modules**: M
  **Exports**:
    - `M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)`

### grid.lua (196 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.create(pkg, settings, theme)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.fx.motion, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.widgets.package_tiles.renderer, ReArkitekt.gui.widgets.package_tiles.micromanage

### height_stabilizer.lua (73 lines)
  **Modules**: M, HeightStabilizer
  **Classes**: HeightStabilizer, M
  **Exports**:
    - `M.new(opts)`

### hue.lua (260 lines)
  **Modules**: M, _locks
  **Exports**:
    - `M.draw_hue(ctx, id, hue, opt)`
    - `M.draw_saturation(ctx, id, saturation, base_hue, opt)`
    - `M.draw_gamma(ctx, id, gamma, opt)`
    - `M.draw(ctx, id, hue, opt)`

### images.lua (284 lines)
  **Modules**: M, Cache
  **Classes**: Cache, M
  **Exports**:
    - `M.new(opts)`

### input.lua (232 lines)
  **Modules**: M, keys_to_adjust, order, order
  **Exports**:
    - `M.is_external_drag_active(grid)`
    - `M.is_mouse_in_exclusion(grid, ctx, item, rect)`
    - `M.find_hovered_item(grid, ctx, items)`
    - `M.is_shortcut_pressed(ctx, shortcut, state)`
    - `M.reset_shortcut_states(ctx, state)`
    - `M.handle_shortcuts(grid, ctx)`
    - `M.handle_wheel_input(grid, ctx, items)`
    - `M.handle_tile_input(grid, ctx, item, rect)`
    - `M.check_start_drag(grid, ctx)`
  **Requires**: ReArkitekt.gui.draw

### json.lua (120 lines)
  **Modules**: M, out, obj, arr
  **Exports**:
    - `M.encode(t)`
    - `M.decode(str)`

### layout.lua (100 lines)
  **Modules**: M, rects
  **Exports**:
    - `M.calculate(avail_w, min_col_w, gap, n_items, origin_x, origin_y, fixed_tile_h)`
    - `M.get_height(rows, tile_h, gap)`

### lifecycle.lua (80 lines)
  **Modules**: M, Group
  **Classes**: Group, M
  **Exports**:
    - `M.new()`

### marching_ants.lua (141 lines)
  **Modules**: M
  **Exports**:
    - `M.draw(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)`

### math.lua (1 lines)

### menutabs.lua (268 lines)
  **Modules**: M, o, o, edges
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

### micromanage.lua (126 lines)
  **Modules**: M
  **Exports**:
    - `M.open(pkg_id)`
    - `M.close()`
    - `M.is_open()`
    - `M.get_package_id()`
    - `M.draw_window(ctx, pkg, settings)`
    - `M.reset()`

### mock_region_playlist.lua (571 lines)
  **Modules**: result, new_items, keys_to_delete, new_items, dragged_keys, filtered_items, new_keys
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.gui.draw, ReArkitekt.core.colors

### motion.lua (177 lines)
  **Modules**: M, Track, RectTrack
  **Classes**: Track, RectTrack
  **Exports**:
    - `M.Track(initial_value, speed)`
    - `M.RectTrack(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)`
    - `M.color_lerp(c1, c2, t)`

### pool.lua (116 lines)
  **Modules**: M
  **Exports**:
    - `M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities

### pool_grid.lua (96 lines)
  **Modules**: M, rids, rids
  **Exports**:
    - `M.create_pool_grid(rt, config)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.pool

### renderer.lua (232 lines)
  **Modules**: M
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.gui.fx.marching_ants, ReArkitekt.core.colors

### rendering.lua (89 lines)
  **Modules**: M
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.marching_ants

### reorder.lua (126 lines)
  **Modules**: M, t, base, new_order, new_order, new_order
  **Exports**:
    - `M.insert_relative(order_keys, dragged_keys, target_key, side)`
    - `M.move_up(order_keys, selected_keys)`
    - `M.move_down(order_keys, selected_keys)`

### runtime.lua (68 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

### selection.lua (141 lines)
  **Modules**: M, Selection, out, out
  **Classes**: Selection, M
  **Exports**:
    - `M.new()`

### selection_rectangle.lua (98 lines)
  **Modules**: M, SelRect
  **Classes**: SelRect, M
  **Exports**:
    - `M.new(opts)`

### selector.lua (97 lines)
  **Modules**: M, Selector
  **Classes**: Selector, M
  **Exports**:
    - `M.new(config)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion

### settings.lua (118 lines)
  **Modules**: Settings, out, M, t
  **Classes**: Settings
  **Exports**:
    - `M.open(cache_dir, filename)`
  **Requires**: json

### shell.lua (96 lines)
  **Modules**: M
  **Exports**:
    - `M.run(opts)`
  **Requires**: ReArkitekt.app.runtime, ReArkitekt.app.window

### spawn.lua (63 lines)
  **Modules**: M, SpawnTracker
  **Classes**: SpawnTracker, M
  **Exports**:
    - `M.new(config)`

### status_bar.lua (196 lines)
  **Modules**: M, right_items, item_widths
  **Classes**: M
  **Exports**:
    - `M.new(config)`

### style.lua (173 lines)
  **Modules**: M
  **Exports**:
    - `M.with_alpha(col, a)`
    - `M.PushMyStyle(ctx)`
    - `M.PopMyStyle(ctx)`

### tile_motion.lua (64 lines)
  **Modules**: M, TileAnimator
  **Classes**: TileAnimator, M
  **Exports**:
    - `M.new(default_speed)`

### tile_utilities.lua (27 lines)
  **Modules**: M
  **Exports**:
    - `M.format_bar_length(seconds, project_bpm, project_time_sig_num)`

### tiles_container.lua (249 lines)
  **Modules**: M, Container
  **Classes**: Container, M
  **Exports**:
    - `M.new(opts)`
    - `M.draw(ctx, id, width, height, content_fn, config)`

### wheel_guard.lua (42 lines)
  **Exports**:
    - `M.begin(ctx)`
    - `M.capture_over_last_item(ctx, on_delta)`
    - `M.capture_if(ctx, condition, on_delta)`
    - `M.finish(ctx)`
  **Requires**: imgui

### widget_demo.lua (222 lines)
  **Modules**: t, arr
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.colorblocks, ReArkitekt.gui.draw, ReArkitekt.gui.fx.effects, ReArkitekt.*

### window.lua (182 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

## Internal Dependencies

### shell.lua
  → ReArkitekt.app.runtime
  → ReArkitekt.app.window

### settings.lua
  → json

### demo.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.navigation.menutabs
  → ReArkitekt.gui.widgets.status_bar
  → ReArkitekt.gui.widgets.package_tiles.grid
  → ReArkitekt.gui.widgets.package_tiles.micromanage
  → ReArkitekt.gui.widgets.tiles_container
  → ReArkitekt.gui.widgets.selection_rectangle

### demo2.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.sliders.hue
  → ReArkitekt.gui.widgets.status_bar
  → ReArkitekt.gui.widgets.tiles_container

### drag_indicator.lua
  → ReArkitekt.gui.draw

### animation.lua
  → ReArkitekt.gui.fx.animations.spawn
  → ReArkitekt.gui.fx.animations.destroy

### core.lua
  → ReArkitekt.gui.widgets.grid.layout
  → ReArkitekt.gui.fx.motion
  → ReArkitekt.gui.systems.selection
  → ReArkitekt.gui.widgets.selection_rectangle
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.fx.dnd.drag_indicator
  → ReArkitekt.gui.fx.dnd.drop_indicator
  → ReArkitekt.gui.widgets.grid.rendering
  → ReArkitekt.gui.widgets.grid.animation
  → ReArkitekt.gui.widgets.grid.input

### input.lua
  → ReArkitekt.gui.draw

### rendering.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.marching_ants

### grid.lua
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.fx.motion
  → ReArkitekt.gui.fx.tile_motion
  → ReArkitekt.gui.widgets.package_tiles.renderer
  → ReArkitekt.gui.widgets.package_tiles.micromanage

### renderer.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.fx.marching_ants
  → ReArkitekt.core.colors

### active_grid.lua
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.widgets.region_tiles.renderers.active

### coordinator.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_motion
  → ReArkitekt.gui.fx.dnd.drag_indicator
  → ReArkitekt.gui.widgets.region_tiles.renderers.active
  → ReArkitekt.gui.widgets.region_tiles.renderers.pool
  → ReArkitekt.gui.systems.height_stabilizer
  → ReArkitekt.gui.widgets.region_tiles.selector
  → ReArkitekt.gui.widgets.region_tiles.active_grid
  → ReArkitekt.gui.widgets.region_tiles.pool_grid

### pool_grid.lua
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.widgets.region_tiles.renderers.pool

### active.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.systems.tile_utilities

### pool.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.systems.tile_utilities

### selector.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_motion

### mock_region_playlist.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.status_bar
  → ReArkitekt.gui.widgets.region_tiles.coordinator
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_motion

### widget_demo.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.fx.effects
