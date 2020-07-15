-- 7200 = 2 * 60 * 60 ticks, every 2 mins
script.on_nth_tick(7200, function()
	game.take_screenshot{
		resolution={4000, 4000},
		position={0, 0},
		zoom=0.3,		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player=Anders142536,
		path="./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
	}
	game.print("screenshot done");
end)
