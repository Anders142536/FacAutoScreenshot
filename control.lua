script.on_init(function()
	game.print("FacAutoScreenshot enabled and initialized")
	initialize()
end)

script.on_configuration_changed(function()
	game.print("Something changed. Reevaluating FacAutoScreenshot")
	initialize()
end)

function initialize()
	if global.zoom == nil then
		global.zoom = 1
	end

	-- if one is null, all are null
	if (global.minX == nil) then
		global.minX = 0
		global.maxX = 0
		global.minY = 0
		global.maxY = 0
	end

	loadSettings(1)
	evaluateLimitsFromWholeBase()
end

function loadSettings(player_index)
	game.print("loading settings for player " .. player_index)
	global.doScreenshot[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-do-screenshot"].value
	global.interval[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-Screenshot-interval"].value * 60 -- 3600

	local resolution = settings.get_player_settings(game.get_player(player_index))["FAS-Resolution"].value

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

	global.resX[player_index] = resX
	global.resY[player_index] = resY
end

function evaluateLimitsFromWholeBase()
	game.print("ev whole base")
	for _, surface in pairs(game.surfaces) do
		game.print("surface " .. surface.index .. ": " .. surface.name);
	end

	game.print("force 1 is : " .. game.forces[1].name)

	local surface = game.surfaces[1];
	-- do this smarter
	local tchunk = 0;
	local rchunk = 0;
	local bchunk = 0;
	local lchunk = 0;

	for chunk in surface.get_chunks() do
		if hasEntities(chunk) then
			if chunk.y > tchunk.y then
				tchunk = chunk
			elseif chunk.y < bchunk.y then
				bchunk = chunk
			end

			if chunk.x > rchunk.x then
				rchunk = chunk
			elseif chunk.x < lchunk.x then
				lchunk = chunk
			end
		end
	end
	evaluateZoomForAllPlayers()
end

function hasEntities(chunk)
	local count = game.surfaces[1].count_entities_filtered{
		area=chunk.area,
		force="player",
		limit=1
	}
	return (count ~= 0)
end

script.on_load(function()
	script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
	script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
	script.on_event(defines.events.on_built_entity, on_built_entity)
end)

function on_player_joined_game(event)
	game.print("player " .. event.player_index .. " joined")
	loadSettings(event.player_index)
end

function on_runtime_mod_setting_changed(event)
	game.print("runtimesettings for player " .. event.player_index .. " changed")
	loadSettings(event.player_index)
end

function on_built_entity(event)
	pos = event.created_entity.position
	if breaksCurrentLimits(pos) then
		evaluateLimitsFromPosition(pos)
	end
end

function breaksCurrentLimits(pos)
	return (pos.x < global.minX or
			pos.x > global.maxX or
			pos.y < global.minY or
			pos.y > global.maxY)
end

function evaluateLimitsFromPosition(pos)
	if pos.x < global.minX then
		global.minX = pos.x
	elseif pos.x > global.maxX then
		global.maxX = pos.x
	end

	if pos.y < global.minY then
		global.minY = pos.y
	elseif pos.y > global.maxY then
		global.maxY = pos.y
	end

	if math.abs(global.minX) > global.maxX then
		global.limitX =  math.abs(global.minX)
	else
		global.limitX = global.maxX
	end

	if math.abs(global.minY) > global.maxY then
		global.limitY = math.abs(global.minY)
	else
		global.limitY = global.maxY
	end

	evaluateZoomForAllPlayers()
end

function evaluateZoomForAllPlayers()
	for _, player in pairs(game.connected_players) do
		if global.doScreenshot[player.index] then
			evaluateZoomForPlayer(player.index)
		end
	end
end

function evaluateZoomForPlayer(player)
	-- 7680					resx
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	-- zoomX = global.resX / (math.abs(pos.x) * 2 * 32);
	-- zoomY = global.resY / (math.abs(pos.y) * 2 * 32);
	local zoomX = global.resX[player] / (global.limitX * 2 * 32)
	local zoomY = global.resY[player] / (global.limitY * 2 * 32)

	local currZoom = global.zoom[player]
	local newZoom = zoomX
	if zoomX < zoomY then
		newZoom = zoomY
	end
	
	if newZoom > currZoom then
		game.print("Adjusted Zoom for player " .. player .. " to " .. newZoom)
		global.zoom[player] = newZoom
	end
end

-- 3600
script.on_nth_tick(60, function(event)
	for _, player in pairs(game.connected_players) do
		local index = player.index
		local doScreenshot = settings.get_player_settings(game.get_player(index))["FAS-do-screenshot"].value
		if doScreenshot then
			local interval = settings.get_player_settings(game.get_player(index))["FAS-Screenshot-interval"].value * 60
			
			if event.tick % interval == 0 then
				renderScreenshot(index)
			end
		end
	end
end)

function renderScreenshot(index)
	game.take_screenshot{
		resolution={global.resX[index], global.resY[index]},
		position={0, 0},
		zoom=global.zoom[index],		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player=index,
		path="./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
	}
end
