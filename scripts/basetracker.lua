local tracker = {}

local function hasEntities(chunk, surface)
	local count = game.surfaces[surface].count_entities_filtered{
		area=chunk.area,
		force="player",
		limit=1
	}
	return (count ~= 0)
end

function tracker.evaluateLimitsOfSurface(surface)
	log("Evaluating whole surface: " .. surface)
	
	local surface = game.surfaces[surface];
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
		global.tracker[surface].limitX = 64
		global.tracker[surface].limitY = 64
		global.tracker[surface].minX = -64
		global.tracker[surface].maxX = 64
		global.tracker[surface].minY = -64
		global.tracker[surface].maxY = 64
	else
		global.tracker[surface].minX = lchunk.area.left_top.x
		global.tracker[surface].maxX = rchunk.area.right_bottom.x
		global.tracker[surface].minY = tchunk.area.left_top.y
		global.tracker[surface].maxY = bchunk.area.right_bottom.y

		if global.verbose then
			log("global.tracker[" .. surface .. "].minX: " .. global.tracker[surface].minX)
			log("global.tracker[" .. surface .. "].maxX: " .. global.tracker[surface].maxX)
			log("global.tracker[" .. surface .. "].minY: " .. global.tracker[surface].minY)
			log("global.tracker[" .. surface .. "].maxY: " .. global.tracker[surface].maxY)
		end

		local top = math.abs(tchunk.area.left_top.x)
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
			global.tracker[surface].limitY = top
		else
			global.tracker[surface].limitY = bottom
		end
		
		if (left > right) then
			global.tracker[surface].limitX = left
		else
			global.tracker[surface].limitX = right
		end

		if (global.verbose) then
			log("limitX: " .. global.tracker[surface].limitX)
			log("limitY: " .. global.tracker[surface].limitY)
		end
	end
end

local function evaluateLimitsFromMinMax(surface)
	if (global.verbose) then
		log("evaluate limits from min max")
	end

	if math.abs(global.tracker[surface].minX) > global.tracker[surface].maxX then
		global.tracker[surface].limitX =  math.abs(global.trackerv.minX)
	else
		global.tracker[surface].limitX = global.tracker[surface].maxX
	end
	
	if math.abs(global.tracker[surface].minY) > global.tracker[surface].maxY then
		global.tracker[surface].limitY = math.abs(global.tracker[surface].minY)
	else
		global.tracker[surface].limitY = global.tracker[surface].maxY
	end
end

function tracker.checkForMinMaxChange(surface)
	if global.tracker[surface].minMaxChanged then
		evaluateLimitsFromMinMax(surface)
		shooter.evaluateZoomForAllPlayersAndAllSurfaces(surface)
		global.tracker[surface].minMaxChanged = false
	end
end

function tracker.evaluateMinMaxFromPosition(pos, surface)
	if (global.verbose) then
		log("Evaluate min max on surface " .. surface .. " from position: " .. pos.x .. "x" .. pos.y)
	end
	if pos.x < global.tracker[surface].minX then
		global.tracker[surface].minX = pos.x
	elseif pos.x > global.tracker[surface].maxX then
		global.tracker[surface].maxX = pos.x
	end
	
	if pos.y < global.tracker[surface].minY then
		global.tracker[surface].minY = pos.y
	elseif pos.y > global.tracker[surface].maxY then
		global.tracker[surface].maxY = pos.y
	end

	if (global.verbose) then
		log("global.tracker[" .. surface .. "].minX = " .. global.tracker[surface].minX)
		log("global.tracker[" .. surface .. "].maxX = " .. global.tracker[surface].maxX)
		log("global.tracker[" .. surface .. "].minY = " .. global.tracker[surface].minY)
		log("global.tracker[" .. surface .. "].maxY = " .. global.tracker[surface].maxY)
	end
	
	global.tracker[surface].minMaxChanged = true
end

function tracker.breaksCurrentLimits(pos, surface)
	if (global.verbose) then
		log("breakscurrentLimits on surface " .. surface .. ": pos: " .. pos.x .. "x" .. pos.y)
	end
	return (pos.x < global.tracker[surface].minX or
	pos.x > global.tracker[surface].maxX or
	pos.y < global.tracker[surface].minY or
	pos.y > global.tracker[surface].maxY)
end

return tracker