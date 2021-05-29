local correctResXList = {15360, 7680, 3840, 1920, 1280}

for index, player in pairs(global.auto) do
    if correctResXList[player.resolution_index] ~= player.resX then
        global.auto[index].resolution_index = player.resolution_index + 1
    end
end