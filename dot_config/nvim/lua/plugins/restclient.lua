return {
	-- HTTP client — test your Spring Boot REST endpoints from inside Neovim
	-- Create .http files, press <leader>rr to run the request under cursor
	{
		"rest-nvim/rest.nvim",
		ft = { "http" },
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>rr", "<Plug>RestNvim", desc = "Run HTTP request" },
			{ "<leader>rp", "<Plug>RestNvimPreview", desc = "Preview HTTP request" },
			{ "<leader>rl", "<Plug>RestNvimLast", desc = "Re-run last request" },
		},
		opts = {
			result_split_horizontal = false,
			result_split_in_place = false,
			skip_ssl_verification = false,
			encode_url = true,
			highlight = { enabled = true, timeout = 150 },
			result = {
				show_url = true,
				show_http_info = true,
				show_headers = true,
				formatters = {
					json = "jq", -- install jq: brew install jq / apt install jq
					html = function(body)
						return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
					end,
				},
			},
		},
	},

	-- Persistent terminal — run AWS CLI, gradle, npm without leaving Neovim
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			{ "<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle terminal (horizontal)" },
			{ "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Toggle terminal (float)" },
			{ "<leader>tg", desc = "Lazygit" },
		},
		opts = {
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return vim.o.columns * 0.4
				end
			end,
			open_mapping = [[<C-\>]],
			shade_terminals = false,
			direction = "horizontal",
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = { border = "curved" },
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)
			-- Lazygit integration
			local Terminal = require("toggleterm.terminal").Terminal
			local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float" })
			vim.keymap.set("n", "<leader>tg", function()
				lazygit:toggle()
			end, { desc = "Lazygit" })
		end,
	},
}

-- EXAMPLE .http file for testing Spring Boot endpoints:
--
-- @baseUrl = http://localhost:8080
-- @token = Bearer eyJhbGc...
--
-- ### Get all users
-- GET {{baseUrl}}/api/users
-- Authorization: {{token}}
--
-- ### Create user
-- POST {{baseUrl}}/api/users
-- Content-Type: application/json
--
-- {
--   "name": "Jane",
--   "email": "jane@example.com"
-- }
