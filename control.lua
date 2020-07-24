script.on_init(function()
	game.print("FacAutoScreenshot enabled and initialized")
	initialize()
end)

script.on_configuration_changed(function()
	game.print("Something changed. Reevaluating FacAutoScreenshot")
	initialize()
end)

function initialize()
	-- game.print("initializing")
	if global.zoom == nil then
		global.zoom = {}
		global.doScreenshot = {}
		global.interval = {}
		global.resX = {}
		global.resY = {}
	end

	-- if one is null, all are null
	if (global.minX == nil) then
		global.minX = 0
		global.maxX = 0
		global.minY = 0
		global.maxY = 0
		global.limitX = 0
		global.limitY = 0
	end

	loadSettings(1)
	evaluateLimitsFromWholeBase()
end

function loadSettings(player_index)
	-- game.print("loading settings for player " .. player_index)
	global.doScreenshot[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-do-screenshot"].value
	global.interval[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-Screenshot-interval"].value * 3600 -- 3600

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
	global.zoom[player_index] = 1
	
	-- confirmation prints reading back the set settings in chat
	if (global.doScreenshot[player_index]) then
		game.print("Player " .. player_index .. " does screenshots with resolution " .. 
		global.resX[player_index] .. "x" .. global.resY[player_index] .. 
		" every " .. (global.interval[player_index] / 3600) .. " minutes")
		evaluateZoomForPlayer(player_index)
	else
		game.print("Player " .. player_index .. " does no screenshots")
	end
end

function evaluateLimitsFromWholeBase()
	game.print("evaluating whole base")

	local surface = game.surfaces[1];
	-- do this smarter
	local tchunk = nil;
	local rchunk = nil;
	local bchunk = nil;
	local lchunk = nil;

	for chunk in surface.get_chunks() do
		if hasEntities(chunk) then
			if (tchunk == nil) then
				tchunk = chunk
				rchunk = chunk
				bchunk = chunk
				lchunk = chunk
			end

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

	local top = math.abs(tchunk.area.left_top.y)
	local right = math.abs(rchunk.area.right_bottom.x)
	local bottom = math.abs(bchunk.area.right_bottom.y)
	local left =  math.abs(lchunk.area.left_top.x)
	
	-- game.print("top: " .. top)
	-- game.print("right: " .. right)
	-- game.print("bottom: " .. bottom)
	-- game.print("left: " .. left)

	if (top > bottom) then
		global.limitY = top
	else
		global.limitY = bottom
	end

	if (left > right) then
		global.limitX = left
	else
		global.limitX = right
	end

	-- game.print("limitX: " .. global.limitX)
	-- game.print("limitY: " .. global.limitY)

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
	-- game.print("player " .. event.player_index .. " joined")
	loadSettings(event.player_index)
	evaluateZoomForPlayer(event.player_index)
end

function on_runtime_mod_setting_changed(event)
	-- game.print("runtimesettings for player " .. event.player_index .. " changed")
	loadSettings(event.player_index)
	evaluateZoomForPlayer(event.player_index)
end

function on_built_entity(event)
	-- game.print("on built entity")
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
	-- game.print("ev limit from position")
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
	-- game.print("ev zoom for all players")
	for _, player in pairs(game.connected_players) do
		-- game.print("ding")
		if global.doScreenshot[player.index] then
			-- game.print("dong")
			evaluateZoomForPlayer(player.index)
		end
	end
end

function evaluateZoomForPlayer(player)
	-- game.print("ev zoom for player")
	-- 7680					resx
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	-- zoomX = global.resX / (math.abs(pos.x) * 2 * 32);
	-- zoomY = global.resY / (math.abs(pos.y) * 2 * 32);
	local zoomX = global.resX[player] / (global.limitX * 2 * 32)
	local zoomY = global.resY[player] / (global.limitY * 2 * 32)

	local newZoom = zoomX
	if zoomX > zoomY then
		newZoom = zoomY
	end
	-- game.print("new zoom: " .. newZoom)
	
	if (global.zoom[player] == nil) then
		global.zoom[player] = 1
	end

	while newZoom < global.zoom[player] do
		global.zoom[player] = global.zoom[player] / 2
		game.print("Adjusted Zoom for player " .. player .. " to " .. global.zoom[player])
	end
end

-- 3600
script.on_nth_tick(3600, function(event)
	for _, player in pairs(game.connected_players) do
		if global.doScreenshot[player.index] then
			if event.tick % global.interval[player.index] == 0 then
				renderScreenshot(player.index)
			end
		end
	end
end)

function renderScreenshot(index)
	-- game.print("index: " .. index)
	-- game.print("resX: " .. global.resX[index])
	-- game.print("resY: " .. global.resY[index])
	-- game.print("zoom: " .. global.zoom[index])
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
