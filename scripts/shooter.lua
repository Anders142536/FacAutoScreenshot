local shooter = {}

--[[ Zoom Evalutation ]]--
local function evaluateZoomForPlayer(index, surface)
		l.debug("ev zoom for player " .. index)
		l.debug("resX: " .. global.auto[index].resX)
		l.debug("resY: " .. global.auto[index].resY)
		l.debug("global.tracker[" .. surface .."].limitX: " .. global.tracker[surface].limitX)
		l.debug("global.tracker[" .. surface .. "].limitY: " .. global.tracker[surface].limitY)
		l.debug("old zoom: " .. (global.auto[index].zoom[surface] or "nil"))
		l.debug("zoomLevel: " .. (global.auto[index].zoomLevel[surface] or "nil"))

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
		l.info("Adjusting zoom for player " .. index .. " on surface " .. surface .. " to " .. global.auto[index].zoom[surface] .. " and zoomlevel to " .. global.auto[index].zoomLevel[surface])
	end
	if oldZoom > global.auto[index].zoom[surface] then
		l.info("Adjusted zoom for player " .. index .. " from " .. oldZoom .. " to " .. global.auto[index].zoom[surface])
		if (global.auto[index].zoom[surface] == 32) then
			l.warn("Player " .. index .. " reached maximum zoomlevel")
			game.print("FAS: Player " .. index .. " reached maximum zoom level of 32. No further zooming out possible. Entities exceeding the screenshot limits will not be shown on the screenshots!")
		end
	end
end

function shooter.evaluateZoomForPlayerAndAllSurfaces(index)
	for _, surface in pairs(game.surfaces) do
		evaluateZoomForPlayer(index, surface.name)
	end
end

function shooter.evaluateZoomForAllPlayersAndAllSurfaces()
    l.info("ev zoom for all players")
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


local function renderAutoSingleScreenshot(index, specs)
	l.debug("rendering auto screenshot as single screenshot")
	l.debug("index:   " .. index)
	l.debug("surface: " .. specs.surface)
	l.debug("res:     " .. specs.resX .. "x " .. specs.resY .. "y")
	l.debug("zoom:    " .. specs.zoom)
	game.take_screenshot{
		resolution = {specs.resX, specs.resY},
		position = {0, 0},
		zoom = specs.zoom,
		surface = specs.surface,
		daytime = 0,
		water_tick = 0,
		by_player = index,
		path = buildPath("auto_singleTick_" .. specs.surface ..  "/", "screenshot" .. game.tick)
	}
	queue.remove(index, specs.surface)
end

local function renderAutoScreenshotFragment(index, fragment)
	local posX = fragment.startpos.x + fragment.stepsize.x * fragment.offset.x
	local posY = fragment.startpos.y + fragment.stepsize.y * fragment.offset.y

	l.debug("rendering next auto screenshot fragment")
	l.debug("index:   " .. index)
	l.debug("surface: " .. fragment.surface)
	l.debug("res:     " .. fragment.res.x .. "x " .. fragment.res.y .. "y")
	l.debug("zoom:    " .. fragment.zoom)
	l.debug("pos:     " .. posX .. "x " .. posY .. "y")

	game.take_screenshot{
		resolution = fragment.res,
		position = {posX, posY},
		zoom = fragment.zoom,
		surface = fragment.surface,
		by_player = index,
		water_tick = 0,
		daytime = 0,
		path = buildPath("auto_split" .. fragment.surface .. "/", fragment.title .. "_x" .. fragment.offset.x .. "_y" .. fragment.offset.y)
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
			queue.remove(index, fragment.surface)
		end
	end
end

function shooter.renderNextQueueStep()
	for _, job in pairs(queue.getNextStep()) do
		if job.specs.isSingleScreenshot then
			renderAutoSingleScreenshot(job.index, job.specs)
		elseif job.specs.isFragmentedScreenshot then
			renderAutoScreenshotFragment(job.index, job.specs)
		end
	end
end

function shooter.renderAreaScreenshot(index)
	l.info("shooter.renderAreaScreenshot was triggered")
	l.debug("index:       " .. index)
	l.debug("area.top:    " .. global.snip[index].area.top)
	l.debug("area.bottom: " .. global.snip[index].area.bottom)
	l.debug("area.left:   " .. global.snip[index].area.left)
	l.debug("area.right:  " .. global.snip[index].area.right)
	l.debug("zoomlevel:   " .. global.snip[index].zoomLevel)

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

