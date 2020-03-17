






require "sys"
require "ril"
require "pio"
require "sim"
require "log"
module(..., package.seeall)


local publish = sys.publish





local state = "INIT"

local simerrsta

flyMode = false




local lac, ci, rssi = "", "", 0


local cellinfo, multicellcb = {}































local function creg(data)
local p1, s

_, _, p1 = string.find(data, "%d,(%d)")
if p1 == nil then
_, _, p1 = string.find(data, "(%d)")
if p1 == nil then
return
end
end


if p1 == "1" or p1 == "5" then
s = "REGISTERED"

else






s = "UNREGISTER"
end

if s ~= state then

if s == "REGISTERED" then

publish("NET_STATE_REGISTERED")
cengQueryPoll()
end
state = s

end

if state == "REGISTERED" then
p2, p3 = string.match(data, "\"(%x+)\",\"(%x+)\"")
if lac ~= p2 or ci ~= p3 then
lac = p2
ci = p3

publish("NET_CELL_CHANGED")
end
end
end







local function resetCellInfo()
local i
cellinfo.cnt = 11 
for i = 1, cellinfo.cnt do
cellinfo[i] = {}
cellinfo[i].mcc, cellinfo[i].mnc = nil
cellinfo[i].lac = 0
cellinfo[i].ci = 0
cellinfo[i].rssi = 0
cellinfo[i].ta = 0
end
end
















local function ceng(data)

if string.find(data, "%+CENG:%d+,\".+\"") then
local id, rssi, lac, ci, ta, mcc, mnc
id = string.match(data, "%+CENG:(%d)")
id = tonumber(id)

if id == 0 then
rssi, mcc, mnc, ci, lac, ta = string.match(data, "%+CENG: *%d, *\"%d+, *(%d+), *%d+, *(%d+), *(%d+), *%d+, *(%d+), *%d+, *%d+, *(%d+), *(%d+)\"")
else
rssi, mcc, mnc, ci, lac, ta = string.match(data, "%+CENG: *%d, *\"%d+, *(%d+), *(%d+), *(%d+), *%d+, *(%d+), *(%d+)\"")
end

if rssi and ci and lac and mcc and mnc then

if id == 0 then
resetCellInfo()
end

cellinfo[id + 1].mcc = mcc
cellinfo[id + 1].mnc = mnc
cellinfo[id + 1].lac = tonumber(lac)
cellinfo[id + 1].ci = tonumber(ci)
cellinfo[id + 1].rssi = (tonumber(rssi) == 99) and 0 or tonumber(rssi)
cellinfo[id + 1].ta = tonumber(ta or "0")

if id == 0 then
if multicellcb then multicellcb(cellinfo) end
publish("CELL_INFO_IND", cellinfo)
end
end
end
end


































local function neturc(data, prefix)
if prefix == "+CREG" then

csqQueryPoll()

creg(data)
elseif prefix == "+CENG" then

ceng(data)





end
end





function switchFly(mode)
if flyMode == mode then return end
flyMode = mode

if mode then
ril.request("AT+CFUN=0")

else
ril.request("AT+CFUN=1")

csqQueryPoll()
cengQueryPoll()

neturc("2", "+CREG")
end
end







function getState()
return state
end




function getMcc()
return cellinfo[1].mcc or sim.getMcc()
end




function getMnc()
return cellinfo[1].mnc or sim.getMnc()
end




function getLac()
return lac
end




function getCi()
return ci
end




function getRssi()
return rssi
end




function getCellInfo()
local i, ret = 1, ""
for i = 1, cellinfo.cnt do
if cellinfo[i] and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
ret = ret .. cellinfo[i].lac .. "." .. cellinfo[i].ci .. "." .. cellinfo[i].rssi .. ";"
end
end
return ret
end




function getCellInfoExt()
local i, ret = 1, ""
for i = 1, cellinfo.cnt do
if cellinfo[i] and cellinfo[i].mcc and cellinfo[i].mnc and cellinfo[i].lac and cellinfo[i].lac ~= 0 and cellinfo[i].ci and cellinfo[i].ci ~= 0 then
ret = ret .. cellinfo[i].mcc .. "." .. cellinfo[i].mnc .. "." .. cellinfo[i].lac .. "." .. cellinfo[i].ci .. "." .. cellinfo[i].rssi .. ";"
end
end
return ret
end




function getTa()
return cellinfo[1].ta
end











local function rsp(cmd, success, response, intermediate)
local prefix = string.match(cmd, "AT(%+%u+)")

if intermediate ~= nil then
if prefix == "+CSQ" then
local s = string.match(intermediate, "+CSQ:%s*(%d+)")
if s ~= nil then
rssi = tonumber(s)
rssi = rssi == 99 and 0 or rssi

publish("GSM_SIGNAL_REPORT_IND", success, rssi)
end
elseif prefix == "+CFUN" then
publish("FLYMODE", flyMode)
elseif prefix == "+CENG" then end
end
end





function getMultiCell(cbFnc)
multicellcb = cbFnc

ril.request("AT+CENG?")
end






function cengQueryPoll(period)

if not flyMode then        

ril.request("AT+CENG?")
else
log.warn("net.cengQueryPoll", "flymode:", flyMode)
end
if nil ~= period then

sys.timerStopAll(cengQueryPoll)
sys.timerStart(cengQueryPoll, period, period)
end
return not flyMode
end






function csqQueryPoll(period)

if not flyMode then        

ril.request("AT+CSQ")
else
log.warn("net.csqQueryPoll", "flymode:", flyMode)
end
if nil ~= period then

sys.timerStopAll(csqQueryPoll)
sys.timerStart(csqQueryPoll, period, period)
end
return not flyMode
end








function startQueryAll(...)
csqQueryPoll(arg[1])
cengQueryPoll(arg[2])
if flyMode then        
log.info("sim.startQuerAll", "flyMode:", flyMode)
end
return true
end




function stopQueryAll()
sys.timerStopAll(csqQueryPoll)
sys.timerStopAll(cengQueryPoll)
end


sys.subscribe("SIM_IND", function(para)
log.info("SIM.subscribe", simerrsta, para)
if simerrsta ~= (para ~= "RDY") then
simerrsta = (para ~= "RDY")
end

if para ~= "RDY" then

state = "UNREGISTER"

publish("NET_STATE_UNREGISTER")
else
state = "INIT"
end
end)


ril.regUrc("+CREG", neturc)
ril.regUrc("+CENG", neturc)


ril.regRsp("+CSQ", rsp)
ril.regRsp("+CENG", rsp)
ril.regRsp("+CFUN", rsp)

ril.request("AT+CREG=2")
ril.request("AT+CREG?")
ril.request("AT+CENG=1,1")

resetCellInfo()
