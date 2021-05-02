local styles = data.raw['gui-style'].default
local button_style = styles["button"]

styles.fas_clicked_tool_button = {
    type = "button_style",
    parent = "tool_button",
    default_graphical_set = button_style.clicked_graphical_set,
    clicked_graphical_set = button_style.default_graphical_set
}
styles.fas_draghandle = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    left_margin = 4,
    right_margin = 4,
    height = 24,
    horizontally_stretchable = "on"
}
styles.fas_label = {
    type = "label_style",
    parent = "label",
    width = 150
}
styles.fas_numeric_input = {
    type = "textbox_style",
    -- parent = ""
    disabled_font_color = {0.5, 0.5, 0.5},
    width = 60
}
styles.fas_section = {
    type = "frame_style",
    parent = "subpanel_frame",
    width = 350
}