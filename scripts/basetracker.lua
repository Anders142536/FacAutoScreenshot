local tracker = {}

tracker.limitX = 1
tracker.limitY = 1
tracker.minX = 1
tracker.minY = 1
tracker.maxX = 1
tracker.maxY = 1

local function hasEntities(chunk)
	local count = game.surfaces[1].count_entities_filtered{
		area=chunk.area,
		force="player",
		limit=1
	}
	return (count ~= 0)
end

function tracker.evaluateLimitsFromWholeBase()
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
		tracker.limitX = 1
		tracker.limitY = 1
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
			tracker.limitY = top
		else
			tracker.limitY = bottom
		end
		
		if (left > right) then
			tracker.limitX = left
		else
			tracker.limitX = right
		end

		if (global.verbose) then
			log("limitX: " .. tracker.limitX)
			log("limitY: " .. tracker.limitY)
		end
	end
end

local function evaluateLimitsFromMinMax()
	if (global.verbose) then
		log("evaluate limits from min max")
	end

	if math.abs(tracker.minX) > tracker.maxX then
		tracker.limitX =  math.abs(tracker.minX)
	else
		tracker.limitX = tracker.maxX
	end
	
	if math.abs(tracker.minY) > tracker.maxY then
		tracker.limitY = math.abs(tracker.minY)
	else
		tracker.limitY = tracker.maxY
	end
end

function tracker.checkForMinMaxChange() 
	if tracker.minMaxChanged then
		evaluateLimitsFromMinMax()
		shooter.evaluateZoomForAllPlayers()
		tracker.minMaxChanged = false
	end
end

function tracker.evaluateMinMaxFromPosition(pos)
	if (global.verbose) then
		log("Evaluate min max from position: " .. pos.x .. "x" .. pos.y)
	end
	if pos.x < tracker.minX then
		tracker.minX = pos.x
	elseif pos.x > tracker.maxX then
		tracker.maxX = pos.x
	end
	
	if pos.y < tracker.minY then
		tracker.minY = pos.y
	elseif pos.y > tracker.maxY then
		tracker.maxY = pos.y
	end

	if (global.verbose) then
		log("tracker.minX = " .. tracker.minX)
		log("tracker.maxX = " .. tracker.maxX)
		log("tracker.minY = " .. tracker.minY)
		log("tracker.maxY = " .. tracker.maxY)
	end
	
	tracker.minMaxChanged = true
end

function tracker.breaksCurrentLimits(pos)
	if (global.verbose) then
		log("breakscurrentLimits: pos: " .. pos.x .. "x" .. pos.y)
	end
	return (pos.x < global.minX or
	pos.x > global.maxX or
	pos.y < global.minY or
	pos.y > global.maxY)
end

return tracker