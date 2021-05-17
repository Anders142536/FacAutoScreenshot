local shooter = {}

--[[ Zoom Evalutation ]]--
local function evaluateZoomForPlayer(index, surface)
	if(global.verbose) then
		log("ev zoom for player " .. index)
		log("resX: " .. global.auto[index].resX)
		log("resY: " .. global.auto[index].resY)
		log("global.tracker[" .. surface .."].limitX: " .. global.tracker[surface].limitX)
		log("global.tracker[" .. surface .. "].limitY: " .. global.tracker[surface].limitY)
		log("old zoom: " .. (global.auto[index].zoom or "nil"))
		log("zoomLevel: " .. (global.auto[index].zoomLevel or "nil"))
	end

	if not global.auto[index].zoom[surface] then global.auto[index].zoom[surface] = 1 end
	if not global.auto[index].zoomLevel[surface] then global.auto[index].zoomLevel[surface] = 1 end

	-- 7680					global.auto.resX
	-- -------- = 0,3		------------------ = zoom
	-- 800  32				leftRight resTiles
	local zoomX = global.auto[index].resX / (global.tracker[surface].limitX * 2 * 32)
	local zoomY = global.auto[index].resY / (global.tracker[surface].limitY * 2 * 32)

	local newZoom = zoomX
	if zoomX > zoomY then
		newZoom = zoomY
	end

	local oldZoom = global.auto[index].zoom[surface]
	while newZoom < global.auto[index].zoom[surface] and global.auto[index].zoomLevel[surface] < 32 do
		global.auto[index].zoomLevel[surface] = global.auto[index].zoomLevel[surface] + 1
		global.auto[index].zoom[surface] = 1 / global.auto[index].zoomLevel[surface]
		log("Adjusting zoom for player " .. index .. " on surface " .. surface .. " to " .. global.auto[index].zoom[surface] .. " and zoomlevel to " .. global.auto[index].zoomLevel[surface])
	end
	if oldZoom > global.auto[index].zoom[surface] then
		log("Adjusted zoom for player " .. index .. " from " .. oldZoom .. " to " .. global.auto[index].zoom[surface])
		if (global.auto[index].zoom[surface] == 32) then
			log("Player " .. index .. " reached maximum zoomlevel")
			game.print("FAS: Player " .. index .. " reached maximum zoom level of 32. No further zooming out possible. Entities exceeding the screenshot limits will not be shown on the screenshots!")
		end
	end
end

function shooter.evaluateZoomForPlayerAndAllSurfaces(index)
	for surface_index, surface in pairs(game.surfaces) do
		evaluateZoomForPlayer(index, surface_index)
	end
end

function shooter.evaluateZoomForAllPlayersAndAllSurfaces()
    log("ev zoom for all players")
	for _, player in pairs(game.connected_players) do
		if global.auto[player.index].doScreenshot then
			shooter.evaluateZoomForPlayerAndAllSurfaces(player.index)
		end
	end
end



--[[ Screenshotting ]]--
local function buildPath(folder, title)
	return "./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. folder .. title .. ".png"
end

function shooter.renderNextQueueStep()
	-- get next queue level
	-- do fragments, do single screenshots
	local step = queue.getNextStep()
end

function shooter.renderAutoSingleScreenshot(index, surface)
	if global.verbose then
		log("rendering auto screenshot as single screenshot")
		log("index:   " .. index)
		log("surface: " .. surface)
		log("res:     " .. global.auto[index].resX .. "x " .. global.auto[index].resY .. "y")
		log("zoom:    " .. global.auto[index].zoom[surface])
	end
	game.take_screenshot{
		resolution = {global.auto[index].resX, global.auto[index].resY},
		position = {0, 0},
		zoom = global.auto[index].zoom[surface],
		surface = surface,
		daytime = 0,
		water_tick = 0,
		by_player = index,
		path = buildPath("auto_singleTick/", "screenshot" .. game.tick)
	}
end

function shooter.renderAutoScreenshotFragment(index, fragment)
	local posX = fragment.startpos.x + fragment.stepsize.x * fragment.offset.x
	local posY = fragment.startpos.y + fragment.stepsize.y * fragment.offset.y

	if global.verbose then
		log("rendering next auto screenshot fragment")
		log("index:   " .. index)
		log("surface: " .. fragment.surface)
		log("res:     " .. fragment.res.x .. "x " .. fragment.res.y .. "y")
		log("zoom:    " .. fragment.zoom)
		log("pos:     " .. posX .. "x " .. posY .. "y")
	end

	game.take_screenshot{
		resolution = fragment.res,
		position = {posX, posY},
		zoom = fragment.zoom,
		surface = fragment.surface,
		by_player = index,
		water_tick = 0,
		daytime = 0,
		path = buildPath("auto_split/", fragment.title .. "_x" .. fragment.offset.x .. "_y" .. fragment.offset.y)
	}

	-- the first screenshot is the screenshot 0 0, therefore +1
	local amount = fragment.offset.y * fragment.numberOfTiles + fragment.offset.x + 1
	local total = fragment.numberOfTiles * fragment.numberOfTiles
	gui.setStatusValue(amount, total)

	fragment.offset.x = fragment.offset.x + 1
	if (fragment.offset.x >= fragment.numberOfTiles) then
		fragment.offset.x = 0
		fragment.offset.y = fragment.offset.y + 1
		if (fragment.offset.y >= fragment.numberOfTiles) then
			--all screenshots have been done, return to countdown
			-- table.remove(global.queue.nextScreenshot, 1)
			-- queue.refreshNextScreenshotTimestamp()
			queue.remove(fragment)
		end
	end
end

function shooter.renderAreaScreenshot(index)
	log("shooter.renderAreaScreenshot was triggered")
	if global.verbose then
		log("index:       " .. index)
		log("area.top:    " .. global.snip[index].area.top)
		log("area.bottom: " .. global.snip[index].area.bottom)
		log("area.left:   " .. global.snip[index].area.left)
		log("area.right:  " .. global.snip[index].area.right)
		log("zoomlevel:   " .. global.snip[index].zoomLevel)
	end

	local width = global.snip[index].area.right - global.snip[index].area.left
	local heigth = global.snip[index].area.bottom - global.snip[index].area.top

	local zoom = 1 / global.snip[index].zoomLevel
	local resX = math.floor(width * 32 * zoom)
	local resY = math.floor(heigth * 32 * zoom)
	local posX = global.snip[index].area.left + width / 2
	local posY = global.snip[index].area.top + heigth / 2

	game.take_screenshot{
		resolution = {resX, resY},
		position = {posX, posY},
		zoom = zoom,
		by_player = index,
		path = buildPath("area/", "screenshot" .. game.tick .. "_" .. resX .. "x" .. resY)
	}
end

return shooter

