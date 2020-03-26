





require "ril"
require "sys"
module(..., package.seeall)



local imsi, iccid, status
local sNumber,bQueryNumber = ""





function getIccid()
return iccid
end





function getImsi()
return imsi
end





function getMcc()
return (imsi ~= nil and imsi ~= "") and string.sub(imsi, 1, 3) or ""
end





function getMnc()
return (imsi ~= nil and imsi ~= "") and string.sub(imsi, 4, 5) or ""
end





function getStatus()
return status
end




function getType()
if type(rtos.is_vsim)=="function" then
return status and (rtos.is_vsim() and "VSIM" or "REAL_SIM") or "NO_RDY_SIM"
else
return "UNSUPPORT"
end 
end





function setQueryNumber(flag)
bQueryNumber = flag
end






function getNumber()
return sNumber or ""
end











local function rsp(cmd, success, response, intermediate)
if cmd == "AT+CCID" then
iccid = intermediate
elseif cmd == "AT+CIMI" then
imsi = intermediate

sys.publish("IMSI_READY")
elseif cmd == "AT+CNUM" then
if success then
if intermediate then sNumber = intermediate:match("%+CNUM:%s*\".-\",\"[%+]*(%d+)\",") end
else
sys.timerStart(ril.request,5000,"AT+CNUM")
end
end
end









local function urc(data, prefix)

if prefix == "+CPIN" then
status = false

if data == "+CPIN: READY" then
status = true
ril.request("AT+CCID")
ril.request("AT+CIMI")
if bQueryNumber then ril.request("AT+CNUM") end
sys.publish("SIM_IND", "RDY")

elseif data == "+CPIN: NOT INSERTED" then
sys.publish("SIM_IND", "NIST")
else

if data == "+CPIN: SIM PIN" then
sys.publish("SIM_IND_SIM_PIN")
end
sys.publish("SIM_IND", "NORDY")
end
end
end


ril.regRsp("+CCID", rsp)

ril.regRsp("+CIMI", rsp)
ril.regRsp("+CNUM", rsp)

ril.regUrc("+CPIN", urc)

ril.request("AT+STON=0")
