





require "ril"
local req = ril.request
module(..., package.seeall)



local sn, imei, calib, ver, muid
local setSnCbFnc,setImeiCbFnc,setClkCbFnc

local function timeReport()
sys.publish("TIME_CLK_IND")
sys.timerStart(setTimeReport,2000)
end

function setTimeReport()
sys.timerStart(timeReport,(os.time()%60==0) and 50 or (60-os.time()%60)*1000)
end











local function rsp(cmd, success, response, intermediate)
local prefix = string.match(cmd, "AT(%+%u+)")

if cmd == "AT+WISN?" then
sn = intermediate
if setSnCbFnc then setSnCbFnc(true) end
sys.publish('SN_READY_IND')

elseif cmd == "AT+CGSN" then
imei = intermediate
if setImeiCbFnc then setImeiCbFnc(true) end
sys.publish('IMEI_READY_IND')
elseif cmd == 'AT+VER' then
ver = intermediate

elseif cmd == "AT+ATWMFT=99" then
log.info('misc.ATWMFT', intermediate)
if intermediate == "SUCC" then
calib = true
else
calib = false
end
elseif prefix == '+CCLK' then
if success then
sys.publish('TIME_UPDATE_IND')
setTimeReport()
end
if setClkCbFnc then setClkCbFnc(getClock(),success) end
elseif cmd:match("AT%+WISN=") then
if success then
req("AT+WISN?")
else
if setSnCbFnc then setSnCbFnc(false) end
end
elseif cmd:match("AT%+WIMEI=") then
if success then
req("AT+CGSN")
else
if setImeiCbFnc then setImeiCbFnc(false) end
end
elseif cmd:match("AT%+MUID?") then
if intermediate then muid = intermediate:match("+MUID:%s*\"(.+)\"") end
end
end

function getVersion()
return ver
end







function setClock(t,cbFnc)
if type(t) ~= "table" or (t.year-2000>38) then
if cbFnc then cbFnc(getClock(),false) end
return
end
setClkCbFnc = cbFnc
req(string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d+32\"", string.sub(t.year, 3, 4), t.month, t.day, t.hour, t.min, t.sec), nil, rsp)
end



function getClock()
return os.date("*t")
end



function getWeek()
local clk = os.date("*t")
return ((clk.wday == 1) and 7 or (clk.wday - 1))
end



function getCalib()
return calib
end








function setSn(s, cbFnc)
if s ~= sn then
setSnCbFnc = cbFnc
req("AT+WISN=\"" .. s .. "\"") 
else
if cbFnc then cbFnc(true) end
end
end




function getSn()
return sn or ""
end






function setImei(s, cbFnc)
if s ~= imei then
setImeiCbFnc = cbFnc
req("AT+WIMEI=\"" .. s .. "\"")
else
if cbFnc then cbFnc(true) end
end
end




function getImei()
return imei or ""
end



function getVbatt()
local v1, v2, v3, v4, v5 = pmd.param_get()
return v2
end





function getMuid()
return muid or ""
end














function openPwm(id, period, level)
assert(type(id) == "number" and type(period) == "number" and type(level) == "number", "openpwm type error")
assert(id == 0 or id == 1, "openpwm id error: " .. id)
local pmin, pmax, lmin, lmax = 80, 1625, 1, 100
if id == 1 then pmin, pmax, lmin, lmax = 0, 7, 1, 15 end
assert(period >= pmin and period <= pmax, "openpwm period error: " .. period)
assert(level >= lmin and level <= lmax, "openpwm level error: " .. level)
req("AT+SPWM=" .. id .. "," .. period .. "," .. level)
end




function closePwm(id)
assert(id == 0 or id == 1, "closepwm id error: " .. id)
req("AT+SPWM=" .. id .. ",0,0")
end


ril.regRsp("+ATWMFT", rsp)
ril.regRsp("+WISN", rsp)
ril.regRsp("+CGSN", rsp)
ril.regRsp("+MUID", rsp)
ril.regRsp("+WIMEI", rsp)
ril.regRsp("+AMFAC", rsp)
ril.regRsp('+VER', rsp, 4, '^[%w_]+$')
req('AT+VER')

req("AT+ATWMFT=99")

req("AT+WISN?")

req("AT+CGSN")
req("AT+MUID?")
setTimeReport()
