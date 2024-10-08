if vim.g.loaded_jumper == 1 then return end
vim.g.loaded_jumper = 1

-- check if jumper is installed
if vim.fn.executable("jumper") ~= 1 then
    vim.api.nvim_err_writeln(
        "jumper is not installed. Please follow the instructions at https://github.com/homerours/jumper")
    return
end

local uv = vim.uv or vim.loop
local j = require('jumper')
local z_config = { jumper_max_results = 1, jumper_colors = false }

-- update the files' database
local function update_database(filename, weight)
    -- exclude git files and filenames with ':' (often temporay buffers generated by plugins)
    if not (string.find(filename, "/.git/") or string.find(filename, ":")) then
        vim.fn.system({ "jumper", "update", "--type=files", "-w", tostring(weight), filename })
    end
end

-- Update database whenever a file is opened
vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPre" }, {
    pattern = { "*" },
    callback = function(ev)
        local filename = vim.api.nvim_buf_get_name(ev.buf)
        update_database(filename, 1.0)
    end
})

-- Update database whenever a file is modified
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function(ev)
        local buf_modified = vim.api.nvim_buf_get_option(ev.buf, 'modified')
        if buf_modified then
            local filename = vim.api.nvim_buf_get_name(ev.buf)
            update_database(filename, 0.3)
        end
    end
})

-- Update database whenever a current directory has changed
vim.api.nvim_create_autocmd({ "DirChanged" }, {
    pattern = { "*" },
    callback = function()
        update_database(uv.cwd(), 1.0)
    end
})

local function make_completion_function(type)
    return function(prompt, _, _)
        local cmd = j.make_command(type,
            { jumper_max_results = j.config.jumper_max_completion_results, jumper_colors = false },
            prompt)
        return vim.fn.systemlist(cmd)
    end
end

local function z(opts)
    local cmd = j.make_command("directories", z_config, vim.fs.normalize(opts.args))
    local dir = vim.fn.systemlist(cmd)
    if dir[1] then
        vim.cmd("cd " .. dir[1])
        vim.print(dir[1])
    else
        vim.print("No match found.")
    end
end

local function zf(opts)
    local cmd = j.make_command("files", z_config, vim.fs.normalize(opts.args))
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
        complete = make_completion_function('directories')
    })
vim.api.nvim_create_user_command('Zf', zf,
    {
        nargs = '+',
        complete = make_completion_function('files')
    })
