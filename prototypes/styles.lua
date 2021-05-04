local styles = data.raw['gui-style'].default
local button_style = styles["button"]

styles.fas_clicked_tool_button = {
    type = "button_style",
    parent = "tool_button",
    default_graphical_set = button_style.clicked_graphical_set,
    clicked_graphical_set = button_style.default_graphical_set
}
styles.fas_expand_button = {
    type = "button_style",
    parent = "frame_action_button",
    size = 28,
    padding = 2
}
styles.fas_draghandle = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    left_margin = 4,
    right_margin = 4,
    height = 24,
    horizontally_stretchable = "on"
}
styles.fas_flow = {
    type = "horizontal_flow_style",
    vertical_align = "center"
}
styles.fas_label = {
    type = "label_style",
    parent = "label",
    width = 150
}
styles.fas_slider = {
    type = "slider_style",
    parent = "notched_slider",
    right_margin = 8,
    width = 128
}
styles.fas_numeric_output = {
    type = "textbox_style",
    -- parent = ""
    disabled_font_color = {0.5, 0.5, 0.5},
    width = 60
}
styles.fas_slim_numeric_output = {
    type = "textbox_style",
    parent = "fas_numeric_output",
    width = 40
}
styles.fas_section = {
    type = "frame_style",
    parent = "subpanel_frame",
    width = 350
}