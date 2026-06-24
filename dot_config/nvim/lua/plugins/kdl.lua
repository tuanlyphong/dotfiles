return {
	-- 1. Ensure KDL files get syntax highlighting and correct filetype detection
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				table.insert(opts.ensure_installed, "kdl")
			end
		end,
	},

	-- 2. Register kdlfmt with conform.nvim for automatic formatting
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				-- Map the .kdl filetype to the kdlfmt formatter
				kdl = { "kdlfmt" },
			},
			formatters = {
				kdlfmt = {
					-- The command-line executable we installed in Step 1
					command = "kdlfmt",
					-- The arguments to pass (format the file in place)
					args = { "format", "$FILENAME" },
					-- Tell conform not to use stdin, but to update the file on disk
					stdin = false,
				},
			},
		},
	},
}
