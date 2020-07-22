script.on_init(function()
	game.print("FacAutoScreenshot enabled and initialized")
	initialize();
end)

script.on_configuration_changed(function()
	game.print("Something changed. Reevaluating FacAutoScreenshot")
	initialize();
end)

function initialize()
	if global.zoom == nil then
		global.zoom = 1;
	end
	evaluateZoomFromWholeBase();
end

-- 3600
script.on_nth_tick(3600, function(event)
	for _, player in pairs(game.connected_players) do
		local index = player.index
		local doScreenshot = settings.get_player_settings(game.get_player(index))["FAS-do-screenshot"].value
		if doScreenshot then
			local interval = settings.get_player_settings(game.get_player(index))["FAS-Screenshot-interval"].value * 3600
			if event.tick % interval == 0 then
				renderScreenshot(index)
			end
		end
	end
end)

script.on_load(function()
	script.on_event(defines.events.on_built_entity, on_built_entity)
end)

function on_built_entity(event)
	pos = event.created_entity.position;

	-- 7680					resx
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	zoomX = global.resX / (math.abs(pos.x) * 2 * 32);
	zoomY = global.resY / (math.abs(pos.y) * 2 * 32);
	
	if breaksCurrentZoom(zoomX, zoomY) then
		evaluateZoomFromPosition(zoomX, zoomY)
		game.print("Adjusted Zoom level to: " .. global.zoom);
	end
end

function renderScreenshot(index)
	local resolution = settings.get_player_settings(game.get_player(index))["FAS-Resolution"].value

	local resX = 7680;
	local resY = 4320;
	if (resolution == "3840x2160 (4K)") then
		resX = 3840;
		resY = 2160;
	elseif (resolution == "1920x1080 (FullHD)") then
		resX = 1920;
		resY = 1080;
	elseif (resolution == "1280x720  (HD)") then
		resX = 1280;
		resY = 720;
	end

	game.take_screenshot{
		resolution={resX, resY},
		position={0, 0},
		zoom=global.zoom,		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player=index,
		path="./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
	}
end

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
