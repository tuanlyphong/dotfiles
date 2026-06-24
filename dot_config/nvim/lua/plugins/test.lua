-- lua/plugins/test.lua
return {
	-- 1. Add the adapter plugins as dependencies
	{ "nvim-neotest/neotest-jest" },
	{ "marilari88/neotest-vitest" },

	-- 2. Register them into the core Neotest options
	{
		"nvim-neotest/neotest",
		opts = {
			adapters = {
				["neotest-jest"] = {
					-- Tells Jest where to find the project root configuration
					jestConfigFile = "jest.config.js",
				},
				["neotest-vitest"] = {},
			},
		},
	},
}
