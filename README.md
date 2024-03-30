# telescope-jumper

This is a [Telescope](https://github.com/nvim-telescope/telescope.nvim) extension for [jumper](https://github.com/homerours/jumper), allowing to jump to frequently visited directories (replicating [z](https://github.com/rupa/z)) and open frequently opened files.

## Installation

For Lazy.nvim, use:
```lua
{
    "homerours/telescope-jumper",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
        local jumper = require("telescope").extensions.jumper
        vim.keymap.set('n', '<c-y>', jumper.jump_to_folder, {})
        vim.keymap.set('n', '<c-u>', jumper.jump_to_file, {})
        vim.keymap.set('n', '<leader>fu', jumper.find_in_files, {})
    end
}
```

## Usage

Use `Ctrl-Y` (from the above mappings) to fuzzy-find directories that you frequently visit. 
- On enter, it will `require('telescope.builtin').find_files` in the selected directory. 
- On `require('telescope.actions').file_edit`, it will `:edit` the selection.

Use `Ctrl-U` (from the above mappings) to fuzzy-find files that you frequently edit. 
Use `<leader>fu` (from the above mappings) to Grep the files of jumper's database. 

Use `:Zf <query>` to open the file matching a given `<query>` or `:Z <query>` to change the current working directory.

## Credits
- [z](https://github.com/rupa/z)
- [telescope-z](https://github.com/nvim-telescope/telescope-z.nvim)
