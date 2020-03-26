






require"net"

module(..., package.seeall)

local publish = sys.publish
local request = ril.request
local ready = false
local gprsAttached

function isReady() return ready end


local apnname, username, password
local dnsIP



local sendMode = 0

function setAPN(apn, user, pwd)
apnname, username, password = apn, user, pwd
end

function setDnsIP(ip1,ip2)
dnsIP = "\""..(ip1 or "").."\",\""..(ip2 or "").."\""
end

function shut()
request('AT+CIPSHUT')
end


sys.subscribe("IMSI_READY", function()
if not apnname then 
local mcc, mnc = tonumber(sim.getMcc(), 16), tonumber(sim.getMnc(), 16)
apnname, username, password = apn and apn.get_default_apn(mcc, mnc) 
if not apnname or apnname == '' or apnname=="CMNET" then 
apnname = (mcc == 0x460 and (mnc == 0x01 or mnc == 0x06)) and 'UNINET' or 'CMIOT'
end
end
username = username or ''
password = password or ''
end)

local function queryStatus() request("AT+CIPSTATUS") end

ril.regRsp('+CGATT', function(a, b, c, intermediate)
local attached = (intermediate=="+CGATT: 1")
if gprsAttached ~= attached then
gprsAttached = attached
sys.publish("GPRS_ATTACH",attached)
end
if attached then
request("AT+CIPSTATUS")
elseif net.getState() == 'REGISTERED' then
sys.timerStart(request, 2000, "AT+CGATT?")
end
end)
ril.regRsp('+CIPSHUT', function(cmd, success)
if success then
ready = false
sys.publish("IP_SHUT_IND")
end
if net.getState() ~= 'REGISTERED' then return end
request('AT+CGATT?')
end)

ril.regUrc("STATE", function(data)
local status = data:sub(8, -1)
log.info("link.STATE", "IP STATUS", status)
ready = status == "IP PROCESSING" or status == "IP STATUS"
if status == 'PDP DEACT' then
sys.timerStop(queryStatus)
request('AT+CIPSHUT') 
return
elseif status == "IP INITIAL" then
if net.getState() ~= 'REGISTERED' then return end
request(string.format('AT+CSTT="%s","%s","%s"', apnname, username or "", password or ""))
request("AT+CIICR")
elseif status == "IP START" then
request("AT+CIICR")
elseif status == "IP CONFIG" then

elseif status == "IP GPRSACT" then        
request("AT+CIFSR")
request("AT+CIPSTATUS")
if dnsIP then request("AT+CDNSCFG="..dnsIP) end
request("AT+CDNSCFG?")
return
elseif status == "IP PROCESSING" or status == "IP STATUS" then
sys.timerStop(queryStatus)
publish("IP_READY_IND")
return
end
sys.timerStart(queryStatus, 2000)
end)

ril.regUrc("+PDP", function() publish('PDP_DEACT_IND') end)

sys.subscribe('PDP_DEACT_IND', function()
ready = false
sys.publish('IP_ERROR_IND')
sys.timerStart(queryStatus, 2000) 
end)


local inited = false

local function initial()
if not inited then
inited = true
request("AT+CIICRMODE=2") 
request("AT+CIPMUX=1") 
request("AT+CIPHEAD=1")
request("AT+CIPQSEND="..sendMode) 
end
end

function setSendMode(mode)
sendMode = mode or 0
end


sys.subscribe("NET_STATE_REGISTERED", function()
initial()
request('AT+CGATT?')
end)
