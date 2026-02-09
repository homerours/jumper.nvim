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
    local highlights = {}
    local parts = {}
    local pos = 1
    local output_offset = 0

    -- Process each ANSI colored segment
    for match_start, highlighted, match_end in line:gmatch("()\x1b%[32m([^\x1b]+)\x1b%[0m()") do
        -- Add plain text before the match
        if match_start > pos then
            local plain_text = line:sub(pos, match_start - 1)
            table.insert(parts, plain_text)
            output_offset = output_offset + #plain_text
        end

        -- Add highlighted text and record its position
        table.insert(parts, highlighted)
        table.insert(highlights, { { output_offset, output_offset + #highlighted }, "Identifier" })
        output_offset = output_offset + #highlighted

        pos = match_end
    end

    -- Add any remaining text after the last match
    if pos <= #line then
        table.insert(parts, line:sub(pos))
    end

    return table.concat(parts), highlights
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
