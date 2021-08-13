local modGui = require("mod-gui")
local guiBuilder = require("guibuilder")

local gui = {}

local function initializeAllConnectedPlayers()
    for _, player in pairs(game.connected_players) do
        gui.initialize(player)
    end
end

function gui.initialize(player)
    log(l.info("initializing gui for player " .. player.index))
    local buttonFlow = modGui.get_button_flow(player)
    
    -- destroying already existing buttons in case of changes
    local flowButton = buttonFlow[guiBuilder.flowButtonName]
    if flowButton then
        flowButton.destroy()
    end
    -- adding the button
    buttonFlow.add{
        type = "sprite-button",
        name = guiBuilder.flowButtonName,
        sprite = "FAS-icon",
        visibility = true;
    }
    
    -- destroying already existing gui in case of changes
    local mainFrame = player.gui.screen[guiBuilder.mainFrameName]
    if mainFrame then
        mainFrame.destroy()
    end
end





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
local function refreshStartHighResScreenshotButton(index)
    -- {1, 16384}
    local zoom = 1 / global.snip[index].zoomLevel
    if not global.snip[index].area.width then
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
    if not global.snip[index].area.width then
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



function gui.togglegui(event)
    log(l.info("toggling gui"))
    local player = game.get_player(event.player_index)
    local guiFrame = player.gui.screen[guiBuilder.mainFrameName]
    if not guiFrame then
        guiBuilder.createGuiFrame(player)
        
    else
        if not guiFrame.visible and not global.auto.amount then
            gui.refreshStatusCountdown()
        end
        guiFrame.visible = not guiFrame.visible
    end
    
    
    if not guiFrame or guiFrame.visible then
        log(l.info("gui is now visible"))
        if global.snip[event.player_index].area.width then
            refreshEstimates(event.player_index)
            refreshStartHighResScreenshotButton(event.player_index)
        end
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
        -- happens if the shortcut was clicked before the ui was created
        if global.gui[event.player_index] then
            --swap styles of button
            global.gui[event.player_index].select_area_button.style = "fas_clicked_tool_button"
        end
        --change this as the player is not correctly fetched
        game.get_player(event.player_index).cursor_stack.set_stack{
            name = "FAS-selection-tool"
          }
    else
        log(l.info("turned off"))
        -- happens if the shortcut was clicked before the ui was created
        if global.gui[event.player_index] then
            --swap styles of button
            global.gui[event.player_index].select_area_button.style = "tool_button"
        end
        game.get_player(event.player_index).cursor_stack.clear()
    end
end

function gui.delete_area_button(event)
    log(l.info("delete area button was clicked by player " .. event.player_index))
    local index = event.player_index
    if global.snip[index].area.width then
        global.snip[index].area = {}
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

    -- happens if the ui was not opened before using the delete shortcut
    -- TODO: refactor this with proper event file to get rid of redundant ifs
    if global.gui[index] then
        global.gui[index].x_value.text = ""
        global.gui[index].y_value.text = ""
        global.gui[index].width_value.text = ""
        global.gui[index].height_value.text = ""
        
        refreshEstimates(index)
        refreshStartHighResScreenshotButton(event.player_index)
    end
end

function gui.start_area_screenshot_button(event)
    log(l.info("start high res screenshot button was pressed by player " .. event.player_index))
    local index = event.player_index

    shooter.renderAreaScreenshot(index)
end

function gui.daytime_switch(event)
    log(l.info("daytime switch was switched for player " .. event.player_index .. " to state " .. event.element.switch_state))
    global.snip[event.player_index].daytime_state = event.element.switch_state
end

function gui.show_ui_value(event)
    log(l.info("show ui tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].showUI = event.element.state
    if l.doD then log(l.debug("snip show ui is " .. (global.snip[event.player_index].showUI and "true" or "false"))) end
end

function gui.alt_mode_value(event)
    log(l.info("show alt mode tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].showAltMode = event.element.state
    if l.doD then log(l.debug("snip show alt mode is " .. (global.snip[event.player_index].showAltMode and "true" or "false"))) end
end

function gui.show_cursor_building_preview_value(event)
    log(l.info("show cursor building preview tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].showCursorBuildingPreview = event.element.state
    if l.doD then log(l.debug("snip show cursor building preview is " .. (global.snip[event.player_index].showCursorBuildingPreview and "true" or "false"))) end
end

function gui.use_anti_alias_value(event)
    log(l.info("use anti alias tickbox was clicked for player " .. event.player_index))
    global.snip[event.player_index].useAntiAlias = event.element.state
    if l.doD then log(l.debug("snip ue anti alias is " .. (global.snip[event.player_index].useAntiAlias and "true" or "false"))) end
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
 
    -- happens if the shortcuts were pressed before the ui was opened
    if global.gui[index] then
        global.gui[index].x_value.text = tostring(left)
        global.gui[index].y_value.text = tostring(top)
        global.gui[index].width_value.text = tostring(width)
        global.gui[index].height_value.text = tostring(height)
    end
    
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
        log(l.info("left click event fired while doing selection by player " .. event.player_index))
        global.snip[event.player_index].areaLeftClick = event.cursor_position
        calculateArea(event.player_index)
        
        if global.gui[event.player_index] then
            refreshEstimates(event.player_index)
            refreshStartHighResScreenshotButton(event.player_index)
        end
    end
end

function gui.on_right_click(event)
    if global.snip[event.player_index].doesSelection then
        log(l.info("right click event fired while doing selection by player " .. event.player_index))
        global.snip[event.player_index].areaRightClick = event.cursor_position
        calculateArea(event.player_index)

        
        if global.gui[event.player_index] then
            refreshEstimates(event.player_index)
            refreshStartHighResScreenshotButton(event.player_index)
        end
    end
end

function gui.on_selection_toggle(event)
    log(l.info("selection toggle shortcut was triggered by player " .. event.player_index))
    if global.snip[event.player_index].doesSelection and global.snip[event.player_index].area.width then
        shooter.renderAreaScreenshot(event.player_index)
    end
    gui.select_area_button(event)
end

function gui.on_delete_area(event)
    log(l.info("delete area shortcut was triggered by player " .. event.player_index))
    gui.delete_area_button(event)
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
    else
        return "-"
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