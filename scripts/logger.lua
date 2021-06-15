local logger = {}

local doDebug

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
    if not doDebug then return end
    log(concat("DBUG:", ...))
end

function logger.info(...)
    log(concat("INFO:", ...))
end

function logger.warn(...)
    log(concat("WARN:", ...))
end

function logger.refreshDoDebug()
    doDebug = settings.global["FAS-enable-debug"].value
end

logger.refreshDoDebug()

return logger