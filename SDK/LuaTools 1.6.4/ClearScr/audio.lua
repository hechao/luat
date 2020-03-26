








require "common"
require "misc"
require "utils"
module(..., package.seeall)

local req = ril.request
local stopCbFnc

local ttsSpeed = 50

local sVolume,sMicVolume = 4,1


local taskID









local sPriority,sType,sPath,sVol,sCb,sDup,sDupInterval,sStrategy,sStopingType

local function update(priority,type,path,vol,cb,dup,dupInterval)
print("audio.update",sPriority,priority,type,path,vol,cb,dup,dupInterval)
if sPriority then
if priority>sPriority or (priority==sPriority and sStrategy==1) then
print("audio.update1",priority,type,path,vol,cb,dup,dupInterval)

sys.publish("AUDIO_PLAY_END","NEW",{pri=priority,typ=type,pth=path,vl=vol,c=cb,dp=dup,dpIntval=dupInterval})
else
log.error("audio.update","priority error")
return false
end
else
sPriority,sType,sPath,sVol,sCb,sDup,sDupInterval = priority,type,path,vol,cb,dup,dupInterval
if vol then setVolume(vol) end
end
return true
end

local function playEnd(result)
log.info("audio.playEnd",result,sCb)
local cb = sCb
sPriority,sType,sPath,sVol,sCb,sDup,sDupInterval,sStopingType = nil
if cb then cb(result) end
end

local function isTtsApi()
return tonumber((rtos.get_version()):match("Luat_V(%d+)_"))>=29
end

local function taskAudio()
local playFnc =
{
FILE = audiocore.play,
TTS = function(text)
if isTtsApi() then
audiocore.openTTS(ttsSpeed)
local _,result = sys.waitUntil("TTS_OPEN_IND")
if result then
audiocore.playTTS(common.utf8ToUcs2(text))
else
audiocore.stopTTS()
sys.waitUntil("TTS_STOP_IND")
audiocore.closeTTS()
sys.waitUntil("TTS_CLOSE_IND")
_,result = sys.waitUntil("TTS_OPEN_IND")
if not result then return false end
end
else
req("AT+QTTS=1") req(string.format("AT+QTTS=%d,\"%s\"",2,string.toHex(common.utf8ToUcs2(text))))
end
end,
TTSCC = function(text) req("AT+QTTS=1") req(string.format("AT+QTTS=%d,\"%s\"",4,string.toHex(common.utf8ToUcs2(text)))) end,
RECORD = function(id) f,d=record.getSize() req("AT+AUDREC=1,0,2," .. id .. "," .. d*1000)end,
}

local stopFnc =
{
FILE = audiocore.stop,
TTS = function(text)
if isTtsApi() then
audiocore.stopTTS()
sys.waitUntil("TTS_STOP_IND")
audiocore.closeTTS()
sys.waitUntil("TTS_CLOSE_IND")
else
req("AT+QTTS=3") sys.waitUntil("AUDIO_STOP_END")
end
end,
TTSCC = function() req("AT+QTTS=3") sys.waitUntil("AUDIO_STOP_END") end,
RECORD = function(id) f,d=record.getSize() req("AT+AUDREC=1,0,3," .. id .. "," .. d*1000) sys.waitUntil("AUDIO_STOP_END") end,
}

while true do
log.info("audio.taskAudio begin",sPriority,sType,sPath,sVol,sCb,sDup,sDupInterval)

if not playFnc[sType] then
playEnd(3)
if sType==nil then break end
end

if playFnc[sType](sPath)==false then
playEnd(1)
if sType==nil then break end
end

local _,msg,param = sys.waitUntil("AUDIO_PLAY_END")

log.info("audio.taskAudio resume msg",msg)
if msg=="SUCCESS" then
if sDup then
if sType=="TTS" and isTtsApi() then
stopFnc[sType](sPath)
end
if sDupInterval and sDupInterval>0 then
sys.waitUntil("AUDIO_PLAY_END",sDupInterval)
if sType==nil then break end
end
else
stopFnc[sType or sStopingType](sPath)
playEnd(0)
if sType==nil then break end
end
elseif msg=="NEW" then
stopFnc[sType](sPath)
playEnd(4)

update(param.pri,param.typ,param.pth,param.vl,param.c,param.dp,param.dpIntval)
elseif msg=="STOP" then
if param=="TTS" and isTtsApi() then
stopFnc[param]()
end
playEnd(5)
break
else
stopFnc[sType](sPath)
playEnd(1)
if sType==nil then break end
end
end
end









local function urc(data,prefix)
if prefix == "+QTTS" then
local flag = string.match(data,": *(%d)",string.len(prefix)+1)

if flag=="0"  then
sys.publish("AUDIO_PLAY_END","SUCCESS")
end
end
end











local function rsp(cmd,success,response,intermediate)
local prefix = string.match(cmd,"AT(%+%u+%?*)")

if prefix == "+QTTS" then
local action = string.match(cmd,"QTTS=(%d)")
if not success then
if action=="1" or action=="2" then
sys.publish("AUDIO_PLAY_END","ERROR")
end
end
if action=="3" then
sys.publish("AUDIO_STOP_END")
end
end
end

ril.regUrc("+QTTS",urc)
ril.regRsp("+QTTS",rsp,0)

local function audioMsg(msg)
sys.publish("AUDIO_PLAY_END",msg.play_end_ind==true and "SUCCESS" or "ERROR")
end

local function ttsMsg(msg)
log.info("audio.ttsMsg",msg.type,msg.result)
local tag = {[0]="CLOSE", [1]="OPEN", [2]="PLAY", [3]="STOP"}
if msg.type==2 then
sys.publish("AUDIO_PLAY_END",msg.result and "SUCCESS" or "ERROR")
else
if tag[msg.type] then sys.publish("TTS_"..tag[msg.type].."_IND",msg.result) end
end
end

rtos.on(rtos.MSG_AUDIO,audioMsg)
if isTtsApi() then
rtos.on(rtos.MSG_TTS,ttsMsg)
end


























function play(priority,type,path,vol,cbFnc,dup,dupInterval)
if not update(priority,type,path,vol or 4,cbFnc,dup,dupInterval or 0) then
log.error("audio.play","sync error")
return false
end
if not sType or not taskID or coroutine.status(taskID)=="dead" then
taskID = sys.taskInit(taskAudio)
end
return true
end









function stop(cbFnc)
log.info("audio.stop",sType,cbFnc)
if stopCbFnc and cbFnc then cbFnc(1) return end
if sType then
if sType=="FILE" then
audiocore.stop()
elseif (sType=="TTS" and not isTtsApi()) or sType=="TTSCC" then
req("AT+QTTS=3")
elseif sType=="TTS" and isTtsApi() then
sStopingType = "TTS"
elseif sType=="RECORD" then
f,d=record.getSize() req("AT+AUDREC=1,0,3," .. sPath .. "," .. d*1000)

if cbFnc then
stopCbFnc = cbFnc
function recordPlayInd()

sys.publish("AUDIO_PLAY_END","STOP","RECORD")
if stopCbFnc then stopCbFnc(0) stopCbFnc=nil end
sys.unsubscribe("LIB_RECORD_PLAY_END_IND",recordPlayInd)
end
sys.subscribe("LIB_RECORD_PLAY_END_IND",recordPlayInd)
else
local typ = sType
sPriority,sType,sPath,sVol,sCb,sDup,sDupInterval = nil
sys.publish("AUDIO_PLAY_END","STOP",typ)
end
end
if sType~="RECORD" then
local typ = sType
sPriority,sType,sPath,sVol,sCb,sDup,sDupInterval = nil
sys.publish("AUDIO_PLAY_END","STOP",typ)
if cbFnc then cbFnc(0) end
end
else
if cbFnc then cbFnc(0) end
end
end





function setVolume(vol)
local result = audiocore.setvol(vol)
if result then sVolume = vol end
return result
end




function setMicVolume(vol)
ril.request("AT+CMIC="..audiocore.LOUDSPEAKER..","..vol)
return true
end

ril.regRsp("+CMIC",function(cmd,success)
if success then
sMicVolume = tonumber(cmd:match("CMIC=%d+,(%d+)"))
end
end)




function getVolume()
return sVolume
end




function getMicVolume(vol)
return sMicVolume
end






function setStrategy(strategy)
sStrategy=strategy
end





function setTTSSpeed(speed)
if type(speed) == "number" and speed >= 0 and speed <= 100 then
ttsSpeed = speed
return true
end
end

local function rsp(cmd, success, response, intermediate)
local prefix = string.match(cmd, "AT(%+%u+)")

log.info("net.rsp",cmd, success, response, intermediate)

if prefix == "+CSQ" then
if intermediate ~= nil then
local s = string.match(intermediate, "+CSQ:%s*(%d+)")
if s ~= nil then
rssi = tonumber(s)
rssi = rssi == 99 and 0 or rssi

publish("GSM_SIGNAL_REPORT_IND", success, rssi)
end
end
elseif prefix == "+CFUN" then
if success then publish("FLYMODE", flyMode) end
end
end


audiocore.setchannel(audiocore.LOUDSPEAKER)

setVolume(sVolume)

setMicVolume(sMicVolume)
