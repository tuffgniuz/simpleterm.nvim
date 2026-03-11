<div align="center">

# simpleterm

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/tuffgniuz/simpleterm.nvim?style=for-the-badge&labelColor=%23181926&color=%23eed49f)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/tuffgniuz/simpleterm.nvim?style=for-the-badge&labelColor=%23181926&color=%23a6da95)

## Summary
A small Neovim plugin for toggling one reusable built-in terminal in splits or a centered float.
</div>

## Installation

### lazy.nvim

With defaults only:

```lua
{
  "tuffgniuz/simpleterm.nvim",
}
```

With custom setup:

```lua
{
  "tuffgniuz/simpleterm.nvim",
  config = function()
    require("simpleterm").setup({
      mode = "right",
      size = 50,
      keymap = "<leader>t",
    })
  end,
}
```

## Setup

Calling `setup()` is optional. The plugin initializes itself automatically with default settings, so installing it is enough if the defaults already match what you want.

The default configuration is:

```lua
{
  mode = "bottom",
  size = 15,
  keymap = "<leader>t",
  scrollback = 1000,
  float = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
  },
}
```

Call `setup()` only when you want to change the defaults:

```lua
require("simpleterm").setup({
  mode = "right",
  size = 50,
  keymap = "<leader>t",
  scrollback = 1000,
})
```

## Configuration

### `mode`

Controls where the terminal opens.

Allowed values:

- `"left"`
- `"right"`
- `"float"`
- `"bottom"`

### `size`

Controls split size.

- For `"left"` and `"right"`, this is the terminal width, but `simpleterm` enforces a minimum width of one third of the editor so vertical terminals do not open too narrowly.
- For `"bottom"`, this is the terminal height.
- For `"float"`, this value is not used.

### `keymap`

The toggle mapping installed in both normal mode and terminal mode.

The mapping is created with `nowait = true` so Neovim does not pause waiting for longer matching key sequences.

### `scrollback`

How many terminal output lines Neovim keeps for the `simpleterm` buffer.

Lower values can improve reopen speed once the terminal has produced a lot of output, because Neovim has less terminal history to redraw.

Example:

```lua
scrollback = 300
```

### `float`

Options used when `mode = "float"`: `width`, `height`, and `border`.

#### `float.width`

Float width.

- A value between `0` and `1` is treated as a percentage of the editor width.
- A value greater than or equal to `1` is treated as a fixed column width.

#### `float.height`

Float height.

- A value between `0` and `1` is treated as a percentage of the editor height.
- A value greater than or equal to `1` is treated as a fixed row height.

#### `float.border`

Border style passed to `nvim_open_win()`, such as:

- `"rounded"`
- `"single"`
- `"none"`

While a floating terminal is visible, it recenters and resizes automatically when the editor is resized. Its float background and border also reuse the normal terminal background highlight.

## Behavior

- The plugin keeps one reusable terminal buffer.
- Toggling while the terminal is visible hides its window.
- Toggling again reopens the same terminal buffer when possible.
- When the terminal is shown, it immediately enters terminal insert mode.
- The same keymap works from normal mode and terminal mode.

## Notes

`simpleterm` is meant to stay simple. It is not trying to be a terminal manager.

The project is still young, so rough edges and bugs are possible. Issues are expected at this stage.

## License

MIT. See [LICENSE](/home/tuffgniuz/code/projects/simpleterm.nvim/LICENSE).
