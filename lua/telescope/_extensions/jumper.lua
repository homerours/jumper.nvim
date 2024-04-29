local jumper_telescope = require('jumper.telescope_extension')
return require("telescope").register_extension({
    exports = {
        jump_to_directory = jumper_telescope.jump_to_directory,
        jump_to_file = jumper_telescope.jump_to_file,
        find_in_files = jumper_telescope.find_in_files,
    },
})
