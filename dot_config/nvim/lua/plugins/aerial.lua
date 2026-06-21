return {
	"stevearc/aerial.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},

	keys = {
		{ "gz", "<cmd>AerialToggle!<CR>", desc = "Aerial Toggle" },
		{ "]a", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
		{ "[a", "<cmd>AerialPrev<CR>", desc = "Previous Symbol" },
	},

	opts = {
		backends = { "lsp", "treesitter", "markdown", "man" },

		layout = {
			min_width = 28,
			default_direction = "right",
			placement = "edge",
			resize_to_content = true,
		},

		attach_mode = "window",

		show_guides = true,
		filter_kind = false,

		highlight_on_hover = true,
		autojump = false,

		close_automatic_events = {},

		guides = {
			mid_item = "├─",
			last_item = "└─",
			nested_top = "│ ",
			whitespace = "  ",
		},

		keymaps = {
			["?"] = "actions.show_help",
			["g?"] = "actions.show_help",
			["<CR>"] = "actions.jump",
			["o"] = "actions.jump",
			["l"] = "actions.jump",
			["v"] = "actions.jump_vsplit",
			["s"] = "actions.jump_split",
			["h"] = "actions.tree_close",
			["za"] = "actions.tree_toggle",
			["zr"] = "actions.tree_increase_fold_level",
			["zm"] = "actions.tree_decrease_fold_level",
			["zR"] = "actions.tree_open_all",
			["zM"] = "actions.tree_close_all",
			["q"] = "actions.close",
			["r"] = "actions.refresh",
		},

		icons = {
			Class = "󰠱 ",
			Constructor = " ",
			Enum = " ",
			Function = "󰊕 ",
			Interface = " ",
			Method = "󰆧 ",
			Module = "󰏗 ",
			Namespace = "󰌗 ",
			Package = "󰏗 ",
			Property = "󰜢 ",
			Struct = "󰙅 ",
			Variable = "󰀫 ",
			Field = "󰜢 ",
		},

		manage_folds = true,
		link_folds_to_tree = false,
		link_tree_to_folds = true,

		nerd_font = "auto",
	},
}
