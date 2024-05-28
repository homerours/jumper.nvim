# jumper.nvim

This is a Neovim plugin for [jumper](https://github.com/homerours/jumper), to quickly jump around files and folders. It allows to
- keep track of the opened files and visited folders, keeping jumper's database updated.
- jump with `:Zf <query>` / `:Z <query>` to files / folders matching `<query>`.
- interactively find jumper's files and directories using either [fzf-lua](https://github.com/ibhagwan/fzf-lua) or [Telescope](https://github.com/nvim-telescope/telescope.nvim) as backend.

## Installation

First install [jumper](https://github.com/homerours/jumper), following [these instructions](https://github.com/homerours/jumper?tab=readme-ov-file#installation).

Then, for Lazy.nvim, use:
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

## Usage

Use the commands `:Zf <query>` to open the file that matches best `<query>` or `:Z <query>` to change the current working directory.
Then, jumper provides 3 "pickers" in order to interactively find files and folders:

#### `jump_to_directory`

This allows to pick directories from jumper's database. By default, pressing `enter` on a directory will open that directory in the default file explorer (`netrw`, `oil`...). This can be overriden using the `on_enter` key of the options supplied to the finder:
- `jumper.jump_to_directories({on_enter = 'find_files'})` will launch a files' search in the selected directory.
- `jumper.jump_to_directories({on_enter = 'change_cwd'})` will update the current working directory to the selected entry.

#### `jump_to_file`

This allows to open files from jumper's database.

#### `find_in_files`

This allows to "live-grep" the files of jumper's database.

## Configuration example

Here is an example of configuration, using fzf-lua as backend:
```lua
{
    "homerours/jumper.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
        local jumper = require("jumper.fzf-lua")

        vim.keymap.set('n', '<c-y>', function() jumper.jump_to_directory({ on_enter = 'find_files'}) end)

        vim.keymap.set('n', '<c-u>', jumper.jump_to_file)

        vim.keymap.set('n', '<leader>fu', jumper.find_in_files)

        -- Defaults should be good enough, one typically does not need the following:
        require("jumper").setup({
            jumper_max_results = 200,           -- maximum number of results to show in Telescope. Default: 300
            jumper_max_completion_results = 10, -- maximum number of results to show when completing :Z and :Zf commands. Default: 12
            jumper_beta = 0.9,                  -- "beta" used for ranking (default: 1.0)
            jumper_syntax = "fuzzy",            -- default = "extended"
            jumper_home_tilde = true,           -- substitute $HOME with ~/ in the results (default: true)
            jumper_relative = false,            -- outputs relative pathes (default: false)
            jumper_case_sensitivity = "insensitive", 

            -- By default, jumper records files and directories' visits in the files $__JUMPER_FILES and $__JUMPER_FOLDERS (which are ~/.jfiles and ~/.jfolders by default)
            -- You can still provide other files to use here:
            jumper_files = '/path/to/a/very/custom/file_database',
            jumper_directories = '/path/to/a/very/custom/directory_database',
        })
    end
}
```

## Thanks
Big thanks to [@ibhagwan](https://github.com/ibhagwan), developer of [fzf-lua](https://github.com/ibhagwan/fzf-lua) who has been super helpful in answering my questions about his plugin.
Credits to:
- [z](https://github.com/rupa/z)
- [telescope-z](https://github.com/nvim-telescope/telescope-z.nvim)
