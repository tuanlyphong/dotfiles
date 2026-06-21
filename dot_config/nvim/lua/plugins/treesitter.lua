return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"java",
				"sql",
				"graphql",
				"http",
				"php",
				"scss",
				"css",
				"svelte",
				"gitignore",
				"html",
				"javascript",
				"kotlin",
				"python",
				"rust",
			},

			highlight = { enable = true },
			indent = { enable = true },

			query_linter = {
				enable = true,
				use_virtual_text = true,
				lint_events = { "BufWrite", "CursorHold" },
			},
		},
		config = function()
			-- MDX support (optional)
			vim.filetype.add({
				extension = { mdx = "mdx" },
			})
			vim.treesitter.language.register("markdown", "mdx")
		end,
	},
}
