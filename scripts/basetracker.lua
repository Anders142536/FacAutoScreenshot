local tracker = {}

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
		global.tracker.limitX = 1
		global.tracker.limitY = 1
	else
		global.tracker.minX = lchunk.area.left_top.x
		global.tracker.maxX = rchunk.area.right_bottom.x
		global.tracker.minY = tchunk.area.left_top.y
		global.tracker.maxY = bchunk.area.right_bottom.y

		if global.verbose then
			log("global.tracker.minX: " .. global.tracker.minX)
			log("global.tracker.maxX: " .. global.tracker.maxX)
			log("global.tracker.minY: " .. global.tracker.minY)
			log("global.tracker.maxY: " .. global.tracker.maxY)
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
			global.tracker.limitY = top
		else
			global.tracker.limitY = bottom
		end
		
		if (left > right) then
			global.tracker.limitX = left
		else
			global.tracker.limitX = right
		end

		if (global.verbose) then
			log("limitX: " .. global.tracker.limitX)
			log("limitY: " .. global.tracker.limitY)
		end
	end
end

local function evaluateLimitsFromMinMax()
	if (global.verbose) then
		log("evaluate limits from min max")
	end

	if math.abs(global.tracker.minX) > global.tracker.maxX then
		global.tracker.limitX =  math.abs(global.tracker.minX)
	else
		global.tracker.limitX = global.tracker.maxX
	end
	
	if math.abs(global.tracker.minY) > global.tracker.maxY then
		global.tracker.limitY = math.abs(global.tracker.minY)
	else
		global.tracker.limitY = global.tracker.maxY
	end
end

function tracker.checkForMinMaxChange() 
	if global.tracker.minMaxChanged then
		evaluateLimitsFromMinMax()
		shooter.evaluateZoomForAllPlayers()
		global.tracker.minMaxChanged = false
	end
end

function tracker.evaluateMinMaxFromPosition(pos)
	if (global.verbose) then
		log("Evaluate min max from position: " .. pos.x .. "x" .. pos.y)
	end
	if pos.x < global.tracker.minX then
		global.tracker.minX = pos.x
	elseif pos.x > global.tracker.maxX then
		global.tracker.maxX = pos.x
	end
	
	if pos.y < global.tracker.minY then
		global.tracker.minY = pos.y
	elseif pos.y > global.tracker.maxY then
		global.tracker.maxY = pos.y
	end

	if (global.verbose) then
		log("global.tracker.minX = " .. global.tracker.minX)
		log("global.tracker.maxX = " .. global.tracker.maxX)
		log("global.tracker.minY = " .. global.tracker.minY)
		log("global.tracker.maxY = " .. global.tracker.maxY)
	end
	
	global.tracker.minMaxChanged = true
end

function tracker.breaksCurrentLimits(pos)
	if (global.verbose) then
		log("breakscurrentLimits: pos: " .. pos.x .. "x" .. pos.y)
	end
	return (pos.x < global.tracker.minX or
	pos.x > global.tracker.maxX or
	pos.y < global.tracker.minY or
	pos.y > global.tracker.maxY)
end

return tracker