





require "sys"
module(..., package.seeall)
local interruptCallbacks = {}





















function setup(pin, val, pull)

pio.pin.close(pin)

if type(val) == "function" then
pio.pin.setdir(pio.INT, pin)
if pull then pio.pin.setpull(pull or pio.PULLUP, pin) end

interruptCallbacks[pin] = val
return function()
return pio.pin.getval(pin)
end
end

if val ~= nil then
pio.pin.setdir(val == 1 and pio.OUTPUT1 or pio.OUTPUT, pin)

else
pio.pin.setdir(pio.INPUT, pin)
if pull then pio.pin.setpull(pull or pio.PULLUP, pin) end
end

return function(val, changeDir)
if changeDir then pio.pin.close(pin) end
if val ~= nil then
if changeDir then pio.pin.setdir(pio.OUTPUT, pin) end
pio.pin.setval(val, pin)
else
if changeDir then
pio.pin.setdir(pio.INPUT, pin)
if pull then pio.pin.setpull(pull or pio.PULLUP, pin) end
end
return pio.pin.getval(pin)
end
end
end








function close(pin)
pio.pin.close(pin)
end

rtos.on(rtos.MSG_INT, function(msg)
if interruptCallbacks[msg.int_resnum] == nil then
log.warn('pins.rtos.on', 'warning:rtos.MSG_INT callback nil', msg.int_resnum)
end
interruptCallbacks[msg.int_resnum](msg.int_id)
end)
