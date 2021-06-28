local logger = {}

local function concat(...)
    local result = {}
    -- table.pack removes the nil values whilst keeping every value at its index,
    -- causing the index of the nil value still to be nil in the for loop
    local args = table.pack(...)
    for i=1,args.n do
        --     -- # returns the size of the table
        --     -- no nil check necessary, nil is returned as "nil"
        result[#result+1] = tostring(args[i])
    end
    --table concatenation is way faster than string concatenation
    return table.concat(result)
end

function logger.debug(...)
    return concat("DBUG: ", ...)
end

function logger.info(...)
    return concat("INFO: ", ...)
end

function logger.warn(...)
    return concat("WARN: ", ...)
end

function logger.doD()
    return global.verbose == true
end

return logger