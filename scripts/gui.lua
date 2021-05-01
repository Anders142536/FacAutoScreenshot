local modGui = require("mod-gui")
local gui = {}

-- handler methods have to be called the same as the element that shall trigger them
local flowButtonName = "togglegui"
local mainFrameName = "guiFrame"

function gui.initialize(player)
    log("initializing gui for player " .. player.index)
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



--[[ EVENT CATCHERS ]]--
function gui.on_gui_event(event)
    log("on gui event triggered with element name " .. event.element.name)

    -- handler methods have to be called the same as the element that shall trigger them
    local handlerMethod = gui[event.element.name]

    -- if a handler method exists the gui press was for an element of this mod
    if handlerMethod then
        handlerMethod(event)
    end
end



--[[ HANDLER METHODS ]]--
function gui.togglegui(event)
    log("toggling gui")
    local player = game.get_player(event.player_index)
    local guiFrame = player.gui.screen[mainFrameName]
    if not guiFrame then
        gui.createGuiFrame(player)
    else
        if guiFrame.visible then
            log("guiframe was visible")
            -- if we hide the gui, the tick on the "I understand" checkbox is removed, so that the user has to click it again the next time
            if global.snip.doesUnderstand[event.player_index] then
                global.snip.doesUnderstand[event.player_index] = false
                global.gui[event.player_index].agree_checkbox.state = false
                global.gui[event.player_index].start_area_screenshot_button.enabled = false
            end
            guiFrame.visible = false
        else
            log("guiframe was not visible")
            guiFrame.visible = true
            if not gui.amount then
                gui.refreshStatusCountdown()
            end
        end
    end
end

function gui.gui_close(event)
    gui.togglegui(event)
end

function gui.select_area_button(event)
    log("select area button was clicked")
    global.snip.doesSelection[event.player_index] = not global.snip.doesSelection[event.player_index]
    
    if global.snip.doesSelection[event.player_index] then
        log("turned on")
        --swap styles of button
        global.gui[event.player_index].select_area_button.style = "fas_clicked_tool_button"
        --change this as the player is not correctly fetched
        game.get_player(event.player_index).cursor_stack.set_stack{
            name = "FAS-selection-tool"
          }
    else
        log("turned off")
        --swap styles of button
        global.gui[event.player_index].select_area_button.style = "tool_button"
        game.get_player(event.player_index).cursor_stack.clear()
    end
end

local function refreshStartHighResScreenshotButton(index)
    -- {1, 16384}
    local zoom = 1 / global.snip.zoomLevel[index]
    if not global.snip.area[index] then
        global.gui[index].start_area_screenshot_button.enabled = false
    else
        local resX = math.floor((global.snip.area[index].right - global.snip.area[index].left) * 32 * zoom)
        local resY = math.floor((global.snip.area[index].bottom - global.snip.area[index].top) * 32 * zoom)
        
        global.gui[index].start_area_screenshot_button.enabled = global.snip.doesUnderstand[index]
            and resX < 16385
            and resY < 16385
    end
end

local function refreshEstimates(index)
    if not global.snip.area[index] then
        -- happens if the zoom slider is moved before an area was selected so far
        global.gui[index].resolution_value.caption = {"FAS-no-area-selected"}
        global.gui[index].estimated_filesize_value.caption = "-"
        return
    end

    local zoom = 1 / global.snip.zoomLevel[index]
    local width = math.floor((global.snip.area[index].right - global.snip.area[index].left) * 32 * zoom)
    local height = math.floor((global.snip.area[index].bottom - global.snip.area[index].top) * 32 * zoom)
    
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
    
    global.gui[index].resolution_value.caption = width .. "x" .. height
    global.gui[index].estimated_filesize_value.caption = size
end

function gui.delete_area_button(event)
    local i = event.player_index
    if global.snip.area[i] then
        global.snip.area[i] = nil
    end
    if global.snip.areaLeftClick[i] then
        global.snip.areaLeftClick[i] = nil
    end
    if global.snip.areaRightClick[i] then
        global.snip.areaRightClick[i] = nil
    end
    if global.snip.rec[i] then
        rendering.destroy(global.snip.rec[i])
        global.snip.rec[i] = nil
    end

    global.gui[i].x_value.text = ""
    global.gui[i].y_value.text = ""
    global.gui[i].width_value.text = ""
    global.gui[i].height_value.text = ""

    refreshEstimates(i)
    refreshStartHighResScreenshotButton(event.player_index)
end

local function calculateArea(index)
    if global.snip.areaLeftClick[index] == nil and global.snip.areaRightClick[index] == nil then
        log("something went wrong when calculating selected area, aborting")
        return
    end

    local top
    local left
    local bottom
    local right

    if global.snip.areaLeftClick[index] then
        top = global.snip.areaLeftClick[index].y
        left = global.snip.areaLeftClick[index].x
    end
    if global.snip.areaRightClick[index] then
        bottom = global.snip.areaRightClick[index].y
        right = global.snip.areaRightClick[index].x
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

    if not global.snip.area[index] then
        global.snip.area[index] = {}
    end
    global.snip.area[index].top = top
    global.snip.area[index].left = left
    global.snip.area[index].right = right
    global.snip.area[index].bottom = bottom
 
    global.gui[index].x_value.text = tostring(left)
    global.gui[index].y_value.text = tostring(top)
    global.gui[index].width_value.text = tostring(width)
    global.gui[index].height_value.text = tostring(height)
    
    if global.snip.rec[index] then
        rendering.destroy(global.snip.rec[index])
    end
    global.snip.rec[index] = rendering.draw_rectangle{
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
    log("left click!")
    --remove this
    local player = game.connected_players[1]
    if global.snip.doesSelection[event.player_index] then
        global.snip.areaLeftClick[event.player_index] = event.cursor_position
        calculateArea(event.player_index)
        refreshEstimates(event.player_index)
        refreshStartHighResScreenshotButton(event.player_index)
    end
end

function gui.on_right_click(event)
    log("right click!")
    if global.snip.doesSelection[event.player_index] then
        global.snip.areaRightClick[event.player_index] = event.cursor_position
        calculateArea(event.player_index)
        refreshEstimates(event.player_index)
        refreshStartHighResScreenshotButton(event.player_index)
    end
end

function gui.on_player_cursor_stack_changed(event)
    log("player " .. event.player_index .. " cursor stack changed")
    local i = event.player_index
    if global.snip.doesSelection[i] then
        local stack = game.get_player(i).cursor_stack
        if stack and (not stack.valid_for_read or stack.name ~= "FAS-selection-tool") then
            log("reverting to not selecting area")
            global.snip.doesSelection[i] = false
            global.gui[i].select_area_button.style = "tool_button"
        end
    end
end

function gui.agree_checkbox(event)
    log("i understand was clicked, toggling button and value")
    local state = event.element.state
    global.snip.doesUnderstand[event.player_index] = state
    refreshStartHighResScreenshotButton(event.player_index)
end

function gui.start_area_screenshot_button(event)
    log("start high res screenshot button was pressed")
    local i = event.player_index

    shooter.renderAreaScreenshot(i, global.snip.area[i], global.snip.zoomLevel[i])
end

function gui.zoom_slider(event)
    if (global.verbose) then log("zoom slider was moved") end
    local level = event.element.slider_value
    global.gui[event.player_index].zoom_value.text = tostring(level)
    global.snip.zoomLevel[event.player_index] = level
    refreshEstimates(event.player_index)
    refreshStartHighResScreenshotButton(event.player_index)
end
--[[ END HANDLER METHODS ]]--



function gui.createGuiFrame(player)
    log("creating gui for player " .. player.index)

    --TODO change these into proper styles
    local label_width = 150
    local max_width = 350
    
    -- [[ GENERAL ]] --
    global.gui[player.index] = {}
    local guiFrame = player.gui.screen.add{
        type = "frame",
        name = mainFrameName,
        direction = "vertical"
    }
    guiFrame.auto_center = true
    global.gui[player.index].mainFrame = guiFrame
    local header = guiFrame.add{ type = "flow" }
    header.style.horizontal_spacing = 8
    header.drag_target = guiFrame

    local title = header.add{
        type = "label",
        style = "frame_title",
        caption = "Screenshot Toolkit Panel"
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


    local content_frame = guiFrame.add{
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }

    local vertical_flow = content_frame.add{
        type = "flow",
        name = "vertical_flow",
        direction = "vertical"
    }



    -- [[ AUTO SCREENSHOT AREA ]] --
    vertical_flow.add{
        type = "label",
        name = "auto_screenshots_label",
        caption = "Auto Screenshots",
        style = "caption_label"
    }

    -- status flow
    local status_flow = vertical_flow.add{
        type = "flow",
        name = "status_flow",
        direction = "horizontal"
    }
    local status_label = status_flow.add{
        type = "label",
        name = "status_label",
        caption = {"FAS-status-caption"}
    }
    status_label.style.width = label_width
    global.gui[player.index].status_value = status_flow.add{
        type = "label",
        name = "status_value",
        caption = gui.getStatusValue(player)
    }

    local progressbar = vertical_flow.add{
        type = "progressbar",
        name = "progress",
        visible = "false"
    }
    progressbar.style.width = 350
    global.gui[player.index].progress_bar = progressbar

    -- surface flow
    local surface_flow = vertical_flow.add{
        type = "flow",
        name = "surface_flow",
        direction = "horizontal"
    }
    local surface_label = surface_flow.add{
        type = "label",
        name = "surface_label",
        caption = {"FAS-surface-label-caption"}
    }
    surface_label.style.width = label_width
    surface_flow.add{
        type = "label",
        name = "surface_value",
        caption = {"FAS-surface-value-caption"},
        tooltip = {"FAS-surface-value-tooltip"}
    }

    -- separator line
    local line = vertical_flow.add{ type = "line" }
    line.style.height = 10



    -- [[ AREA SCREENSHOTS AREA ]] --
    vertical_flow.add{
        type = "label",
        name = "area_screenshots_label",
        caption = {"FAS-area-screenshots-label"},
        style = "caption_label"
    }

    -- Area select area
    local area_select_flow = vertical_flow.add{
        type = "flow",
        name = "area_select_flow",
        direction = "horizontal"
    }

    area_select_flow.add{
        type = "label",
        name = "area-label",
        caption = {"FAS-area-caption"},
        tooltip = {"FAS-area-tooltip"}
    }

    global.gui[player.index].select_area_button = area_select_flow.add{
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
        enabled = "false",
        style = "fas_numeric_input"
    }
    global.gui[player.index].width_value = width_value

    area_input_table.add{
        type = "label",
        name = "height-label",
        caption = {"FAS-height-label-caption", ":"}
    }

    local height_value = area_input_table.add{
        type = "textfield",
        name = "height_value",
        numeric = "true",
        enabled = "false",
        style = "fas_numeric_input"
    }
    global.gui[player.index].height_value = height_value

    area_input_table.add{
        type = "label",
        name = "x-label",
        caption = "X:"
    }

    local x_value = area_input_table.add{
        type = "textfield",
        name = "x_value",
        numeric = "true",
        enabled = "false",
        style = "fas_numeric_input"
    }
    global.gui[player.index].x_value = x_value


    area_input_table.add{
        type = "label",
        name = "y-label",
        caption = "Y:",
    }

    local y_value = area_input_table.add{
        type = "textfield",
        name = "y_value",
        numeric = "true",
        enabled = "false",
        style = "fas_numeric_input"
    }
    global.gui[player.index].y_value = y_value

    -- zoom flow
    local zoom_flow = vertical_flow.add{
        type = "flow",
        name = "zoom_flow",
        direction = "horizontal"
    }
    zoom_flow.style.vertical_align = "center"
    local zoom_label = zoom_flow.add{
        type = "label",
        name = "zoom_label",
        caption = {"FAS-zoom-label-caption"}
    }
    zoom_label.style.width = label_width
    local zoom_slider = zoom_flow.add{
        type = "slider",
        name = "zoom_slider",
        maximum_value = "5",
        minimum_value = "0.25",
        value = "1",
        value_step = "0.25",
        style = "notched_slider"
    }
    zoom_slider.style.right_margin = 8
    zoom_slider.style.width = 124
    global.gui[player.index].zoom_slider = zoom_slider
    local zoom_value = zoom_flow.add{
        type = "textfield",
        name = "zoom_value",
        text = "1",
        numeric = "true",
        allow_decimal = "true",
        enabled = "false",
        style = "fas_numeric_input"
    }
    -- zoom_value.style.disabled_font_color = {1, 1, 1}
    global.gui[player.index].zoom_value = zoom_value
    global.snip.zoomLevel[player.index] = 1

    -- estimated resolution flow
    local resolution_flow = vertical_flow.add{
        type = "flow",
        name = "resolution_flow",
        direction = "horizontal"
    }
    local resolution_label = resolution_flow.add{
        type = "label",
        name = "resolution_label",
        caption = {"FAS-resolution-caption"}
    }
    resolution_label.style.width = label_width
    global.gui[player.index].resolution_value = resolution_flow.add{
        type = "label",
        name = "resolution_value",
        caption = {"FAS-no-area-selected"}
    }

    -- estimated filesize flow
    local estimated_filesize_flow = vertical_flow.add{
        type = "flow",
        name = "estimated_filesize_flow",
        direction = "horizontal"
    }
    local estimated_filesize_label = estimated_filesize_flow.add{
        type = "label",
        name = "estimated_filesize_label",
        caption = {"FAS-estimated-filesize"}
    }
    estimated_filesize_label.style.width = label_width
    global.gui[player.index].estimated_filesize_value = estimated_filesize_flow.add{
        type = "label",
        name = "estimated_filesize_value",
        caption = "-"
    }

    -- warning
    local warning = vertical_flow.add{
        type = "label",
        name = "warning_label",
        caption = {"FAS-warning"}
    }
    warning.style.width = max_width
    warning.style.single_line = false

    -- agree flow
    local agree_flow = vertical_flow.add{
        type = "flow",
        name = "agree_flow",
        direction = "horizontal"
    }

    agree_flow.style.vertical_align = "center"
    global.gui[player.index].agree_checkbox = agree_flow.add{
        type = "checkbox",
        name = "agree_checkbox",
        caption = {"FAS-i-understand-caption"},
        state = "false"
    }
    local spreader = agree_flow.add{
        type = "empty-widget",
        name = "spreader"
    }
    spreader.style.horizontally_stretchable = true
    global.gui[player.index].start_area_screenshot_button = agree_flow.add{
        type = "button",
        name = "start_area_screenshot_button",
        caption = {"FAS-start-area-screenshot-button-caption"},
        mouse_button_filter = {"left"},
        enabled = "false"
    }
end

function gui.getStatusValue(player)
    if gui.amount then
        return gui.amount .. " / " .. gui.total
    end

end

function gui.setStatusValue(amount, total)
    gui.amount = amount
    gui.total = total
    gui.progressValue = amount / total
    for index, player in pairs(global.gui) do
        if player.mainFrame.visible then
            if global.verbose then log("setting status value for player " .. index .. " with amount " .. amount .. " / " .. total) end
            player.status_value.caption = amount .. " / " .. total
            if player.progress_bar.visible == false then
                player.progress_bar.visible = true
            end
            player.progress_bar.value = gui.progressValue
        end
        -- set flowbutton pie progress value
    end
end

local function calculateCountdown()
    if (shooter.nextScreenshotTimestamp ~= nil) then
        local timediff = (shooter.nextScreenshotTimestamp - game.tick) / 60

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
    if gui.amount then
        gui.amount = nil
        gui.total = nil
        gui.progressValue = nil
        for _, player in pairs(global.gui) do
            player.progress_bar.visible = false
            -- reset flowbutton pie progress value
        end
    end
    
    local countdown = calculateCountdown()
    for index, player in pairs(global.gui) do
        if player.mainFrame.visible then
            if global.verbose then log("setting status value for player " .. index .. " with countdown " .. countdown) end
            player.status_value.caption = countdown
        end
    end
end


return gui