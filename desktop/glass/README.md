# oblio-glass

Oblio's glass: one renderer for app windows and the shell's own surfaces (bar, dock, menus,
settings), drawn by Hyprland as a plugin. A fork of [hyprglass](https://github.com/hyprnux/hyprglass)
(BSD-3-Clause, see LICENSE), pinned to the Hyprland version in `.hyprland-version`.

What Oblio adds:

- `og.shapes(namespace, { { x, y, w, h, radius }, ... }, style)`: the shell sends the exact glass
  shapes of a layer (layer-local px; `radius` a number or `{ tl, tr, br, bl }`, negative = capsule).
  Inside them the layer gets glass whatever its alpha, each shape with its own bezel; outside them
  none. Live: it applies at once. No shapes gives the layer back to its mask.
- `og.style(name, { ... })`: a preset (same settings as `og.preset`) that also applies at once,
  so Settings can change the look live.

`og` is `hl.plugin.oblio_glass`. Build: `make` (needs Hyprland's headers, `pkg-config hyprland`).
