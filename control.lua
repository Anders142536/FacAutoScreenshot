l = require("scripts.logger")
gui = require("scripts.gui")
basetracker = require("scripts.basetracker")
shooter = require("scripts.shooter")
queue = require("scripts.queue")

local function loadDefaultsForPlayer(index)
	log(l.info("loading defaults for player " .. index))

	if not global.auto[index] then 
		l.info("global.auto was nil")
		global.auto[index] = {}
	end
	if not global.auto[index].zoom then
		l.info("global.auto.zoom was nil")
		global.auto[index].zoom = {}
	end
	if not global.auto[index].zoomLevel then
		l.info("global.auto.zoomlevel was nil")
		global.auto[index].zoomLevel = {}
	end
	
	if global.auto[index].interval == nil then global.auto[index].interval = 10 * 60 * 60 end
	log(l.info("interval is " .. (global.auto[index].interval / 60 / 60)) .. " min")
	
	if global.auto[index].resX == nil then
		global.auto[index].resolution_index = 3
		global.auto[index].resX = 3840
		global.auto[index].resY = 2160
	end

	log(l.info("resolution is " .. global.auto[index].resX .. "x" .. global.auto[index].resY))

	if global.auto[index].singleScreenshot == nil then global.auto[index].singleScreenshot = true end
	log(l.info("singleScreenshot is " .. (global.auto[index].singleScreenshot and "on" or "off")))
	
	if global.auto[index].splittingFactor == nil then global.auto[index].splittingFactor = 1 end
	log(l.info("splittingFactor is " .. global.auto[index].splittingFactor))
	
	if not global.auto[index].doSurface then global.auto[index].doSurface = {} end
	for _, surface in pairs(game.surfaces) do
		log(l.info("does surface " .. surface.name .. ": " ..
		(global.auto[index].doSurface[surface.name] and "true" or "false")))
	end

	if not global.snip[index] then
		l.info("global.snip was nil")
		global.snip[index] = {}
	end
	if not global.snip[index].area then
		l.info("global.snip.area was nil")
		global.snip[index].area = {}
	end

	if global.snip[index].showAltMode == nil then global.snip[index].showAltMode = false end
	log(l.info("snip show alt mode is " .. (global.snip[index].showAltMode and "true" or "false")))

	if global.snip[index].showUI == nil then global.snip[index].showUI = false end
	log(l.info("snip show ui is " .. (global.snip[index].showUI and "true" or "false")))

	if global.snip[index].showCursorBuildingPreview == nil then global.snip[index].showCursorBuildingPreview = false end
	log(l.info("snip show cursor building preview is " .. (global.snip[index].showCursorBuildingPreview and "true" or "false")))

	if global.snip[index].useAntiAlias == nil then global.snip[index].useAntiAlias = false end
	log(l.info("snip use anti alias is " .. (global.snip[index].useAntiAlias and "true" or "false")))

	if not global.snip[index].zoomLevel then global.snip[index].zoomLevel = 1 end
	log(l.info("snip zoomlevel is " .. global.snip[index].zoomLevel))


	shooter.evaluateZoomForPlayerAndAllSurfaces(index)
end

local function initializePlayer(player)
	loadDefaultsForPlayer(player.index)
	gui.initialize(player)
	queue.initialize(player.index)
end

-- this method resets everything to a default state apart from already registered screenshots
local function initialize()
	log(l.info("initialize"))

	global.auto = {}
	global.snip = {}
	global.tracker = {}
	global.gui = {}
	global.queue = {}

	for _, surface in pairs(game.surfaces) do
		basetracker.initializeSurface(surface.name)
	end

	for _, player in pairs(game.connected_players) do
		log(l.info("found player: " .. player.name))
		initializePlayer(player)
	end

	queue.refreshNextScreenshotTimestamp()
end

local function on_player_joined_game(event)
	log(l.info("player " .. event.player_index .. " joined"))
	initializePlayer(game.get_player(event.player_index))
	queue.refreshNextScreenshotTimestamp()
end

local function on_player_left_game(event)
	log(l.info("player " .. event.player_index .. " left"))
	queue.refreshNextScreenshotTimestamp()
end

local function on_runtime_mod_setting_changed(event)
	if (event.setting_type == "runtime-global") then
		log(l.info("global settings changed"))
	end
end

local function on_built_entity(event)
	local pos = event.created_entity.position
	local surface = event.created_entity.surface.name
	if l.doD then log(l.debug("entity built on surface", surface, "at pos:", pos.x, "x", pos.y)) end
	if basetracker.breaksCurrentLimits(pos, surface) then
		basetracker.evaluateMinMaxFromPosition(pos, surface)
	end
end

local function on_tick()
	if queue.hasAnyEntries() then
		shooter.renderNextQueueStep()
	else
		if game.tick % 60  == 0 then
			gui.refreshStatusCountdown()
		end
	end
end

local function on_nth_tick(event)
	log(l.info("on nth tick"))
	-- if something was built in the last minute that should cause a recalc of all zoom levels
	basetracker.checkForMinMaxChange()

	for _, player in pairs(game.connected_players) do

		if l.doD then log(l.debug("player ", player.name, " with index ", player.index, " found")) end
		if l.doD then log(l.debug("do screenshot:   ", queue.doesAutoScreenshot(player.index))) end
		if l.doD then log(l.debug("interval:        ", global.auto[player.index].interval)) end
		if l.doD then log(l.debug("singleScreenshot:", global.auto[player.index].singleScreenshot)) end
		if l.doD then log(l.debug("tick:            ", game.tick)) end

		if queue.doesAutoScreenshot(player.index) and (event.tick % global.auto[player.index].interval == 0) then
			queue.registerPlayerToQueue(player.index)
		end
	end

end


--[[ EVENT REGISTRATION ]]--
script.on_init(initialize)


-- every minute
script.on_nth_tick(3600, on_nth_tick)

script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_player_left_game, on_player_left_game)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)

-- GUI
script.on_event(defines.events.on_gui_click, gui.on_gui_event)
script.on_event(defines.events.on_gui_value_changed, gui.on_gui_value_changed)
script.on_event(defines.events.on_gui_text_changed, gui.on_gui_text_changed)
script.on_event(defines.events.on_gui_selection_state_changed, gui.on_gui_selection_state_changed)
script.on_event("FAS-left-click", gui.on_left_click)
script.on_event("FAS-right-click", gui.on_right_click)
script.on_event(defines.events.on_player_cursor_stack_changed, gui.on_player_cursor_stack_changed)
-- script.on_event(defines.events.on_gui_text_changed, gui.on_gui_event)
script.on_event(defines.events.on_pre_surface_deleted, gui.on_pre_surface_deleted)
script.on_event(defines.events.on_surface_created, function(event)
	gui.on_surface_created(event)
	basetracker.initializeSurface(game.get_surface(event.surface_index).name)
end)
script.on_event(defines.events.on_surface_imported, function(event)
	gui.on_surface_imported(event)
	basetracker.initializeSurface(game.get_surface(event.surface_index).name)
end)
script.on_event(defines.events.on_surface_renamed, function(event)
	gui.on_surface_renamed(event)
	basetracker.on_surface_renamed(event)
end)