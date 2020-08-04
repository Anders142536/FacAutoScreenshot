-- script.on_load(function()
-- 	log("on load")
-- 	isFirst = true;
-- end)

script.on_init(function()
	log("on init")
	-- isFirst = true;
	initialize()
end)

script.on_configuration_changed(function()
	log("on configuraiton changed")
	-- isFirst = true;
	initialize()
end)

-- basically resets the state of the script
function initialize()
	log("initialize")

	global.verbose = settings.global["FAS-enable-debug"].value
	
	global.zoom = {}
	global.zoomLevel = {}
	global.doScreenshot = {}
	global.interval = {}
	global.resX = {}
	global.resY = {}
	
	global.minX = 1
	global.maxX = 1
	global.minY = 1
	global.maxY = 1
	global.limitX = 1
	global.limitY = 1

	evaluateLimitsFromWholeBase()
	for _, player in pairs(game.connected_players) do
		log("found player already connected: " .. player.name)
		loadSettings(player.index)
	end

end

function evaluateLimitsFromWholeBase()
	log("Evaluating whole base")
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
			
			if chunk.y < tchunk.y then
				tchunk = chunk
			elseif chunk.y > bchunk.y then
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
		log("tchunk is nil")
		global.limitX = 1
		global.limitY = 1
	else
		-- add 20 to have empty margin
		local top = math.abs(tchunk.area.left_top.y) + 20
		local right = math.abs(rchunk.area.right_bottom.x) + 20
		local bottom = math.abs(bchunk.area.right_bottom.y) + 20
		local left =  math.abs(lchunk.area.left_top.x) + 20
		
		if (global.verbose) then
			log("top: " .. top)
			log("right: " .. right)
			log("bottom: " .. bottom)
			log("left: " .. left)
		end
		
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

		if (global.verbose) then
			log("limitX: " .. global.limitX)
			log("limitY: " .. global.limitY)
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

function on_player_joined_game(event)
	log("player " .. event.player_index .. " joined")
	loadSettings(event.player_index)
end

function on_runtime_mod_setting_changed(event)
	if (event.setting_type == "runtime-global") then
		log("global settings changed")
		game.print("FAS: Global settings changed")
		global.verbose = settings.global["FAS-enable-debug"].value
	else
		log("runtimesettings for player " .. event.player_index .. " changed")
		loadSettings(event.player_index)
	end
end

function loadSettings(player_index)
	log("loading settings for player " .. player_index)
	global.doScreenshot[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-do-screenshot"].value
	global.interval[player_index] = settings.get_player_settings(game.get_player(player_index))["FAS-Screenshot-interval"].value * 3600 -- 3600
	
	local resolution = settings.get_player_settings(game.get_player(player_index))["FAS-Resolution"].value
	
	global.resX[player_index] = 7680;
	global.resY[player_index] = 4320;
	if (resolution == "3840x2160 (4K)") then
		global.resX[player_index] = 3840;
		global.resY[player_index] = 2160;
	elseif (resolution == "1920x1080 (FullHD)") then
		global.resX[player_index] = 1920;
		global.resY[player_index] = 1080;
	elseif (resolution == "1280x720  (HD)") then
		global.resX[player_index] = 1280;
		global.resY[player_index] = 720;
	end
	
	global.zoom[player_index] = 1
	global.zoomLevel[player_index] = 1
	
	-- confirmation prints reading back the set settings in chat.
	local outputString
	if (global.doScreenshot[player_index]) then
		outputString = "Player " .. player_index .. " does screenshots with resolution " .. 
		global.resX[player_index] .. "x" .. global.resY[player_index] .. 
		" every " .. (global.interval[player_index] / 3600) .. " minutes"
		log(outputString)
		game.print("FAS: " .. outputString)
		evaluateZoomForPlayer(player_index)
	else
		outputString = "Player " .. player_index .. " does no screenshots"
		log(outputString)
		game.print("FAS: " .. outputString)
	end
end

function on_built_entity(event)
	local pos = event.created_entity.position
	if (global.verbose) then
		log("pos: " .. pos.x .. "x" .. pos.y)
	end
	if breaksCurrentLimits(pos) then
		evaluateMinMaxFromPosition(pos)
	end
end

function breaksCurrentLimits(pos)
	if (global.verbose) then
		log("breakscurrentLimits: pos: " .. pos.x .. "x" .. pos.y)
	end
	return (pos.x < global.minX or
	pos.x > global.maxX or
	pos.y < global.minY or
	pos.y > global.maxY)
end

function evaluateMinMaxFromPosition(pos)
	if (global.verbose) then
		log("Evaluate min max from position: " .. pos.x .. "x" .. pos.y)
	end
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

	if (global.verbose) then
		log("global.minX = " .. global.minX)
		log("global.maxX = " .. global.maxX)
		log("global.minY = " .. global.minY)
		log("global.maxY = " .. global.maxY)
	end
	
	global.minMaxChanged = true
end

-- 3600
script.on_nth_tick(3600, function(event)
	log("on nth tick")
	-- if something was built in the last minute that should cause a recalc of all zoom levels
	if (global.minMaxChanged) then
		if (global.verbose) then
			log("min max changed")
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
		global.minMaxChanged = false
	end
	
	for _, player in pairs(game.connected_players) do
		log("player " .. player.name .. " with index " .. player.index .. " found")
		log(global.doScreenshot[player.index])
		log(global.interval[player.index])
		log(game.tick)
		if global.doScreenshot[player.index] and (event.tick % global.interval[player.index] == 0) then
			renderScreenshot(player.index)
		end
	end
end)

function evaluateZoomForAllPlayers()
	log("ev zoom for all players")
	for _, player in pairs(game.connected_players) do
		if global.doScreenshot[player.index] then
			evaluateZoomForPlayer(player.index)
		end
	end
end

function evaluateZoomForPlayer(player)
	if(global.verbose) then
		log("ev zoom for player " .. player)
		log("resX: " .. global.resX[player])
		log("resY: " .. global.resY[player])
		log("global.limitX: " .. global.limitX)
		log("global.limitY: " .. global.limitY)
		log("old zoom: " .. global.zoom[player])
		log("zoomLevel: " .. global.zoomLevel[player])
	end
	-- 7680					global.resX
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	local zoomX = global.resX[player] / (global.limitX * 2 * 32)
	local zoomY = global.resY[player] / (global.limitY * 2 * 32)

	local newZoom = zoomX
	if zoomX > zoomY then
		newZoom = zoomY
	end

	local oldZoom = global.zoom[player]
	while newZoom < global.zoom[player] do
		global.zoomLevel[player] = global.zoomLevel[player] + 1
		global.zoom[player] = 1 / global.zoomLevel[player]
		log("Adjusting zoom for player " .. player .. " to " .. global.zoom[player] .. " and zoomlevel to " .. global.zoomLevel[player])
	end
	if oldZoom > global.zoom[player] then
		log("Adjusted zoom for player " .. player .. " from " .. oldZoom .. " to " .. global.zoom[player])
		game.print("FAS: Adjusted zoom for player " .. player .. " from " .. oldZoom .. " to " .. global.zoom[player])
	end
end

function renderScreenshot(index)
	if (global.verbose) then
		log("rendering screenshot")
		log("index: " .. index)
		log("global.resX: " .. global.resX[index])
		log("global.resY: " .. global.resY[index])
		log("zoom: " .. global.zoom[index])
	end
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

-- function on_tick()
-- 	-- log("FAS: doing screenshot benchmarks weeeee")

-- 	if (isFirst) then
-- 		log("is first")
-- 		log(global.verbose)
	
-- 		log(global.zoom[1])
-- 		log(global.zoomLevel[1])
-- 		log(global.doScreenshot[1])
-- 		log(global.interval [1])
-- 		log(global.resX[1])
-- 		log(global.resY[1])
		
-- 		log(global.minX)
-- 		log(global.maxX)
-- 		log(global.minY)
-- 		log(global.maxY)
-- 		log(global.limitX)
-- 		log(global.limitY)

-- 		isFirst = false
-- 	end
-- 	-- game.take_screenshot{
-- 	-- 	resolution={1920, 1080},
-- 	-- 	position={0, 0},
-- 	-- 	zoom=1,		-- lower means further zoomed out
-- 	-- 	daytime=0,		-- bright daylight
-- 	-- 	water_tick=0,
-- 	-- 	path="./testscreenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
-- 	-- }
-- end

-- script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)
