FASgui = require("FASgui")

script.on_init(function()
	log("on init")
	initialize()
end)

script.on_configuration_changed(function()
	log("on configuraiton changed")
	initialize()
end)

function initialize()
	log("initialize")

	-- runtime global settings
	global.verbose = settings.global["FAS-enable-debug"].value
	global.increasedSplitting = settings.global["FAS-increased-splitting"].value
	
	-- runtime user settings
	global.doScreenshot = {}
	global.interval = {}
	global.singleScreenshot = {}
	global.resX = {}
	global.resY = {}

	-- calculated values
	global.zoom = {}
	global.zoomLevel = {}
	global.nextScreenshot = {}
	global.minX = 1
	global.maxX = 1
	global.minY = 1
	global.maxY = 1
	global.limitX = 1
	global.limitY = 1

	evaluateLimitsFromWholeBase()

	-- this should be unnecessary, but i feel there are some things missing if not present
	for _, player in pairs(game.connected_players) do
		log("found player already connected: " .. player.name)
		FASgui.initialize(player)
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
		local top = math.abs(tchunk.area.left_top.y)
		local right = math.abs(rchunk.area.right_bottom.x)
		local bottom = math.abs(bchunk.area.right_bottom.y)
		local left =  math.abs(lchunk.area.left_top.x)
		
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

function evaluateLimitsFromMinMax()
	if (global.verbose) then
		log("evaluate limits from min max")
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
	FASgui.initialize(game.get_player(event.player_index))
	loadSettings(event.player_index)
end

function on_runtime_mod_setting_changed(event)
	if (event.setting_type == "runtime-global") then
		log("global settings changed")
		game.print("FAS: Global settings changed")
		global.verbose = settings.global["FAS-enable-debug"].value
		global.increasedSplitting = settings.global["FAS-increased-splitting"].value
	else
		log("runtimesettings for player " .. event.player_index .. " changed")
		loadSettings(event.player_index)
	end
end

function loadSettings(player_index)
	log("loading settings for player " .. player_index)

	local player = game.get_player(player_index)
	global.doScreenshot[player_index] = settings.get_player_settings(player)["FAS-do-screenshot"].value
	global.interval[player_index] = settings.get_player_settings(player)["FAS-Screenshot-interval"].value * 3600 -- 3600
	global.singleScreenshot[player_index] = settings.get_player_settings(player)["FAS-single-screenshot"].value

	local resolution = settings.get_player_settings(player)["FAS-Resolution"].value
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
		evaluateLimitsFromMinMax()
		evaluateZoomForAllPlayers()
		global.minMaxChanged = false
	end

	for _, player in pairs(game.connected_players) do
		if (global.verbose) then
			log("player " .. player.name .. " with index " .. player.index .. " found")
			log(global.doScreenshot[player.index])
			log(global.interval[player.index])
			log(global.singleScreenshot[player.index])
			log(game.tick)
		end
		if global.doScreenshot[player.index] and (event.tick % global.interval[player.index] == 0) then
			local n = global.nextScreenshot[1]
			if (n ~= nil) then
				log("there was still a screenshot queued on nth tick event trigger")
				game.print("FAS: The script is not yet done with the screenshots but tried to register new ones. This screenshot interval will be skipped. Please lower the \"increased splitting\" setting if it is set, make less players do screenshots or make the intervals in which you do screenshots longer. Changing the resolution will not prevent this from happening.")
				return
			end
			if (global.singleScreenshot[player.index]) then
				renderScreenshot(player.index, {global.resX[player.index], global.resY[player.index]}, {0, 0}, global.zoom[player.index], "", "screenshot" .. game.tick) -- set params
			else
				registerPlayerToScreenshotlist(player.index)
			end
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
	while newZoom < global.zoom[player] and global.zoomLevel[player] < 32 do
		global.zoomLevel[player] = global.zoomLevel[player] + 1
		global.zoom[player] = 1 / global.zoomLevel[player]
		log("Adjusting zoom for player " .. player .. " to " .. global.zoom[player] .. " and zoomlevel to " .. global.zoomLevel[player])
	end
	if oldZoom > global.zoom[player] then
		log("Adjusted zoom for player " .. player .. " from " .. oldZoom .. " to " .. global.zoom[player])
		game.print("FAS: Adjusted zoom for player " .. player .. " from " .. oldZoom .. " to " .. global.zoom[player] .. " (zoomlevel: " .. global.zoomLevel[player] .. ")")
		if (global.zoom[player] == 32) then
			log("Player " .. player .. " reached maximum zoomlevel")
			game.print("FAS: Player " .. player .. " reached maximum zoom level of 32. No further zooming out possible. Entities exceeding the screenshot limits will not be shown on the screenshots!")
		end
	end
end

function registerPlayerToScreenshotlist(index)
	log("registering player to screenshot list")

	local numberOfTiles = getDivisor(global.zoomLevel[index])
	local resX = global.resX[index]
	local resY = global.resY[index]
	local zoom = global.zoom[index]

	-- like calculating zoom, but reverse
	-- cannot take limits from global, as we want the border of the screenshot, not the base
	local rightborder = resX / (zoom * 2 * 32)
	local bottomborder = resY / (zoom * 2 * 32)

	local posXStepsize = rightborder * 2 / numberOfTiles
	local posYStepsize = bottomborder * 2 / numberOfTiles
	
	local temp = {}
	temp["index"] = index
	temp["res"] = {x = resX / numberOfTiles, y = resY / numberOfTiles}
	temp["numberOfTiles"] = numberOfTiles
	temp["offset"] = {x=0, y=0}
	temp["startpos"] = {x = -rightborder + posXStepsize / 2, y = -bottomborder + posYStepsize}
	temp["stepsize"] = {x = posXStepsize, y = posYStepsize}
	temp["zoom"] = zoom
	temp["title"] = "screenshot" .. game.tick

	if (global.verbose) then
		log("index:      " .. temp["index"])
		log("res:        " .. temp["res"].x .. "x" .. temp["res"].y)
		log("numOfTiles: " .. temp["numberOfTiles"])
		log("offset:     " .. temp["offset"].x .. " " .. temp["offset"].y)
		log("startpos:   " .. temp["startpos"].x .. " " .. temp["startpos"].y)
		log("stepsize:   " .. temp["stepsize"].x .. " " .. temp["stepsize"].y)
		log("zoom:       " .. temp["zoom"])
		log("title:      " .. temp["title"])
	end

	table.insert(global.nextScreenshot, temp)
end

function getDivisor(zoomLevel)
	-- rough expected result:
	--  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16
	--  1,  2,  2,  2,  4,  4,  4,  4,  8,  8,  8,  8,  8,  8,  8,  8, 16 from there

	local divisor
	if zoomLevel == 1 then
		divisor = 1
	elseif zoomLevel < 5 then
		divisor = 2
	elseif zoomLevel < 9 then
		divisor = 4
	elseif zoomLevel < 17 then
		divisor = 8
	else
		divisor = 16
	end
	
	divisor = divisor * (math.sqrt(global.increasedSplitting))

	if (global.verbose) then
		log("returned divisor " .. divisor .. " from input " .. zoomLevel)
	end

	return divisor
end

function on_tick()
	-- global.test = {}
	-- for i = 1,64 do
	-- 	table.insert(global.test, {i, getDivisor(i)})
	-- end

	-- log("testing done")

	local n = global.nextScreenshot[1]
	if (n ~= nil) then
		local posX = n.startpos.x + n.stepsize.x * n.offset.x
		local posY = n.startpos.y + n.stepsize.y * n.offset.y

		renderScreenshot(n.index, {n.res.x, n.res.y}, {posX, posY}, n.zoom, "split/", n.title .. "_x" .. n.offset.x .. "_y" .. n.offset.y)

		local amount = n.offset.y * n.numberOfTiles + n.offset.x
		local total = n.numberOfTiles * n.numberOfTiles
		FASgui.setStatusValue(amount, total)

		n.offset.x = n.offset.x + 1
		if (n.offset.x >= n.numberOfTiles) then
			n.offset.x = 0
			n.offset.y = n.offset.y + 1
			if (n.offset.y >= n.numberOfTiles) then
				table.remove(global.nextScreenshot, 1)
			end
		end
	else
		if game.tick % 60  == 0 then
			-- refresh countdown in FASgui
			FASgui.setStatusCountdown(game.tick / 60)
		end
	end
end

function renderScreenshot(index, resolution, position, zoom, folder, title)
	if (global.verbose) then
		log("rendering screenshot")
		log("resolution: " .. resolution[1] .. " " .. resolution[2])
		log("position:   " .. position[1] .. " " .. position[2])
		log("zoom:       " .. zoom)
		log("title:      " .. title)
	end
	game.take_screenshot{
		resolution=resolution,
		position=position,
		zoom=zoom,		-- lower means further zoomed out
		daytime=0,		-- bright daylight
		water_tick=0,
		by_player=index,
		path="./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. folder .. title .. ".png"
	}
end

script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)

-- GUI
script.on_event(defines.events.on_gui_click, FASgui.on_gui_event)
script.on_event(defines.events.on_gui_value_changed, FASgui.on_gui_event)
-- script.on_event(defines.events.on_gui_text_changed, FASgui.on_gui_event)