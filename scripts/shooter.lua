local shooter = {}

function shooter.evaluateZoomForAllPlayers()
    log("ev zoom for all players")
	for _, player in pairs(game.connected_players) do
		if global.auto[player.index].doScreenshot then
			shooter.evaluateZoomForPlayer(player.index)
		end
	end
end

function shooter.evaluateZoomForPlayer(index)
	if(global.verbose) then
		log("ev zoom for player " .. index)
		log("resX: " .. global.auto[index].resX)
		log("resY: " .. global.auto[index].resY)
		log("global.tracker.limitX: " .. global.tracker.limitX)
		log("global.tracker.limitY: " .. global.tracker.limitY)
		log("old zoom: " .. (global.auto[index].zoom or "nil"))
		log("zoomLevel: " .. (global.auto[index].zoomLevel or "nil"))
	end

	if not global.auto[index].zoom then global.auto[index].zoom = 1 end
	if not global.auto[index].zoomLevel then global.auto[index].zoomLevel = 1 end

	-- 7680					global.auto.resX
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	local zoomX = global.auto[index].resX / (global.tracker.limitX * 2 * 32)
	local zoomY = global.auto[index].resY / (global.tracker.limitY * 2 * 32)

	local newZoom = zoomX
	if zoomX > zoomY then
		newZoom = zoomY
	end

	local oldZoom = global.auto[index].zoom
	while newZoom < global.auto[index].zoom and global.auto[index].zoomLevel < 32 do
		global.auto[index].zoomLevel = global.auto[index].zoomLevel + 1
		global.auto[index].zoom = 1 / global.auto[index].zoomLevel
		log("Adjusting zoom for player " .. index .. " to " .. global.auto[index].zoom .. " and zoomlevel to " .. global.auto[index].zoomLevel)
	end
	if oldZoom > global.auto[index].zoom then
		log("Adjusted zoom for player " .. index .. " from " .. oldZoom .. " to " .. global.auto[index].zoom)
		if (global.auto[index].zoom == 32) then
			log("Player " .. index .. " reached maximum zoomlevel")
			game.print("FAS: Player " .. index .. " reached maximum zoom level of 32. No further zooming out possible. Entities exceeding the screenshot limits will not be shown on the screenshots!")
		end
	end
end

local function getDivisor(index)
	-- rough expected result:
	--  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16
	--  1,  2,  2,  2,  4,  4,  4,  4,  8,  8,  8,  8,  8,  8,  8,  8, 16 from there

	local zoomLevel = global.auto[index].zoomLevel
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
	
	divisor = divisor * (math.sqrt(global.auto[index].splittingFactor))

	if (global.verbose) then
		log("returned divisor " .. divisor .. " from input " .. zoomLevel)
	end

	return divisor
end

function shooter.registerPlayerToScreenshotlist(index)
	log("registering player to screenshot list")

	local numberOfTiles = getDivisor(index)
	local resX = global.auto[index].resX
	local resY = global.auto[index].resY
	local zoom = global.auto[index].zoom

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
	temp["startpos"] = {x = -rightborder + posXStepsize / 2, y = -bottomborder + posYStepsize / 2}
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

	table.insert(global.schedule.nextScreenshot, temp)
end

function shooter.refreshNextScreenshotTimestamp()
	local closest
	for _, player in pairs(game.connected_players) do
		if global.auto[player.index].doScreenshot then
			local times = math.floor(game.tick / global.auto[player.index].interval)
			local next = global.auto[player.index].interval * (times + 1)
			if closest == nil or next < closest then
				closest = next
			end
		end
	end

	if closest then
		global.nextScreenshotTimestamp = closest
	else
		global.nextScreenshotTimestamp = nil
	end
end

local function renderScreenshot(index, resolution, position, zoom, folder, title)
	if global.verbose then
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

function shooter.hasNextScreenshot()
	return global.schedule.nextScreenshot[1] ~= nil
end

function shooter.renderSingleScreenshot(index)

	renderScreenshot(index, {global.auto[index].resX, global.auto[index].resY}, {0, 0}, global.auto[index].zoom, "", "screenshot" .. game.tick) -- set params
			
end

function shooter.renderNextScreenshot()
	local n = global.schedule.nextScreenshot[1]
	local posX = n.startpos.x + n.stepsize.x * n.offset.x
	local posY = n.startpos.y + n.stepsize.y * n.offset.y

	renderScreenshot(n.index, {n.res.x, n.res.y}, {posX, posY}, n.zoom, "split/", n.title .. "_x" .. n.offset.x .. "_y" .. n.offset.y)

	-- the first screenshot is the screenshot 0 0, therefore +1
	local amount = n.offset.y * n.numberOfTiles + n.offset.x + 1
	local total = n.numberOfTiles * n.numberOfTiles
	gui.setStatusValue(amount, total)

	n.offset.x = n.offset.x + 1
	if (n.offset.x >= n.numberOfTiles) then
		n.offset.x = 0
		n.offset.y = n.offset.y + 1
		if (n.offset.y >= n.numberOfTiles) then
			--all screenshots have been done, return to countdown
			log("end of doing screenshots")
			table.remove(global.schedule.nextScreenshot, 1)
			shooter.refreshNextScreenshotTimestamp()
		end
	end
end

function shooter.renderAreaScreenshot(index, area, zoomLevel)
	log("shooter.renderAreaScreenshot was triggered")
	if global.verbose then log("index: " .. index .. " area.top: " .. area.top .. " area.bottom: " .. area.bottom .. " area.left: " .. area.left .. " area.right: " .. area.right .. " zoomlevel: " .. zoomLevel) end

	local width = area.right - area.left
	local heigth = area.bottom - area.top

	local zoom = 1 / zoomLevel
	local resX = math.floor(width * 32 * zoom)
	local resY = math.floor(heigth * 32 * zoom)
	local posX = area.left + width / 2
	local posY = area.top + heigth / 2

	renderScreenshot(index, {resX, resY}, {posX, posY}, zoom, "high_res_screenshots/", "screenshot" .. game.tick .. "_" .. resX .. "x" .. resY)
end

return shooter

