local fzf = require("fzf-lua")
local jumper = require("jumper")

local saved = {}

local function add_icons(results, opts)
    return  vim.tbl_map(function(x)
        return fzf.make_entry.file(x, opts)
    end,results)
end

local function make_f(type, opts)
    return function(q)
        saved.query = q
        local cmd = jumper.make_command(type, opts, q)
        local results = vim.fn.systemlist(cmd)
        if opts.file_icons then
            return add_icons(results, opts)
        else
            return results
        end
    end
end

local on_enter = {
    change_cwd = function(selected, _)
        local f = fzf.path.entry_to_file(selected[1])
        vim.api.nvim_set_current_dir(f.path)
    end,
    find_files = function(selected, _)
        local f = fzf.path.entry_to_file(selected[1])
        fzf.files({ cwd = f.path })
    end,
}
setmetatable(on_enter, { __index = function() return fzf.actions.file_edit end })
local M = {}

local function ls_previewer(items)
    local f = fzf.path.entry_to_file(items[1])
    return "ls -1UpC --color=always " .. vim.fs.normalize(f.path)
end

M.jump_to_directory = function(opts)
    opts = opts or {}
    opts.exec_empty_query = true
    opts.actions = { default = on_enter[opts.on_enter] }
    opts.fzf_opts = { ['--keep-right'] = true, ['--ansi'] = true }
    opts = fzf.config.normalize_opts(opts, "files")
    opts.preview = { type = 'cmd', fn = ls_previewer }
    if opts.previewer == false then
        opts.fzf_opts['--preview-window'] = 'hidden'
    else
        opts.previewer = true
    end
    fzf.fzf_live(make_f("directories", opts), opts)
end

M.jump_to_file = function(opts)
    opts = opts or {}
    opts.exec_empty_query = true
    opts.actions = opts.actions or {}
    opts.actions['ctrl-g'] = {
        fn = function(_)
            M.find_in_files({ query = opts.grep_query, jumper_query = saved.query })
        end,
        reload = false
    }
    opts.fzf_opts = { ['--keep-right'] = true, ['--ansi'] = true, ['--header'] = '<Ctrl-g> to grep files' }
    opts = fzf.config.normalize_opts(opts, "files")
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
    -- opts = fzf.config.normalize_opts(opts,{})

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
