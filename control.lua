l = require("scripts.logger")
gui = require("scripts.gui")
basetracker = require("scripts.basetracker")
shooter = require("scripts.shooter")
queue = require("scripts.queue")

local function loadDefaultsForPlayer(index)
	log(l.info("loading defaults for player " .. index))

	if not global.auto[index] then global.auto[index] = {} end
	if not global.snip[index] then global.snip[index] = {} end

	if global.auto[index].interval == nil then
		if l.doD then log(l.debug("setting interval to 10 min")) end
		global.auto[index].interval = 10 * 60 * 60
	end

	if global.auto[index].resX == nil then
		if l.doD then log(l.debug("setting resolution to 4k")) end
		global.auto[index].resolution_index = 3
		global.auto[index].resX = 3840
		global.auto[index].resY = 2160
	end

	if global.auto[index].singleScreenshot == nil then
		if l.doD then log(l.debug("setting singleScreenshot to false")) end
		global.auto[index].singleScreenshot = false
	end

	if global.auto[index].splittingFactor == nil then
		if l.doD then log(l.debug("setting splittingFactor to 1")) end
		global.auto[index].splittingFactor = 1
	end
	
	if not global.snip[index].zoomLevel then global.snip[index].zoomLevel = 1 end

	-- confirmation logs reading back the set settings in chat.
	if (global.auto[index].doScreenshot) then
		l.info("Player " .. index .. " does screenshots with resolution " .. 
		global.auto[index].resX .. "x" .. global.auto[index].resY .. 
		" every " .. (global.auto[index].interval / 3600) .. " minutes")
		shooter.evaluateZoomForPlayerAndAllSurfaces(index)
	else
		log(l.info("Player " .. index .. " does no screenshots"))
	end
end

local function initializePlayer(player)
	-- surface specific, need to be indexed via surface index
	global.auto[player.index] = {
		zoom = {},
		zoomLevel = {},
		doSurface = {}
	}
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

		if l.doD then log(l.debug("player", player.name, "with index", player.index, "found")) end
		if l.doD then log(l.debug("do screenshot:   ", global.auto[player.index].doScreenshot)) end
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
script.on_configuration_changed(function(data)
	--check what is in data and see if we can skip a lot of things
	--we only need to reinitialize if the mod version changed
	initialize()
end)

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
	gui.on_surface_created()
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