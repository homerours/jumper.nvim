local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local telescope_state = require("telescope.state")
local conf = require("telescope.config").values

local jumper = require("jumper")
local state = {}

local function set_results_width()
    local status = telescope_state.get_status(vim.api.nvim_get_current_buf())
    state.results_width = vim.api.nvim_win_get_width(status.results_win)
end

-- parse the colors from jumper's outputs
local function parse_ansi_colors(line)
    local chunks = {}
    local highlights = {}
    local color = '\x1b[32m'
    local reset = '\x1b[0m'
    local offset = 1
    local hl_offset = 5
    while true do
        local x1, y1 = string.find(line, color, offset, true)
        local x2, y2 = string.find(line, reset, offset, true)
        if x1 == nil then break end
        table.insert(chunks, string.sub(line, offset, x1 - 1))
        table.insert(chunks, string.sub(line, y1 + 1, x2 - 1))
        table.insert(highlights, { { y1 - hl_offset, x2 - 1 - hl_offset }, "Identifier" })
        hl_offset = hl_offset + 9
        offset = y2 + 1
    end
    table.insert(chunks, string.sub(line, offset, -1))
    return table.concat(chunks), highlights
end

local function make_display(entry)
    if state.results_width ~= nil then
        local delta = string.len(entry.value) - state.results_width + 3
        if delta > 0 then
            local display_path = "..." .. string.sub(entry.value, delta + 3)
            local new_highlights = {}
            for _, hl in ipairs(entry.highlights) do
                if hl[1][2] > delta then
                    local hl_new = { { math.max(hl[1][1] - delta + 1, 0), hl[1][2] - delta + 1 }, hl[2] }
                    table.insert(new_highlights, hl_new)
                end
            end
            return display_path, new_highlights
        end
    end
    return entry.value, entry.highlights
end

local function entry_maker(line)
    local path, highlights = parse_ansi_colors(line)
    return {
        value = path,
        highlights = highlights,
        display = make_display,
        ordinal = 1
    }
end

-- previewer for directories
local ls_previewer = previewers.new_termopen_previewer({
    title = "Contents",
    get_command = function(entry)
        return { 'ls', '-1UpC', '--color=always', vim.fs.normalize(entry.value) }
    end
})

local on_enter_directory = {
    change_cwd = function(prompt_buffer)
        local entry = actions_state.get_selected_entry()
        vim.api.nvim_set_current_dir(entry.value)
        actions.close(prompt_buffer)
    end,
    find_files = function()
        local entry = actions_state.get_selected_entry()
        require("telescope.builtin").find_files({ cwd = entry.value })
    end,
}


-- Pickers:
local M = {}

M.jump_to_directory = function(opts)
    opts = opts or {}

    local directory_finder = finders.new_job(function(prompt)
        set_results_width()
        return jumper.make_command("directories", opts, prompt)
    end, entry_maker, {}, '')

    pickers.new(opts, {
        prompt_title = "Directories",
        finder = directory_finder,
        previewer = opts.previewer or ls_previewer,
        attach_mappings = function(_)
            local on_enter_function = on_enter_directory[opts.on_enter]
            if on_enter_function ~= nil then
                actions.select_default:replace(on_enter_function)
            end
            return true
        end,
    }):find()
end

M.jump_to_file = function(opts)
    opts = opts or {}

    local file_finder = finders.new_job(function(prompt)
        state.jumper_query = prompt
        set_results_width()
        return jumper.make_command("files", opts, prompt)
    end, entry_maker, {}, '')

    pickers.new(opts, {
        prompt_title = "Files. Ctrl-f to live grep.",
        finder = file_finder,
        previewer = opts.previewer or conf.grep_previewer(opts),
        attach_mappings = function(_, map)
            map('i', '<c-f>', function()
                M.find_in_files({ default_text = opts.grep_query, jumper_query = state.jumper_query })
            end)
            return true
        end,
    }):find()
end

M.find_in_files = function(opts)
    opts = opts or {}

    local list_opts = { jumper_max_results = 'no_limit', jumper_colors = false, jumper_home_tilde = false }
    local file_list = vim.fn.systemlist(jumper.make_command("files", list_opts, opts.jumper_query))

    local grep_finder = finders.new_job(function(prompt)
        state.grep_query = prompt
        return vim.tbl_flatten({ conf.vimgrep_arguments, '--', prompt, file_list })
    end, opts.entry_maker or make_entry.gen_from_vimgrep(opts), {}, '')

    local title = "Live grep. Ctrl-f to filter files."
    if opts.jumper_query ~= nil and opts.jumper_query ~= "" then
        title = title .. "Current filter: " .. opts.jumper_query
    end

    pickers.new(opts, {
        prompt_title = title,
        previewer = conf.grep_previewer(opts),
        finder = grep_finder,
        attach_mappings = function(_, map)
            map('i', '<c-f>', function()
                M.jump_to_file({ default_text = opts.jumper_query, grep_query = state.grep_query })
            end)
            return true
        end,
    }):find()
end

return M
