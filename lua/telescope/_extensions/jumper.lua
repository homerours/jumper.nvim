local actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local sorters = require "telescope.sorters"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"


local jumpfile = os.getenv("jumpfile")
local cmd = vim.tbl_flatten({ "jumper", "-f", jumpfile, "-n", "50" })

local function jump(opts)
    opts = opts or {}
    local cwd = vim.loop.cwd()

    local jumper_finder = finders.new_job(function(prompt)
        return vim.tbl_flatten({ cmd, prompt })
    end, make_entry.gen_from_string(), {}, cwd)

    local ls = previewers.new_termopen_previewer({
        title = "Contents",
        get_command = function(entry)
            return { 'ls', entry[1] }
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

return require("telescope").register_extension({
    exports = {
        jump = jump,
    },
})
