local l = require("logger")

local shooter = {}

--[[ Zoom Evalutation ]]--
local function evaluateZoomForPlayer(index, surface)
		if l.doD then log(l.debug("ev zoom for player " .. index)) end
		if l.doD then log(l.debug("resX: " .. global.auto[index].resX)) end
		if l.doD then log(l.debug("resY: " .. global.auto[index].resY)) end
		if l.doD then log(l.debug("global.tracker[" .. surface .."].limitX: " .. global.tracker[surface].limitX)) end
		if l.doD then log(l.debug("global.tracker[" .. surface .. "].limitY: " .. global.tracker[surface].limitY)) end
		if l.doD then log(l.debug("old zoom: " .. (global.auto[index].zoom[surface] or "nil"))) end
		if l.doD then log(l.debug("zoomLevel: " .. (global.auto[index].zoomLevel[surface] or "nil"))) end

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
		log(l.info("Adjusting zoom for player " .. index .. " on surface " .. surface .. " to " .. global.auto[index].zoom[surface] .. " and zoomlevel to " .. global.auto[index].zoomLevel[surface]))
	end
	if oldZoom > global.auto[index].zoom[surface] then
		log(l.info("Adjusted zoom for player " .. index .. " from " .. oldZoom .. " to " .. global.auto[index].zoom[surface]))
		if (global.auto[index].zoom[surface] == 32) then
			log(l.warn("Player " .. index .. " reached maximum zoomlevel"))
			game.print("FAS: Player " .. index .. " reached maximum zoom level of 32. No further zooming out possible. Entities exceeding the screenshot limits will not be shown on the screenshots!")
		end
	end
end

function shooter.evaluateZoomForPlayerAndAllSurfaces(index)
	for _, surface in pairs(game.surfaces) do
		evaluateZoomForPlayer(index, surface.name)
	end
end

function shooter.evaluateZoomForAllPlayersAndSurface(surface)
	for _, player in pairs(game.connected_players) do
		evaluateZoomForPlayer(player.index, surface)
	end
end

function shooter.evaluateZoomForAllPlayersAndAllSurfaces()
    log(l.info("ev zoom for all players"))
	for _, player in pairs(game.connected_players) do
			shooter.evaluateZoomForPlayerAndAllSurfaces(player.index)
	end
end



--[[ Screenshotting ]]--
local function buildPath(folder, title, format)
	return "./screenshots/" .. game.default_map_gen_settings.seed .. "/" .. folder .. title .. format
end


function shooter.renderAutoSingleScreenshot(index, specs)
	if l.doD then log(l.debug("rendering auto screenshot as single screenshot")) end
	if l.doD then log(l.debug("index:   " .. index)) end
	if l.doD then log(l.debug("surface: " .. specs.surface)) end
	if l.doD then log(l.debug("res:     " .. specs.resX .. "x " .. specs.resY .. "y")) end
	if l.doD then log(l.debug("zoom:    " .. specs.zoom)) end
	game.take_screenshot{
		resolution = {specs.resX, specs.resY},
		position = {0, 0},
		zoom = specs.zoom,
		surface = specs.surface,
		daytime = 0,
		water_tick = 0,
		by_player = index,
		path = buildPath("auto_singleTick_" .. specs.surface ..  "/", "screenshot" .. game.tick, ".png")
	}
end

function shooter.renderAutoScreenshotFragment(index, fragment)
	local posX = fragment.startpos.x + fragment.stepsize.x * fragment.offset.x
	local posY = fragment.startpos.y + fragment.stepsize.y * fragment.offset.y

	if l.doD then log(l.debug("rendering next auto screenshot fragment")) end
	if l.doD then log(l.debug("index:   " .. index)) end
	if l.doD then log(l.debug("surface: " .. fragment.surface)) end
	if l.doD then log(l.debug("res:     " .. fragment.res.x .. "x " .. fragment.res.y .. "y")) end
	if l.doD then log(l.debug("zoom:    " .. fragment.zoom)) end
	if l.doD then log(l.debug("pos:     " .. posX .. "x " .. posY .. "y")) end

	game.take_screenshot{
		resolution = fragment.res,
		position = {posX, posY},
		zoom = fragment.zoom,
		surface = fragment.surface,
		by_player = index,
		water_tick = 0,
		daytime = 0,
		path = buildPath("auto_split_" .. fragment.surface .. "/", fragment.title .. "_x" .. fragment.offset.x .. "_y" .. fragment.offset.y, ".png")
	}

	-- the first screenshot is the screenshot 0 0, therefore +1
	global.auto.amount = fragment.offset.y * fragment.numberOfTiles + fragment.offset.x + 1
	global.auto.total = fragment.numberOfTiles * fragment.numberOfTiles
end


function shooter.renderAreaScreenshot(index)
	log(l.info("shooter.renderAreaScreenshot was triggered"))
	if l.doD then
		log(l.debug("index:       " .. index))
		log(l.debug("area.top:    " .. global.snip[index].area.top))
		log(l.debug("area.bottom: " .. global.snip[index].area.bottom))
		log(l.debug("area.left:   " .. global.snip[index].area.left))
		log(l.debug("area.right:  " .. global.snip[index].area.right))
		log(l.debug("zoomlevel:   " .. global.snip[index].zoomLevel))
		log(l.debug("daytime:     " .. (global.snip[index].daytime_state or "none")))
		log(l.debug("show alt m.: " .. (global.snip[index].showAltMode and "true" or "false")))
		log(l.debug("show ui:     " .. (global.snip[index].showUI and "true" or "false")))
		log(l.debug("show cur b.: " .. (global.snip[index].showCursorBuildingPreview and "true" or "false")))
		log(l.debug("use antial.: " .. (global.snip[index].useAntiAlias and "true" or "false")))
		log(l.debug("output name: " .. (global.snip[index].outputName or "screenshot")))
		log(l.debug("format:      " .. global.snip[index].output_format_index))
		log(l.debug("jpg quality: " .. global.snip[index].jpg_quality))
		log(l.debug("surface_name:" .. global.snip[index].surface_name))
	end

	local width = global.snip[index].area.right - global.snip[index].area.left
	local heigth = global.snip[index].area.bottom - global.snip[index].area.top

	local zoom = 1 / global.snip[index].zoomLevel
	local resX = math.floor(width * 32 * zoom)
	local resY = math.floor(heigth * 32 * zoom)
	local posX = global.snip[index].area.left + width / 2
	local posY = global.snip[index].area.top + heigth / 2

	local surface = game.surfaces[global.snip[index].surface_name]

	local dstate = global.snip[index].daytime_state
	if dstate == nil or dstate == "none" then
		dstate = surface.daytime
	elseif dstate == "left" then
		dstate = 0
	else
		dstate = 0.5
	end
	if l.doD then log(l.debug("dstate ended up being " .. dstate)) end

	local name = global.snip[index].outputName
	if not name then name = "screenshot" end
	local format = "." .. (global.snip[index].output_format_index == 1 and "png" or "jpg")
	local path = buildPath("area/", name .. "_" .. game.tick .. "_" .. resX .. "x" .. resY, format)

	game.take_screenshot{
		resolution = {resX, resY},
		position = {posX, posY},
		surface = surface,
		zoom = zoom,
		by_player = index,
		path = path,
		show_gui = global.snip[index].showUI,
		show_entity_info = global.snip[index].showAltMode,
		show_cursor_building_preview = global.snip[index].showCursorBuildingPreview,
		anti_allias = global.snip[index].useAntiAlias,
		daytime = dstate,
		quality = global.snip[index].jpg_quality
	}
	game.get_player(index).print({"FAS-did-screenshot", path})
end

return shooter

