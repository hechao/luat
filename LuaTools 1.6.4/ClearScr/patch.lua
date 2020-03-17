






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
if errDump and errDump.appendErr and type(errDump.appendErr)=="function" then
errDump.appendErr(traceBack)                
else
log.error("coroutine.resume",traceBack)
end
if _G.COROUTINE_ERROR_RESTART then rtos.restart() end
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
