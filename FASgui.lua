local modGui = require("mod-gui")
local FASgui = {}

FASgui.zoomLevels = {}
FASgui.doesUnderstand = {}
FASgui.players = {}

-- handler methods have to be called the same as the element that shall trigger them
local flowButtonName = "toggleFASgui"
local mainFrameName = "FASguiFrame"

function FASgui.initialize(player)
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

-- event catchers
function FASgui.on_gui_event(event)
    log("on gui event triggered with element name " .. event.element.name)

    -- handler methods have to be called the same as the element that shall trigger them
    local handlerMethod = FASgui[event.element.name]

    -- if a handler method exists the gui press was for an element of this mod
    if handlerMethod then
        handlerMethod(event)
    end
end

-- handler methods
function FASgui.toggleFASgui(event)
    log("toggling FASgui")
    local player = game.get_player(event.player_index)
    local guiFrame = player.gui.screen[mainFrameName]
    if not guiFrame then
        createGuiFrame(player)
    else
        -- if we hide the gui, the tick on the "I understand" checkbox is removed, so that the user has to click it again the next time
        if FASgui.doesUnderstand[event.player_index] then
            FASgui.doesUnderstand[event.player_index] = false
            FASgui.players[event.player_index].agree_checkbox.state = false
            FASgui.players[event.player_index].start_high_res_screenshot_button.enabled = false
        end
        guiFrame.visible = not guiFrame.visible
    end
end

function FASgui.agree_checkbox(event)
    log("i understand was clicked, toggling button and value")
    local state = event.element.state
    FASgui.players[event.player_index].start_high_res_screenshot_button.enabled = state
    FASgui.doesUnderstand[event.player_index] = state
end

function FASgui.zoom_slider(event)
    if (global.verbose) then log("zoom slider was moved") end
    FASgui.players[event.player_index].zoom_value.text = tostring(event.element.slider_value)
end

-- end handler methods

function createGuiFrame(player)
    log("creating gui for player " .. player.index)
    local label_width = 150
    
    FASgui.players[player.index] = {}
    FASgui.players[player.index].index = player.index
    local guiFrame = player.gui.screen.add{
        type = "frame",
        name = mainFrameName,
        caption = "FAS Panel"
    }
    guiFrame.auto_center = true
    FASgui.players[player.index].mainFrame = guiFrame

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
    FASgui.players[player.index].status_value = status_flow.add{
        type = "label",
        name = "status_value",
        caption = getStatusValue(player)
    }

    local progressbar = vertical_flow.add{
        type = "progressbar",
        name = "progress",
        visible = "false"
    }
    progressbar.style.width = 350
    FASgui.players[player.index].progress_bar = progressbar

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

    vertical_flow.add{
        type = "label",
        name = "high_res_screenshots_label",
        caption = "High Resolution Screenshots",
        style = "caption_label"
    }

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
    FASgui.players[player.index].zoom_slider = zoom_slider
    local zoom_value = zoom_flow.add{
        type = "textfield",
        name = "zoom_value",
        text = "1",
        numeric = "true",
        allow_decimal = "true",
        enabled = "false"
    }
    zoom_value.style.width = 40
    -- zoom_value.style.disabled_font_color = {1, 1, 1}
    FASgui.players[player.index].zoom_value = zoom_value

    -- resolution flow
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
    FASgui.players[player.index].estimated_resolution_value = estimated_resolution_flow.add{
        type = "label",
        name = "estimated_resolution_value",
        caption = "aLot x evenMore"
    }

    -- warning
    vertical_flow.add{
        type = "label",
        name = "warning_label",
        caption = "This is a long warning"
    }

    -- agree flow
    local agree_flow = vertical_flow.add{
        type = "flow",
        name = "agree_flow",
        direction = "horizontal"
    }
    agree_flow.style.vertical_align = "center"
    FASgui.players[player.index].agree_checkbox = agree_flow.add{
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
    FASgui.players[player.index].start_high_res_screenshot_button = agree_flow.add{
        type = "button",
        name = "start_high_res_screenshot_button",
        caption = "Start High Res Screenshots",
        mouse_button_filter = {"left"},
        enabled = "false"
    }
end

function getStatusValue(player)
    if FASgui.amount then
        return FASgui.amount .. " / " .. FASgui.total
    end

end

function FASgui.setStatusValue(amount, total)
    FASgui.amount = amount
    FASgui.total = total
    FASgui.progressValue = amount / total
    for _, player in pairs(FASgui.players) do
        if player.mainFrame.visible then
            if global.verbose then log("setting status value for player " .. player.index .. " with amount " .. amount .. " / " .. total) end
            player.status_value.caption = amount .. " / " .. total
            if player.progress_bar.visible == false then
                player.progress_bar.visible = true
            end
            player.progress_bar.value = FASgui.progressValue
        end
        -- set flowbutton pie progress value
    end
end

function FASgui.setStatusCountdown(countdown)
    FASgui.countdown = countdown

    --reset status values if still present, necessary on the first time the cooldown is set
    if FASgui.amount then
        FASgui.amount = nil
        FASgui.total = nil
        FASgui.progressValue = nil
        for _, player in pairs(FASgui.players) do
            player.progress_bar.visible = false
            -- reset flowbutton pie progress value
        end
    end

    for _, player in pairs(FASgui.players) do
        if player.mainFrame.visible then
            if global.verbose then log("setting status value for player " .. player.index .. " with countdown " .. countdown) end
            player.status_value.caption = countdown
        end
    end
end

return FASgui