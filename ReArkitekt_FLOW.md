# FOLDER FLOW: ReArkitekt
Generated: 2025-10-09 05:08:11
Location: D:\Dropbox\REAPER\Scripts\ARKADATA Scripts\ReArkitekt

## Overview
- **Files**: 98
- **Total Lines**: 18,590
- **Public Functions**: 278
- **Classes**: 65

## Files

### ARK_Region_Playlist.lua (51 lines)
  **Requires**: ReArkitekt.app.shell, Region_Playlist.app.config, Region_Playlist.app.state, Region_Playlist.app.gui, Region_Playlist.app.status

### active.lua (234 lines)
  **Modules**: M, k
  **Exports**:
    - `M.render(ctx, rect, item, state, get_region_by_rid, animator, on_repeat_cycle, hover_config, tile_height, border_thickness, bridge)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config, ReArkitekt.gui.fx.marching_ants

### active_grid_factory.lua (213 lines)
  **Modules**: M, item_map, items_by_key, dragged_items, items_by_key, new_items
  **Classes**: M
  **Exports**:
    - `M.create(rt, config)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.active

### animation.lua (100 lines)
  **Modules**: M, AnimationCoordinator
  **Classes**: AnimationCoordinator, M
  **Exports**:
    - `M.new(config)`
  **Requires**: ReArkitekt.gui.fx.animations.spawn, ReArkitekt.gui.fx.animations.destroy

### background.lua (60 lines)
  **Modules**: M
  **Exports**:
    - `M.draw(dl, x1, y1, x2, y2, pattern_cfg)`

### chip.lua (207 lines)
  **Modules**: M
  **Exports**:
    - `M.calculate_min_width(ctx, label, opts)`
    - `M.draw(ctx, label, color, opts)`
    - `M.draw_with_dot(ctx, label, color, opts)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config

### colors.lua (514 lines)
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

### config.lua (85 lines)
  **Modules**: M, keys
  **Exports**:
    - `M.get_defaults()`
    - `M.get(path)`

### config.lua (90 lines)
  **Modules**: M
  **Exports**:
    - `M.get_mode_config(config, is_copy, is_delete)`

### config.lua (138 lines)
  **Modules**: M, new_config
  **Exports**:
    - `M.get()`
    - `M.override(overrides)`
    - `M.reset()`

### config.lua (181 lines)
  **Modules**: M
  **Exports**:
    - `M.get_region_tiles_config(layout_mode)`

### content.lua (43 lines)
  **Modules**: M
  **Exports**:
    - `M.begin_child(ctx, id, width, height, scroll_config)`
    - `M.end_child(ctx, container)`

### context_menu.lua (105 lines)
  **Modules**: M
  **Exports**:
    - `M.begin(ctx, id, config)`
    - `M.end_menu(ctx)`
    - `M.item(ctx, label, config)`
    - `M.separator(ctx, config)`

### controls_widget.lua (150 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_transport_controls(ctx, bridge, x, y)`
    - `M.draw_quantize_selector(ctx, bridge, x, y, width)`
    - `M.draw_playback_info(ctx, bridge, x, y, width)`
    - `M.draw_complete_controls(ctx, bridge, x, y, available_width)`

### coordinator.lua (854 lines)
  **Modules**: M, result, RegionTiles, copy, spawned_keys, rids, colors, keys_to_adjust
  **Classes**: RegionTiles, M
  **Exports**:
    - `M.create(opts)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.fx.dnd.drag_indicator, ReArkitekt.gui.widgets.region_tiles.renderers.active

### coordinator_bridge.lua (148 lines)
  **Modules**: M, order, regions
  **Classes**: M
  **Exports**:
    - `M.create(opts)`
  **Requires**: ReArkitekt.features.region_playlist.engine, ReArkitekt.features.region_playlist.playback, ReArkitekt.features.region_playlist.state

### core.lua (549 lines)
  **Modules**: M, Grid, current_keys, new_keys, rect_map, rect_map, order, filtered_order, new_order
  **Classes**: Grid, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.widgets.grid.layout, ReArkitekt.gui.fx.animation.rect_track, ReArkitekt.core.colors, ReArkitekt.gui.systems.selection, ReArkitekt.gui.widgets.selection_rectangle

### demo.lua (271 lines)
  **Modules**: result
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.package_tiles.grid, ReArkitekt.gui.widgets.package_tiles.micromanage, ReArkitekt.gui.widgets.tiles_container, ReArkitekt.gui.widgets.selection_rectangle

### demo2.lua (182 lines)
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.sliders.hue, ReArkitekt.gui.widgets.tiles_container

### demo3.lua (120 lines)
  **Modules**: pads
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.displays.status_pad, ReArkitekt.gui.widgets.status_bar

### demo_modal_overlay.lua (423 lines)
  **Modules**: selected_tag_items
  **Requires**: ReArkitekt.app.shell, ReArkitekt.gui.widgets.overlay.sheet, ReArkitekt.gui.widgets.chip_list.list, ReArkitekt.gui.widgets.overlay.config

### destroy.lua (148 lines)
  **Modules**: M, DestroyAnim, completed
  **Classes**: DestroyAnim, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.fx.easing

### dnd_state.lua (112 lines)
  **Modules**: M, DnDState
  **Classes**: DnDState, M
  **Exports**:
    - `M.new(opts)`

### drag_indicator.lua (218 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_badge(ctx, dl, mx, my, count, config, is_copy_mode, is_delete_mode)`
    - `M.draw(ctx, dl, mx, my, count, config, colors, is_copy_mode, is_delete_mode)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.dnd.config

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

### drop_indicator.lua (112 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_vertical(ctx, dl, x, y1, y2, config, is_copy_mode)`
    - `M.draw_horizontal(ctx, dl, x1, x2, y, config, is_copy_mode)`
    - `M.draw(ctx, dl, config, is_copy_mode, orientation, ...)`
  **Requires**: ReArkitekt.gui.fx.dnd.config

### drop_zones.lua (276 lines)
  **Modules**: M, non_dragged, zones, zones, rows, sequential_items, set
  **Exports**:
    - `M.find_drop_target(mx, my, items, key_fn, dragged_set, rect_track, is_single_column, grid_bounds)`
    - `M.find_external_drop_target(mx, my, items, key_fn, rect_track, is_single_column, grid_bounds)`
    - `M.build_dragged_set(dragged_ids)`

### dropdown.lua (355 lines)
  **Modules**: M, Dropdown
  **Classes**: Dropdown, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.widgets.controls.tooltip

### easing.lua (93 lines)
  **Modules**: M
  **Exports**:
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

### effects.lua (53 lines)
  **Modules**: M
  **Exports**:
    - `M.hover_shadow(dl, x1, y1, x2, y2, strength, radius)`
    - `M.soft_glow(dl, x1, y1, x2, y2, color, intensity, radius)`
    - `M.pulse_glow(dl, x1, y1, x2, y2, color, time, speed, radius)`

### engine.lua (575 lines)
  **Modules**: M, Engine
  **Classes**: Engine, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.reaper.regions, ReArkitekt.reaper.transport

### grid.lua (196 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.create(pkg, settings, theme)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_motion, ReArkitekt.gui.widgets.package_tiles.renderer, ReArkitekt.gui.widgets.package_tiles.micromanage

### grid_bridge.lua (218 lines)
  **Modules**: M, GridBridge
  **Classes**: GridBridge, M
  **Exports**:
    - `M.new(config)`

### gui.lua (606 lines)
  **Modules**: M, GUI, filtered
  **Classes**: GUI, M
  **Exports**:
    - `M.create(State, Config, settings)`
  **Requires**: ReArkitekt.gui.widgets.region_tiles.coordinator, ReArkitekt.core.colors, Region_Playlist.app.shortcuts, ReArkitekt.features.region_playlist.playlist_controller, ReArkitekt.gui.widgets.transport.transport_container

### header.lua (49 lines)
  **Modules**: M
  **Exports**:
    - `M.draw(ctx, dl, x, y, width, height, state, cfg, container_rounding)`
  **Requires**: ReArkitekt.gui.widgets.tiles_container.modes.tabs, ReArkitekt.gui.widgets.tiles_container.modes.search_sort

### height_stabilizer.lua (73 lines)
  **Modules**: M, HeightStabilizer
  **Classes**: HeightStabilizer, M
  **Exports**:
    - `M.new(opts)`

### hue.lua (275 lines)
  **Modules**: M, _locks
  **Exports**:
    - `M.draw_hue(ctx, id, hue, opt)`
    - `M.draw_saturation(ctx, id, saturation, base_hue, opt)`
    - `M.draw_gamma(ctx, id, gamma, opt)`
    - `M.draw(ctx, id, hue, opt)`

### icon.lua (123 lines)
  **Modules**: M
  **Exports**:
    - `M.draw_rearkitekt(ctx, x, y, size, color)`
    - `M.draw_rearkitekt_v2(ctx, x, y, size, color)`
    - `M.draw_simple_a(ctx, x, y, size, color)`

### images.lua (284 lines)
  **Modules**: M, Cache
  **Classes**: Cache, M
  **Exports**:
    - `M.new(opts)`

### init.lua (451 lines)
  **Modules**: M, Container, old_ids
  **Classes**: Container, M
  **Exports**:
    - `M.new(opts)`
    - `M.draw(ctx, id, width, height, content_fn, config, on_search_changed, on_sort_changed)`
  **Requires**: ReArkitekt.gui.widgets.tiles_container.header, ReArkitekt.gui.widgets.tiles_container.content, ReArkitekt.gui.widgets.tiles_container.background, ReArkitekt.gui.widgets.tiles_container.tab_animator, ReArkitekt.gui.widgets.tiles_container.modes.tabs

### input.lua (236 lines)
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

### list.lua (433 lines)
  **Modules**: M, filtered_items, min_widths, filtered_items, filtered_items, min_widths
  **Exports**:
    - `M.draw(ctx, items, opts)`
    - `M.draw_vertical(ctx, items, opts)`
    - `M.draw_columns(ctx, items, opts)`
    - `M.draw_grid(ctx, items, opts)`
    - `M.draw_auto(ctx, items, opts)`
  **Requires**: ReArkitekt.gui.widgets.chip_list.chip, ReArkitekt.gui.systems.responsive_grid

### manager.lua (144 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.new()`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.style, ReArkitekt.gui.widgets.overlay.config

### marching_ants.lua (141 lines)
  **Modules**: M
  **Exports**:
    - `M.draw(dl, x1, y1, x2, y2, color, thickness, radius, dash, gap, speed_px)`

### math.lua (51 lines)
  **Modules**: M
  **Exports**:
    - `M.lerp(a, b, t)`
    - `M.clamp(value, min, max)`
    - `M.remap(value, in_min, in_max, out_min, out_max)`
    - `M.snap(value, step)`
    - `M.smoothdamp(current, target, velocity, smoothtime, maxspeed, dt)`
    - `M.approximately(a, b, epsilon)`

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

### playback.lua (102 lines)
  **Modules**: M, Playback
  **Classes**: Playback, M
  **Exports**:
    - `M.new(engine, opts)`
  **Requires**: ReArkitekt.reaper.transport

### playback_manager.lua (21 lines)
  **Modules**: M
  **Exports**:
    - `M.compute_fade_alpha(progress, fade_in_ratio, fade_out_ratio)`

### playlist_controller.lua (313 lines)
  **Modules**: M, Controller, keys, keys, keys_set, new_items, keys_set, keys_set
  **Classes**: Controller, M
  **Exports**:
    - `M.new(state_module, settings, undo_manager)`

### pool.lua (146 lines)
  **Modules**: M, k
  **Exports**:
    - `M.render(ctx, rect, region, state, animator, hover_config, tile_height, border_thickness)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config, ReArkitekt.gui.fx.marching_ants

### pool_grid_factory.lua (122 lines)
  **Modules**: M, rids, rids
  **Classes**: M
  **Exports**:
    - `M.create(rt, config)`
  **Requires**: ReArkitekt.gui.widgets.grid.core, ReArkitekt.gui.widgets.region_tiles.renderers.pool

### rect_track.lua (135 lines)
  **Modules**: M, RectTrack
  **Classes**: RectTrack, M
  **Exports**:
    - `M.new(speed, snap_epsilon, magnetic_threshold, magnetic_multiplier)`
  **Requires**: ReArkitekt.core.math

### regions.lua (82 lines)
  **Modules**: M, regions
  **Exports**:
    - `M.scan_project_regions(proj)`
    - `M.get_region_by_rid(proj, target_rid)`
    - `M.go_to_region(proj, target_rid)`

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

### responsive_grid.lua (228 lines)
  **Modules**: M, rows, current_row, layout
  **Exports**:
    - `M.calculate_scaled_gap(tile_height, base_gap, base_height, min_height, responsive_config)`
    - `M.calculate_responsive_tile_height(opts)`
    - `M.calculate_grid_metrics(opts)`
    - `M.calculate_justified_layout(items, opts)`
    - `M.should_show_scrollbar(grid_height, available_height, buffer)`
    - `M.create_default_config()`

### runtime.lua (68 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

### search_sort.lua (144 lines)
  **Modules**: M
  **Exports**:
    - `M.draw(ctx, dl, x, y, width, height, state, cfg)`
  **Requires**: ReArkitekt.gui.widgets.controls.dropdown

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

### sheet.lua (124 lines)
  **Modules**: Sheet
  **Exports**:
    - `Sheet.render(ctx, alpha, bounds, content_fn, opts)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.style, ReArkitekt.gui.widgets.overlay.config

### shell.lua (247 lines)
  **Modules**: M, DEFAULTS
  **Exports**:
    - `M.run(opts)`
  **Requires**: ReArkitekt.app.runtime, ReArkitekt.app.window

### shortcuts.lua (68 lines)
  **Modules**: M
  **Exports**:
    - `M.handle_shortcuts(ctx, bridge)`

### shortcuts.lua (82 lines)
  **Modules**: M
  **Exports**:
    - `M.handle_keyboard_shortcuts(ctx, state, region_tiles)`
  **Requires**: Region_Playlist.app.state

### spawn.lua (57 lines)
  **Modules**: M, SpawnTracker
  **Classes**: SpawnTracker, M
  **Exports**:
    - `M.new(config)`
  **Requires**: ReArkitekt.gui.fx.easing

### state.lua (100 lines)
  **Modules**: M, default_items
  **Exports**:
    - `M.save_playlists(playlists, proj)`
    - `M.load_playlists(proj)`
    - `M.save_active_playlist(playlist_id, proj)`
    - `M.load_active_playlist(proj)`
    - `M.save_settings(settings, proj)`
    - `M.load_settings(proj)`
    - `M.clear_all(proj)`
    - `M.get_or_create_default_playlist(playlists, regions)`
  **Requires**: ReArkitekt.core.json

### state.lua (305 lines)
  **Modules**: M, tabs, result, reversed
  **Exports**:
    - `M.initialize(settings)`
    - `M.load_project_state()`
    - `M.get_active_playlist()`
    - `M.get_tabs()`
    - `M.refresh_regions()`
    - `M.sync_playlist_to_engine()`
    - `M.persist()`
    - `M.persist_ui_prefs()`
    - `M.capture_undo_snapshot()`
    - `M.clear_pending()`
  **Requires**: ReArkitekt.features.region_playlist.coordinator_bridge, ReArkitekt.features.region_playlist.state, ReArkitekt.core.undo_manager, ReArkitekt.features.region_playlist.undo_bridge, ReArkitekt.core.colors

### status.lua (58 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.create(State, Style)`
  **Requires**: ReArkitekt.gui.widgets.status_bar

### status_bar.lua (329 lines)
  **Modules**: M, right_items, item_widths
  **Classes**: M
  **Exports**:
    - `M.new(config)`

### status_pad.lua (191 lines)
  **Modules**: M, FontPool, StatusPad
  **Classes**: StatusPad, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.draw, ReArkitekt.core.colors, ReArkitekt.gui.fx.tile_fx, ReArkitekt.gui.fx.tile_fx_config

### style.lua (173 lines)
  **Modules**: M
  **Exports**:
    - `M.with_alpha(col, a)`
    - `M.PushMyStyle(ctx)`
    - `M.PopMyStyle(ctx)`

### tab_animator.lua (106 lines)
  **Modules**: M, TabAnimator, spawn_complete, destroy_complete
  **Classes**: TabAnimator, M
  **Exports**:
    - `M.new(opts)`
  **Requires**: ReArkitekt.gui.fx.easing

### tabs.lua (597 lines)
  **Modules**: M, positions
  **Exports**:
    - `M.assign_random_color(tab_data)`
    - `M.draw(ctx, dl, x, y, width, height, state, cfg)`
  **Requires**: ReArkitekt.gui.widgets.controls.context_menu, ReArkitekt.gui.fx.easing

### temp_search.lua (1 lines)

### tile_fx.lua (169 lines)
  **Modules**: M
  **Exports**:
    - `M.render_base_fill(dl, x1, y1, x2, y2, rounding)`
    - `M.render_color_fill(dl, x1, y1, x2, y2, base_color, opacity, saturation, brightness, rounding)`
    - `M.render_gradient(dl, x1, y1, x2, y2, base_color, intensity, opacity, rounding)`
    - `M.render_specular(dl, x1, y1, x2, y2, base_color, strength, coverage, rounding)`
    - `M.render_inner_shadow(dl, x1, y1, x2, y2, strength, rounding)`
    - `M.render_playback_progress(dl, x1, y1, x2, y2, base_color, progress, fade_alpha, rounding)`
    - `M.render_border(dl, x1, y1, x2, y2, base_color, saturation, brightness, opacity, thickness, rounding, is_selected, glow_strength, glow_layers)`
    - `M.render_complete(dl, x1, y1, x2, y2, base_color, config, is_selected, hover_factor, playback_progress, playback_fade)`
  **Requires**: ReArkitekt.core.colors

### tile_fx_config.lua (78 lines)
  **Modules**: M, config
  **Exports**:
    - `M.get()`
    - `M.override(overrides)`

### tile_motion.lua (57 lines)
  **Modules**: M, TileAnimator
  **Classes**: TileAnimator, M
  **Exports**:
    - `M.new(default_speed)`
  **Requires**: ReArkitekt.gui.fx.animation.track

### tile_utilities.lua (48 lines)
  **Modules**: M
  **Exports**:
    - `M.format_bar_length(start_time, end_time, proj)`

### tiles_container_old.lua (752 lines)
  **Modules**: M, Container
  **Classes**: Container, M
  **Exports**:
    - `M.new(opts)`
    - `M.draw(ctx, id, width, height, content_fn, config, on_search_changed, on_sort_changed)`
  **Requires**: ReArkitekt.gui.widgets.controls.dropdown

### timing.lua (112 lines)
  **Modules**: M
  **Exports**:
    - `M.time_to_qn(time, proj)`
    - `M.qn_to_time(qn, proj)`
    - `M.get_tempo_at_time(time, proj)`
    - `M.get_time_signature_at_time(time, proj)`
    - `M.quantize_to_beat(time, proj, allow_backward)`
    - `M.quantize_to_bar(time, proj, allow_backward)`
    - `M.quantize_to_grid(time, proj, allow_backward)`
    - `M.calculate_next_transition(region_end, mode, max_lookahead, proj)`
    - `M.get_beats_in_region(start_time, end_time, proj)`

### titlebar.lua (418 lines)
  **Modules**: M, DEFAULTS
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

### tooltip.lua (128 lines)
  **Modules**: M
  **Exports**:
    - `M.show(ctx, text, config)`
    - `M.show_delayed(ctx, text, config)`
    - `M.show_at_mouse(ctx, text, config)`
    - `M.reset()`

### track.lua (52 lines)
  **Modules**: M, Track
  **Classes**: Track, M
  **Exports**:
    - `M.new(initial_value, speed)`
  **Requires**: ReArkitekt.core.math

### transport.lua (96 lines)
  **Modules**: M
  **Exports**:
    - `M.is_playing(proj)`
    - `M.is_paused(proj)`
    - `M.is_recording(proj)`
    - `M.play(proj)`
    - `M.stop(proj)`
    - `M.pause(proj)`
    - `M.get_play_position(proj)`
    - `M.get_cursor_position(proj)`
    - `M.set_edit_cursor(pos, move_view, seek_play, proj)`
    - `M.set_play_position(pos, move_view, proj)`

### transport_container.lua (136 lines)
  **Modules**: M, TransportContainer
  **Classes**: TransportContainer, M
  **Exports**:
    - `M.new(opts)`
    - `M.draw(ctx, id, width, height, content_fn, config)`
  **Requires**: ReArkitekt.gui.widgets.transport.transport_fx

### transport_fx.lua (106 lines)
  **Modules**: M
  **Exports**:
    - `M.render_base(dl, x1, y1, x2, y2, config)`
    - `M.render_specular(dl, x1, y1, x2, y2, config, hover_factor)`
    - `M.render_inner_glow(dl, x1, y1, x2, y2, config, hover_factor)`
    - `M.render_border(dl, x1, y1, x2, y2, config)`
    - `M.render_complete(dl, x1, y1, x2, y2, config, hover_factor)`
  **Requires**: ReArkitekt.core.colors

### undo_bridge.lua (90 lines)
  **Modules**: M, restored_playlists
  **Exports**:
    - `M.capture_snapshot(playlists, active_playlist_id)`
    - `M.restore_snapshot(snapshot, region_index)`
    - `M.should_capture(old_playlists, new_playlists)`

### undo_manager.lua (69 lines)
  **Modules**: M
  **Classes**: M
  **Exports**:
    - `M.new(opts)`

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

### window.lua (568 lines)
  **Modules**: M, DEFAULTS
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
  → ReArkitekt.gui.widgets.package_tiles.grid
  → ReArkitekt.gui.widgets.package_tiles.micromanage
  → ReArkitekt.gui.widgets.selection_rectangle

### demo2.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.sliders.hue

### demo3.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.displays.status_pad
  → ReArkitekt.gui.widgets.status_bar

### demo_modal_overlay.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.widgets.overlay.sheet
  → ReArkitekt.gui.widgets.chip_list.list
  → ReArkitekt.gui.widgets.overlay.config

### coordinator_bridge.lua
  → ReArkitekt.features.region_playlist.engine
  → ReArkitekt.features.region_playlist.playback
  → ReArkitekt.features.region_playlist.state

### engine.lua
  → ReArkitekt.reaper.regions
  → ReArkitekt.reaper.transport

### playback.lua
  → ReArkitekt.reaper.transport

### state.lua
  → ReArkitekt.core.json

### rect_track.lua
  → ReArkitekt.core.math

### track.lua
  → ReArkitekt.core.math

### destroy.lua
  → ReArkitekt.gui.fx.easing

### spawn.lua
  → ReArkitekt.gui.fx.easing

### drag_indicator.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.dnd.config

### drop_indicator.lua
  → ReArkitekt.gui.fx.dnd.config

### tile_fx.lua
  → ReArkitekt.core.colors

### tile_motion.lua
  → ReArkitekt.gui.fx.animation.track

### chip.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_fx
  → ReArkitekt.gui.fx.tile_fx_config

### list.lua
  → ReArkitekt.gui.widgets.chip_list.chip
  → ReArkitekt.gui.systems.responsive_grid

### dropdown.lua
  → ReArkitekt.gui.widgets.controls.tooltip

### status_pad.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_fx
  → ReArkitekt.gui.fx.tile_fx_config

### animation.lua
  → ReArkitekt.gui.fx.animations.spawn
  → ReArkitekt.gui.fx.animations.destroy

### core.lua
  → ReArkitekt.gui.widgets.grid.layout
  → ReArkitekt.gui.fx.animation.rect_track
  → ReArkitekt.core.colors
  → ReArkitekt.gui.systems.selection
  → ReArkitekt.gui.widgets.selection_rectangle
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.fx.dnd.drag_indicator
  → ReArkitekt.gui.fx.dnd.drop_indicator
  → ReArkitekt.gui.widgets.grid.rendering
  → ReArkitekt.gui.widgets.grid.animation
  → ReArkitekt.gui.widgets.grid.input
  → ReArkitekt.gui.widgets.grid.dnd_state
  → ReArkitekt.gui.widgets.grid.drop_zones

### input.lua
  → ReArkitekt.gui.draw

### rendering.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.marching_ants

### manager.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.style
  → ReArkitekt.gui.widgets.overlay.config

### sheet.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.style
  → ReArkitekt.gui.widgets.overlay.config

### grid.lua
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_motion
  → ReArkitekt.gui.widgets.package_tiles.renderer
  → ReArkitekt.gui.widgets.package_tiles.micromanage

### renderer.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.fx.marching_ants
  → ReArkitekt.core.colors

### active_grid_factory.lua
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
  → ReArkitekt.gui.widgets.region_tiles.active_grid_factory
  → ReArkitekt.gui.widgets.region_tiles.pool_grid_factory
  → ReArkitekt.gui.widgets.grid.grid_bridge
  → ReArkitekt.gui.systems.responsive_grid

### pool_grid_factory.lua
  → ReArkitekt.gui.widgets.grid.core
  → ReArkitekt.gui.widgets.region_tiles.renderers.pool

### active.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_fx
  → ReArkitekt.gui.fx.tile_fx_config
  → ReArkitekt.gui.fx.marching_ants
  → ReArkitekt.gui.systems.tile_utilities
  → ReArkitekt.gui.systems.playback_manager

### pool.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_fx
  → ReArkitekt.gui.fx.tile_fx_config
  → ReArkitekt.gui.fx.marching_ants
  → ReArkitekt.gui.systems.tile_utilities

### selector.lua
  → ReArkitekt.gui.draw
  → ReArkitekt.core.colors
  → ReArkitekt.gui.fx.tile_motion

### header.lua
  → ReArkitekt.gui.widgets.tiles_container.modes.tabs
  → ReArkitekt.gui.widgets.tiles_container.modes.search_sort

### init.lua
  → ReArkitekt.gui.widgets.tiles_container.header
  → ReArkitekt.gui.widgets.tiles_container.content
  → ReArkitekt.gui.widgets.tiles_container.background
  → ReArkitekt.gui.widgets.tiles_container.tab_animator
  → ReArkitekt.gui.widgets.tiles_container.modes.tabs

### search_sort.lua
  → ReArkitekt.gui.widgets.controls.dropdown

### tabs.lua
  → ReArkitekt.gui.widgets.controls.context_menu
  → ReArkitekt.gui.fx.easing

### tab_animator.lua
  → ReArkitekt.gui.fx.easing

### tiles_container_old.lua
  → ReArkitekt.gui.widgets.controls.dropdown

### transport_container.lua
  → ReArkitekt.gui.widgets.transport.transport_fx

### transport_fx.lua
  → ReArkitekt.core.colors

### gui.lua
  → ReArkitekt.gui.widgets.region_tiles.coordinator
  → ReArkitekt.core.colors
  → Region_Playlist.app.shortcuts
  → ReArkitekt.features.region_playlist.playlist_controller
  → ReArkitekt.gui.widgets.transport.transport_container
  → ReArkitekt.gui.fx.tile_motion

### shortcuts.lua
  → Region_Playlist.app.state

### state.lua
  → ReArkitekt.features.region_playlist.coordinator_bridge
  → ReArkitekt.features.region_playlist.state
  → ReArkitekt.core.undo_manager
  → ReArkitekt.features.region_playlist.undo_bridge
  → ReArkitekt.core.colors

### status.lua
  → ReArkitekt.gui.widgets.status_bar

### ARK_Region_Playlist.lua
  → ReArkitekt.app.shell
  → Region_Playlist.app.config
  → Region_Playlist.app.state
  → Region_Playlist.app.gui
  → Region_Playlist.app.status

### widget_demo.lua
  → ReArkitekt.app.shell
  → ReArkitekt.gui.draw
  → ReArkitekt.gui.fx.effects
