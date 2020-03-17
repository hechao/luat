





require "ril"
require "sys"
module(..., package.seeall)



local imsi, iccid, status





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











local function rsp(cmd, success, response, intermediate)
if cmd == "AT+CCID" then
iccid = intermediate
elseif cmd == "AT+CIMI" then
imsi = intermediate

sys.publish("IMSI_READY")
end
end









local function urc(data, prefix)

if prefix == "+CPIN" then
status = false

if data == "+CPIN: READY" then
status = true
ril.request("AT+CCID")
ril.request("AT+CIMI")
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

ril.regUrc("+CPIN", urc)

ril.request("AT+STON=0")
