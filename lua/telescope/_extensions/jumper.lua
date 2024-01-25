local actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local sorters = require "telescope.sorters"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

local conf = require("telescope.config").values

local jumpfile = os.getenv("jumpfile")
local jumpfile_files = os.getenv("jumpfile_files")
local cmd = vim.tbl_flatten({ "jumper", "-f", jumpfile, "-n", "100" })
local cmd_files = vim.tbl_flatten({ "jumper", "-f", jumpfile_files, "-n", "100" })

local function jump(opts)
    opts = opts or {}
    local cwd = vim.loop.cwd()

    local jumper_finder = finders.new_job(function(prompt)
        return vim.tbl_flatten({ cmd, prompt })
    end, make_entry.gen_from_string(), {}, cwd)

    local ls = previewers.new_termopen_previewer({
        title = "Contents",
        get_command = function(entry)
            return { 'ls', '-1UpC', '--color=always', entry[1] }
        end
    })

    pickers.new(opts, {
        prompt_title = "Search",
        finder = jumper_finder,
        sorter = sorters.highlighter_only(opts),
        previewer = ls,
        attach_mappings = function(_)
            actions.select_default:replace(function()
                local entry = actions_state.get_selected_entry()
                require("telescope.builtin").find_files { cwd = entry[1], hidden = false }
            end)
            return true
        end,
    }):find()
end

local function jump_file(opts)
    opts = opts or {}
    local jumper_finder = finders.new_job(function(prompt)
        return vim.tbl_flatten({ cmd_files, prompt })
    end, make_entry.gen_from_string(), {}, '')
    pickers.new(opts, {
        prompt_title = "Search files",
        finder = jumper_finder,
        sorter = sorters.highlighter_only(opts),
    }):find()
end

local function os_capture(command, raw)
    local handle = assert(io.popen(command, 'r'))
    local output = assert(handle:read('*a'))
    handle:close()
    if raw then
        return output
    end
    output = string.gsub(string.gsub(output, '^%s+', ''), '%s+$', '')
    return output
end

local function find_in_files(opts)
    opts = opts or {}
    local jumper_finder = finders.new_job(function(prompt)
        local raw = os_capture("jumper -f ${jumpfile_files} ''", false)
        local file_list = {}
        for value in string.gmatch(raw, "([^" .. '\n' .. "]+)") do
            table.insert(file_list, value)
        end
        return vim.tbl_flatten({ conf.vimgrep_arguments, '--', prompt, file_list })
    end, opts.entry_maker or make_entry.gen_from_vimgrep(opts), {}, '')
    pickers.new(opts, {
        prompt_title = "Live Grep",
        finder = jumper_finder,
        previewer = conf.grep_previewer(opts),
        sorter = sorters.highlighter_only(opts),
    }):find()
end

return require("telescope").register_extension({
    exports = {
        jump = jump,
        jump_file = jump_file,
        find_in_files = find_in_files,
    },
})
