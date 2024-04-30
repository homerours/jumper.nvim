-- check if jumper is installed
if vim.fn.executable("jumper") ~= 1 then
    error("jumper is not installed. Please follow the instructions at https://github.com/homerours/jumper")
end

-- default configuration
local M = {}
local config = {
    jumper_files = os.getenv("__JUMPER_FILES"),
    jumper_directories = os.getenv("__JUMPER_FOLDERS"),
    jumper_max_results = 300,
    jumper_max_completion_results = 12,
    jumper_colors = true,
    jumper_beta = 1.0,
    jumper_syntax = 'extended',
    jumper_case_sensitivity = 'default'
}

local z_config = { jumper_max_results = 1, jumper_colors = false }

-- override default config
M.set_preferences = function(opts)
    for k, v in pairs(opts) do
        config[k] = v
    end
end

-- make jumper's command
M.make_command = function(database_file, opts, prompt)
    local cmd = { "jumper", "-f", database_file }

    local n = vim.F.if_nil(opts.jumper_max_results, config.jumper_max_results)
    if n ~= 'no_limit' then
        table.insert(cmd, "-n")
        table.insert(cmd, n)
    end

    local colors = vim.F.if_nil(opts.jumper_colors, config.jumper_colors)
    if colors then
        table.insert(cmd, "-c")
    end

    local syntax = vim.F.if_nil(opts.jumper_syntax, config.jumper_syntax)
    table.insert(cmd, "--syntax=" .. syntax)

    local case_sensitivity = vim.F.if_nil(opts.jumper_case_sensitivity, config.jumper_case_sensitivity)
    if case_sensitivity == 'sensitive' then
        table.insert(cmd, '-S')
    elseif case_sensitivity == 'insensitive' then
        table.insert(cmd, '-I')
    end

    if prompt ~= nil then
        table.insert(cmd, prompt)
    end
    return cmd
end

-- update the files' database
local function update_database(database_file, filename, weight)
    -- exclude git files and filenames with ':' (often temporay buffers generated by plugins)
    if not (string.find(filename, "/.git/") or string.find(filename, ":")) then
        vim.fn.system({ "jumper", "-f", database_file, "-w", tostring(weight), "-a", filename })
    end
end

-- Update database whenever a file is opened
vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPre" }, {
    pattern = { "*" },
    callback = function(ev)
        local filename = vim.api.nvim_buf_get_name(ev.buf)
        update_database(config.jumper_files, filename, 1.0)
    end
})

-- Update database whenever a file is modified
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function(ev)
        local buf_modified = vim.api.nvim_buf_get_option(ev.buf, 'modified')
        if buf_modified then
            local filename = vim.api.nvim_buf_get_name(ev.buf)
            update_database(config.jumper_files, filename, 0.3)
        end
    end
})

-- Update database whenever a current directory has changed
vim.api.nvim_create_autocmd({ "DirChanged" }, {
    pattern = { "*" },
    callback = function()
        update_database(config.jumper_directories, vim.loop.cwd(), 1.0)
    end
})

local function make_completion_function(database_file, max_results)
    return function(prompt, _, _)
        local cmd = M.make_command(database_file, { jumper_max_results = max_results, jumper_colors = false }, prompt)
        return vim.fn.systemlist(cmd)
    end
end

local function z(opts)
    local cmd = M.make_command(config.jumper_directories, z_config, opts.args)
    local dir = vim.fn.systemlist(cmd)
    if dir[1] then
        vim.cmd("cd " .. dir[1])
        vim.print(dir[1])
    else
        vim.print("No match found.")
    end
end

local function zf(opts)
    local cmd = M.make_command(config.jumper_files, z_config, opts.args)
    local dir = vim.fn.systemlist(cmd)
    if dir[1] then
        vim.cmd("edit " .. dir[1])
    else
        vim.print("No match found.")
    end
end

-- Functions to jump from the command line:
vim.api.nvim_create_user_command('Z', z,
    {
        nargs = '+',
        complete = make_completion_function(config.jumper_directories, config.jumper_max_completion_results)
    })
vim.api.nvim_create_user_command('Zf', zf,
    {
        nargs = '+',
        complete = make_completion_function(config.jumper_files, config.jumper_max_completion_results)
    })

M.config = config
return M
