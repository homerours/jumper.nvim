local M = {}
M.check = function()
    vim.health.start("jumper.nvim")
    if vim.fn.executable("jumper") == 1 then
        vim.health.ok("jumper's binary is installed")
    else
        vim.health.error(
            "jumper's binary is not installed. Please follow the instructions at https://github.com/homerours/jumper")
    end
    local j = require('jumper')
    vim.health.info("Files' database:         " .. j.config.jumper_files)
    vim.health.info("Directories' database:   " .. j.config.jumper_directories)
end
return M
