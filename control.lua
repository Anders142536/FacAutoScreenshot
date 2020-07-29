script.on_init(function()
	log("on init")
	initialize()
end)

script.on_configuration_changed(function()
	log("on configuraiton changed")
	initialize()
end)

-- basically resets the state of the script
function initialize()
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
		global.limitX = 1
		global.limitY = 1
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
			global.limitY = top
		else
			global.limitY = bottom
		end
		
		if (left > right) then
			global.limitX = left
		else
			global.limitX = right
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
	log("runtimesettings for player " .. event.player_index .. " changed")
	loadSettings(event.player_index)
end

function loadSettings(player_index)
	game.print("loading settings for player " .. player_index)
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
	if (global.doScreenshot[player_index]) then
		game.print("FAS: Player " .. player_index .. " does screenshots with resolution " .. 
		global.resX[player_index] .. "x" .. global.resY[player_index] .. 
		" every " .. (global.interval[player_index] / 3600) .. " minutes")
		evaluateZoomForPlayer(player_index)
	else
		game.print("FAS: Player " .. player_index .. " does no screenshots")
	end
end

function on_built_entity(event)
	-- log("on built entity")
	local pos = event.created_entity.position
	
	-- log("pos: " .. pos.x .. "x" .. pos.y)
	if breaksCurrentLimits(pos) then
		-- log("breaks current limits")
		evaluateMinMaxFromPosition(pos)
	end
end

function breaksCurrentLimits(pos)
	-- log("breakscurrentLimits: pos: " .. pos.x .. "x" .. pos.y)
	return (pos.x < global.minX or
	pos.x > global.maxX or
	pos.y < global.minY or
	pos.y > global.maxY)
end

function evaluateMinMaxFromPosition(pos)
	-- log("FAS: Evaluate limit from position: pos: " .. pos.x .. "x" .. pos.y)
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
	
	global.minMaxChanged = true
end

-- 3600
script.on_nth_tick(3600, function(event)
	-- log("on nth tick")
	-- if something was built in the last minute that should cause a recalc of all zoom levels
	if (global.minMaxChanged) then
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
		if global.doScreenshot[player.index] and (event.tick % global.interval[player.index] == 0) then
			renderScreenshot(player.index)
		end
	end
end)

function evaluateZoomForAllPlayers()
log("ev zoom for all players")
for _, player in pairs(game.connected_players) do
	-- game.print("ding")
	if global.doScreenshot[player.index] then
		-- game.print("dong")
		evaluateZoomForPlayer(player.index)
	end
end
end

function evaluateZoomForPlayer(player)
-- log("ev zoom for player " .. player)
-- 7680					global.resX
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

local oldZoom = global.zoom[player]
while newZoom < global.zoom[player] do
	global.zoomLevel[player] = global.zoomLevel[player] + 1
	global.zoom[player] = 1 / global.zoomLevel[player]
end
if oldZoom > global.zoom[player] then
	game.print("FAS: Adjusted zoom for player " .. player .. " from " .. oldZoom .. " to " .. global.zoom[player])
end
end

function renderScreenshot(index)
	-- log("index: " .. index)
	-- log("global.resX: " .. global.resX[index])
	-- log("global.resY: " .. global.resY[index])
	-- log("zoom: " .. global.zoom[index])
	game.take_screenshot{
		resolution={global.resX[index], global.resY[index]},
		position={0, 0},
		zoom=global.zoom[index],		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player=index,
		path="./testscreenshots/" .. game.default_map_gen_settings.seed .. "/" .. "screenshot" .. game.tick .. ".png"
	}
end

script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)
