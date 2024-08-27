-- default M.configuration
local M = {}
M.config = {
    jumper_max_results = 300,
    jumper_max_completion_results = 12,
    jumper_colors = true,
    jumper_home_tilde = true,
    jumper_orderless = true,
    jumper_relative = false,
    jumper_existing = false,
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

local function add_flag(cmd, opts, key, flag)
    if vim.F.if_nil(opts[key], M.config[key]) then
        table.insert(cmd, flag)
    end
end

-- make jumper's command
M.make_command = function(type, opts, prompt)
    local cmd = { "jumper", "find", "--type=" .. type}

    local n = vim.F.if_nil(opts.jumper_max_results, M.config.jumper_max_results)
    if n ~= 'no_limit' then
        table.insert(cmd, "-n")
        table.insert(cmd, n)
    end

	add_flag(cmd, opts, "jumper_colors", "-c")
	add_flag(cmd, opts, "jumper_home_tilde", "-H")
	add_flag(cmd, opts, "jumper_orderless", "-o")
	add_flag(cmd, opts, "jumper_relative", "-r")
	add_flag(cmd, opts, "jumper_existing", "-e")

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
