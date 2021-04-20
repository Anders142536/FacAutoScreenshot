# Anders 142536 — Today at 20:19
    to sell the effect a simple change to a yellow color would be fine i guess, but it would be nicer
# curiosity — Today at 20:19
    Swap pressed and unpressed graphics set.
# Anders 142536 — Today at 20:19
    i dont think i understand fully what that means
# curiosity — Today at 20:20
    From IT:
    [lua]
    local styles = data.raw['gui-style'].default
    local button_style = styles[mod_button_style]
    local clicked_graphics = button_style.clicked_graphical_set
    local default_graphics = button_style.default_graphical_set
    while not (clicked_graphics and default_graphics) do
        button_style = styles[button_style.parent]
        clicked_graphics = clicked_graphics or button_style.clicked_graphical_set
        default_graphics = default_graphics or button_style.default_graphical_set
    end

    styles.inserter_throughput_pressed_button = {
        type = 'button_style',
        parent = mod_button_style,
        default_graphical_set = clicked_graphics,
        clicked_graphical_set = default_graphics
    }
    [end]
# Anders 142536 — Today at 20:21
    is there some api documentation for those things? i at least dont find anything about the graphical sets on the LuaGuiElement page
# curiosity — Today at 20:21
    Of course not, it's data stage, therefore on the wiki.
# JanSharp — Today at 20:21
    https://wiki.factorio.com/Prototype/GuiStyle