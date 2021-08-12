require("prototypes.sprites")
require("prototypes.styles")

data:extend{
    {
        type = "custom-input",
        name = "FAS-left-click",
        key_sequence = "mouse-button-1"
    },
    {
        type = "custom-input",
        name = "FAS-right-click",
        key_sequence = "mouse-button-2"
    },
    {
        type = "custom-input",
        name = "FAS-selection-toggle-shortcut",
        key_sequence = "SHIFT + ALT + S"
    },
    {
        type = "custom-input",
        name = "FAS-delete-area-shortcut",
        key_sequence = "SHIFT + ALT + D"
    },
    {
        type = "selection-tool",
        name = "FAS-selection-tool",
        icon = "__FacAutoScreenshot__/graphics/FAS-24px.png",
        icon_size = 24,
        flags = {"hidden", "not-stackable", "spawnable", "only-in-cursor"},
        stack_size = 1,
        selection_color = {0, 0, 0, 0},
        alt_selection_color = {0, 0, 0, 0},
        selection_mode = {"nothing"},
        alt_selection_mode = {"nothing"},
        selection_cursor_box_type = "entity",
        alt_selection_cursor_box_type = "entity",
        mouse_cursor = "selection-tool-cursor"
    }
}