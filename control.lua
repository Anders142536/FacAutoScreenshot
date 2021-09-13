local basetracker = require("scripts.basetracker")
local gui = require("scripts.gui")
local l = require("scripts.logger")
local queue = require("scripts.queue")
local shooter = require("scripts.shooter")
local snip = require("scripts.snip")

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

	if not global.snip[index].output_format_index then global.snip[index].output_format_index = 1 end
	log(l.info("snip output format index is " .. global.snip[index].output_format_index))

	if not global.snip[index].jpg_quality then global.snip[index].jpg_quality = 100 end
	log(l.info("jpg quality is " .. global.snip[index].jpg_quality))


	shooter.evaluateZoomForPlayerAndAllSurfaces(index)
end

local function initializePlayer(player)
	loadDefaultsForPlayer(player.index)
	queue.initialize(player.index)
	gui.initialize(player)
end

-- this method resets everything to a default state apart from already registered screenshots or user settings
local function initialize()
	log(l.info("initialize"))

    global.verbose = settings.global["FAS-enable-debug"].value
	if not global.auto then global.auto = {} end
	if not global.snip then global.snip = {} end
	global.tracker = {}
	global.gui = {}
	global.flowButton = {}
	if not global.queue then global.queue = {} end

	for _, surface in pairs(game.surfaces) do
		basetracker.initializeSurface(surface.name)
	end

	for _, player in pairs(game.connected_players) do
		log(l.info("found player: " .. player.name))
		initializePlayer(player)
	end

	queue.refreshNextScreenshotTimestamp()
end



--#region -~[[ EVENT HANDLERS ]]~-
local function on_init(event)
	l.info("on init triggered")
	initialize()
end

local function on_configuration_changed(event)
	if event.mod_changes.FacAutoScreenshot then
		l.info("configuration of FAS changed")
		initialize()
	end
end

local function on_runtime_mod_setting_changed(event)
	if event.setting_type == "runtime-global" then
        global.verbose = settings.global["FAS-enable-debug"].value
		log(l.info("debug mode is now " .. (l.doD() and "on" or "off")))
	end
end

local function on_nth_tick(event)
	log(l.info("on nth tick"))
	-- if something was built in the last minute that should cause a recalc of all zoom levels
	basetracker.checkForMinMaxChange()

	local newRegistrations = false
	for _, player in pairs(game.connected_players) do

		if l.doD then log(l.debug("player ", player.name, " with index ", player.index, " found")) end
		if l.doD then log(l.debug("do screenshot:   ", queue.doesAutoScreenshot(player.index))) end
		if l.doD then log(l.debug("interval:        ", global.auto[player.index].interval)) end
		if l.doD then log(l.debug("singleScreenshot:", global.auto[player.index].singleScreenshot)) end
		if l.doD then log(l.debug("tick:            ", game.tick)) end

		if queue.doesAutoScreenshot(player.index) and (event.tick % global.auto[player.index].interval == 0) then
			queue.registerPlayerToQueue(player.index)
			newRegistrations = true
		end
	end

	if newRegistrations then queue.refreshNextScreenshotTimestamp() end
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

local function on_player_joined_game(event)
	log(l.info("player " .. event.player_index .. " joined"))
	initializePlayer(game.get_player(event.player_index))
	queue.refreshNextScreenshotTimestamp()
end

local function on_player_left_game(event)
	log(l.info("player " .. event.player_index .. " left"))
	queue.refreshNextScreenshotTimestamp()
end

local function on_player_cursor_stack_changed(event)
    log(l.info("on_player_cursor_stack_changed triggered for player " .. event.player_index))
    local index = event.player_index
    if global.snip[index].doesSelection then
        local stack = game.get_player(index).cursor_stack
        if stack and (not stack.valid_for_read or stack.name ~= "FAS-selection-tool") then
            log(l.info("reverting to not selecting area"))
            global.snip[index].doesSelection = false
            gui.unhighlightSelectAreaButton(index)
        end
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




--#region  gui event handlers
local handlers = {}
function handlers.gui_close_click(event)
    gui.togglegui(event)
end

function handlers.on_selection_toggle_button_click(event)
	log(l.info("select area button was clicked by player " .. event.player_index))
	local index = event.player_index
	global.snip[index].doesSelection = not global.snip[index].doesSelection

	if global.snip[index].doesSelection then
		gui.givePlayerSelectionTool(index)
		gui.highlightSelectAreaButton(index)
	else
		gui.clearPlayerCursorStack(index)
		gui.unhighlightSelectAreaButton(index)
		if global.snip[index].area.width then
			shooter.renderAreaScreenshot(index)
		end
	end
end

function handlers.on_delete_area_button_click(event)
	log(l.info("delete area button was clicked by player " .. event.player_index))
	snip.resetArea(event.player_index)
	gui.resetAreaValues(event.player_index)
	gui.refreshEstimates(event.player_index)
	gui.refreshStartHighResScreenshotButton(event.player_index)
end

function handlers.area_content_collapse_click(event)
	log(l.info("area_content_collapse was clicked by player " .. event.player_index))
	gui.toggle_area_content_area(event.player_index)
end

function handlers.auto_content_collapse_click(event)
	log(l.info("auto_content_collapse was clicked by player " .. event.player_index))
	gui.toggle_auto_content_area(event.player_index)
end

--#endregion gui event handlers


-- #region gui event handler picker
local function callHandler(event, suffix)
    local handlerMethod

	if string.find(event.element.name, "surface_checkbox") then
        handlerMethod = handlers["surface_checkbox"]
    else
        -- handler methods have to be called the same as the element that shall trigger them
        handlerMethod = handlers[event.element.name .. suffix]
    end

    -- if a handler method exists the gui press was for an element of this mod
    if handlerMethod then
        handlerMethod(event)
	else
		log(l.warn("Couldn't find handler method " .. event.element.name .. suffix))
    end
end

local function on_gui_click(event)
    log(l.info("on_gui_click triggered with element name " .. event.element.name))
    callHandler(event, "_click")
end

local function on_gui_value_changed(event)
    log(l.info("on_gui_value_changed triggered with element name " .. event.element.name))
    callHandler(event, "_value_changed")
end

local function on_gui_text_changed(event)
    log(l.info("on_gui_text changed triggered with element name " .. event.element.name))
    callHandler(event, "_text_changed")
end

local function on_gui_selection_state_changed(event)
    log(l.info("on_gui_selection_state_changed event triggered with element name " .. event.element.name))
    callHandler(event, "_selection")
end
--#endregion


-- #region shortcuts handlers
local function handleAreaChange(index)
    gui.calculateArea(index)
        
    if global.gui[index] then
        gui.refreshEstimates(index)
        gui.refreshStartHighResScreenshotButton(index)
    end
end

local function on_left_click(event)
    log(l.info("left click event fired while doing selection by player " .. event.player_index))
    global.snip[event.player_index].areaLeftClick = event.cursor_position
	handleAreaChange(event.player_index)
end

local function on_right_click(event)
    if global.snip[event.player_index].doesSelection then
        log(l.info("right click event fired while doing selection by player " .. event.player_index))
        global.snip[event.player_index].areaRightClick = event.cursor_position
		handleAreaChange(event.player_index)
    end
end

local function on_selection_toggle(event)
	log(l.info("selection toggle shortcut was triggered by player " .. event.player_index))
end

local function on_delete_area(event)
    on_delete_area_button_click(event)
end
-- #endregion


--#region surfaces
local function on_pre_surface_deleted(event)
    log(l.info("surface " .. game.get_surface(event.surface_index).name .. " deleted"))

    -- delete entries of deleted surface
    for _, playerData in pairs(global.auto) do
        local name = game.get_surface(event.surface_index).name
        if playerData.doSurface[name] ~= nil then
            playerData.doSurface[name] = nil
        end
    end

    gui.initializeAllConnectedPlayers(queue.hasAnyEntries())
end

local function on_surface_created(event)
    log(l.info("surface " .. game.get_surface(event.surface_index).name .. "created"))
    gui.initializeAllConnectedPlayers(queue.hasAnyEntries())
    basetracker.initializeSurface(game.get_surface(event.surface_index).name)
    shooter.evaluateZoomForAllPlayersAndSurface(game.get_surface(event.surface_index).name)
end

local function on_surface_imported(event)
    log(l.info("surface " .. event.original_name .. " imported with name " .. game.get_surface(event.surface_index).name))

    gui.initializeAllConnectedPlayers(queue.hasAnyEntries())
    basetracker.initializeSurface(game.get_surface(event.surface_index).name)
    shooter.evaluateZoomForAllPlayersAndSurface(game.get_surface(event.surface_index).name)
end

local function on_surface_renamed(event)
    log(l.info("surface " .. event.old_name .. " renamed to " .. event.new_name))
    for _, playerData in pairs(global.auto) do
        if playerData.doSurface[event.old_name] ~= nil then
            playerData.doSurface[event.new_name] = playerData.doSurface[event.old_name]
            playerData.doSurface[event.old_name] = nil
        end
    end
    gui.initializeAllConnectedPlayers(queue.hasAnyEntries())
    shooter.evaluateZoomForAllPlayersAndSurface(game.get_surface(event.surface_index).name)
	basetracker.on_surface_renamed(event)
end
--#endregion


--#endregion


--#region -~[[ EVENT REGISTRATION ]]~-
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)

script.on_nth_tick(3600, on_nth_tick)
script.on_event(defines.events.on_tick, on_tick)

script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_player_left_game, on_player_left_game)
script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)

-- gui events
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_value_changed, on_gui_value_changed)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)

-- shortcuts
script.on_event("FAS-left-click", on_left_click)
script.on_event("FAS-right-click", on_right_click)
script.on_event("FAS-selection-toggle-shortcut", on_selection_toggle)
script.on_event("FAS-delete-area-shortcut", on_delete_area)

-- surfaces
script.on_event(defines.events.on_pre_surface_deleted, on_pre_surface_deleted)
script.on_event(defines.events.on_surface_created, on_surface_created)
script.on_event(defines.events.on_surface_imported, on_surface_imported)
script.on_event(defines.events.on_surface_renamed, on_surface_renamed)
--#endregion