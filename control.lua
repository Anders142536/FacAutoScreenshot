script.on_load(function()
	initialize()
end)

script.on_init(function()
	initialize()
end)

function initialize()
	zoom = {}
	zoomLevel = {}
	doScreenshot = {}
	interval = {}
	resX = {}
	resY = {}
	
	minX = 1
	maxX = 1
	minY = 1
	maxY = 1
	limitX = 1
	limitY = 1
	
	firstRun = true;
end

function on_player_joined_game(event)
	-- game.print("player " .. event.player_index .. " joined")
	loadSettings(event.player_index)
end

function on_runtime_mod_setting_changed(event)
	-- game.print("runtimesettings for player " .. event.player_index .. " changed")
	loadSettings(event.player_index)
end

function on_built_entity(event)
	-- game.print("on built entity")
	pos = event.created_entity.position
	if breaksCurrentLimits(pos) then
		evaluateLimitsFromPosition(pos)
	end
end


function loadSettings(player_index)
	-- game.print("loading settings for player " .. player_index)
	doScreenshot[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-do-screenshot"].value
	interval[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-Screenshot-interval"].value * 3600 -- 3600
	
	local resolution = settings.get_player_settings(game.get_player(player_index))["FAS-Resolution"].value
	
	resX[player_index] = 7680;
	resY[player_index] = 4320;
	if (resolution == "3840x2160 (4K)") then
		resX[player_index] = 3840;
		resY[player_index] = 2160;
	elseif (resolution == "1920x1080 (FullHD)") then
		resX[player_index] = 1920;
		resY[player_index] = 1080;
	elseif (resolution == "1280x720  (HD)") then
		resX[player_index] = 1280;
		resY[player_index] = 720;
	end
	
	zoom[player_index] = 1
	zoomLevel[player_index] = 1
	
	-- confirmation prints reading back the set settings in chat
	if (doScreenshot[player_index]) then
		game.print("FAS: Player " .. player_index .. " does screenshots with resolution " .. 
		resX[player_index] .. "x" .. resY[player_index] .. 
		" every " .. (interval[player_index] / 3600) .. " minutes")
		evaluateZoomForPlayer(player_index)
	else
		game.print("FAS: Player " .. player_index .. " does no screenshots")
	end
end
	
function evaluateLimitsFromWholeBase()
	game.print("FAS: Evaluating whole base")
	
	local surface = game.surfaces[1];
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
	
	-- if no blocks have been placed yet
	if tchunk == nil then
		limitX = 1
		limitY = 1
	else
		local top = math.abs(tchunk.area.left_top.y)
		local right = math.abs(rchunk.area.right_bottom.x)
		local bottom = math.abs(bchunk.area.right_bottom.y)
		local left =  math.abs(lchunk.area.left_top.x)
		
		-- game.print("top: " .. top)
		-- game.print("right: " .. right)
		-- game.print("bottom: " .. bottom)
		-- game.print("left: " .. left)
		
		if (top > bottom) then
			limitY = top
		else
			limitY = bottom
		end
		
		if (left > right) then
			limitX = left
		else
			limitX = right
		end
	end
end

function hasEntities(chunk)
	local count = game.surfaces[1].count_entities_filtered{
		area=chunk.area,
		force="player",
		limit=1
	}
	return (count ~= 0)
end


function breaksCurrentLimits(pos)
	return (pos.x < minX or
	pos.x > maxX or
	pos.y < minY or
	pos.y > maxY)
end

function evaluateLimitsFromPosition(pos)
	-- game.print("FAS: Evaluate limit from position")
	if pos.x < minX then
		minX = pos.x
	elseif pos.x > maxX then
		maxX = pos.x
	end
	
	if pos.y < minY then
		minY = pos.y
	elseif pos.y > maxY then
		maxY = pos.y
	end
	
	if math.abs(minX) > maxX then
		limitX =  math.abs(minX)
	else
		limitX = maxX
	end
	
	if math.abs(minY) > maxY then
		limitY = math.abs(minY)
	else
		limitY = maxY
	end
	
	evaluateZoomForAllPlayers()
end

function evaluateZoomForAllPlayers()
	-- game.print("ev zoom for all players")
	for _, player in pairs(game.connected_players) do
		-- game.print("ding")
		if doScreenshot[player.index] then
			-- game.print("dong")
			evaluateZoomForPlayer(player.index)
		end
	end
end

function evaluateZoomForPlayer(player)
	-- game.print("ev zoom for player " .. player)
	-- 7680					resx
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	-- zoomX = resX / (math.abs(pos.x) * 2 * 32);
	-- zoomY = resY / (math.abs(pos.y) * 2 * 32);
	local zoomX = resX[player] / (limitX * 2 * 32)
	local zoomY = resY[player] / (limitY * 2 * 32)

	local newZoom = zoomX
	if zoomX > zoomY then
		newZoom = zoomY
	end
	
	local oldZoom = zoom[player]
	while newZoom < zoom[player] do
		zoomLevel[player] = zoomLevel[player] + 1
		zoom[player] = 1 / zoomLevel[player]
	end
	if oldZoom > zoom[player] then
		game.print("FAS: Adjusted zoom for player " .. player .. " from " .. oldZoom .. " to " .. zoom[player])
	end
end

-- 3600
script.on_nth_tick(3600, function(event)
	-- game.print("on nth tick")
	if firstRun then
		evaluateLimitsFromWholeBase()
		evaluateZoomForAllPlayers()
		firstRun = false
	end
	
	for _, player in pairs(game.connected_players) do
		if doScreenshot[player.index] then
			if event.tick % interval[player.index] == 0 then
				renderScreenshot(player.index)
			end
		end
	end
end)

function renderScreenshot(index)
	-- game.print("index: " .. index)
	-- game.print("resX: " .. resX[index])
	-- game.print("resY: " .. resY[index])
	-- game.print("zoom: " .. zoom[index])
	game.take_screenshot{
		resolution={resX[index], resY[index]},
		position={0, 0},
		zoom=zoom[index],		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player=index,
		path="./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
	}
end

script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)
