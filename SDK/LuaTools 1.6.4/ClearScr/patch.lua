






require"pm"
module(..., package.seeall)







local oldostime = os.time








function safeostime(t)
return oldostime(t) or 0
end


os.time = safeostime


local oldosdate = os.date









function safeosdate(s, t)
if s == "*t" then
return oldosdate(s, t) or {year = 2012,
month = 12,
day = 11,
hour = 10,
min = 9,
sec = 0}
else
return oldosdate(s, t)
end
end


os.date = safeosdate


local rawcoresume = coroutine.resume
coroutine.resume = function(...)
function wrapper(co,...)
if not arg[1] then
local traceBack = debug.traceback(co)
traceBack = (traceBack and traceBack~="") and (arg[2].."\r\n"..traceBack) or arg[2]
log.error("coroutine.resume",traceBack)
if errDump and type(errDump.appendErr)=="function" then
errDump.appendErr(traceBack)
end
if _G.COROUTINE_ERROR_ROLL_BACK then
sys.timerStart(assert,500,false,traceBack)
elseif _G.COROUTINE_ERROR_RESTART then
rtos.restart()
end
end
return unpack(arg)
end
return wrapper(arg[1],rawcoresume(unpack(arg)))
end

os.clockms = function() return rtos.tick()/16 end


if json and json.decode then oldjsondecode = json.decode end






local function safeJsonDecode(s)
local result, info = pcall(oldjsondecode, s)
if result then
return info, true
else
return {}, false, info
end
end


if json and json.decode then json.decode = safeJsonDecode end

local oldUartWrite = uart.write
uart.write = function(...)
pm.wake("lib.patch.uart.write")
local result = oldUartWrite(unpack(arg))
pm.sleep("lib.patch.uart.write")
return result
end

if i2c and i2c.write then
local oldI2cWrite = i2c.write
i2c.write = function(...)
pm.wake("lib.patch.i2c.write")
local result = oldI2cWrite(unpack(arg))
pm.sleep("lib.patch.i2c.write")
return result
end
end

if i2c and i2c.send then
local oldI2cSend = i2c.send
i2c.send = function(...)
pm.wake("lib.patch.i2c.send")
local result = oldI2cSend(unpack(arg))
pm.sleep("lib.patch.i2c.send")
return result
end
end

if spi and spi.send then
oldSpiSend = spi.send
spi.send = function(...)
pm.wake("lib.patch.spi.send")
local result = oldSpiSend(unpack(arg))
pm.sleep("lib.patch.spi.send")
return result
end
end
