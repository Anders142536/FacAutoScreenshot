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
	log(l.info("on init triggered"))
	initialize()
end

local function on_configuration_changed(event)
	if event.mod_changes.FacAutoScreenshot then
		log(l.info("configuration of FAS changed"))
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
	if basetracker.checkForMinMaxChange() then
		shooter.evaluateZoomForAllPlayersAndAllSurfaces()
    end

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
		-- shooter.renderNextQueueStep(queue.getNextStep())
		if queue.executeNextStep() then
			gui.setStatusValue()
		else
			gui.refreshStatusCountdown()
		end
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




-- #region  gui event handlers
local handlers = {}

--  #region click handlers
function handlers.togglegui_click(event)
	gui.togglegui(event.player_index)
end

function handlers.gui_close_click(event)
    gui.togglegui(event.player_index)
end

function handlers.auto_content_collapse_click(event)
	log(l.info("auto_content_collapse was clicked by player " .. event.player_index))
	gui.toggle_auto_content_area(event.player_index)
end

function handlers.surface_checkbox_click(event)
    log(l.info("surface_checkbox was triggered for player " .. event.player_index))
    global.auto[event.player_index].doSurface[event.element.caption] = event.element.state
    
    if global.auto[event.player_index].zoomLevel[event.element.caption] == nil then
        if l.doD then log(l.debug("Zoomlevel was nil when changing surface selection")) end
        shooter.evaluateZoomForPlayerAndAllSurfaces(event.player_index)
    end
    queue.refreshNextScreenshotTimestamp()
    gui.refreshStatusCountdown()
end

function handlers.single_tick_value_click(event)
    log(l.info(("single tick value was changed for player " .. event.player_index)))
    local doesSingle = event.element.state
    global.auto[event.player_index].singleScreenshot = doesSingle
    global.gui[event.player_index].splitting_factor_flow.visible = not doesSingle
end

function handlers.area_content_collapse_click(event)
	log(l.info("area_content_collapse was clicked by player " .. event.player_index))
	gui.toggle_area_content_area(event.player_index)
end

function handlers.select_area_button_click(event)
	log(l.info("select area button was clicked by player " .. event.player_index))
	local index = event.player_index
	global.snip[index].doesSelection = not global.snip[index].doesSelection

	if global.snip[index].doesSelection then
		gui.givePlayerSelectionTool(index)
		gui.highlightSelectAreaButton(index)
	else
		gui.clearPlayerCursorStack(index)
		gui.unhighlightSelectAreaButton(index)
	end
end

function handlers.delete_area_button_click(event)
	log(l.info("delete area button was clicked by player " .. event.player_index))
	snip.resetArea(event.player_index)
    snip.calculateEstimates(event.player_index)
    snip.checkIfScreenshotPossible(event.player_index)
    
	gui.resetAreaValues(event.player_index)
	gui.refreshEstimates(event.player_index)
	gui.refreshStartHighResScreenshotButton(event.player_index)
end

function handlers.daytime_switch_click(event)
    log(l.info("daytime switch was switched for player " .. event.player_index .. " to state " .. event.element.switch_state))
    global.snip[event.player_index].daytime_state = event.element.switch_state
end

function handlers.show_ui_value_click(event)
    log(l.info("show ui tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].showUI = event.element.state
    if l.doD then log(l.debug("snip show ui is " .. (global.snip[event.player_index].showUI and "true" or "false"))) end
end

function handlers.alt_mode_value_click(event)
    log(l.info("show alt mode tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].showAltMode = event.element.state
    if l.doD then log(l.debug("snip show alt mode is " .. (global.snip[event.player_index].showAltMode and "true" or "false"))) end
end

function handlers.show_cursor_building_preview_value_click(event)
    log(l.info("show cursor building preview tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].showCursorBuildingPreview = event.element.state
    if l.doD then log(l.debug("snip show cursor building preview is " .. (global.snip[event.player_index].showCursorBuildingPreview and "true" or "false"))) end
end

function handlers.use_anti_alias_value_click(event)
    log(l.info("use anti alias tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].useAntiAlias = event.element.state
    if l.doD then log(l.debug("snip ue anti alias is " .. (global.snip[event.player_index].useAntiAlias and "true" or "false"))) end
end

function handlers.start_area_screenshot_button_click(event)
    log(l.info("start high res screenshot button was pressed by player " .. event.player_index))
    shooter.renderAreaScreenshot(event.player_index)
end


--  #endregion click handlers

--  #region value changed handlers
function handlers.splitting_factor_slider_value_changed(event)
    log(l.info("splitting factor was changed for player " .. event.player_index))
    local splittingFactor = math.pow(4, event.element.slider_value)
    global.auto[event.player_index].splittingFactor = splittingFactor
    global.gui[event.player_index].splitting_factor_value.text = tostring(splittingFactor)
end

function handlers.zoom_slider_value_changed(event)
    log(l.info("zoom slider was moved"))
    local level = event.element.slider_value
    global.gui[event.player_index].zoom_value.text = tostring(level)
    global.snip[event.player_index].zoomLevel = level
    snip.calculateEstimates(event.player_index)
    gui.refreshEstimates(event.player_index)
    gui.refreshStartHighResScreenshotButton(event.player_index)
end

function handlers.area_jpg_quality_slider_value_changed(event)
    log(l.info("quality slider was moved"))
    local level = event.element.slider_value
    global.gui[event.player_index].area_jpg_quality_value.text = tostring(level)
    global.snip[event.player_index].jpg_quality = level
end

--#endregion value changed handlers

--  #region text changed handlers
function handlers.interval_value_text_changed(event)
    log(l.info("interval was changed for player " .. event.player_index))
    local suggestion = tonumber(event.text)
    if suggestion == nil then return end
    if suggestion < 1 or suggestion > 60 then
        event.element.text = tostring(global.auto[event.player_index].interval / 3600)
        return
    end

    global.auto[event.player_index].interval = suggestion * 60 * 60

    queue.refreshNextScreenshotTimestamp()
    gui.refreshStatusCountdown()
end

function handlers.area_output_name_text_changed(event)
    log(l.info("area output name changed"))
    global.snip[event.player_index].outputName = event.element.text
end


--#endregion text changed handlers

--  #region selection handlers
function handlers.auto_resolution_value_selection(event)
    log(l.info("resolution setting was changed for player " .. event.player_index .. " with index " .. event.element.selected_index
))
    local resolution_index = event.element.selected_index
    if resolution_index == 1 then
        global.auto[event.player_index].resolution_index = 1
        global.auto[event.player_index].resX = 15360;
        global.auto[event.player_index].resY = 8640;
    elseif resolution_index == 2 then
        global.auto[event.player_index].resolution_index = 2
        global.auto[event.player_index].resX = 7680;
        global.auto[event.player_index].resY = 4320;
    elseif resolution_index == 3 then
        global.auto[event.player_index].resolution_index = 3
        global.auto[event.player_index].resX = 3840
        global.auto[event.player_index].resY = 2160
    elseif resolution_index == 4 then
        global.auto[event.player_index].resolution_index = 4
        global.auto[event.player_index].resX = 1920
        global.auto[event.player_index].resY = 1080
    elseif resolution_index == 5 then
        global.auto[event.player_index].resolution_index = 5
        global.auto[event.player_index].resX = 1280
        global.auto[event.player_index].resY = 720
    else
        log(l.warn("could not match resolution index " .. resolution_index))
    end
    global.auto[event.player_index].zoom = {}
    global.auto[event.player_index].zoomLevel = {}
    shooter.evaluateZoomForPlayerAndAllSurfaces(event.player_index)
end

function handlers.area_output_format_selection(event)
    log(l.info("area output format changed"))
    global.snip[event.player_index].output_format_index = event.element.selected_index
    global.gui[event.player_index].area_jpg_quality_flow.visible = event.element.selected_index == 2
    gui.refreshEstimates(event.player_index)
end


--  #endregion selection handlers

-- #endregion gui event handlers


-- #region gui event handler picker
local function callHandler(event, suffix)
    local handlerMethod

	if string.find(event.element.name, "surface_checkbox") then
        handlerMethod = handlers["surface_checkbox_click"]
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
-- #endregion gui event handler picker


-- #region shortcuts handlers
local function handleAreaChange(index)
    snip.calculateArea(index)
    snip.calculateEstimates(index)
    snip.checkIfScreenshotPossible(index)
        
    if global.gui[index] then
        gui.refreshAreaValues(index)
        gui.refreshEstimates(index)
        gui.refreshStartHighResScreenshotButton(index)
    end
end

local function on_left_click(event)
    if global.snip[event.player_index].doesSelection then
        log(l.info("left click event fired while doing selection by player " .. event.player_index))
        global.snip[event.player_index].areaLeftClick = event.cursor_position
	    handleAreaChange(event.player_index)
    end
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
    handlers.select_area_button_click(event)

	if not global.snip[event.player_index].doesSelection and global.snip[event.player_index].area.width then
        shooter.renderAreaScreenshot(event.player_index)
	end
end

local function on_delete_area(event)
    handlers.delete_area_button_click(event)
end
-- #endregion


-- #region surfaces
local function on_pre_surface_deleted(event)
    log(l.info("surface " .. game.get_surface(event.surface_index).name .. " deleted"))

    -- delete entries of deleted surface
    for _, player in pairs(game.players) do
        local name = game.get_surface(event.surface_index).name
        if global.auto[player.index].doSurface[name] ~= nil then
            global.auto[player.index].doSurface[name] = nil
        end

        -- if the surface was in queue for a screenshot
        if global.queue[player.index] and global.queue[player.index][name] then
            queue.remove(player.index, name)
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