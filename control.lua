resX = 7680;
resY = 4320;

script.on_init(function()
	game.print("FacAutoScreenshot enabled and initialized")
	global.zoom = 1;
	evaluateZoomFromWholeBase();
end)

script.on_configuration_changed(function()
	game.print("Something changed. Reevaluating FacAutoScreenshot")
	global.zoom = 1;
	evaluateZoomFromWholeBase();
end)

script.on_load(function()
	script.on_event(defines.events.on_built_entity, on_built_entity)
end)

function on_built_entity(event)
	pos = event.created_entity.position;

	-- 7680					resx
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	zoomX = resX / (math.abs(pos.x) * 2 * 32);
	zoomY = resY / (math.abs(pos.y) * 2 * 32);
	
	if breaksCurrentZoom(zoomX, zoomY) then
		evaluateZoomFromPosition(zoomX, zoomY)
		game.print("Adjusted Zoom level to: " .. global.zoom);
	end
end

-- 7200 = 2 * 60 * 60 ticks, every 10 mins
script.on_nth_tick(7200, function()
	game.take_screenshot{
		resolution={resX, resY},
		position={0, 0},
		zoom=global.zoom,		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player="Anders142536",
		path="./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
	}
end)

function breaksCurrentZoom(zoomX, zoomY)
	return (zoomX < global.zoom or zoomY < global.zoom);
end

function evaluateZoomFromWholeBase()
	game.print("ev whole base");
end

function evaluateZoomFromPosition(zoomX, zoomY)
	while breaksCurrentZoom(zoomX, zoomY) do
		global.zoom = global.zoom / 2;
	end
end
