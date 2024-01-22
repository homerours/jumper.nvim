# telescope-jumper

Telescope extension for [jumper](https://github.com/homerours/jumper), allowing to jump to frequently visited directories (replicating [z](https://github.com/rupa/z)).

## Installation

For Lazy.nvim, use:
```lua
{
    "homerours/telescope-jumper",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
        local jumper = require("telescope").extensions.jumper
        vim.keymap.set('n', '<c-j>', jumper.jump, {})
    end,
}
```

## Usage

Use `Ctrl-J` (from the above mapping) to fuzzy-find directories that you frequently visit. 
- On enter, it will `require('telescope.builtin').find_files` in the selected directory. 
- On `require('telescope.actions').file_edit`, it will `:edit` the selection.

## Credits
- [z](https://github.com/rupa/z)
- [telescope-z](https://github.com/nvim-telescope/telescope-z.nvim)
