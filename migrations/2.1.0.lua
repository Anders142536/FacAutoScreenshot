--[[
With surface support the fields for auto screenshots became tables,
with surface indexi being the index in the table. This migration script
should fix precisely that
]]--
if global.auto then
    for index, player in pairs(global.auto) do
        if global.auto[index].doScreenshot ~= nil then
            if not global.auto[index].doSurface then
                global.auto[index].doSurface = {nauvis = global.auto[index].doScreenshot}
            end
            global.auto[index].doScreenshot = nil
        end
        if type(global.auto[index].zoom) == "number" then
            global.auto[index].zoom = {}
        end
        if type(global.auto[index].zoomLevel) == "number" then
            global.auto[index].zoomLevel = nil
        end
    end
end