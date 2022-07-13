local l = require("logger")

local snip = {}

function snip.resetArea(index)
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
    if global.snip[index].resolution then
        global.snip[index].resolution = nil
    end
    if global.snip[index].filesize then
        global.snip[index].filesize = nil
    end
    if global.snip[index].surface_name then
        global.snip[index].surface_name = nil
    end
end

function snip.calculateArea(index)
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

    -- happens if the player clicks exactly on the border between tiles
    -- which would result in a line instead of a square
    if top == bottom then
        bottom = bottom + 1
    end
    if left == right then
        right = right + 1
    end

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

    local surface_name = game.get_player(index).surface.name
    global.snip[index].surface_name = surface_name

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
        surface = surface_name
    }
    
end

function snip.calculateEstimates(index)
    if not global.snip[index].area.width then
        -- happens if the zoom slider is moved before an area was selected so far
        return
    end

    local zoom = 1 / global.snip[index].zoomLevel
    local width = math.floor((global.snip[index].area.right - global.snip[index].area.left) * 32 * zoom)
    local height = math.floor((global.snip[index].area.bottom - global.snip[index].area.top) * 32 * zoom)
    
    local size = "-"
    -- 1 means png, only other option is 2, meaning jpg
    if global.snip[index].output_format_index == 1 then
        local bytesPerPixel = 2
        size = bytesPerPixel * width * height

        if size > 999999999 then
            size = (math.floor(size / 100000000) / 10) .. " GiB"
        elseif size > 999999 then
            size = (math.floor(size / 100000) / 10) .. " MiB"
        elseif size > 999 then
            size = (math.floor(size / 100) / 10) .. " KiB"
        else
            size = size .. " B"
        end
    end
    
    local resolution = width .. "x" .. height
    global.snip[index].resolution = resolution
    global.snip[index].filesize = size
end

function snip.checkIfScreenshotPossible(index)
    -- {1, 16384}
    local zoom = 1 / global.snip[index].zoomLevel
    if not global.snip[index].area.width then
        global.snip[index].enableScreenshotButton = false
    else
        local resX = math.floor((global.snip[index].area.right - global.snip[index].area.left) * 32 * zoom)
        local resY = math.floor((global.snip[index].area.bottom - global.snip[index].area.top) * 32 * zoom)
        
        local enable = resX < 16385 and resY < 16385
        global.snip[index].enableScreenshotButton = enable
    end
end

return snip