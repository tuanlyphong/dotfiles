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
					kaggle = function()
						return require("codecompanion.adapters").extend("openai_compatible", {
							name = "kaggle",

							schema = {
								model = {
									default = "qwen2.5-coder:14b",
								},
							},

							env = {
								url = "https://executable-lustered-brittanie.ngrok-free.dev",
							},
						})
					end,
				},
			},

			strategies = {
				chat = {
					adapter = "kaggle",
				},

				inline = {
					adapter = "kaggle",

					prompts = {
						system = {
							content = "You are a code editor. Output ONLY raw code with no markdown fences, no explanation, no preamble. Output the complete updated file contents only.",
						},
					},
				},

				agent = {
					adapter = "kaggle",
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
