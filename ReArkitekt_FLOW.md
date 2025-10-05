# FOLDER FLOW: ReArkitekt
Generated: 2025-10-05 16:20:20
Location: D:/Dropbox/REAPER/Scripts/ARKADATA Scripts\ReArkitekt

## Overview
- **Files**: 48
- **Total Code Lines**: 6,708
- **Public Functions**: 102
- **Classes**: 18

## Files

### runtime.lua (41 lines)
  **Modules**: M
  **Exports**:
    - `M.new(opts)`

### shell.lua (72 lines)
  **Modules**: M
  **Exports**:
    - `M.run(opts)`
  **Requires**: ReArkitekt.app.runtime, ReArkitekt.app.window

### window.lua (139 lines)
  **Modules**: M
  **Exports**:
    - `M.new(opts)`

### colors.lua (143 lines)
  **Modules**: M
  **Exports**:
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

### json.lua (106 lines)
  **Modules**: M, out, obj, arr
  **Exports**:
    - `M.encode(t)`
    - `M.decode(str)`

### lifecycle.lua (52 lines)
  **Modules**: M, Group
  **Classes**: Group
  **Exports**:
    - `M.new()`

### settings.lua (97 lines)
  **Modules**: Settings, out, M, t
  **Classes**: Settings
  **Exports**:
    - `M.open(cache_dir, filename)`
  **Requires**: json

### demo.lua (247 lines)
  **Modules**: result
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.menutabs, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.package_tiles, ReArkitekt.gui.widgets.tiles_container, ReArkitekt.gui.widgets.selection_rectangle

### demo2.lua (141 lines)
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.hue_slider, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.tiles_container

### draw.lua (80 lines)
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

### effects.lua (165 lines)
  **Modules**: M
  **Exports**:
    - `M.marching_ants_rounded(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)`
    - `M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)`
    - `M.drop_line(dl, x, y1, y2, color, thickness, cap_radius)`
    - `M.selection_overlay(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)`
    - `M.ghost_rect(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)`
    - `M.dim_rect(dl, x1, y1, x2, y2, fill_color, stroke_color, rounding, stroke_width)`

### destroy.lua (113 lines)
  **Modules**: M, DestroyAnim, completed
  **Classes**: DestroyAnim
  **Exports**:
    - `M.new(opts)`

### spawn.lua (45 lines)
  **Modules**: M, SpawnTracker
  **Classes**: SpawnTracker
  **Exports**:
    - `M.new(config)`

### drag_indicator.lua (256 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_badge(ctx, dl, mx, my, count, config, is_copy_mode, is_delete_mode)`
    - `M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)`
  **Requires**: ReArkitekt.gui.draw

### drop_indicator.lua (120 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)`
    - `M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)`
    - `M.draw(ctx, dl, config, is_copy_mode, orientation, ...)`

### motion.lua (147 lines)
  **Modules**: M, Track, RectTrack
  **Classes**: Track, RectTrack
  **Exports**:
    - `M.Track(initial_value, speed)`
    - `M.RectTrack(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)`
    - `M.color_lerp(c1, c2, t)`

### tile_motion.lua (48 lines)
  **Modules**: M, TileAnimator
  **Classes**: TileAnimator
  **Exports**:
    - `M.new(default_speed)`

### images.lua (239 lines)
  **Modules**: M, Cache
  **Classes**: Cache
  **Exports**:
    - `M.new(opts)`

### style.lua (132 lines)
  **Modules**: M
  **Exports**:
    - `M.with_alpha(col, a)`
    - `M.PushMyStyle(ctx)`
    - `M.PopMyStyle(ctx)`

### height_stabilizer.lua (45 lines)
  **Modules**: M, HeightStabilizer
  **Classes**: HeightStabilizer
  **Exports**:
    - `M.new(opts)`

### layout_grid.lua (57 lines)
  **Modules**: M, rects
  **Exports**:
    - `M.calculate(avail_w, min_col_w, gap, n_items, origin_x, origin_y, fixed_tile_h)`
    - `M.get_height(rows, tile_h, gap)`

### reorder.lua (79 lines)
  **Modules**: M, t, base, new_order, new_order, new_order
  **Exports**:
    - `M.insert_relative(order_keys, dragged_keys, target_key, side)`
    - `M.move_up(order_keys, selected_keys)`
    - `M.move_down(order_keys, selected_keys)`

### selection.lua (100 lines)
  **Modules**: M, Selection, out, out
  **Classes**: Selection
  **Exports**:
    - `M.new()`

### tile_utilities.lua (14 lines)
  **Modules**: M
  **Exports**:
    - `M.format_bar_length(seconds, project_bpm, project_time_sig_num)`

### animation.lua (79 lines)
  **Modules**: M, AnimationCoordinator
  **Classes**: AnimationCoordinator
  **Exports**:
    - `M.new(config)`
  **Requires**: ReArkitekt.gui.fx.animations.spawn, ReArkitekt.gui.fx.animations.destroy

### core.lua (559 lines)
  **Modules**: M, Grid, map, non_dragged_items, drop_zones, dragged_set, current_keys, new_keys, rect_map, order, dragged_set, filtered_order, new_order
  **Classes**: Grid
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.widgets.grid.layout, ReArkitekt.gui.fx.motion, ReArkitekt.gui.systems.selection, ReArkitekt.gui.widgets.selection_rectangle, ReArkitekt.gui.draw, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.fx.dnd.drop_indicator, ReArkitekt.gui.widgets.grid.rendering, ReArkitekt.gui.widgets.grid.animation, ReArkitekt.gui.widgets.grid.input

### input.lua (186 lines)
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

### rendering.lua (76 lines)
  **Modules**: M
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.effects

### hue_slider.lua (199 lines)
  **Modules**: M, _locks
  **Exports**:
    - `M.draw_hue(ctx, id, hue, opt)`
    - `M.draw_saturation(ctx, id, saturation, base_hue, opt)`
    - `M.draw_gamma(ctx, id, gamma, opt)`
    - `M.draw(ctx, id, hue, opt)`

### menutabs.lua (228 lines)
  **Modules**: M, o, o, edges
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

### package_tiles.lua (8 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_micromanage_window(ctx, pkg, settings)`
  **Requires**: ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage

### grid.lua (158 lines)
  **Modules**: M
  **Exports**:
    - `M.create(pkg, settings, theme)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.fx.motion, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.widgets.package_tiles.renderer, ReArkitekt.gui.widgets.package_tiles.micromanage

### micromanage.lua (93 lines)
  **Modules**: M
  **Exports**:
    - `M.open(pkg_id)`
    - `M.close()`
    - `M.is_open()`
    - `M.get_package_id()`
    - `M.draw_window(ctx, pkg, settings)`
    - `M.reset()`

### renderer.lua (188 lines)
  **Modules**: M
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.gui.effects, ReArkitekt.core.colors

### region_tiles.lua (4 lines)
  **Modules**: M
  **Requires**: ReArkitekt.gui.widgets.region_tiles.coordinator

### active_grid.lua (163 lines)
  **Modules**: M, item_map, items_by_key, dragged_items, items_by_key, new_items, spawned_keys
  **Exports**:
    - `M.create_active_grid(rt, config)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.active

### coordinator.lua (517 lines)
  **Modules**: M, result, RegionTiles, colors, keys_to_adjust
  **Classes**: RegionTiles
  **Exports**:
    - `M.create(opts)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.widgets.region_tiles.renderers.active, ReArkitekt.gui.widgets.region_tiles.renderers.pool, ReArkitekt.gui.systems.height_stabilizer, ReArkitekt.gui.widgets.region_tiles.selector, ReArkitekt.gui.widgets.region_tiles.active_grid, ReArkitekt.gui.widgets.region_tiles.pool_grid

### pool_grid.lua (77 lines)
  **Modules**: M, rids, rids
  **Exports**:
    - `M.create_pool_grid(rt, config)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.pool

### active.lua (139 lines)
  **Modules**: M
  **Exports**:
    - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities

### pool.lua (100 lines)
  **Modules**: M
  **Exports**:
    - `M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.systems.tile_utilities

### selector.lua (72 lines)
  **Modules**: M, Selector
  **Classes**: Selector
  **Exports**:
    - `M.new(config)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion

### selection_rectangle.lua (67 lines)
  **Modules**: M, SelRect
  **Classes**: SelRect
  **Exports**:
    - `M.new(opts)`

### status_bar.lua (151 lines)
  **Modules**: M, right_items, item_widths
  **Exports**:
    - `M.new(config)`

### tabs.lua (100 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.new(id, opts)`
  **Requires**: ReArkitekt.gui.widgets.tabs

### tiles_container.lua (183 lines)
  **Modules**: M, Container
  **Classes**: Container
  **Exports**:
    - `M.new(opts)`
    - `M.draw(ctx, id, width, height, content_fn, config)`

### wheel_guard.lua (34 lines)
  **Exports**:
    - `M.begin(ctx)`
    - `M.capture_over_last_item(ctx, on_delta)`
    - `M.capture_if(ctx, condition, on_delta)`
    - `M.finish(ctx)`
  **Requires**: imgui

### mock_region_playlist.lua (472 lines)
  **Modules**: result, new_items, keys_to_delete, new_items, dragged_keys, filtered_items, new_keys
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.status_bar, ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion

### widget_demo.lua (177 lines)
  **Modules**: t, arr
  **Requires**: ReArkitekt.*, ReArkitekt.app.shell, ReArkitekt.gui.widgets.colorblocks, ReArkitekt.gui.draw, ReArkitekt.gui.effects

## Internal Dependencies

### shell.lua
  → ReArkitekt.app.runtime
  → ReArkitekt.app.window

### settings.lua
  → json

### demo.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.menutabs
  → ReArkitekt.gui.widgets.status_bar
  → ReArkitekt.gui.widgets.package_tiles
  → ReArkitekt.gui.widgets.tiles_container
  → ReArkitekt.gui.widgets.selection_rectangle

### demo2.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.hue_slider
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
  → ReArkitekt.gui.effects

### package_tiles.lua
  → ReArkitekt.gui.widgets.package_tiles.grid
  → ReArkitekt.gui.widgets.package_tiles.micromanage

### grid.lua
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.fx.motion
  → ReArkitekt.gui.fx.tile_motion
  → ReArkitekt.gui.widgets.package_tiles.renderer
  → ReArkitekt.gui.widgets.package_tiles.micromanage

### renderer.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.effects
  → ReArkitekt.core.colors

### region_tiles.lua
  → ReArkitekt.gui.widgets.region_tiles.coordinator

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

### tabs.lua
  → ReArkitekt.gui.widgets.tabs

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
  → ReArkitekt.gui.effects
