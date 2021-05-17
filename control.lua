gui = require("scripts.gui")
basetracker = require("scripts.basetracker")
shooter = require("scripts.shooter")
queue = require("scripts.queue")

local function loadDefaultsForEmptySettings(index)
	log("loading defaults for player " .. index)

	if not global.auto[index] then global.auto[index] = {} end
	if not global.snip[index] then global.snip[index] = {} end

	-- on removing settings support, remove settings and fetching of player
	-- instead use default values of settings directly
	local player_settings = settings.get_player_settings(game.get_player(index))


	if global.auto[index].doScreenshot == nil then
		global.auto[index].doScreenshot = player_settings["FAS-do-screenshot"].value
	end

	if global.auto[index].interval == nil then
		global.auto[index].interval = player_settings["FAS-Screenshot-interval"].value * 60 * 60
	end

	if global.auto[index].resX == nil then
		local resolution = player_settings["FAS-Resolution"].value
		global.auto[index].resolution_index = 1
		global.auto[index].resX = 15360
		global.auto[index].resY = 8640
		if resolution == "7680x4320 (8K)" then
			global.auto[index].resolution_index = 2
			global.auto[index].resX = 7680
			global.auto[index].resY = 4320
		elseif resolution == "3840x2160 (4K)" then
			global.auto[index].resolution_index = 3
			global.auto[index].resX = 3840
			global.auto[index].resY = 2160
		elseif resolution == "1920x1080 (FullHD)" then
			global.auto[index].resolution_index = 4
			global.auto[index].resX = 1920
			global.auto[index].resY = 1080
		elseif resolution == "1280x720  (HD)" then
			global.auto[index].resolution_index = 5
			global.auto[index].resX = 1280
			global.auto[index].resY = 720
		end
	end

	if global.auto[index].singleScreenshot == nil then
		global.auto[index].singleScreenshot = player_settings["FAS-single-screenshot"].value
	end

	if global.auto[index].splittingFactor == nil then
		global.auto[index].splittingFactor = settings.global["FAS-increased-splitting"].value
	end
	
	if not global.snip[index].zoomLevel then global.snip[index].zoomLevel = 1 end

	-- confirmation logs reading back the set settings in chat.
	if (global.auto[index].doScreenshot) then
		log("Player " .. index .. " does screenshots with resolution " .. 
		global.auto[index].resX .. "x" .. global.auto[index].resY .. 
		" every " .. (global.auto[index].interval / 3600) .. " minutes")
		shooter.evaluateZoomForPlayerAndAllSurfaces(index)
	else
		log("Player " .. index .. " does no screenshots")
	end
end

-- this method resets everything to a default state apart from already registered screenshots
local function initialize()
	log("initialize")

	global.auto = {
		-- surface specific, therefore indexed after surfaces
		zoom = {},
		zoomLevel = {}
	}
	global.snip = {}
	global.tracker = {}
	global.gui = {}
	global.queue = {
		hasAnyEntries = false
	}


	global.verbose = settings.global["FAS-enable-debug"].value

	basetracker.evaluateLimitsOfSurface()

	--this should only find the host player if hosted directly
	for _, player in pairs(game.connected_players) do
		log("found player already connected: " .. player.name)
		loadDefaultsForEmptySettings(player.index)
		gui.initialize(player)
		queue.initialize(player.index)
	end

	queue.refreshNextScreenshotTimestamp()
end

local function on_player_joined_game(event)
	log("player " .. event.player_index .. " joined")
	gui.initialize(game.get_player(event.player_index))
	loadDefaultsForEmptySettings(event.player_index)
	queue.refreshNextScreenshotTimestamp()
end

local function on_player_left_game(event)
	log("player " .. event.player_index .. " left")
	queue.refreshNextScreenshotTimestamp()
end

local function on_runtime_mod_setting_changed(event)
	if (event.setting_type == "runtime-global") then
		log("global settings changed")
		global.verbose = settings.global["FAS-enable-debug"].value
	end
end

local function on_built_entity(event)
	local pos = event.created_entity.position
	local surface = event.created_entity.surface.index
	if (global.verbose) then
		log("entity built on surface " .. surface .. event " at pos: " .. pos.x .. "x" .. pos.y)
	end
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
	log("on nth tick")
	-- if something was built in the last minute that should cause a recalc of all zoom levels
	basetracker.checkForMinMaxChange()

	for _, player in pairs(game.connected_players) do
		if global.verbose then
			log("player " .. player.name .. " with index " .. player.index .. " found")
			log("do screenshot:    " .. (global.auto[player.index].doScreenshot and "true" or "false"))
			log("interval:         " .. (global.auto[player.index].interval or "nil"))
			log("singleScreenshot: " .. (global.auto[player.index].singleScreenshot and "true" or "false"))
			log("tick:             " .. game.tick)
		end
		if global.auto[player.index].doScreenshot and (event.tick % global.auto[player.index].interval == 0) then
			if queue.hasEntries(player.index) then
				log("there was still a screenshot queued on nth tick event trigger")
				game.print("FAS: The script is not yet done with the screenshots but tried to register new ones. This screenshot interval will be skipped. Please lower the \"increased splitting\" setting if it is set, make less players do screenshots or make the intervals in which you do screenshots longer. Changing the resolution will not prevent this from happening.")
				return
			end
			queue.registerPlayerToScreenshotlist(player.index)
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