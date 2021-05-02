gui = require("scripts.gui")
basetracker = require("scripts.basetracker")
shooter = require("scripts.shooter")

local function loadDefaultsForEmptySettings(index)
	log("loading defaults for player " .. index)

	-- on removing settings support, remove settings and fetching of player
	-- instead use default values of settings directly
	local player_settings = settings.get_player_settings(game.get_player(index))

	if global.auto.doScreenshot[index] == nil then
		global.auto.doScreenshot[index] = player_settings["FAS-do-screenshot"].value
	end

	if global.auto.interval[index] == nil then
		global.auto.interval[index] = player_settings["FAS-Screenshot-interval"].value * 60 * 60
	end

	if global.auto.resX[index] == nil then
		local resolution = player_settings["FAS-Resolution"].value
		global.auto.resX[index] = 7680;
		global.auto.resY[index] = 4320;
		if (resolution == "3840x2160 (4K)") then
			global.auto.resX[index] = 3840;
			global.auto.resY[index] = 2160;
		elseif (resolution == "1920x1080 (FullHD)") then
			global.auto.resX[index] = 1920;
			global.auto.resY[index] = 1080;
		elseif (resolution == "1280x720  (HD)") then
			global.auto.resX[index] = 1280;
			global.auto.resY[index] = 720;
		end
	end

	if global.auto.singleScreenshot[index] == nil then
		global.auto.singleScreenshot[index] = player_settings["FAS-single-screenshot"].value
	end

	if global.auto.splittingFactor[index] == nil then
		global.auto.splittingFactor[index] = settings.global["FAS-increased-splitting"].value
	end
	
	if not global.snip.zoomLevel[index] then global.snip.zoomLevel[index] = 1 end

	-- confirmation logs reading back the set settings in chat.
	if (global.auto.doScreenshot[index]) then
		log("Player " .. index .. " does screenshots with resolution " .. 
		global.auto.resX[index] .. "x" .. global.auto.resY[index] .. 
		" every " .. (global.auto.interval[index] / 3600) .. " minutes")
		shooter.evaluateZoomForPlayer(index)
	else
		log("Player " .. index .. " does no screenshots")
	end
end

-- this method resets everything to a default state apart from already registered screenshots
local function initialize()
	log("initialize")

	global.auto = {}
	global.snip = {}
	-- tracker doesnt need to hold values based on players, hence no table init below
	global.tracker = {}
	global.gui = {}

	global.verbose = settings.global["FAS-enable-debug"].value

	if not global.auto.nextScreenshot then
		global.auto.nextScreenshot = {}
	end
	global.auto.doScreenshot = {}
	global.auto.interval = {}
	global.auto.singleScreenshot = {}
	global.auto.splittingFactor = {}
	global.auto.resX = {}
	global.auto.resY = {}
	global.auto.zoom = {}
	global.auto.zoomLevel = {}

	global.snip.zoomLevel = {}
	global.snip.doesSelection = {}
	global.snip.areaLeftClick = {}
	global.snip.areaRightClick = {}
	global.snip.rec = {}
	global.snip.area = {}

	global.gui = {}

	basetracker.evaluateLimitsFromWholeBase()

	--this should only find the host player if hosted directly
	for _, player in pairs(game.connected_players) do
		log("found player already connected: " .. player.name)
		loadDefaultsForEmptySettings(player.index)
		gui.initialize(player)
	end

	shooter.refreshNextScreenshotTimestamp()
end

local function on_player_joined_game(event)
	log("player " .. event.player_index .. " joined")
	gui.initialize(game.get_player(event.player_index))
	loadDefaultsForEmptySettings(event.player_index)
	shooter.refreshNextScreenshotTimestamp()
end

local function on_player_left_game(event)
	log("player " .. event.player_index .. " left")
	shooter.refreshNextScreenshotTimestamp()
end

local function on_runtime_mod_setting_changed(event)
	if (event.setting_type == "runtime-global") then
		log("global settings changed")
		global.verbose = settings.global["FAS-enable-debug"].value
	end
end

local function on_built_entity(event)
	local pos = event.created_entity.position
	if (global.verbose) then
		log("pos: " .. pos.x .. "x" .. pos.y)
	end
	if basetracker.breaksCurrentLimits(pos) then
		basetracker.evaluateMinMaxFromPosition(pos)
	end
end

local function on_tick()
	if (shooter.hasNextScreenshot()) then
		shooter.renderNextScreenshot()
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
			log("do screenshot:    " .. (global.auto.doScreenshot[player.index] and "true" or "false"))
			log("interval:         " .. global.auto.interval[player.index])
			log("singleScreenshot: " .. (global.auto.singleScreenshot[player.index] or "false"))
			log("tick:             " .. game.tick)
		end
		if global.auto.doScreenshot[player.index] and (event.tick % global.auto.interval[player.index] == 0) then
			if shooter.hasNextScreenshot() then
				log("there was still a screenshot queued on nth tick event trigger")
				game.print("FAS: The script is not yet done with the screenshots but tried to register new ones. This screenshot interval will be skipped. Please lower the \"increased splitting\" setting if it is set, make less players do screenshots or make the intervals in which you do screenshots longer. Changing the resolution will not prevent this from happening.")
				return
			end
			if global.auto.singleScreenshot[player.index] then
				shooter.renderScreenshot(player.index, {global.auto.resX[player.index], global.auto.resY[player.index]}, {0, 0}, global.auto.zoom[player.index], "", "screenshot" .. game.tick) -- set params
			else
				shooter.registerPlayerToScreenshotlist(player.index)
			end
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
script.on_event(defines.events.on_gui_value_changed, gui.on_gui_event)
script.on_event("FAS-left-click", gui.on_left_click)
script.on_event("FAS-right-click", gui.on_right_click)
script.on_event(defines.events.on_player_cursor_stack_changed, gui.on_player_cursor_stack_changed)
-- script.on_event(defines.events.on_gui_text_changed, gui.on_gui_event)