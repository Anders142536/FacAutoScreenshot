local modGui = require("mod-gui")
local gui = {}

gui.zoomLevels = {}
gui.doesUnderstand = {}
gui.components = {}

-- area selection
gui.doesSelection = {}
gui.areaLeftClick = {}
gui.areaRightClick = {}
-- area selection rectangles. this is needed to be able
-- to delete the old rectangle on creating a new one
gui.rec = {}
gui.areas = {}

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
        sprite = "item/rocket-silo",
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
            if gui.doesUnderstand[event.player_index] then
                gui.doesUnderstand[event.player_index] = false
                gui.components[event.player_index].agree_checkbox.state = false
                gui.components[event.player_index].start_high_res_screenshot_button.enabled = false
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

function gui.select_area_button(event)
    log("select area button was clicked")
    gui.doesSelection[event.player_index] = not gui.doesSelection[event.player_index]
    
    if gui.doesSelection[event.player_index] then
        log("turned on")
        --swap styles of button
        gui.components[event.player_index].select_area_button.style = "fas_clicked_tool_button"
    else
        log("turned off")
        --swap styles of button
        gui.components[event.player_index].select_area_button.style = "tool_button"
    end
end

local function refreshEstimates(index)
    if not gui.areas[index] then
        -- happens if the zoom slider is moved before an area was selected so far
        gui.components[index].estimated_resolution_value.caption = "no area selected"
        gui.components[index].estimated_filesize_value.caption = "-"
        return
    end

    local zoom = 1 / gui.zoomLevels[index]
    local width = math.floor((gui.areas[index].right - gui.areas[index].left) * 32 * zoom)
    local height = math.floor((gui.areas[index].bottom - gui.areas[index].top) * 32 * zoom)
    
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
    
    gui.components[index].estimated_resolution_value.caption = width .. "x" .. height
    gui.components[index].estimated_filesize_value.caption = size
end

function gui.delete_area_button(event)
    local i = event.player_index
    if gui.areas[i] then
        gui.areas[i] = nil
    end
    if gui.areaLeftClick[i] then
        gui.areaLeftClick[i] = nil
    end
    if gui.areaRightClick[i] then
        gui.areaRightClick[i] = nil
    end
    if gui.rec[i] then
        rendering.destroy(gui.rec[i])
        gui.rec[i] = nil
    end

    gui.components[i].x_value.text = ""
    gui.components[i].y_value.text = ""
    gui.components[i].width_value.text = ""
    gui.components[i].height_value.text = ""

    refreshEstimates(i)
end

local function calculateArea(index)
    if gui.areaLeftClick[index] == nil and gui.areaRightClick[index] == nil then
        log("something went wrong when calculating selected area, aborting")
        return
    end

    local top
    local left
    local bottom
    local right

    if gui.areaLeftClick[index] then
        top = gui.areaLeftClick[index].y
        left = gui.areaLeftClick[index].x
    end
    if gui.areaRightClick[index] then
        bottom = gui.areaRightClick[index].y
        right = gui.areaRightClick[index].x
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

    if not gui.areas[index] then
        gui.areas[index] = {}
    end
    gui.areas[index].top = top
    gui.areas[index].left = left
    gui.areas[index].right = right
    gui.areas[index].bottom = bottom
 
    gui.components[index].x_value.text = tostring(left)
    gui.components[index].y_value.text = tostring(top)
    gui.components[index].width_value.text = tostring(width)
    gui.components[index].height_value.text = tostring(height)
    
    if gui.rec[index] then
        rendering.destroy(gui.rec[index])
    end
    gui.rec[index] = rendering.draw_rectangle{
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
    if gui.doesSelection[event.player_index] then
        gui.areaLeftClick[event.player_index] = event.cursor_position
        calculateArea(event.player_index)
        refreshEstimates(event.player_index)
    end
end

function gui.on_right_click(event)
    log("right click!")
    if gui.doesSelection[event.player_index] then
        gui.areaRightClick[event.player_index] = event.cursor_position
        calculateArea(event.player_index)
        refreshEstimates(event.player_index)
    end
end

function gui.agree_checkbox(event)
    log("i understand was clicked, toggling button and value")
    local state = event.element.state
    gui.components[event.player_index].start_high_res_screenshot_button.enabled = state
    gui.doesUnderstand[event.player_index] = state
end

function gui.zoom_slider(event)
    if (global.verbose) then log("zoom slider was moved") end
    local level = event.element.slider_value
    gui.components[event.player_index].zoom_value.text = tostring(level)
    gui.zoomLevels[event.player_index] = level
    refreshEstimates(event.player_index)
end
--[[ END HANDLER METHODS ]]--



function gui.createGuiFrame(player)
    log("creating gui for player " .. player.index)

    --TODO change these into proper styles
    local label_width = 150
    local max_width = 350
    local numeric_input_width = 40
    
    -- [[ GENERAL ]] --
    gui.components[player.index] = {}
    local guiFrame = player.gui.screen.add{
        type = "frame",
        name = mainFrameName,
        caption = "FAS Panel"
    }
    guiFrame.auto_center = true
    gui.components[player.index].mainFrame = guiFrame

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
        caption = "Status"
    }
    status_label.style.width = label_width
    gui.components[player.index].status_value = status_flow.add{
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
    gui.components[player.index].progress_bar = progressbar

    -- surface flow
    local surface_flow = vertical_flow.add{
        type = "flow",
        name = "surface_flow",
        direction = "horizontal"
    }
    local surface_label = surface_flow.add{
        type = "label",
        name = "surface_label",
        caption = "Surface"
    }
    surface_label.style.width = label_width
    surface_flow.add{
        type = "label",
        name = "surface_value",
        caption = "nauvis (default)",
        tooltip = "This is currently unsettable."
    }

    -- separator line
    local line = vertical_flow.add{ type = "line" }
    line.style.height = 10



    -- [[ HIGH RES SCREENSHOTS AREA ]] --
    vertical_flow.add{
        type = "label",
        name = "high_res_screenshots_label",
        caption = "High Resolution Screenshots",
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
        caption = "Area"
    }

    gui.components[player.index].select_area_button = area_select_flow.add{
        type = "sprite-button",
        name = "select_area_button",
        sprite = "FAS-area-select-icon",
        mouse_button_filter = {"left"},
        style = "tool_button"
    }

    area_select_flow.add{
        type = "sprite-button",
        name = "delete_area_button",
        sprite = "FAS-delete-selection-icon",
        mouse_button_filter = {"left"},
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
        caption = "Width"
    }

    local width_value = area_input_table.add{
        type = "textfield",
        name = "width_value",
        numeric = "true"
    }
    width_value.style.width = numeric_input_width
    gui.components[player.index].width_value = width_value

    area_input_table.add{
        type = "label",
        name = "height-label",
        caption = "Height"
    }

    local height_value = area_input_table.add{
        type = "textfield",
        name = "height_value",
        numeric = "true"
    }
    height_value.style.width = numeric_input_width
    gui.components[player.index].height_value = height_value

    area_input_table.add{
        type = "label",
        name = "x-label",
        caption = "X"
    }

    local x_value = area_input_table.add{
        type = "textfield",
        name = "x_value",
        numeric = "true"
    }
    x_value.style.width = numeric_input_width
    gui.components[player.index].x_value = x_value


    area_input_table.add{
        type = "label",
        name = "y-label",
        caption = "Y",
    }

    local y_value = area_input_table.add{
        type = "textfield",
        name = "y_value",
        numeric = "true"
    }
    y_value.style.width = numeric_input_width
    gui.components[player.index].y_value = y_value

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
        caption = "Zoom level"
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
    zoom_slider.style.width = 144
    gui.components[player.index].zoom_slider = zoom_slider
    local zoom_value = zoom_flow.add{
        type = "textfield",
        name = "zoom_value",
        text = "1",
        numeric = "true",
        allow_decimal = "true",
        enabled = "false"
    }
    zoom_value.style.width = numeric_input_width
    -- zoom_value.style.disabled_font_color = {1, 1, 1}
    gui.components[player.index].zoom_value = zoom_value
    gui.zoomLevels[player.index] = 1

    -- estimated resolution flow
    local estimated_resolution_flow = vertical_flow.add{
        type = "flow",
        name = "estimated_resolution_flow",
        direction = "horizontal"
    }
    local estimated_resolution_label = estimated_resolution_flow.add{
        type = "label",
        name = "estimated_resolution_label",
        caption = "Estimated Resolution"
    }
    estimated_resolution_label.style.width = label_width
    gui.components[player.index].estimated_resolution_value = estimated_resolution_flow.add{
        type = "label",
        name = "estimated_resolution_value",
        caption = "no area selected"
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
        caption = "Estimated Filesize"
    }
    estimated_filesize_label.style.width = label_width
    gui.components[player.index].estimated_filesize_value = estimated_filesize_flow.add{
        type = "label",
        name = "estimated_filesize_value",
        caption = "-"
    }

    -- warning
    local warning = vertical_flow.add{
        type = "label",
        name = "warning_label",
        caption = "This will probably break multiplayer games and might cause a lot of data on your hard drive. Use at own risk."
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
    gui.components[player.index].agree_checkbox = agree_flow.add{
        type = "checkbox",
        name = "agree_checkbox",
        caption = "I understand",
        state = "false"
    }
    local spreader = agree_flow.add{
        type = "empty-widget",
        name = "spreader"
    }
    spreader.style.horizontally_stretchable = true
    gui.components[player.index].start_high_res_screenshot_button = agree_flow.add{
        type = "button",
        name = "start_high_res_screenshot_button",
        caption = "Start High Res Screenshots",
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
    for index, player in pairs(gui.components) do
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
        for _, player in pairs(gui.components) do
            player.progress_bar.visible = false
            -- reset flowbutton pie progress value
        end
    end
    
    local countdown = calculateCountdown()
    for index, player in pairs(gui.components) do
        if player.mainFrame.visible then
            if global.verbose then log("setting status value for player " .. index .. " with countdown " .. countdown) end
            player.status_value.caption = countdown
        end
    end
end


return gui