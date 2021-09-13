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
end



return snip