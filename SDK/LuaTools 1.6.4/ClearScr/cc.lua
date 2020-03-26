






module(..., package.seeall)
require"ril"
require"pm"


CONNECTED = 0

HOLD = 1

DIALING = 2
ALERTING = 3

INCOMING = 4
WAITING = 5

DISCONNECTING = 98

DISCONNECTED = 99

local req = ril.request
local publish = sys.publish


local ccready = false

local call_list = {n= 0}




function anyCallExist()
return call_list.n ~= 0
end





function getState(num)
return call_list[num] or DISCONNECTED
end






function dial(num, delay)
if num == "" or num == nil then return false end
pm.wake("cc")
req(string.format("%s%s;", "ATD", num), nil, nil, delay)
call_list[num] = DIALING
return true
end





function hangUp(num)
if call_list[num] == DISCONNECTING or call_list[num] == DISCONNECTED then return end
if audio and type(audio.stop)=="function" then audio.stop() end
req("AT+CHUP")
call_list[num] = DISCONNECTING
end





function accept(num)
if call_list[num] ~= INCOMING then return end
if audio and type(audio.stop)=="function" then audio.stop() end
req("ATA")
call_list[num] = CONNECTING
end










function transVoice(data, loop, downLinkPlay)
local f = io.open("/RecDir/rec000", "wb")

if f == nil then
log.error("transVoice:open file error")
return false
end


if string.sub(data, 1, 7) == "#!AMR\010\060" then

elseif string.byte(data, 1) == 0x3C then
f:write("#!AMR\010")
else
log.error('cc.transVoice', 'must be 12.2K AMR')
return false
end

f:write(data)
f:close()

req(string.format("AT+AUDREC=%d,%d,2,0,50000", downLinkPlay == true and 1 or 0, loop == true and 1 or 0))

return true
end






function dtmfDetect(enable, sens)
if enable == true then
if sens then
req("AT+DTMFDET=2,1," .. sens)
else
req("AT+DTMFDET=2,1,3")
end
end

req("AT+DTMFDET=" .. (enable and 1 or 0))
end







function sendDtmf(str, playtime, intvl)
if string.match(str, "([%dABCD%*#]+)") ~= str then
log.error("sendDtmf: illegal string " .. str)
return false
end

playtime = playtime and playtime or 100
intvl = intvl and intvl or 100

req("AT+SENDSOUND=" .. string.format("\"%s\",%d,%d", str, playtime, intvl))
end

local dtmfnum = { [71] = "Hz1000", [69] = "Hz1400", [70] = "Hz2300" }
local function parsedtmfnum(data)
local n = tonumber(string.match(data, "(%d+)"))
local dtmf

if (n >= 48 and n <= 57) or (n >= 65 and n <= 68) or n == 42 or n == 35 then
dtmf = string.char(n)
else
dtmf = dtmfnum[n]
end

if dtmf then
publish("CALL_DTMF_DETECT", dtmf) 
end
end

local function ccurc(data, prefix)
if data == "CALL READY" then 
ccready = true
publish("CALL_READY")
req("AT+CCWA=1")
elseif prefix == "+DTMFDET" then
parsedtmfnum(data)
else
req('AT+CLCC')
if data == "CONNECT" and audio and type(audio.stop)=="function" then audio.stop() end 
end
end

local function ccrsp() req('AT+CLCC') end


ril.regUrc("CALL READY", ccurc)
ril.regUrc("CONNECT", ccurc)
ril.regUrc("NO CARRIER", ccurc)
ril.regUrc("NO ANSWER", ccurc)
ril.regUrc("BUSY", ccurc)
ril.regUrc("+CLIP", ccurc)
ril.regUrc("+CCWA", ccurc)
ril.regUrc("+DTMFDET", ccurc)

ril.regRsp("D", ccrsp)
ril.regRsp("A", ccrsp)
ril.regRsp("+CHUP", ccrsp)
ril.regRsp("+CHLD", ccrsp)
ril.regRsp("+CLCC", function(cmd, success, response, intermediate)
if success then
local new = {n = 0 }
if intermediate and intermediate:len() > 0 then
for id, dir, stat, num in intermediate:gmatch('%+CLCC:%s*(%d+),(%d),(%d),%d,%d,"([^"]*)".-\r\n') do
stat = tonumber(stat)
if stat == WAITING then
req('AT+CHLD=1' .. id)
return
end
if call_list[num] ~= stat then
if stat == INCOMING or stat == CONNECTED then
pm.wake('cc')
publish(stat == INCOMING and 'CALL_INCOMING' or 'CALL_CONNECTED', num)
end
end
new[num] = stat
new.n = new.n + 1
end
end
call_list = new
if new.n == 0 then
publish('CALL_DISCONNECTED')
pm.sleep('cc')
end
end
end)


req("ATX4")

req("AT+CLIP=1")
req("ATS7=60")
