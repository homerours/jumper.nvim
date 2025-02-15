# jumper.nvim

This is a Neovim plugin for [jumper](https://github.com/homerours/jumper) to open files and folders with very few keystrokes, as `jumper` does in the shell. This allows to quickly navigate to past opened files/folders in an uniform way accross the shell and Neovim. It will therefore:
- keep track of the opened files and visited folders, keeping jumper's database updated.
- interactively fuzzy-find jumper's files and directories using either [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) as backend.
- jump with `:Zf <query>` / `:Z <query>` to files / folders matching `<query>`.


https://github.com/homerours/jumper.nvim/assets/12702557/8c053590-09ae-4f08-a050-0a11c97c22c7


# Installation

1. Install [jumper](https://github.com/homerours/jumper)'s binary, following [these instructions](https://github.com/homerours/jumper?tab=readme-ov-file#installation).
2. Install `homerours/jumper.nvim` with your plugin manager.
3. (Optional, requires fzf-lua or Telescope) Define keymaps for the interactive pickers to jump to files and directories. For lua configuration, use
```lua
vim.keymap.set('n', '<c-y>', require("jumper.fzf-lua").jump_to_directory)
vim.keymap.set('n', '<c-u>', require("jumper.fzf-lua").jump_to_file)
vim.keymap.set('n', '<leader>fu', require("jumper.fzf-lua").find_in_files)
```
or for vimscript, use
```vim
nnoremap <c-y> <cmd>lua require("jumper.fzf-lua").jump_to_directory()<cr>
nnoremap <c-u> <cmd>lua require("jumper.fzf-lua").jump_to_file()<cr>
nnoremap <leader>fu <cmd>lua require("jumper.fzf-lua").find_in_files()<cr>
```
`require("jumper.fzf-lua")` has to be replaced by `require("telescope").extensions.jumper` if using Telescope's backend.


Using for instance Lazy.nvim, steps 2 and 3 can be achieved with
```lua
{
    "homerours/jumper.nvim",
    dependencies = { 
        'nvim-telescope/telescope.nvim', -- for Telescope backend
        'ibhagwan/fzf-lua'  -- alternatively, for fzf-lua backend
    }, 
    config = function()
        -- If using Telescope as backend:
        local jumper = require("telescope").extensions.jumper
        -- or, if using fzf-lua as backend:
        local jumper = require("jumper.fzf-lua")

        -- Configure bindings to launch the pickers:
        vim.keymap.set('n', '<c-y>', jumper.jump_to_directory)
        vim.keymap.set('n', '<c-u>', jumper.jump_to_file)
        vim.keymap.set('n', '<leader>fu', jumper.find_in_files)
    end
}
```

# Usage

Use the commands `:Zf <query>` to open the file that matches best `<query>` or `:Z <query>` to change the current working directory.
Then, jumper provides 3 "pickers" in order to interactively find files and folders:


| Command              | Function                                   |
| -------------------- | ------------------------------------------ |
| `jump_to_directory`  | Pick a directory from jumper's database    |
| `jump_to_file`       | Pick a file from jumper's database         |
| `find_in_files`      | "live-grep" the files of the database      |


Depending of the backend used, these functions can be either accessed using `require('jumper.fzf-lua').jump_to_directory()` or `require('telescope').extensions.jumper.jump_to_directory()`.

By default, pressing `enter` on a directory will open that directory in the default file explorer (`netrw`, `oil`...). This can be overriden using the `on_enter` key of the options supplied to the finder:
- `jump_to_directory({on_enter = 'find_files'})` will launch a files' search in the selected directory.
- `jump_to_directory({on_enter = 'change_cwd'})` will update the current working directory to the selected entry.

# Configuration example

Here is an example of configuration, using Lazy.nvim and fzf-lua as backend:
```lua
{
    "homerours/jumper.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
        local jumper = require("jumper.fzf-lua")

        vim.keymap.set('n', '<c-y>', 
                    function() jumper.jump_to_directory({ on_enter = 'find_files'}) end)

        vim.keymap.set('n', '<c-u>', jumper.jump_to_file)

        vim.keymap.set('n', '<leader>fu', jumper.find_in_files)

        -- Defaults should be good enough,
        -- one typically does not need the following:
        require("jumper").setup({
            jumper_max_results = 200,           -- maximum number of results to show 
                                                -- in Telescope. Default: 300
            jumper_max_completion_results = 10, -- maximum number of results to show
                                                -- when completing :Z/Zf commands. Default: 12
            jumper_beta = 0.9,                  -- "beta" used for ranking (default: 1.0)
            jumper_syntax = "fuzzy",            -- default = "extended"
            jumper_home_tilde = true,           -- substitute $HOME with ~/ in the results (default: true)
            jumper_relative = false,            -- outputs relative pathes (default: false)
            jumper_case_sensitivity = "insensitive", 
        })
    end
}
```

# Thanks
Big thanks to [ibhagwan](https://github.com/ibhagwan), developer of [fzf-lua](https://github.com/ibhagwan/fzf-lua) who has been super helpful for questions about his plugin.
Credits to [z](https://github.com/rupa/z) and [telescope-z](https://github.com/nvim-telescope/telescope-z.nvim)
