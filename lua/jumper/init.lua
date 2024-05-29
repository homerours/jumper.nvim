-- default M.configuration
local M = {}
M.config = {
    jumper_files = os.getenv("__JUMPER_FILES"),
    jumper_directories = os.getenv("__JUMPER_FOLDERS"),
    jumper_max_results = 300,
    jumper_max_completion_results = 12,
    jumper_colors = true,
    jumper_home_tilde = true,
    jumper_relative = false,
    jumper_beta = 1.0,
    jumper_syntax = 'extended',
    jumper_case_sensitivity = 'default'
}

M.unmatched_config = {}

-- override default M.config
M.setup = function(opts)
    for k, v in pairs(opts) do
        if M.config[k] ~= nil then
            M.config[k] = v
        else
            M.unmatched_config[k] = v
        end
    end
end

-- make jumper's command
M.make_command = function(database_file, opts, prompt)
    local cmd = { "jumper", "-f", database_file }

    local n = vim.F.if_nil(opts.jumper_max_results, M.config.jumper_max_results)
    if n ~= 'no_limit' then
        table.insert(cmd, "-n")
        table.insert(cmd, n)
    end

    local colors = vim.F.if_nil(opts.jumper_colors, M.config.jumper_colors)
    if colors then
        table.insert(cmd, "-c")
    end

    local home_tilde = vim.F.if_nil(opts.jumper_home_tilde, M.config.jumper_home_tilde)
    if home_tilde then
        table.insert(cmd, "-H")
    end

    local relative = vim.F.if_nil(opts.jumper_relative, M.config.jumper_relative)
    if relative then
        table.insert(cmd, "-r")
    end

    local syntax = vim.F.if_nil(opts.jumper_syntax, M.config.jumper_syntax)
    table.insert(cmd, "--syntax=" .. syntax)

    local case_sensitivity = vim.F.if_nil(opts.jumper_case_sensitivity, M.config.jumper_case_sensitivity)
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

return M
