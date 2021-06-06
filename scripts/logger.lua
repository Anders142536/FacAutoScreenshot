local logger = {}

local doDebug
logger.refreshDoDebug()

local function concat(...)
    local result = {}
    for _, v in ipairs{...} do
        result[#result+1] = tostring(v)
     end
    return table.concat(result, " ")
end

function logger.debug(...)
    if not doDebug then return end
    log(concat("DBUG: ", arg))
end

function logger.info(...)
    log(concat("INFO: ", arg))
end

function logger.warn(...)
    log(concat("WARN: ", arg))
end

function logger.refreshDoDebug()
    doDebug = settings.global["FAS-enable-debug"].value
end

return logger