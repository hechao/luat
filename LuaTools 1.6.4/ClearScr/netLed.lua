





module(..., package.seeall)

require "pins"
require "sim"


local simError

local flyMode

local gsmRegistered

local gprsAttached

local socketConnected









local ledState = "NULL"
local ON,OFF = 1,2

local ledBlinkTime =
{
NULL = {0,0xFFFF},  
FLYMODE = {0,0xFFFF},  
SIMERR = {300,5700},  
IDLE = {300,3700},  
GSM = {300,1700},  
GPRS = {300,700},  
SCK = {100,100},  
}


local ledSwitch = false

local ledPin = pio.P1_1







local function updateState()

if ledSwitch then
local newState = "IDLE"
if flyMode then
newState = "FLYMODE"
elseif simError then
newState = "SIMERR"
elseif socketConnected then
newState = "SCK"
elseif gprsAttached then
newState = "GPRS"
elseif gsmRegistered then
newState = "GSM"	
end

if newState~=ledState then
ledState = newState
sys.publish("NET_LED_UPDATE")
end
end
end







local function taskLed(ledPinSetFunc)
while true do

if ledSwitch then
local onTime,offTime = ledBlinkTime[ledState][ON],ledBlinkTime[ledState][OFF]
if onTime>0 then
ledPinSetFunc(1)
if not sys.waitUntil("NET_LED_UPDATE", onTime) then
if offTime>0 then
ledPinSetFunc(0)
sys.waitUntil("NET_LED_UPDATE", offTime)
end
end
else if offTime>0 then
ledPinSetFunc(0)
sys.waitUntil("NET_LED_UPDATE", offTime)
end
end            
else
ledPinSetFunc(0)
break
end
end
end











function setup(flag,pin)

local oldSwitch = ledSwitch
if flag~=ledSwitch then
ledSwitch = flag
sys.publish("NET_LED_UPDATE")
end
if flag and not oldSwitch then
if type(pin)=="function" then pin(0) end
sys.taskInit(taskLed, type(pin)=="function" and pin or pins.setup(pin or ledPin, 0))
end        
end









function updateBlinkTime(state,on,off)
if not ledBlinkTime[state] then log.error("netLed.updateBlinkTime") return end    
local updated
if on and ledBlinkTime[state][ON]~=on then
ledBlinkTime[state][ON] = on
updated = true
end
if off and ledBlinkTime[state][OFF]~=off then
ledBlinkTime[state][OFF] = off
updated = true
end

if updated then sys.publish("NET_LED_UPDATE") end
end

sys.subscribe("FLYMODE", function(mode) if flyMode~=mode then flyMode=mode updateState() end end)
sys.subscribe("SIM_IND", function(para) if simError~=(para~="RDY") then simError=(para~="RDY") updateState() end end)
sys.subscribe("NET_STATE_UNREGISTER", function() if gsmRegistered then gsmRegistered=false updateState() end end)
sys.subscribe("NET_STATE_REGISTERED", function() if not gsmRegistered then gsmRegistered=true updateState() end end)
sys.subscribe("GPRS_ATTACH", function(attach) if gprsAttached~=attach then gprsAttached=attach updateState() end end)
sys.subscribe("SOCKET_ACTIVE", function(active) if socketConnected~=active then socketConnected=active updateState() end end)
