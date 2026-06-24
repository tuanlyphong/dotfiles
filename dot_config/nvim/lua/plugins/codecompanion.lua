return {
	{
		"olimorris/codecompanion.nvim",
		version = "^19.0.0",

		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
		},

		opts = {
			adapters = {
				http = {
					ollama = function()
						return require("codecompanion.adapters").extend("ollama", {
							env = {
								url = "https://executable-lustered-brittanie.ngrok-free.dev",
							},
							schema = {
								model = {
									default = "qwen2.5-coder:32b",
								},
							},
						})
					end,
				},
			},
			strategies = {
				chat = {
					adapter = "ollama",
				},
				inline = {
					adapter = "ollama",
				},
				agent = {
					adapter = "ollama",
				},
			},
			extensions = {
				mcphub = {
					callback = "mcphub.extensions.codecompanion",

					opts = {
						make_tools = true,

						-- FIXES:
						-- bad argument #1 to 'pairs'
						make_vars = false,

						make_slash_commands = true,
						show_result_in_chat = true,
					},
				},
			},
		},
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "codecompanion" },
	},

	{
		"OXY2DEV/markview.nvim",

		lazy = false,

		opts = {
			preview = {
				filetypes = {
					"markdown",
					"codecompanion",
				},

				ignore_buftypes = {},
			},
		},
	},
}
