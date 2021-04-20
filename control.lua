--[[ TODO
# 2.0

* refactor control.lua
* think about peeling the settings stuff into seperate file, as that would be nicer to do
	and the require-loading would avoid some sync issues
* build gui as shown in mocks
* add necessary functions to Shooter

* make button do mega screenshot
	> test if the resolution in the screenshotting is limited

--]]
gui = require("scripts.gui")
basetracker = require("scripts.basetracker")
shooter = require("scripts.shooter")

script.on_init(initialize)

script.on_configuration_changed(function(data)
	--check what is in data and see if we can skip a lot of things
	--we only need to reinitialize if the mod version changed
	initialize()
end)

function initialize()
	log("initialize")

	-- runtime global settings
	global.verbose = settings.global["FAS-enable-debug"].value
	global.increasedSplitting = settings.global["FAS-increased-splitting"].value
	
	-- runtime user settings
	global.doScreenshot = {}
	global.interval = {}
	global.singleScreenshot = {}
	global.resX = {}
	global.resY = {}

	basetracker.evaluateLimitsFromWholeBase()

	--this should only find the host player if hosted directly
	for _, player in pairs(game.connected_players) do
		log("found player already connected: " .. player.name)
		game.print("this should only find the player in sp: " .. player.name)
		gui.initialize(player)
		loadSettings(player.index)
	end

	shooter.refreshNextScreenshotTimestamp()
end

function on_player_joined_game(event)
	log("player " .. event.player_index .. " joined")
	gui.initialize(game.get_player(event.player_index))
	loadSettings(event.player_index)
	shooter.refreshNextScreenshotTimestamp()
end

function on_player_left_game(event)
	log("player " .. event.player_index .. " left")
	shooter.refreshNextScreenshotTimestamp()
end

function on_runtime_mod_setting_changed(event)
	if (event.setting_type == "runtime-global") then
		log("global settings changed")
		game.print("FAS: Global settings changed")
	else
		log("runtimesettings for player " .. event.player_index .. " changed")
		loadSettings(event.player_index)
		shooter.refreshNextScreenshotTimestamp()
	end
end

function loadGlobalSettings()
	log("loading global settings")
	global.verbose = settings.global["FAS-enable-debug"].value
	global.increasedSplitting = settings.global["FAS-increased-splitting"].value

	if global.verbose then
		log("new settings:\nverbose:")
	end
end

function loadSettings(player_index)
	log("loading settings for player " .. player_index)

	local player = game.get_player(player_index)
	global.doScreenshot[player_index] = settings.get_player_settings(player)["FAS-do-screenshot"].value
	global.interval[player_index] = settings.get_player_settings(player)["FAS-Screenshot-interval"].value * 3600 -- 3600
	global.singleScreenshot[player_index] = settings.get_player_settings(player)["FAS-single-screenshot"].value

	local resolution = settings.get_player_settings(player)["FAS-Resolution"].value
	global.resX[player_index] = 7680;
	global.resY[player_index] = 4320;
	if (resolution == "3840x2160 (4K)") then
		global.resX[player_index] = 3840;
		global.resY[player_index] = 2160;
	elseif (resolution == "1920x1080 (FullHD)") then
		global.resX[player_index] = 1920;
		global.resY[player_index] = 1080;
	elseif (resolution == "1280x720  (HD)") then
		global.resX[player_index] = 1280;
		global.resY[player_index] = 720;
	end
	
	-- confirmation prints reading back the set settings in chat.
	local outputString
	if (global.doScreenshot[player_index]) then
		outputString = "Player " .. player_index .. " does screenshots with resolution " .. 
		global.resX[player_index] .. "x" .. global.resY[player_index] .. 
		" every " .. (global.interval[player_index] / 3600) .. " minutes"
		log(outputString)
		game.print("FAS: " .. outputString)
		shooter.evaluateZoomForPlayer(player_index)
	else
		outputString = "Player " .. player_index .. " does no screenshots"
		log(outputString)
		game.print("FAS: " .. outputString)
	end
end

function on_built_entity(event)
	local pos = event.created_entity.position
	if (global.verbose) then
		log("pos: " .. pos.x .. "x" .. pos.y)
	end
	if basetracker.breaksCurrentLimits(pos) then
		basetracker.evaluateMinMaxFromPosition(pos)
	end
end

-- 3600
script.on_nth_tick(3600, function(event)
	log("on nth tick")
	-- if something was built in the last minute that should cause a recalc of all zoom levels
	basetracker.checkForMinMaxChange()

	for _, player in pairs(game.connected_players) do
		if (global.verbose) then
			log("player " .. player.name .. " with index " .. player.index .. " found")
			log(global.doScreenshot[player.index])
			log(global.interval[player.index])
			log(global.singleScreenshot[player.index])
			log(game.tick)
		end
		if global.doScreenshot[player.index] and (event.tick % global.interval[player.index] == 0) then
			local n = shooter.nextScreenshot[1]
			if (n ~= nil) then
				log("there was still a screenshot queued on nth tick event trigger")
				game.print("FAS: The script is not yet done with the screenshots but tried to register new ones. This screenshot interval will be skipped. Please lower the \"increased splitting\" setting if it is set, make less players do screenshots or make the intervals in which you do screenshots longer. Changing the resolution will not prevent this from happening.")
				return
			end
			if (global.singleScreenshot[player.index]) then
				shooter.renderScreenshot(player.index, {global.resX[player.index], global.resY[player.index]}, {0, 0}, global.zoom[player.index], "", "screenshot" .. game.tick) -- set params
			else
				shooter.registerPlayerToScreenshotlist(player.index)
			end
		end
	end
end)

local function on_tick()
	if (shooter.hasNextScreenshot()) then
		shooter.renderNextScreenshot()
	else
		if game.tick % 60  == 0 then
			gui.refreshStatusCountdown()
		end
	end
end


script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)

-- GUI
script.on_event(defines.events.on_gui_click, gui.on_gui_event)
script.on_event(defines.events.on_gui_value_changed, gui.on_gui_event)
script.on_event("FAS-left-click", gui.on_left_click)
script.on_event("FAS-right-click", gui.on_right_click)
-- script.on_event(defines.events.on_gui_text_changed, gui.on_gui_event)