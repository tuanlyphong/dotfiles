return {
	-- 1. Ensure KDL and TOML files get syntax highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				table.insert(opts.ensure_installed, "kdl")
				table.insert(opts.ensure_installed, "toml")
			end
		end,
	},

	-- 2. Register kdlfmt and taplo with conform.nvim safely
	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			-- Initialize tables if they don't exist to prevent errors
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters = opts.formatters or {}

			-- Map filetypes to formatters
			opts.formatters_by_ft.kdl = { "kdlfmt" }
			opts.formatters_by_ft.toml = { "taplo" }

			-- Define the custom kdlfmt binary properties
			opts.formatters.kdlfmt = {
				command = "kdlfmt",
				args = { "format", "$FILENAME" },
				stdin = false,
			}
		end,
	},
}
