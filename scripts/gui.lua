local guiBuilder = require("guibuilder")
local l = require("logger")
local modGui = require("mod-gui")

local gui = {}

function gui.initializeAllConnectedPlayers(queueHasEntries)
    for _, player in pairs(game.connected_players) do
        gui.initialize(player, queueHasEntries)
    end
end

function gui.initialize(player, queueHasEntries)
    log(l.info("initializing gui for player " .. player.index))
    local buttonFlow = modGui.get_button_flow(player)
    
    -- destroying already existing buttons in case of changes
    local flowButton = buttonFlow[guiBuilder.flowButtonName]
    if flowButton then
        flowButton.destroy()
    end
    -- adding the button
    global.flowButton[player.index] = buttonFlow.add{
        type = "sprite-button",
        name = guiBuilder.flowButtonName,
        sprite = queueHasEntries and "FAS-recording-icon" or "FAS-icon",
        visibility = true;
    }
    
    -- destroying already existing gui in case of changes
    local mainFrame = player.gui.screen[guiBuilder.mainFrameName]
    if mainFrame then
        mainFrame.destroy()
    end
end

function gui.highlightSelectAreaButton(player)
    -- happens if the shortcut was clicked before the ui was created
    if global.gui[player] then
        global.gui[player].select_area_button.style = "fas_clicked_tool_button"
    end
end

function gui.unhighlightSelectAreaButton(player)
    -- happens if the shortcut was clicked before the ui was created
    if global.gui[player] then
        global.gui[player].select_area_button.style = "tool_button"
    end
end

function gui.togglegui(index)
    log(l.info("toggling gui"))
    local player = game.get_player(index)
    local guiFrame = player.gui.screen[guiBuilder.mainFrameName]
    if not guiFrame then
        guiBuilder.createGuiFrame(player, gui)
        
    else
        if not guiFrame.visible and not global.auto.amount then
            gui.refreshStatusCountdown()
        end
        guiFrame.visible = not guiFrame.visible
    end
    
    
    if not guiFrame or guiFrame.visible then
        log(l.info("gui is now visible"))
        if global.snip[index].area.width then
            gui.refreshEstimates(index)
            gui.refreshStartHighResScreenshotButton(index)
        end
    else
        log(l.info("gui is now hidden"))
    end
end


function gui.refreshStartHighResScreenshotButton(index)
    -- {1, 16384}
    if global.gui[index] then
        global.gui[index].start_area_screenshot_button.enabled =
            global.snip[index].enableScreenshotButton
    end
end

function gui.refreshEstimates(index)
    if not global.gui[index] then return end

    if not global.snip[index].resolution then
        -- happens if the zoom slider is moved before an area was selected so far
        global.gui[index].resolution_value.caption = {"FAS-no-area-selected"}
        global.gui[index].estimated_filesize_value.caption = "-"
        return
    end

    global.gui[index].resolution_value.caption = global.snip[index].resolution
    global.gui[index].estimated_filesize_value.caption = global.snip[index].filesize
end

function gui.resetAreaValues(index)
    -- is nil if the ui was not opened before using the delete shortcut
    if global.gui[index] then
        global.gui[index].x_value.text = ""
        global.gui[index].y_value.text = ""
        global.gui[index].width_value.text = ""
        global.gui[index].height_value.text = ""
    end
end

function gui.refreshAreaValues(index)
    -- happens if the shortcuts were pressed before the ui was opened
    if global.gui[index] then
        global.gui[index].x_value.text = tostring(global.snip[index].area.left)
        global.gui[index].y_value.text = tostring(global.snip[index].area.top)
        global.gui[index].width_value.text = tostring(global.snip[index].area.width)
        global.gui[index].height_value.text = tostring(global.snip[index].area.height)
    end
end

-- cursor stack stuff
function gui.clearPlayerCursorStack(index)
    game.get_player(index).cursor_stack.clear()
end

function gui.givePlayerSelectionTool(index)
    game.get_player(index).cursor_stack.set_stack{
            name = "FAS-selection-tool"
        }
end

function gui.toggle_auto_content_area(index)
    if global.gui[index].auto_content.visible then
        global.gui[index].auto_content_collapse.sprite = "utility/expand"
        global.gui[index].auto_content_collapse.hovered_sprite = "utility/expand_dark"
        global.gui[index].auto_content_collapse.clicked_sprite = "utility/expand_dark"
    else
        global.gui[index].auto_content_collapse.sprite = "utility/collapse"
        global.gui[index].auto_content_collapse.hovered_sprite = "utility/collapse_dark"
        global.gui[index].auto_content_collapse.clicked_sprite = "utility/collapse_dark"
    end
    global.gui[index].auto_content.visible = not global.gui[index].auto_content.visible
end

function gui.toggle_area_content_area(index)
    if global.gui[index].area_content.visible then
        global.gui[index].area_content_collapse.sprite = "utility/expand"
        global.gui[index].area_content_collapse.hovered_sprite = "utility/expand_dark"
        global.gui[index].area_content_collapse.clicked_sprite = "utility/expand_dark"
    else
        global.gui[index].area_content_collapse.sprite = "utility/collapse"
        global.gui[index].area_content_collapse.hovered_sprite = "utility/collapse_dark"
        global.gui[index].area_content_collapse.clicked_sprite = "utility/collapse_dark"
    end
    global.gui[index].area_content.visible = not global.gui[index].area_content.visible
end


function gui.getStatusValue()
    if global.auto.amount then
        return global.auto.amount .. " / " .. global.auto.total
    else
        return "-"
    end
end

function gui.setStatusValue()
    global.auto.progressValue = global.auto.amount / global.auto.total
    for index, player in pairs(global.gui) do
        if l.doD then log(l.debug("player " .. index .. " found")) end
        if l.doD then log(l.debug("player.mainframe nil? " .. (player.mainFrame == nil and "true" or "false"))) end
        if player.mainFrame and player.mainFrame.valid and player.mainFrame.visible then
            if l.doD then log(l.debug("setting status value for player " .. index .. " with amount " .. global.auto.amount .. " / " .. global.auto.total)) end
            player.status_value.caption = global.auto.amount .. " / " .. global.auto.total
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
        if timediff >= 60 then
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