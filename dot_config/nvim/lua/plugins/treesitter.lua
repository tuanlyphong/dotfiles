return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"c", -- ✅ for ESP32 C
				"cpp", -- ✅ for ESP32 C++
				"cmake", -- ✅ useful for ESP-IDF / build configs
				"rust",
				"go",
				"java",
				"sql",
				"graphql",
				"http",
				"php",
				"astro",
				"scss",
				"css",
				"svelte",
				"gitignore",
				"fish",
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
