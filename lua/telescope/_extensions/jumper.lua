local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local jumper = require("jumper")

local function add_missing(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local function parse_ascii_colors(line)
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
    return entry.value, entry.highlights
end

local function entry_maker(line)
    local path, highlights = parse_ascii_colors(line)
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
        return { 'ls', '-1UpC', '--color=always', entry.value }
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

local function jump_to_directory(opts)
    opts = add_missing(opts or {}, jumper.config)

    local directory_finder = finders.new_job(function(prompt)
        return jumper.make_command(opts.jumper_directories, opts.jumper_max_results, true, prompt)
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

local function jump_to_file(opts)
    opts = add_missing(opts or {}, jumper.config)

    local file_finder = finders.new_job(function(prompt)
        return jumper.make_command(opts.jumper_files, opts.jumper_max_results, true, prompt)
    end, entry_maker, {}, '')

    pickers.new(opts, {
        prompt_title = "Files",
        finder = file_finder,
        previewer = opts.previewer or conf.grep_previewer(opts),
    }):find()
end

local function find_in_files(opts)
    opts = add_missing(opts or {}, jumper.config)

    local file_list = vim.fn.systemlist(jumper.make_command(opts.jumper_files, nil, false, ''))

    local grep_finder = finders.new_job(function(prompt)
        return vim.tbl_flatten({ conf.vimgrep_arguments, '--', prompt, file_list })
    end, opts.entry_maker or make_entry.gen_from_vimgrep(opts), {}, '')

    pickers.new(opts, {
        prompt_title = "Find in files",
        previewer = conf.grep_previewer(opts),
        finder = grep_finder,
    }):find()
end


return require("telescope").register_extension({
    exports = {
        jump_to_directory = jump_to_directory,
        jump_to_file = jump_to_file,
        find_in_files = find_in_files,
    },
})
