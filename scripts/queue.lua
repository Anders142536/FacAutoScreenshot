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

	if (global.verbose) then
		log("returned divisor " .. divisor .. " from input " .. zoomLevel)
	end

	return divisor
end

local function registerPlayerSingleScreenshots(index)
	for _, surface in pairs(game.surfaces) do
		global.queue[index][surface.index] = {
			isSingleScreenshot = true,
			surface = surface.index,
			resX = global.auto[index].resX,
			resY = global.auto[index].resY,
			zoom = global.auto[index].zoom[index]
		}
	end
end

local function registerPlayerFragmentedScreenshots(index)
	for _, surface in pairs(game.surfaces) do
		local numberOfTiles = getDivisor(index, surface.index)
		local resX = global.auto[index].resX
		local resY = global.auto[index].resY
		local zoom = global.auto[index].zoom[surface.index]

		-- like calculating zoom, but reverse
		-- cannot take limits from global, as we want the border of the screenshot, not the base
		local rightborder = resX / (zoom * 2 * 32)
		local bottomborder = resY / (zoom * 2 * 32)

		local posXStepsize = rightborder * 2 / numberOfTiles
		local posYStepsize = bottomborder * 2 / numberOfTiles
		
		local fragment = {
			isFragmentedScreenshot = true,
			surface = surface.index,
			res = {x = resX / numberOfTiles, y = resY / numberOfTiles},
			numberOfTiles = numberOfTiles,
			offset = {x=0, y=0},
			startpos = {x = -rightborder + posXStepsize / 2, y = -bottomborder + posYStepsize / 2},
			stepsize = {x = posXStepsize, y = posYStepsize},
			zoom = zoom,
			title = "screenshot" .. game.tick
		}

		if (global.verbose) then
			log("surface:    " .. fragment["surface"])
			log("res:        " .. fragment["res"].x .. "x" .. fragment["res"].y)
			log("numOfTiles: " .. fragment["numberOfTiles"])
			log("offset:     " .. fragment["offset"].x .. " " .. fragment["offset"].y)
			log("startpos:   " .. fragment["startpos"].x .. " " .. fragment["startpos"].y)
			log("stepsize:   " .. fragment["stepsize"].x .. " " .. fragment["stepsize"].y)
			log("zoom:       " .. fragment["zoom"])
			log("title:      " .. fragment["title"])
		end

		global.queue[index][surface.index] = fragment
	end
end

function q.registerPlayerToQueue(index)
	log("registering player to screenshot list")
	if queue.hasAnyEntries() then
		log("there was still a screenshot queued when trying to register a player to queue")
		game.print("FAS: The script is not yet done with the screenshots but tried to register new ones. This screenshot interval will be skipped. Please lower the \"increased splitting\" setting if it is set or make the intervals in which you do screenshots longer. Changing the resolution will not prevent this from happening.")
		return
	end
	if global.auto[index].singleScreenshot then
		registerPlayerSingleScreenshots(index)
	else
		registerPlayerFragmentedScreenshots(index)
	end

	global.debugding = true
end

-- CHANGE THIS
function q.refreshNextScreenshotTimestamp()
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
		global.queue.nextScreenshotTimestamp = closest
	else
		global.queue.nextScreenshotTimestamp = nil
	end
end

-- CHECK IF THIS WORKS
function q.remove(index, surface)
	global.queue[index][surface] = nil
end

local function getNextEntry(index)
	for _, surface in pairs(game.surfaces) do
		local entry = global.queue[index][surface.index]
		if entry then
			return entry
		end
	end
	if global.verbose then log("there was no entry for player " .. index) end
	return nil
end

-- CHECK IF THIS WORKS
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

-- CHECK IF THIS WORKS
function q.hasAnyEntries()
	if global.verbose then log("checking for queue entries") end
	for _, player in pairs(game.connected_players) do
		if getNextEntry(player.index) then
			return true
		end
	end
	return false
end

return q