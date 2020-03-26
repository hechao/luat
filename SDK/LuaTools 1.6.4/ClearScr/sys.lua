





require "utils"
require "log"
require "patch"
module(..., package.seeall)


SCRIPT_LIB_VER = "2.3.5"


local TASK_TIMER_ID_MAX = 0x1FFFFFFF

local MSG_TIMER_ID_MAX = 0x7FFFFFFF


local taskTimerId = 0

local msgId = TASK_TIMER_ID_MAX

local timerPool = {}
local taskTimerPool = {}

local para = {}

local loop = {}

local sRollBack = true





function powerOn()
rtos.poweron(1)
end





function restart(r)
assert(r and r ~= "", "sys.restart cause null")
if errDump and errDump.appendErr and type(errDump.appendErr) == "function" then errDump.appendErr("restart[" .. r .. "];") end
rtos.restart()
end





function wait(ms)

assert(ms > 0, "The wait time cannot be negative!")

if taskTimerId >= TASK_TIMER_ID_MAX then taskTimerId = 0 end
taskTimerId = taskTimerId + 1
local timerid = taskTimerId
taskTimerPool[coroutine.running()] = timerid
timerPool[timerid] = coroutine.running()

if 1 ~= rtos.timer_start(timerid, ms) then log.debug("rtos.timer_start error") return end

local message = {coroutine.yield()}
if #message ~= 0 then
rtos.timer_stop(timerid)
taskTimerPool[coroutine.running()] = nil
timerPool[timerid] = nil
return unpack(message)
end
end







function waitUntil(id, ms)
subscribe(id, coroutine.running())
local message = ms and {wait(ms)} or {coroutine.yield()}
unsubscribe(id, coroutine.running())
return message[1] ~= nil, unpack(message, 2, #message)
end







function waitUntilExt(id, ms)
subscribe(id, coroutine.running())
local message = ms and {wait(ms)} or {coroutine.yield()}
unsubscribe(id, coroutine.running())
if message[1] ~= nil then return unpack(message) end
return false
end






function taskInit(fun, ...)
local co = coroutine.create(fun)
coroutine.resume(co, unpack(arg))
return co
end






function init(mode, lprfnc)

assert(PROJECT and PROJECT ~= "" and VERSION and VERSION ~= "", "Undefine PROJECT or VERSION")
collectgarbage("setpause", 80)


uart.setup(uart.ATC, 0, 0, uart.PAR_NONE, uart.STOP_1)
log.info("poweron reason:", rtos.poweron_reason(), PROJECT, VERSION, SCRIPT_LIB_VER, rtos.get_version())
if mode == 1 then

if rtos.poweron_reason() == rtos.POWERON_CHARGER then

rtos.poweron(0)
end
end
end










local function cmpTable(t1, t2)
if not t2 then return #t1 == 0 end
if #t1 == #t2 then
for i = 1, #t1 do
if unpack(t1, i, i) ~= unpack(t2, i, i) then
return false
end
end
return true
end
return false
end






function timerStop(val, ...)

if type(val) == 'number' then
timerPool[val], para[val], loop[val] = nil
rtos.timer_stop(val)
else
for k, v in pairs(timerPool) do

if type(v) == 'table' and v.cb == val or v == val then

if cmpTable(arg, para[k]) then
rtos.timer_stop(k)
timerPool[k], para[k], loop[val] = nil
break
end
end
end
end
end





function timerStopAll(fnc)
for k, v in pairs(timerPool) do
if type(v) == "table" and v.cb == fnc or v == fnc then
rtos.timer_stop(k)
timerPool[k], para[k], loop[k] = nil
end
end
end






function timerStart(fnc, ms, ...)

assert(fnc ~= nil, "sys.timerStart(first param) is nil !")
assert(ms > 0, "sys.timerStart(Second parameter) is <= zero !")

if arg.n == 0 then
timerStop(fnc)
else
timerStop(fnc, unpack(arg))
end

while true do
if msgId >= MSG_TIMER_ID_MAX then msgId = TASK_TIMER_ID_MAX end
msgId = msgId + 1
if timerPool[msgId] == nil then
timerPool[msgId] = fnc
break
end
end

if rtos.timer_start(msgId, ms) ~= 1 then log.debug("rtos.timer_start error") return end

if arg.n ~= 0 then
para[msgId] = arg
end

return msgId
end






function timerLoopStart(fnc, ms, ...)
local tid = timerStart(fnc, ms, unpack(arg))
if tid then loop[tid] = ms end
return tid
end







function timerIsActive(val, ...)
if type(val) == "number" then
return timerPool[val]
else
for k, v in pairs(timerPool) do
if v == val then
if cmpTable(arg, para[k]) then return true end
end
end
end
end




local subscribers = {}

local messageQueue = {}





function subscribe(id, callback)
if type(id) ~= "string" or (type(callback) ~= "function" and type(callback) ~= "thread") then
log.warn("warning: sys.subscribe invalid parameter", id, callback)
return
end
if not subscribers[id] then subscribers[id] = {} end
subscribers[id][callback] = true
end





function unsubscribe(id, callback)
if type(id) ~= "string" or (type(callback) ~= "function" and type(callback) ~= "thread") then
log.warn("warning: sys.unsubscribe invalid parameter", id, callback)
return
end
if subscribers[id] then subscribers[id][callback] = nil end
end





function publish(...)
table.insert(messageQueue, arg)
end


local function dispatch()
while true do
if #messageQueue == 0 then
break
end
local message = table.remove(messageQueue, 1)
if subscribers[message[1]] then
for callback, _ in pairs(subscribers[message[1]]) do
if type(callback) == "function" then
callback(unpack(message, 2, #message))
elseif type(callback) == "thread" then
coroutine.resume(callback, unpack(message))
end
end
end
end
end


local handlers = {}
setmetatable(handlers, {__index = function() return function() end end, })






rtos.on = function(id, handler)
handlers[id] = handler
end


local function safeRun()

dispatch()

local msg, param, exparam = rtos.receive(rtos.INF_TIMEOUT)

if msg == rtos.MSG_TIMER and timerPool[param] then
if param < TASK_TIMER_ID_MAX then
local taskId = timerPool[param]
timerPool[param] = nil
if taskTimerPool[taskId] == param then
taskTimerPool[taskId] = nil
coroutine.resume(taskId)
end
else
local cb = timerPool[param]

if not loop[param] then timerPool[param] = nil end
if para[param] ~= nil then
cb(unpack(para[param]))
if not loop[param] then para[param] = nil end
else
cb()
end

if loop[param] then rtos.timer_start(param, loop[param]) end
end

elseif type(msg) == "number" then
handlers[msg](param, exparam)
else
handlers[msg.id](msg)
end
end




function run()
local result, err
while true do
if sRollBack then
safeRun()
else
result, err = pcall(safeRun)
if not result then restart(err) end
end
end
end











function setRollBack(flag,secs)
sRollBack = flag
secs = secs or 300
if type(rtos.set_script_rollback)=="function" then
rtos.set_script_rollback(1)
if not flag then
assert(secs>=1 and secs<=72*3600)
timerStart(rtos.set_script_rollback,secs*1000,0)
end
end
end

require "clib"
