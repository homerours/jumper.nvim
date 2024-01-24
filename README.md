# telescope-jumper

Telescope extension for [jumper](https://github.com/homerours/jumper), allowing to jump to frequently visited directories (replicating [z](https://github.com/rupa/z)) and open frequently opened files.

## Installation

For Lazy.nvim, use:
```lua
{
    "homerours/telescope-jumper",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
        local jumper = require("telescope").extensions.jumper
        vim.keymap.set('n', '<c-y>', jumper.jump, {})
        vim.keymap.set('n', '<c-u>', jumper.jump_file, {})

        vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPre" }, {
            pattern = { "*" },
            callback = function(ev)
                local filename = vim.api.nvim_buf_get_name(ev.buf)
                if not string.find(filename, "/.git") then
                    local cmd = 'jumper -f ${jumpfile_files} -a ' .. filename
                    os.execute(cmd)
                end
            end
        })
    end,
}
```

## Usage

Use `Ctrl-Y` (from the above mapping) to fuzzy-find directories that you frequently visit. 
- On enter, it will `require('telescope.builtin').find_files` in the selected directory. 
- On `require('telescope.actions').file_edit`, it will `:edit` the selection.
Use `Ctrl-U` (from the above mapping) to fuzzy-find files that you frequently edit. 

## Credits
- [z](https://github.com/rupa/z)
- [telescope-z](https://github.com/nvim-telescope/telescope-z.nvim)
