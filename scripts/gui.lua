local modGui = require("mod-gui")
local gui = {}

-- handler methods have to be called the same as the element that shall trigger them
local flowButtonName = "togglegui"
local mainFrameName = "guiFrame"

local function initializeAllConnectedPlayers()
    for _, player in pairs(game.connected_players) do
        gui.initialize(player)
    end
end

function gui.initialize(player)
    log(l.info("initializing gui for player " .. player.index))
    local buttonFlow = modGui.get_button_flow(player)
    
    -- destroying already existing buttons in case of changes
    local flowButton = buttonFlow[flowButtonName]
    if flowButton then
        flowButton.destroy()
    end
    -- adding the button
    buttonFlow.add{
        type = "sprite-button",
        name = flowButtonName,
        sprite = "FAS-icon",
        visibility = true;
    }
    
    -- destroying already existing gui in case of changes
    local mainFrame = player.gui.screen[mainFrameName]
    if mainFrame then
        mainFrame.destroy()
    end
end



--[[ GUI CREATION CHAOS ]]--
local function buildHeader(guiFrame)
    local header = guiFrame.add{ type = "flow" }
    header.style.horizontal_spacing = 8
    header.drag_target = guiFrame

    local title = header.add{
        type = "label",
        style = "frame_title",
        caption = {"FAS-screenshot-toolkit-panel"}
    }
    title.drag_target = guiFrame
    local dragHandle = header.add{
        type = "empty-widget",
        style = "fas_draghandle"
    }
    dragHandle.drag_target = guiFrame
    header.add{
        type = "sprite-button",
        name = "gui_close",
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        mouse_button_filter = {"left"},
    }
end


-- auto
local function buildAutoHeader(index, auto_header)
    global.gui[index].auto_content_collapse = auto_header.add{
        type = "sprite-button",
        name = "auto_content_collapse",
        style = "fas_expand_button",
        sprite = "utility/collapse",
        hovered_sprite = "utility/collapse_dark",
        clicked_sprite = "utility/collapse_dark",
        mouse_button_filter = {"left"}
    }

    auto_header.add{
        type = "label",
        name = "auto_screenshots_label",
        caption = {"FAS-auto-screenshots-label"},
        style = "caption_label"
    }
end

local function buildAutoStatus(index, auto_content)
    local status_flow = auto_content.add{
        type = "flow",
        name = "status_flow",
        direction = "horizontal",
        style = "fas_flow"
    }
    status_flow.add{
        type = "label",
        name = "status_label",
        caption = {"FAS-status-caption"},
        style = "fas_label"
    }
    global.gui[index].status_value = status_flow.add{
        type = "label",
        name = "status_value",
        caption = gui.getStatusValue()
    }

    local progressbar = auto_content.add{
        type = "progressbar",
        name = "progress",
        visible = "false"
    }
    progressbar.style.width = 334
    global.gui[index].progress_bar = progressbar
end

local function addListitem(index, list, surfacename)
    local list_item = list.add{
        type = "flow",
        name = "surface_listitem_" .. surfacename,
        direction = "horizontal",
        style = "fas_flow"
    }
    local temp = global.auto[index].doSurface[surfacename]
    list_item.add{
        type = "checkbox",
        name = "surface_checkbox_" .. surfacename,
        caption = surfacename,
        state = global.auto[index].doSurface[surfacename] or false
    }
end

local function buildAutoSurface(index, auto_content)
    local surface_flow = auto_content.add{
        type = "flow",
        name = "surface_flow",
        direction = "horizontal"
    }
    surface_flow.add{
        type = "label",
        name = "surface_label",
        caption = {"FAS-surface-label-caption"},
        tooltip = {"FAS-surface-label-tooltip"},
        style = "fas_label_for_list"
    }
    local list = surface_flow.add{
        type = "frame",
        name = "surface_list",
        direction = "vertical",
        style = "fas_list"
    }

    -- making sure nauvis is on top
    addListitem(index, list, "nauvis")
    for _, surface in pairs(game.surfaces) do
        if surface.name ~= "nauvis" then
            addListitem(index, list, surface.name)
        end
    end
end

local function buildAutoResolution(index, auto_screenshot_config)
    local resolution_flow = auto_screenshot_config.add{
        type = "flow",
        name = "do_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    resolution_flow.add{
        type = "label",
        name = "resolution_label",
        caption = {"FAS-resolution-caption"},
        style = "fas_label"
    }

    resolution_flow.add{
        type = "drop-down",
        name = "auto_resolution_value",
        selected_index = global.auto[index].resolution_index,
        items = {"15360x8640 (16K)", "7680x4320 (8K)", "3840x2160 (4K)", "1920x1080 (FullHD)", "1280x720  (HD)"}
    }
end

local function buildAutoInterval(index, auto_screenshot_config)
    local interval_flow = auto_screenshot_config.add{
        type = "flow",
        name = "interval_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    interval_flow.add{
        type = "label",
        name = "interval_label",
        caption = {"FAS-interval-label-caption"},
        style = "fas_label"
    }

    global.gui[index].interval_value = interval_flow.add{
        type = "textfield",
        name = "interval_value",
        tooltip = {"FAS-interval-value-tooltip"},
        text = global.auto[index].interval / 3600,
        numeric = true,
        style = "fas_slim_numeric_output"
    }

    interval_flow.add{
        type = "label",
        name = "interval_unit",
        caption = "min"
    }
end

local function buildAutoSingleTick(index, auto_screenshot_config)
    local single_tick_flow = auto_screenshot_config.add{
        type = "flow",
        name = "single_tick_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    single_tick_flow.add{
        type = "label",
        name = "single_tick_label",
        caption = {"FAS-single-tick-caption"},
        style = "fas_label"
    }

    global.gui[index].single_tick_value = single_tick_flow.add{
        type = "checkbox",
        name = "single_tick_value",
        state = global.auto[index].singleScreenshot
    }
end

local function buildAutoSplittingFactor(index, auto_screenshot_config)
    local splitting_factor_flow = auto_screenshot_config.add{
        type = "flow",
        name = "splitting_factor_flow",
        direction = "horizontal",
        style = "fas_flow",
        visible = not global.auto[index].singleScreenshot
    }
    global.gui[index].splitting_factor_flow = splitting_factor_flow

    splitting_factor_flow.add{
        type = "label",
        name = "splitting_factor_label",
        caption = {"FAS-splitting-factor-caption"},
        tooltip = {"FAS-splitting-factor-tooltip"},
        style = "fas_label"
    }

    splitting_factor_flow.add{
        type = "slider",
        name = "splitting_factor_slider",
        minimum_value = "0",
        maximum_value = "3",
        -- x in 4^x, log_4(x), as log_a(b) is ln(b)/ln(a) -- credits to curiosity!
        value = math.log(global.auto[index].splittingFactor)/math.log(4),
        style = "fas_slider"
    }

    global.gui[index].splitting_factor_value = splitting_factor_flow.add{
        type = "textfield",
        name = "splitting_factor_value",
        text = global.auto[index].splittingFactor,
        numeric = "true",
        enabled = false,
        style = "fas_slim_numeric_output"
    }
end

local function buildAutoScreenshotSection(index, auto_frame)
    buildAutoHeader(index, auto_frame.add{
        type = "flow",
        style = "player_input_horizontal_flow"
    })

    local auto_content = auto_frame.add{
        type = "flow",
        direction = "vertical"
    }
    global.gui[index].auto_content = auto_content

    buildAutoStatus(index, auto_content)
    buildAutoSurface(index, auto_content)
    buildAutoResolution(index, auto_content)
    buildAutoInterval(index, auto_content)
    buildAutoSingleTick(index, auto_content)
    buildAutoSplittingFactor(index, auto_content)
end


-- area
local function buildAreaHeader(index, area_header)
    global.gui[index].area_content_collapse = area_header.add{
        type = "sprite-button",
        name = "area_content_collapse",
        style = "fas_expand_button",
        sprite = "utility/collapse",
        hovered_sprite = "utility/collapse_dark",
        clicked_sprite = "utility/collapse_dark",
        mouse_button_filter = {"left"}
    }

    area_header.add{
        type = "label",
        name = "area_screenshots_label",
        caption = {"FAS-area-screenshots-label"},
        style = "caption_label"
    }
end

local function buildAreaArea(index, area_content)
    local area_select_flow = area_content.add{
        type = "flow",
        name = "area_select_flow",
        direction = "horizontal"
    }

    local area_label = area_select_flow.add{
        type = "label",
        name = "area-label",
        caption = {"FAS-area-caption"},
        tooltip = {"FAS-area-tooltip"}
    }
    area_label.style.top_margin = 4

    global.gui[index].select_area_button = area_select_flow.add{
        type = "sprite-button",
        name = "select_area_button",
        sprite = "FAS-area-select-icon",
        mouse_button_filter = {"left"},
        tooltip = {"FAS-area-select-button-tooltip"},
        style = "tool_button"
    }

    area_select_flow.add{
        type = "sprite-button",
        name = "delete_area_button",
        sprite = "FAS-delete-selection-icon",
        mouse_button_filter = {"left"},
        tooltip = {"FAS-delete-area-button-tooltip"},
        style = "tool_button_red"
    }

    local area_spreader = area_select_flow.add{
        type = "empty-widget",
        name = "area_spreader"
    }
    area_spreader.style.horizontally_stretchable = true

    -- Area select table
    local area_input_table = area_select_flow.add{
        type = "table",
        name = "area_select_table",
        column_count = 4
    }
    area_input_table.add{
        type = "label",
        name = "width-label",
        caption = {"FAS-width-label-caption", ":"}
    }

    local width_value = area_input_table.add{
        type = "textfield",
        name = "width_value",
        numeric = "true",
        text = (global.snip[index].area.width or ""),
        enabled = "false",
        style = "fas_numeric_output"
    }
    global.gui[index].width_value = width_value

    area_input_table.add{
        type = "label",
        name = "height-label",
        caption = {"FAS-height-label-caption", ":"}
    }

    local height_value = area_input_table.add{
        type = "textfield",
        name = "height_value",
        numeric = "true",
        text = (global.snip[index].area.height or ""),
        enabled = "false",
        style = "fas_numeric_output"
    }
    global.gui[index].height_value = height_value

    area_input_table.add{
        type = "label",
        name = "x-label",
        caption = "X:"
    }

    local x_value = area_input_table.add{
        type = "textfield",
        name = "x_value",
        numeric = "true",
        text = (global.snip[index].area.left or ""),
        enabled = "false",
        style = "fas_numeric_output"
    }
    global.gui[index].x_value = x_value


    area_input_table.add{
        type = "label",
        name = "y-label",
        caption = "Y:",
    }

    local y_value = area_input_table.add{
        type = "textfield",
        name = "y_value",
        numeric = "true",
        text = (global.snip[index].area.top or ""),
        enabled = "false",
        style = "fas_numeric_output"
    }
    global.gui[index].y_value = y_value
end

local function buildAreaZoom(index, area_content)
    local zoom_flow = area_content.add{
        type = "flow",
        name = "zoom_flow",
        direction = "horizontal",
        style = "fas_flow"
    }
    zoom_flow.add{
        type = "label",
        name = "zoom_label",
        caption = {"FAS-zoom-label-caption"},
        style = "fas_label"
    }
    global.gui[index].zoom_slider = zoom_flow.add{
        type = "slider",
        name = "zoom_slider",
        maximum_value = "5",
        minimum_value = "0.25",
        value = global.snip[index].zoomLevel,
        value_step = "0.25",
        style = "fas_slider"
    }
    global.gui[index].zoom_value = zoom_flow.add{
        type = "textfield",
        name = "zoom_value",
        text = global.snip[index].zoomLevel,
        numeric = "true",
        allow_decimal = "true",
        enabled = "false",
        style = "fas_slim_numeric_output"
    }
end

local function buildAreaResolution(index, area_content)
    local resolution_flow = area_content.add{
        type = "flow",
        name = "resolution_flow",
        direction = "horizontal",
        style = "fas_flow"
    }
    resolution_flow.add{
        type = "label",
        name = "resolution_label",
        caption = {"FAS-resolution-caption"},
        style = "fas_label"
    }
    global.gui[index].resolution_value = resolution_flow.add{
        type = "label",
        name = "resolution_value",
        caption = global.snip[index].resolution or {"FAS-no-area-selected"}
    }
end

local function buildAreaFilesize(index, area_content)
    local estimated_filesize_flow = area_content.add{
        type = "flow",
        name = "estimated_filesize_flow",
        direction = "horizontal",
        style = "fas_flow"
    }
    estimated_filesize_flow.add{
        type = "label",
        name = "estimated_filesize_label",
        caption = {"FAS-estimated-filesize"},
        style = "fas_label"
    }
    global.gui[index].estimated_filesize_value = estimated_filesize_flow.add{
        type = "label",
        name = "estimated_filesize_value",
        caption = global.snip[index].filesize or "-"
    }
end

local function buildAreaStartButton(index, area_content)
    local agree_flow = area_content.add{
        type = "flow",
        name = "agree_flow",
        direction = "horizontal"
    }
    agree_flow.style.vertical_align = "center"
    local spreader = agree_flow.add{
        type = "empty-widget",
        name = "spreader"
    }
    spreader.style.horizontally_stretchable = true
    global.gui[index].start_area_screenshot_button = agree_flow.add{
        type = "button",
        name = "start_area_screenshot_button",
        caption = {"FAS-start-area-screenshot-button-caption"},
        mouse_button_filter = {"left"},
        enabled = global.snip[index].enableScreenshotButton or false
    }
end

local function buildAreaScreenshotSection(index, area_frame)
    buildAreaHeader(index, area_frame.add{
        type = "flow",
        style = "player_input_horizontal_flow"
    })

    local area_content = area_frame.add{
        type = "flow",
        direction = "vertical"
    }
    global.gui[index].area_content = area_content


    buildAreaArea(index, area_content)
    buildAreaZoom(index, area_content)
    buildAreaResolution(index, area_content)
    buildAreaFilesize(index, area_content)
    
    -- warning
    local warning = area_content.add{
        type = "label",
        name = "warning_label",
        caption = {"FAS-warning"}
    }
    warning.style.width = 334
    warning.style.single_line = false

    buildAreaStartButton(index, area_content)
end

local function createGuiFrame(player)
    log(l.info("creating gui for player " .. player.index))
    
    -- [[ GENERAL ]] --
    global.gui[player.index] = {}
    local guiFrame = player.gui.screen.add{
        type = "frame",
        name = mainFrameName,
        direction = "vertical"
    }
    guiFrame.auto_center = true
    global.gui[player.index].mainFrame = guiFrame

    buildHeader(guiFrame)

    -- content frame below the header
    local content_frame = guiFrame.add{
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "window_content_frame_deep"
    }
    
    buildAutoScreenshotSection(player.index, content_frame.add{
        type = "frame",
        name = "auto_frame",
        direction = "vertical",
        style = "fas_section"
    })

    buildAreaScreenshotSection(player.index, content_frame.add{
        type = "frame",
        name = "area_frame",
        direction = "vertical",
        style = "fas_section"
    })
end
--[[ END GUI CREATION CHAOS ]]--





--[[ EVENT CATCHERS ]]--
local function callHandler(event, suffix)
    local handlerMethod
    if string.find(event.element.name, "surface_checkbox") then
        handlerMethod = gui["surface_checkbox"]
    else
        -- handler methods have to be called the same as the element that shall trigger them
        handlerMethod = gui[event.element.name .. suffix]
    end

    -- if a handler method exists the gui press was for an element of this mod
    if handlerMethod then
        handlerMethod(event)
    end
end

function gui.on_gui_event(event)
    log(l.info("on gui event triggered with element name " .. event.element.name))
    callHandler(event, "")
end

function gui.on_gui_value_changed(event)
    log(l.info("on_gui_value_changed triggered with element name " .. event.element.name))
    callHandler(event, "_value_changed")
end

function gui.on_gui_text_changed(event)
    log(l.info("on gui text changed triggered with element name " .. event.element.name))
    callHandler(event, "_text_changed")
end

function gui.on_gui_selection_state_changed(event)
    log(l.info("on_gui_selection_state_changed event triggered with element name " .. event.element.name))
    callHandler(event, "_selection")
end

function gui.on_pre_surface_deleted(event)
    log(l.info("surface " .. game.get_surface(event.surface_index).name .. " deleted"))
    for _, playerData in pairs(global.auto) do
        local name = game.get_surface(event.surface_index).name
        if playerData.doSurface[name] ~= nil then
            playerData.doSurface[name] = nil
        end
    end
    initializeAllConnectedPlayers()
end

function gui.on_surface_created(event)
    log(l.info("surface " .. game.get_surface(event.surface_index).name .. "created"))
    initializeAllConnectedPlayers()
    basetracker.initializeSurface(game.get_surface(event.surface_index).name)
    shooter.evaluateZoomForAllPlayersAndSurface(game.get_surface(event.surface_index).name)
end

function gui.on_surface_renamed(event)
    log(l.info("surface " .. event.old_name .. " renamed to " .. event.new_name))
    for _, playerData in pairs(global.auto) do
        if playerData.doSurface[event.old_name] ~= nil then
            playerData.doSurface[event.new_name] = playerData.doSurface[event.old_name]
            playerData.doSurface[event.old_name] = nil
        end
    end
    initializeAllConnectedPlayers()
    basetracker.initializeSurface(game.get_surface(event.surface_index).name)
    shooter.evaluateZoomForAllPlayersAndSurface(game.get_surface(event.surface_index).name)
end

function gui.on_surface_imported(event)
    log(l.info("surface " .. event.original_name .. " imported with name " .. game.get_surface(event.surface_index).name))

    initializeAllConnectedPlayers()
    basetracker.initializeSurface(game.get_surface(event.surface_index).name)
    shooter.evaluateZoomForAllPlayersAndSurface(game.get_surface(event.surface_index).name)
end


--[[ HANDLER METHODS ]]--
function gui.togglegui(event)
    log(l.info("toggling gui"))
    local player = game.get_player(event.player_index)
    local guiFrame = player.gui.screen[mainFrameName]
    if not guiFrame then
        createGuiFrame(player)
        
    else
        if not guiFrame.visible and not global.auto.amount then
                gui.refreshStatusCountdown()
        end
        guiFrame.visible = not guiFrame.visible
    end

    if not guiFrame or guiFrame.visible then
        log(l.info("gui is now visible"))
    else
        log(l.info("gui is now hidden"))
    end
end

function gui.gui_close(event)
    gui.togglegui(event)
end

function gui.auto_content_collapse(event)
    if global.gui[event.player_index].auto_content.visible then
        global.gui[event.player_index].auto_content_collapse.sprite = "utility/expand"
        global.gui[event.player_index].auto_content_collapse.hovered_sprite = "utility/expand_dark"
        global.gui[event.player_index].auto_content_collapse.clicked_sprite = "utility/expand_dark"
    else
        global.gui[event.player_index].auto_content_collapse.sprite = "utility/collapse"
        global.gui[event.player_index].auto_content_collapse.hovered_sprite = "utility/collapse_dark"
        global.gui[event.player_index].auto_content_collapse.clicked_sprite = "utility/collapse_dark"
    end
    global.gui[event.player_index].auto_content.visible = not global.gui[event.player_index].auto_content.visible
end

function gui.area_content_collapse(event)
    if global.gui[event.player_index].area_content.visible then
        global.gui[event.player_index].area_content_collapse.sprite = "utility/expand"
        global.gui[event.player_index].area_content_collapse.hovered_sprite = "utility/expand_dark"
        global.gui[event.player_index].area_content_collapse.clicked_sprite = "utility/expand_dark"
    else
        global.gui[event.player_index].area_content_collapse.sprite = "utility/collapse"
        global.gui[event.player_index].area_content_collapse.hovered_sprite = "utility/collapse_dark"
        global.gui[event.player_index].area_content_collapse.clicked_sprite = "utility/collapse_dark"
    end
    global.gui[event.player_index].area_content.visible = not global.gui[event.player_index].area_content.visible

end

-- transform this to surface selection handling
function gui.surface_checkbox(event)
    log(l.info("surface_checkbox was triggered for player " .. event.player_index))
    global.auto[event.player_index].doSurface[event.element.caption] = event.element.state
    
    if global.auto[event.player_index].zoomLevel[event.element.caption] == nil then
        if l.doD then log(l.debug("Zoomlevel was nil when changing surface selection")) end
        shooter.evaluateZoomForPlayerAndAllSurfaces(event.player_index)
    end
    queue.refreshNextScreenshotTimestamp()
    gui.refreshStatusCountdown()
end

function gui.auto_resolution_value_selection(event)
    log(l.info("resolution setting was changed for player " .. event.player_index))
    local resolution_index = event.element.selected_index
    if resolution_index == 1 then
        global.auto[event.player_index].resolution_index = 1
        global.auto[event.player_index].resX = 7680;
        global.auto[event.player_index].resY = 4320;
    elseif resolution_index == 2 then
        global.auto[event.player_index].resolution_index = 2
        global.auto[event.player_index].resX = 3840
        global.auto[event.player_index].resY = 2160
    elseif resolution_index == 3 then
        global.auto[event.player_index].resolution_index = 3
        global.auto[event.player_index].resX = 1920
        global.auto[event.player_index].resY = 1080
    elseif resolution_index == 4 then
        global.auto[event.player_index].resolution_index = 4
        global.auto[event.player_index].resX = 1280
        global.auto[event.player_index].resY = 720
    end
    global.auto[event.player_index].zoom = {}
    global.auto[event.player_index].zoomLevel = {}
    shooter.evaluateZoomForPlayerAndAllSurfaces(event.player_index)
end

function gui.interval_value_text_changed(event)
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

function gui.single_tick_value(event)
    log(l.info(("single tick value was changed for player " .. event.player_index)))
    local doesSingle = event.element.state
    global.auto[event.player_index].singleScreenshot = doesSingle
    global.gui[event.player_index].splitting_factor_flow.visible = not doesSingle
    
end

function gui.splitting_factor_slider_value_changed(event)
    log(l.info("splitting factor was changed for player " .. event.player_index))
    local splittingFactor = math.pow(4, event.element.slider_value)
    global.auto[event.player_index].splittingFactor = splittingFactor
    global.gui[event.player_index].splitting_factor_value.text = tostring(splittingFactor)
end

function gui.select_area_button(event)
    log(l.info("select area button was clicked"))
    global.snip[event.player_index].doesSelection = not global.snip[event.player_index].doesSelection
    
    if global.snip[event.player_index].doesSelection then
        log(l.info("turned on"))
        --swap styles of button
        global.gui[event.player_index].select_area_button.style = "fas_clicked_tool_button"
        --change this as the player is not correctly fetched
        game.get_player(event.player_index).cursor_stack.set_stack{
            name = "FAS-selection-tool"
          }
    else
        log(l.info("turned off"))
        --swap styles of button
        global.gui[event.player_index].select_area_button.style = "tool_button"
        game.get_player(event.player_index).cursor_stack.clear()
    end
end

local function refreshStartHighResScreenshotButton(index)
    -- {1, 16384}
    local zoom = 1 / global.snip[index].zoomLevel
    if not global.snip[index].area then
        global.snip[index].enableScreenshotButton = false
        global.gui[index].start_area_screenshot_button.enabled = false
    else
        local resX = math.floor((global.snip[index].area.right - global.snip[index].area.left) * 32 * zoom)
        local resY = math.floor((global.snip[index].area.bottom - global.snip[index].area.top) * 32 * zoom)
        
        local enable = resX < 16385 and resY < 16385
        global.snip[index].enableScreenshotButton = enable
        global.gui[index].start_area_screenshot_button.enabled = enable
    end
end

local function refreshEstimates(index)
    if not global.snip[index].area then
        -- happens if the zoom slider is moved before an area was selected so far
        global.snip[index].resolution = nil
        global.snip[index].filesize = nil
        global.gui[index].resolution_value.caption = {"FAS-no-area-selected"}
        global.gui[index].estimated_filesize_value.caption = "-"
        return
    end

    local zoom = 1 / global.snip[index].zoomLevel
    local width = math.floor((global.snip[index].area.right - global.snip[index].area.left) * 32 * zoom)
    local height = math.floor((global.snip[index].area.bottom - global.snip[index].area.top) * 32 * zoom)
    
    local bytesPerPixel = 3
    local size = bytesPerPixel * width * height

    if size > 999999999 then
        size = (math.floor(size / 100000000) / 10) .. " GiB"
    elseif size > 999999 then
        size = (math.floor(size / 100000) / 10) .. " MiB"
    elseif size > 999 then
        size = (math.floor(size / 100) / 10) .. " KiB"
    else
        size = size .. " B"
    end
    
    local resolution = width .. "x" .. height
    global.snip[index].resolution = resolution
    global.snip[index].filesize = size
    global.gui[index].resolution_value.caption = resolution
    global.gui[index].estimated_filesize_value.caption = size
end

function gui.delete_area_button(event)
    local index = event.player_index
    if global.snip[index].area then
        global.snip[index].area = nil
    end
    if global.snip[index].areaLeftClick then
        global.snip[index].areaLeftClick = nil
    end
    if global.snip[index].areaRightClick then
        global.snip[index].areaRightClick = nil
    end
    if global.snip[index].rec then
        rendering.destroy(global.snip[index].rec)
        global.snip[index].rec = nil
    end

    global.gui[index].x_value.text = ""
    global.gui[index].y_value.text = ""
    global.gui[index].width_value.text = ""
    global.gui[index].height_value.text = ""

    refreshEstimates(index)
    refreshStartHighResScreenshotButton(event.player_index)
end

function gui.start_area_screenshot_button(event)
    log(l.info("start high res screenshot button was pressed"))
    local index = event.player_index

    shooter.renderAreaScreenshot(index)
end

function gui.zoom_slider_value_changed(event)
    log(l.info("zoom slider was moved"))
    local level = event.element.slider_value
    global.gui[event.player_index].zoom_value.text = tostring(level)
    global.snip[event.player_index].zoomLevel = level
    refreshEstimates(event.player_index)
    refreshStartHighResScreenshotButton(event.player_index)
end

local function calculateArea(index)
    if global.snip[index].areaLeftClick == nil and global.snip[index].areaRightClick == nil then
        log(l.warn("something went wrong when calculating selected area, aborting"))
        return
    end

    local top
    local left
    local bottom
    local right

    if global.snip[index].areaLeftClick then
        top = global.snip[index].areaLeftClick.y
        left = global.snip[index].areaLeftClick.x
    end
    if global.snip[index].areaRightClick then
        bottom = global.snip[index].areaRightClick.y
        right = global.snip[index].areaRightClick.x
    end

    if not top then
        top = bottom
        left = right
    elseif not bottom then
        bottom = top
        right = left
    end

    if left > right then
        local temp = left
        left = right
        right = temp
    end

    if top > bottom then
        local temp = bottom
        bottom = top
        top = temp
    end

    --rounding the limits
    top = math.floor(top)
    left = math.floor (left)
    right = math.ceil(right)
    bottom = math.ceil(bottom)
    local width = right - left
    local height = bottom - top

    if not global.snip[index].area then
        global.snip[index].area = {}
    end
    global.snip[index].area.top = top
    global.snip[index].area.left = left
    global.snip[index].area.right = right
    global.snip[index].area.bottom = bottom
    global.snip[index].area.width = width
    global.snip[index].area.height = height
 
    global.gui[index].x_value.text = tostring(left)
    global.gui[index].y_value.text = tostring(top)
    global.gui[index].width_value.text = tostring(width)
    global.gui[index].height_value.text = tostring(height)
    
    if global.snip[index].rec then
        rendering.destroy(global.snip[index].rec)
    end
    global.snip[index].rec = rendering.draw_rectangle{
        color = {0.5, 0.5, 0.5, 0.5},
        width = 1,
        filled = false,
        left_top = {left, top},
        right_bottom = {right, bottom},
        players = {index},
        surface = "nauvis"
    }
    
end

function gui.on_left_click(event)
    if global.snip[event.player_index].doesSelection then
        log(l.info("left click event fired while doing selection"))
        global.snip[event.player_index].areaLeftClick = event.cursor_position
        calculateArea(event.player_index)
        refreshEstimates(event.player_index)
        refreshStartHighResScreenshotButton(event.player_index)
    end
end

function gui.on_right_click(event)
    if global.snip[event.player_index].doesSelection then
        log(l.info("right click event fired while doing selection"))
        global.snip[event.player_index].areaRightClick = event.cursor_position
        calculateArea(event.player_index)
        refreshEstimates(event.player_index)
        refreshStartHighResScreenshotButton(event.player_index)
    end
end

function gui.on_player_cursor_stack_changed(event)
    log(l.info("player " .. event.player_index .. " cursor stack changed"))
    local index = event.player_index
    if global.snip[index].doesSelection then
        local stack = game.get_player(index).cursor_stack
        if stack and (not stack.valid_for_read or stack.name ~= "FAS-selection-tool") then
            log(l.info("reverting to not selecting area"))
            global.snip[index].doesSelection = false
            global.gui[index].select_area_button.style = "tool_button"
        end
    end
end

--[[ END HANDLER METHODS ]]--



function gui.getStatusValue()
    if global.auto.amount then
        return global.auto.amount .. " / " .. global.auto.total
    end

end

function gui.setStatusValue(amount, total)
    global.auto.amount = amount
    global.auto.total = total
    global.auto.progressValue = amount / total
    for index, player in pairs(global.gui) do
        if l.doD then log(l.debug("player " .. index .. " found")) end
        if l.doD then log(l.debug("player.mainframe nil? " .. (player.mainFrame == nil and "true" or "false"))) end
        if player.mainFrame and player.mainFrame.valid and player.mainFrame.visible then
            if l.doD then log(l.debug("setting status value for player " .. index .. " with amount " .. amount .. " / " .. total)) end
            player.status_value.caption = amount .. " / " .. total
            if player.progress_bar.visible == false then
                player.progress_bar.visible = true
            end
            player.progress_bar.value = global.auto.progressValue
        end
        -- set flowbutton pie progress value
    end
end

local function calculateCountdown()
    if global.queue.nextScreenshotTimestamp ~= nil then
        local timediff = (global.queue.nextScreenshotTimestamp - game.tick) / 60

        local diffSec = math.floor(timediff % 60)
        if timediff > 59 then
            local diffMin = math.floor(timediff / 60) % 60
            return diffMin .. "min " .. diffSec .. "s"
        else
            return diffSec .. "s"
        end
    else
        return "-"
    end
end

function gui.refreshStatusCountdown()
    --reset status values if still present, necessary on the first time the cooldown is set
    if global.auto.amount then
        global.auto.amount = nil
        global.auto.total = nil
        global.auto.progressValue = nil
        for _, player in pairs(global.gui) do
            if player.progress_bar and player.progress_bar.valid then
                player.progress_bar.visible = false
            end
            -- reset flowbutton pie progress value
        end
    end
    
    local countdown = calculateCountdown()
    for index, player in pairs(global.gui) do
        if player.mainFrame and player.mainFrame.valid and player.mainFrame.visible then
            -- when the status is '-' this would always refresh without the if here
            if (player.status_value.caption ~= countdown) then
                if l.doD then log(l.debug("setting status value for player " .. index .. " with countdown " .. countdown)) end
                player.status_value.caption = countdown
            end
        end
    end
end


return gui