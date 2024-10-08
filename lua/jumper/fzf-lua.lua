local fzf = require("fzf-lua")
local jumper = require("jumper")

local saved = {}

local function make_f(type, opts)
    return function(q)
        saved.query = q
        local cmd = jumper.make_command(type, opts, q)
        return vim.fn.systemlist(cmd)
    end
end

local on_enter = {
    change_cwd = function(selected, _)
        vim.api.nvim_set_current_dir(selected[1])
    end,
    find_files = function(selected, _)
        fzf.files({ cwd = selected[1] })
    end,
}
setmetatable(on_enter, { __index = function() return fzf.actions.file_edit end })
local M = {}

local function ls_previewer(items)
    return "ls -1UpC --color=always " .. vim.fs.normalize(items[1])
end

M.jump_to_directory = function(opts)
    opts = opts or {}
    opts.exec_empty_query = true
    opts.actions = { default = on_enter[opts.on_enter] }
    opts.fzf_opts = { ['--keep-right'] = true, ['--ansi'] = true }
    opts.preview = { type = 'cmd', fn = ls_previewer }
    if opts.previewer == false then
        opts.fzf_opts['--preview-window'] = 'hidden'
    end
    fzf.fzf_live(make_f("directories", opts), opts)
end

M.jump_to_file = function(opts)
    opts = opts or {}
    opts.exec_empty_query = true
    opts.actions = {
        ['default'] = fzf.actions.file_edit,
        ['ctrl-g'] = {
            fn = function(_)
                M.find_in_files({ query = opts.grep_query, jumper_query = saved.query })
            end,
            reload = false
        }
    }
    opts.previewer = "builtin"
    opts.fzf_opts = { ['--keep-right'] = true, ['--ansi'] = true, ['--header'] = '<Ctrl-g> to grep files' }
    fzf.fzf_live(make_f("files", opts), opts)
end

M.find_in_files = function(opts)
    opts = opts or {}
    saved.grep_query = opts.query
    opts.actions = fzf.defaults.actions.files
    opts.actions['ctrl-g'] = function(_)
        M.jump_to_file({ query = opts.jumper_query, grep_query = saved.grep_query })
    end
    opts.previewer = "builtin"
    opts.fn_transform = function(x)
        return fzf.make_entry.file(x, opts)
    end

    local list_opts = { jumper_max_results = 'no_limit', jumper_colors = false, jumper_home_tilde = false }
    local cmd = jumper.make_command("files", list_opts, opts.jumper_query)
    local file_list = vim.fn.systemlist(cmd)
    local files = " " .. table.concat(file_list, " ")

    local header = '<Ctrl-g> to filter files.'
    if opts.jumper_query and opts.jumper_query ~= '' then
        header = header .. ' Current filter: ' .. opts.jumper_query
    end
    opts.fzf_opts = { ['--header'] = header }

    return fzf.fzf_live(function(q)
        saved.grep_query = q
        return "rg --column --color=always -- " .. vim.fn.shellescape(q or '') .. files .. " 2>/dev/null"
    end, opts)
end

return M
