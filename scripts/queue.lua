local l = require("logger")
local shooter = require("shooter")

local q = {}

--[[ Queue explanation
	The queue has one entry for every player

	Every player queue has an entry for every surface, indexed with surface
	index, with lower indexi being next
]]--

function q.initialize(index)
	global.queue[index] = {}
end

local function getDivisor(index, surface)
	-- rough expected result:
	--  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16
	--  1,  2,  2,  2,  4,  4,  4,  4,  8,  8,  8,  8,  8,  8,  8,  8, 16 from there

	local zoomLevel = global.auto[index].zoomLevel[surface]
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

	if l.doD then log(l.debug("returned divisor " .. divisor .. " from input " .. zoomLevel)) end

	return divisor
end

local function registerPlayerSingleScreenshots(index)
	for _, surface in pairs(game.surfaces) do
		if global.auto[index].doSurface[surface.name] then
			global.queue[index][surface.name] = {
				isSingleScreenshot = true,
				surface = surface.name,
				resX = global.auto[index].resX,
				resY = global.auto[index].resY,
				zoom = global.auto[index].zoom[surface.name]
			}
		end
	end
end

local function registerPlayerFragmentedScreenshots(index)
	for _, surface in pairs(game.surfaces) do
		if global.auto[index].doSurface[surface.name] then
			local numberOfTiles = getDivisor(index, surface.name)
			local resX = global.auto[index].resX
			local resY = global.auto[index].resY
			local zoom = global.auto[index].zoom[surface.name]

			-- like calculating zoom, but reverse
			-- cannot take limits from global, as we want the border of the screenshot, not the base
			local rightborder = resX / (zoom * 2 * 32)
			local bottomborder = resY / (zoom * 2 * 32)

			local posXStepsize = rightborder * 2 / numberOfTiles
			local posYStepsize = bottomborder * 2 / numberOfTiles
		
			local fragment = {
				isFragmentedScreenshot = true,
				surface = surface.name,
				res = {x = resX / numberOfTiles, y = resY / numberOfTiles},
				numberOfTiles = numberOfTiles,
				offset = {x=0, y=0},
				startpos = {x = -rightborder + posXStepsize / 2, y = -bottomborder + posYStepsize / 2},
				stepsize = {x = posXStepsize, y = posYStepsize},
				zoom = zoom,
				title = "screenshot" .. game.tick
			}

			if l.doD then log(l.debug("surface:    " .. fragment["surface"])) end
			if l.doD then log(l.debug("res:        " .. fragment["res"].x .. "x" .. fragment["res"].y)) end
			if l.doD then log(l.debug("numOfTiles: " .. fragment["numberOfTiles"])) end
			if l.doD then log(l.debug("offset:     " .. fragment["offset"].x .. " " .. fragment["offset"].y)) end
			if l.doD then log(l.debug("startpos:   " .. fragment["startpos"].x .. " " .. fragment["startpos"].y)) end
			if l.doD then log(l.debug("stepsize:   " .. fragment["stepsize"].x .. " " .. fragment["stepsize"].y)) end
			if l.doD then log(l.debug("zoom:       " .. fragment["zoom"])) end
			if l.doD then log(l.debug("title:      " .. fragment["title"])) end

			global.queue[index][surface.name] = fragment
		end
	end
end

local function getNextEntry(index)
	-- apparently this can happen if there was a player connected on save
	-- but is no longer connected on load, whilst the configuration changed
	if not global.queue[index] then return nil end

	for _, surface in pairs(game.surfaces) do
		local entry = global.queue[index][surface.name]
		if entry then
			return entry
		end
	end
	-- if l.doD then log(l.debug("there was no entry for player " .. index)) end
	return nil
end

local function hasEntriesForPlayer(index)
	return getNextEntry(index) ~= nil
end

function q.registerPlayerToQueue(index)
	log(l.info("registering player to screenshot list"))
	if not q.hasAnyEntries() then
		for _, player in pairs(game.connected_players) do
			global.flowButton[player.index].sprite = "FAS-recording-icon"
		end
	else
		if hasEntriesForPlayer(index) then
			log(l.warn("there was still a screenshot queued when trying to register a player to queue"))
			game.print("FAS: The script is not yet done with the screenshots for player " .. game.get_player(index).name .. " but tried to register new ones. This screenshot interval will be skipped. Please lower the \"increased splitting\" setting if it is set or make the intervals in which screenshots are done longer. Changing the resolution will not prevent this from happening.")
			return
		end
	end

	if global.auto[index].singleScreenshot then
		registerPlayerSingleScreenshots(index)
	else
		registerPlayerFragmentedScreenshots(index)
	end

end

function q.doesAutoScreenshot(index)
	for _, surface in pairs(game.surfaces) do
		if global.auto[index].doSurface[surface.name] then
			return true
		end
	end
	return false
end

function q.refreshNextScreenshotTimestamp()
	local closest
	for _, player in pairs(game.connected_players) do
		if q.doesAutoScreenshot(player.index) then
			local times = math.floor(game.tick / global.auto[player.index].interval)
			local next = global.auto[player.index].interval * (times + 1)
			if closest == nil or next < closest then
				closest = next
			end
		end
	end

	if closest then
		global.queue.nextScreenshotTimestamp = closest
	else
		global.queue.nextScreenshotTimestamp = nil
	end
end

function q.remove(index, surface)
	global.queue[index][surface] = nil
	if not q.hasAnyEntries() then
		for _, player in pairs(game.connected_players) do
			global.flowButton[player.index].sprite = "FAS-icon"
		end
	end
end


function q.getNextStep()
	local step = {}
	for _, player in pairs(game.connected_players) do
		local entry = getNextEntry(player.index)
		if entry then
			step[player.index] = {
				index = player.index,
				specs = entry
			}
		end
	end
	return step
end

function q.hasAnyEntries()
	for _, player in pairs(game.connected_players) do
		if getNextEntry(player.index) then
			return true
		end
	end
	return false
end

function q.executeNextStep()
	local didFragment = false
	for _, job in pairs(q.getNextStep()) do
		if job.specs.isSingleScreenshot then
			shooter.renderAutoSingleScreenshot(job.index, job.specs)

			q.remove(job.index, job.specs.surface)
		elseif job.specs.isFragmentedScreenshot then
			didFragment = true
			shooter.renderAutoScreenshotFragment(job.index, job.specs)
			job.specs.offset.x = job.specs.offset.x + 1
			if (job.specs.offset.x >= job.specs.numberOfTiles) then
				job.specs.offset.x = 0
				job.specs.offset.y = job.specs.offset.y + 1
				if (job.specs.offset.y >= job.specs.numberOfTiles) then
					--all screenshots have been done, return to countdown
					-- table.remove(global.queue.nextScreenshot, 1)
					-- queue.refreshNextScreenshotTimestamp()
					q.remove(job.index, job.specs.surface)
				end
			end
		end
	end
	return didFragment
end

return q