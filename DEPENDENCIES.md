# DEPENDENCIES: ARKADATA Scripts
Generated: 2025-10-05 23:39:18

## Dependency Graph

**`ReArkitekt/app/shell.lua`**
  → `ReArkitekt/app/runtime.lua`
  → `ReArkitekt/app/window.lua`

**`ReArkitekt/core/settings.lua`**
  → `ReArkitekt/core/json.lua`

**`ReArkitekt/demo.lua`**
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/navigation/menutabs.lua`
  → `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`
  → `ReArkitekt/gui/widgets/status_bar.lua`
  → `ReArkitekt/gui/widgets/tiles_container.lua`

**`ReArkitekt/demo2.lua`**
  → `ReArkitekt/app/shell.lua`
  → `ReArkitekt/gui/widgets/sliders/hue.lua`
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
  → `ReArkitekt/gui/systems/selection.lua`
  → `ReArkitekt/gui/widgets/grid/animation.lua`
  → `ReArkitekt/gui/widgets/grid/input.lua`
  → `ReArkitekt/gui/widgets/grid/layout.lua`
  → `ReArkitekt/gui/widgets/grid/rendering.lua`
  → `ReArkitekt/gui/widgets/selection_rectangle.lua`

**`ReArkitekt/gui/widgets/grid/input.lua`**
  → `ReArkitekt/gui/draw.lua`

**`ReArkitekt/gui/widgets/grid/rendering.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`**
  → `ReArkitekt/gui/fx/motion.lua`
  → `ReArkitekt/gui/fx/tile_motion.lua`
  → `ReArkitekt/gui/widgets/grid/core.lua`
  → `ReArkitekt/gui/widgets/package_tiles/micromanage.lua`
  → `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/gui/widgets/package_tiles/renderer.lua`**
  → `ReArkitekt/core/colors.lua`
  → `ReArkitekt/gui/draw.lua`
  → `ReArkitekt/gui/fx/marching_ants.lua`

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
  → `ReArkitekt/gui/fx/effects.lua`

## Reverse Dependencies (Imported By)

**`ReArkitekt/gui/draw.lua`** (11 imports)
  ← `ReArkitekt/gui/fx/dnd/drag_indicator.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/grid/input.lua`
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/mock_region_playlist.lua`
  ← ... and 1 more

**`ReArkitekt/core/colors.lua`** (7 imports)
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/grid/core.lua`** (5 imports)
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/app/shell.lua`** (4 imports)
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/mock_region_playlist.lua`
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/fx/tile_motion.lua`** (4 imports)
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/selector.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/status_bar.lua`** (3 imports)
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/fx/dnd/drag_indicator.lua`** (2 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/fx/marching_ants.lua`** (2 imports)
  ← `ReArkitekt/gui/widgets/grid/rendering.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/renderer.lua`

**`ReArkitekt/gui/fx/motion.lua`** (2 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/systems/tile_utilities.lua`** (2 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`

**`ReArkitekt/gui/widgets/package_tiles/micromanage.lua`** (2 imports)
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`** (2 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/active_grid.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`** (2 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`
  ← `ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`

**`ReArkitekt/gui/widgets/selection_rectangle.lua`** (2 imports)
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/tiles_container.lua`** (2 imports)
  ← `ReArkitekt/demo.lua`
  ← `ReArkitekt/demo2.lua`

**`ReArkitekt/app/runtime.lua`** (1 imports)
  ← `ReArkitekt/app/shell.lua`

**`ReArkitekt/app/window.lua`** (1 imports)
  ← `ReArkitekt/app/shell.lua`

**`ReArkitekt/core/json.lua`** (1 imports)
  ← `ReArkitekt/core/settings.lua`

**`ReArkitekt/gui/fx/animations/destroy.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/animation.lua`

**`ReArkitekt/gui/fx/animations/spawn.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/animation.lua`

**`ReArkitekt/gui/fx/dnd/drop_indicator.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/fx/effects.lua`** (1 imports)
  ← `ReArkitekt/widget_demo.lua`

**`ReArkitekt/gui/systems/height_stabilizer.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/systems/selection.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/grid/animation.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/grid/input.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/grid/layout.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/grid/rendering.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/grid/core.lua`

**`ReArkitekt/gui/widgets/navigation/menutabs.lua`** (1 imports)
  ← `ReArkitekt/demo.lua`

**`ReArkitekt/gui/widgets/package_tiles/grid.lua`** (1 imports)
  ← `ReArkitekt/demo.lua`

**`ReArkitekt/gui/widgets/package_tiles/renderer.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/package_tiles/grid.lua`

**`ReArkitekt/gui/widgets/region_tiles/active_grid.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/widgets/region_tiles/coordinator.lua`** (1 imports)
  ← `ReArkitekt/mock_region_playlist.lua`

**`ReArkitekt/gui/widgets/region_tiles/pool_grid.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/widgets/region_tiles/selector.lua`** (1 imports)
  ← `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`

**`ReArkitekt/gui/widgets/sliders/hue.lua`** (1 imports)
  ← `ReArkitekt/demo2.lua`

## Circular Dependencies

✓ No circular dependencies detected

## Isolated Files (No Dependencies)

- `ReArkitekt/core/lifecycle.lua`
- `ReArkitekt/gui/images.lua`
- `ReArkitekt/gui/style.lua`
- `ReArkitekt/gui/systems/reorder.lua`
- `ReArkitekt/input/wheel_guard.lua`

## Complexity by Dependencies

- `ReArkitekt/gui/widgets/grid/core.lua`: 10 imports, 5 importers (total: 15)
- `ReArkitekt/gui/draw.lua`: 0 imports, 11 importers (total: 11)
- `ReArkitekt/gui/widgets/region_tiles/coordinator.lua`: 10 imports, 1 importers (total: 11)
- `ReArkitekt/core/colors.lua`: 0 imports, 7 importers (total: 7)
- `ReArkitekt/demo.lua`: 7 imports, 0 importers (total: 7)
- `ReArkitekt/app/shell.lua`: 2 imports, 4 importers (total: 6)
- `ReArkitekt/gui/widgets/package_tiles/grid.lua`: 5 imports, 1 importers (total: 6)
- `ReArkitekt/gui/widgets/region_tiles/renderers/active.lua`: 4 imports, 2 importers (total: 6)
- `ReArkitekt/gui/widgets/region_tiles/renderers/pool.lua`: 4 imports, 2 importers (total: 6)
- `ReArkitekt/mock_region_playlist.lua`: 6 imports, 0 importers (total: 6)