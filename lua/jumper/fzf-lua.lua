local fzf = require("fzf-lua")
local jumper = require("jumper")

local function make_f(database_file, max_results)
    local cmd_table = jumper.make_command(database_file, max_results, true)
    local cmd = table.concat(cmd_table, " ") .. " "
    return function(q)
        return vim.fn.systemlist(cmd .. q)
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

local function jump_to_directory(opts)
    opts = opts or {}
    opts.exec_empty_query = true
    opts.actions = { default = on_enter[opts.on_enter] }
    opts.fzf_opts = { ['--preview'] = 'ls -1UpC --color=always {}' }
    if opts.previewer == false then
        opts.fzf_opts['--preview-window'] = 'hidden'
    end
    fzf.fzf_live(
        make_f(opts.jumper_directories or jumper.config.jumper_directories,
            opts.jumper_max_results or jumper.config.jumper_max_results), opts)
end

local function jump_to_file(opts)
    opts = opts or {}
    opts.exec_empty_query = true
    opts.actions = { ['default'] = fzf.actions.file_edit }
    opts.previewer = "builtin"
    fzf.fzf_live(
        make_f(opts.jumper_files or jumper.config.jumper_files,
            opts.jumper_max_results or jumper.config.jumper_max_results), opts
    )
end

local function find_in_files(opts)
    opts = opts or {}
    opts.actions = fzf.defaults.actions.files
    opts.previewer = "builtin"
    opts.fn_transform = function(x)
        return fzf.make_entry.file(x, opts)
    end
    opts.fn_preprocess = function(o)
        opts.diff_files = fzf.make_entry.preprocess(o).diff_files
        return opts
    end
    local file_list = vim.fn.systemlist(jumper.make_command(jumper.config.jumper_files, nil, false, ''))
    local files = " " .. table.concat(file_list, " ")
    return fzf.fzf_live(function(q)
        return "rg --column --color=always -- " .. vim.fn.shellescape(q or '') .. files
    end, opts)
end

return {
    jump_to_directory = jump_to_directory,
    jump_to_file = jump_to_file,
    find_in_files = find_in_files
}
