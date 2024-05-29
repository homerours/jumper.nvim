local M = {}

local function is_installed(plugin)
    local res, _ = pcall(require, plugin)
    return res
end

M.check = function()
    vim.health.start("jumper.nvim")
    if vim.fn.executable("jumper") == 1 then
        vim.health.ok("jumper's binary is installed.")
    else
        vim.health.error(
            "jumper's binary is not installed. Please follow the instructions at https://github.com/homerours/jumper")
    end

    local fzf_lua_installed = is_installed("fzf-lua")
    local telescope_installed = is_installed("telescope")

    if fzf_lua_installed then
        vim.health.ok("fzf-lua installed.")
    end
    if telescope_installed then
        vim.health.ok("Telescope installed.")
    end

    if not fzf_lua_installed and not telescope_installed then
        vim.health.warn(
        "Neither of fzf-lua or telescope is installed.\n You may want to install one of them for interactive queries.")
    end

    local j = require('jumper')
    vim.health.info("Files' database:         " .. j.config.jumper_files)
    vim.health.info("Directories' database:   " .. j.config.jumper_directories)

    for k, _ in pairs(j.unmatched_config) do
        vim.health.warn("Unmatched option: " .. k)
    end
end
return M
