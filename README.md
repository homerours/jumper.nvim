# jumper.nvim

This is a Neovim plugin for using [jumper](https://github.com/homerours/jumper). It allows
- to keep track of the opened files and visited folders, updating Jumper's database.
- to jump with `:Zf <query>` / `:Z <query>` to files and folders matching `<query>`.
- to fuzzy-find Jumper's files and directories using either [Telescope](https://github.com/nvim-telescope/telescope.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua) as backend.

## Installation

For Lazy.nvim, use:
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

Use `:Zf <query>` to open the file best matching a given `<query>` or `:Z <query>` to change the current working directory.

Jumper then provides 3 "pickers":

#### `jump_to_directory`

This allows to pick directories from jumper's database. By default, selecting a directory with `enter` will open that directory in the default file explorer (`netrw`, `oil`...). This can be overriden using the `on_enter` entry of the options supplied to the finder:
- `jumper.jump_to_folder({on_enter = 'find_files'})` will launch a files' search on the selected folder.
- `jumper.jump_to_folder({on_enter = 'change_cwd'})` will update the current working directory to the selected entry.

#### `jump_to_file`

This allows to open files from jumper's database.

#### `find_in_files`

This allows to "grep" files of jumper's database.

## Configuration example

Here is an example of configuration, using Telescope as backend:
```lua
{
    "homerours/jumper.nvim",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
        local jumper = require("telescope").extensions.jumper

        vim.keymap.set('n', '<c-y>', function() jumper.jump_to_directory({ on_enter = 'find_files', previewer = false }) end)
        -- Disable previewer on start, which can be then be turned on with a mapping to
        -- require('telescope.actions.layout').toggle_preview()

        vim.keymap.set('n', '<c-u>', function () jumper.jump_to_file({ previewer = false }) end)

        vim.keymap.set('n', '<leader>fu', jumper.find_in_files)

        require("jumper").set_preferences({
            jumper_max_results = 200, -- maximum number of results to show in Telescope. Default: 150
            jumper_max_completion_results = 10, -- maximum number of results to show when completing :Z and :Zf commands. Default: 12

            -- By default, jumper records files and directories' visits in the files $__JUMPER_FILES and $__JUMPER_FOLDERS (which are ~/.jfiles and ~/.jfolders by default)
            -- You can still provide other files to use here:
            jumper_files = '/path/to/a/very/custom/file_database',
            jumper_directories = '/path/to/a/very/custom/directory_database',
        })
    end
}
```

## Credits
- [z](https://github.com/rupa/z)
- [telescope-z](https://github.com/nvim-telescope/telescope-z.nvim)
