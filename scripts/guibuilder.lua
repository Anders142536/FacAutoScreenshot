local guibuilder = {}

--[[
This class does nothing but create the gui frame for a given player.
--]]

--[[ CONSTANTS ]]--
guibuilder.flowButtonName = "togglegui"
guibuilder.mainFrameName = "guiFrame"



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


--[[ AUTO ]]--
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
        state = global.auto[index].singleScreenshot or false
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


--[[ AREA ]]--
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

local function buildAreaDayTime(index, area_content)
    local daytime_flow = area_content.add{
        type = "flow",
        name = "daytime_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    daytime_flow.add{
        type = "label",
        name = "daytime_label",
        caption = {"FAS-daytime-caption"},
        tooltip = {"FAS-daytime-tooltip"},
        style = "fas_label"
    }

    global.gui[index].daytime_switch = daytime_flow.add{
        type = "switch",
        name = "daytime_switch",
        switch_state = global.snip[index].daytime_state or "none",
        allow_none_state = true,
        left_label_caption = {"FAS-day-caption"},
        left_label_tooltip = {"FAS-day-tooltip"},
        right_label_caption = {"FAS-night-caption"},
        right_label_tooltip = {"FAS-night-tooltip"}
    }
end

local function buildAreaShowAltMode(index, area_content)
    local alt_mode_flow = area_content.add{
        type = "flow",
        name = "alt_mode_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    alt_mode_flow.add{
        type = "label",
        name = "alt_mode_label",
        caption = {"FAS-alt-mode-caption"},
        tooltip = {"FAS-alt-mode-tooltip"},
        style = "fas_label"
    }

    global.gui[index].alt_mode_value = alt_mode_flow.add{
        type = "checkbox",
        name = "alt_mode_value",
        state = global.snip[index].showAltMode or false
    }
end

local function buildAreaShowUi(index, area_content)
    local show_ui_flow = area_content.add{
        type = "flow",
        name = "show_ui_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    show_ui_flow.add{
        type = "label",
        name = "show_ui_label",
        caption = {"FAS-show-ui-caption"},
        tooltip = {"FAS-show-ui-tooltip"},
        style = "fas_label"
    }

    global.gui[index].show_ui_value = show_ui_flow.add{
        type = "checkbox",
        name = "show_ui_value",
        state = global.snip[index].showUI or false
    }
end

local function buildAreaShowCursorBuildingPreview(index, area_content)
    local show_cursor_building_preview_flow = area_content.add{
        type = "flow",
        name = "show_cursor_building_preview_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    show_cursor_building_preview_flow.add{
        type = "label",
        name = "show_cursor_building_preview_label",
        caption = {"FAS-show-cursor-building-preview-caption"},
        tooltip = {"FAS-show-cursor-building-preview-tooltip"},
        style = "fas_label"
    }

    global.gui[index].show_cursor_building_preview_value = show_cursor_building_preview_flow.add{
        type = "checkbox",
        name = "show_cursor_building_preview_value",
        state = global.snip[index].showCursorBuildingPreview or false
    }
end

local function buildAreaUseAntiAlias(index, area_content)
    local use_anti_alias_flow = area_content.add{
        type = "flow",
        name = "use_anti_alias_flow",
        direction = "horizontal",
        style = "fas_flow"
    }

    use_anti_alias_flow.add{
        type = "label",
        name = "use_anti_alias_label",
        caption = {"FAS-use-anti-alias-caption"},
        tooltip = {"FAS-use-anti-alias-tooltip"},
        style = "fas_label"
    }

    global.gui[index].use_anti_alias_value = use_anti_alias_flow.add{
        type = "checkbox",
        name = "use_anti_alias_value",
        state = global.snip[index].useAntiAlias or false
    }
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

local function buildAreaOutput(index, area_content)
    local area_output_flow = area_content.add{
        type = "flow",
        name = "area_output_flow",
        direction = "horizontal",
        style = "fas_flow"
    }
    area_output_flow.add{
        type = "label",
        name = "area_output_label",
        caption = {"FAS-area-output-label"},
        style = "fas_label"
    }
    area_output_flow.add{
        type = "textfield",
        name = "area_output_name",
        text = global.snip[index].outputName or "screenshot",
        style = "fas_wide_text_input"
    }
    area_output_flow.add{
        type = "drop-down",
        name = "area_output_format",
        selected_index = global.snip[index].output_format_index,
        items = {".png", ".jpg"},
        style = "fas_slim_drop_down"
    }
end

local function buildAreaJpgQuality(index, area_content)
    local area_jpg_quality_flow = area_content.add{
        type = "flow",
        name = "area_jpg_quality_flow",
        direction = "horizontal",
        style = "fas_flow",
        visible = global.snip[index].output_format_index == 2
    }
    global.gui[index].area_jpg_quality_flow = area_jpg_quality_flow
    area_jpg_quality_flow.add{
        type = "label",
        name = "area_jpg_quality_label",
        caption = {"FAS-area-jpg-quality-label"},
        tooltip = {"FAS-area-jpg-quality-tooltip"},
        style = "fas_label"
    }

    area_jpg_quality_flow.add{
        type = "slider",
        name = "area_jpg_quality_slider",
        minimum_value = "10",
        maximum_value = "100",
        value_step = "10",
        value = global.snip[index].jpg_quality,
        style = "fas_slider"
    }

    global.gui[index].area_jpg_quality_value = area_jpg_quality_flow.add{
        type = "textfield",
        name = "area_jpg_quality_value",
        text = global.snip[index].jpg_quality,
        enabled = false,
        style = "fas_slim_numeric_output"
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
    buildAreaDayTime(index, area_content)
    buildAreaShowAltMode(index, area_content)
    buildAreaShowUi(index, area_content)
    buildAreaShowCursorBuildingPreview(index, area_content)
    buildAreaUseAntiAlias(index, area_content)
    buildAreaZoom(index, area_content)
    buildAreaResolution(index, area_content)
    buildAreaFilesize(index, area_content)
    buildAreaOutput(index, area_content)
    buildAreaJpgQuality(index, area_content)

    buildAreaStartButton(index, area_content)
end



local function buildContentFrame(index, content_frame)
    buildAutoScreenshotSection(index, content_frame.add{
        type = "frame",
        name = "auto_frame",
        direction = "vertical",
        style = "fas_section"
    })

    buildAreaScreenshotSection(index, content_frame.add{
        type = "frame",
        name = "area_frame",
        direction = "vertical",
        style = "fas_section"
    })
end

-- creates a new gui frame for the given player. if a frame
-- already exists, it is destroyed
function guibuilder.createGuiFrame(player)
    log(l.info("creating gui for player " .. player.index))

    global.gui[player.index] = {}
    local guiFrame = player.gui.screen.add{
        type = "frame",
        name = guibuilder.mainFrameName,
        direction = "vertical"
    }
    guiFrame.auto_center = true
    global.gui[player.index].mainFrame = guiFrame

    buildHeader(guiFrame)
    buildContentFrame(player.index, guiFrame.add{
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "window_content_frame_deep"
    })
end

return guibuilder