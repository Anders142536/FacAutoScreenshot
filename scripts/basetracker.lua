local tracker = {}

function tracker.initializeSurface(surface)
	global.tracker[surface] = {}
	tracker.evaluateLimitsOfSurface(surface)
end

function tracker.on_surface_renamed(event)
	if global.tracker[event.old_name] then
		global.tracker[event.new_name] = global.tracker[event.old_name]
		global.tracker[event.old_name] = nil
	end
end

local function hasEntities(chunk, surface)
	local count = surface.count_entities_filtered{
		area=chunk.area,
		force="player",
		limit=1
	}
	return (count ~= 0)
end

function tracker.evaluateLimitsOfSurface(surface_index)
	log(l.info("Evaluating whole surface: " .. surface_index))
	
	local surface = game.surfaces[surface_index];
	local tchunk = nil;
	local rchunk = nil;
	local bchunk = nil;
	local lchunk = nil;
	
	for chunk in surface.get_chunks() do
		if hasEntities(chunk, surface) then
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
		log(l.info("tchunk is nil"))
		global.tracker[surface_index].limitX = 64
		global.tracker[surface_index].limitY = 64
		global.tracker[surface_index].minX = -64
		global.tracker[surface_index].maxX = 64
		global.tracker[surface_index].minY = -64
		global.tracker[surface_index].maxY = 64
	else
		global.tracker[surface_index].minX = lchunk.area.left_top.x
		global.tracker[surface_index].maxX = rchunk.area.right_bottom.x
		global.tracker[surface_index].minY = tchunk.area.left_top.y
		global.tracker[surface_index].maxY = bchunk.area.right_bottom.y

		if l.doD then log(l.debug("global.tracker[", surface_index, "].minX: ", global.tracker[surface_index].minX)) end
		if l.doD then log(l.debug("global.tracker[", surface_index, "].maxX: ", global.tracker[surface_index].maxX)) end
		if l.doD then log(l.debug("global.tracker[", surface_index, "].minY: ", global.tracker[surface_index].minY)) end
		if l.doD then log(l.debug("global.tracker[", surface_index, "].maxY: ", global.tracker[surface_index].maxY)) end

		local top = math.abs(tchunk.area.left_top.x)
		local right = math.abs(rchunk.area.right_bottom.x)
		local bottom = math.abs(bchunk.area.right_bottom.y)
		local left =  math.abs(lchunk.area.left_top.x)

		if l.doD then log(l.debug("top: ", top)) end
		if l.doD then log(l.debug("right: ", right)) end
		if l.doD then log(l.debug("bottom: ", bottom)) end
		if l.doD then log(l.debug("left: ", left)) end
		
		if (top > bottom) then
			global.tracker[surface_index].limitY = top
		else
			global.tracker[surface_index].limitY = bottom
		end
		
		if (left > right) then
			global.tracker[surface_index].limitX = left
		else
			global.tracker[surface_index].limitX = right
		end

		if l.doD then log(l.debug("limitX: ", global.tracker[surface_index].limitX)) end
		if l.doD then log(l.debug("limitY: ", global.tracker[surface_index].limitY)) end
	end
end

local function evaluateLimitsFromMinMax(surface)
	if l.doD then log(l.debug("evaluate limits from min max")) end

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

function tracker.checkForMinMaxChange()
	for _, surface in pairs(game.surfaces) do
		if global.tracker[surface.name].minMaxChanged then
			evaluateLimitsFromMinMax(surface.name)
			shooter.evaluateZoomForAllPlayersAndAllSurfaces()
			global.tracker[surface.name].minMaxChanged = false
		end
	end
end

function tracker.evaluateMinMaxFromPosition(pos, surface)
	if l.doD then log(l.debug("Evaluate min max on surface ", surface, "from position: ", pos.x, "x", pos.y)) end
	
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

	if l.doD then log(l.debug("global.tracker[", surface, "].minX = ", global.tracker[surface].minX)) end
	if l.doD then log(l.debug("global.tracker[", surface, "].maxX = ", global.tracker[surface].maxX)) end
	if l.doD then log(l.debug("global.tracker[", surface, "].minY = ", global.tracker[surface].minY)) end
	if l.doD then log(l.debug("global.tracker[", surface, "].maxY = ", global.tracker[surface].maxY)) end
	
	global.tracker[surface].minMaxChanged = true
end

function tracker.breaksCurrentLimits(pos, surface)
	if l.doD then log(l.debug("breakscurrentLimits on surface ", surface, ": pos: ", pos.x, "x", pos.y)) end

	return (pos.x < global.tracker[surface].minX or
	pos.x > global.tracker[surface].maxX or
	pos.y < global.tracker[surface].minY or
	pos.y > global.tracker[surface].maxY)
end

return tracker