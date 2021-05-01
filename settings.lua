data:extend(
{
    -- {
    --     type = "bool-setting",
    --     name = "FAS-do-screenshot",
    --     setting_type = "runtime-per-user",
    --     default_value = false
    -- },
	-- {
	-- 	type = "int-setting",
	-- 	name = "FAS-Screenshot-interval",
	-- 	setting_type = "runtime-per-user",
    --     default_value = 2,
    --     minimum_value = 1,
    -- },
    -- {
    --     type = "string-setting",
    --     name = "FAS-Resolution",
    --     setting_type = "runtime-per-user",
    --     allowed_values = {"7680x4320 (8K)", "3840x2160 (4K)", "1920x1080 (FullHD)", "1280x720  (HD)"},
    --     default_value = "7680x4320 (8K)"
    -- },
    {
        type = "bool-setting",
        name = "FAS-enable-debug",
        setting_type = "runtime-global",
        default_value = false
    }
    -- {
    --     type = "int-setting",
    --     name = "FAS-increased-splitting",
    --     setting_type = "runtime-global",
    --     default_value = 1,
    --     allowed_values = {1, 4, 16, 64}
    -- },
	-- {
	-- 	type = "bool-setting",
	-- 	name = "FAS-single-screenshot",
	-- 	setting_type = "runtime-per-user",
    --     default_value = false
    -- }
})