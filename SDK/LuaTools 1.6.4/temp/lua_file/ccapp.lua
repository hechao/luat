module(...,package.seeall)
local fs = require"filestore"
local gb2312toucs2 = common.gb2312toucs2
local binstohexs = common.binstohexs
local curNum,curConnTm,curConnSecs,curConnBgn,curConnEnd,appId = "","",0,0,0
local IDLE,DIALING,INCOMING,CONNECTED,DISCONNECTING,DISCONNECTED = 1,2,3,4,5,6
local state = IDLE
local playOutgoingAudio,isProcMonitor,isProcSos,isSosTts
local sosNumTable,SOS_TIMER_PERIOD = {},25000
local monitorNumTable,MONITOR_TIMER_PERIOD = {},25000
local sosCcInf = ""
local isShutLink,isShutSck
local function ShutLink()
	if not isShutLink then
		isShutSck,isShutLink = dataapp.IsSckConnect(),true
		link.shut()
		print("ShutLink",isShutSck)
	end
end
local function ReopenLink()
	print("ReopenLink",isShutLink,isShutSck,state,IsCcing())
	if isShutLink and not IsCcing() then
		isShutLink = false
		link.reset()
		if isShutSck then
			isShutSck = false
			dataapp.StartSckConnect()
		end
	end
end
local function ProcChannel(key)
	if (state == CONNECTED or state == DIALING) and (keypad.KEY_SOS == key) then
		audioapp.SetChannel((audioapp.GetChannel() == audioapp.RECEIVER) and audioapp.LOUDSPEAKER or audioapp.RECEIVER,true,fs.GetPara(fs.PARA_CALLVOL))
	end
end
local function ProcCallVol(key)
	if keypad.KEY_1 == key or keypad.KEY_2 == key then
		local tmpVol = fs.GetPara(fs.PARA_CALLVOL)
		if keypad.KEY_1 == key then			
			if tmpVol < audioapp.AUDIO_VOL_MAX_LEV then
				tmpVol = tmpVol + 1
				fs.SetPara(fs.PARA_CALLVOL,tmpVol,true)
			end			
		elseif keypad.KEY_2 == key then
			if tmpVol > 1 then
				tmpVol = tmpVol - 1
				fs.SetPara(fs.PARA_CALLVOL,tmpVol,true)
			end			
		end
		audioapp.SetChannel(audioapp.GetChannel(),true,tmpVol)
	end
end
local function ProcKey(key)
	if isProcMonitor or isProcSos then return end
	if state == DIALING or state == CONNECTED then
		if key == keypad.KEY_4 then
			cc.hangup()
			state = DISCONNECTING
			ProcSosNumEnd()			
		end
		ProcChannel(key)
		ProcCallVol(key)
	elseif state == INCOMING then		
		if key == keypad.KEY_3 then
			cc.accept()
		elseif key == keypad.KEY_4 then
			cc.hangup()
			state = DISCONNECTING			
		end
	elseif state == DISCONNECTED then
		if key == keypad.KEY_4 then
			sys.timer_stop(DisTimerFun)
			DisTimerFun()
		end
	end
end
local function Connect()
	curConnTm = "20"..misc.getclockstr()
	curConnBgn = os.time()
	audioapp.Stop()		
	audioapp.SetChannel(audioapp.RECEIVER,true,(isProcMonitor or isProcSos) and 0 or fs.GetPara(fs.PARA_CALLVOL))
	state = CONNECTED	
	ProcSosNumEnd()	
	ProcMonitorNumEnd()
end
DisTimerFun = function()
	if not curConnTm or curConnTm == "" then
		curConnTm = "20"..misc.getclockstr()
		curConnSecs = 0
	else
		curConnSecs = os.time() - curConnBgn
	end
	if isProcSos then
		sosCcInf = sosCcInf..curNum.."="..curConnTm.."-"..curConnSecs.."!"
	end
	if appId ~= nil then
		sys.deregapp(appId)
		appId = nil
	end
	state = IDLE
	audioapp.SetChannel(audioapp.RECEIVER,true)	
	if not ProcSosNum() and not ProcMonitorNum() then	
		ReopenLink()
		
	end
end
local function Disconnect(data)
	audioapp.Stop()
	state = DISCONNECTED
	sys.timer_start(DisTimerFun,1*1000)
end
local ccApp = {
	MMI_KEYPAD_IND = ProcKey,
	CALL_CONNECTED = Connect,
	CALL_DISCONNECTED = Disconnect,
}
local function PlayCallRing(num)
	print("PlayCallRing",state)
	if state ~= INCOMING then return end
	if not audioapp.Play(audioapp.CALL_RING,"/ldata/R_CALL_"..fs.GetPara(fs.PARA_RINGTYP)..".mp3",true,fs.GetPara(fs.PARA_RINGVOL)) then
		StartCallRingTimer(num)
	end
end
function StartCallRingTimer(num)
	sys.timer_start(PlayCallRing,1000,num)
end
local function IsFamilyNum(num)
	return num and string.find(num,"^55[1-9]$")
end
local function Incoming(id,num)
	print("Incoming",id,num)
	if appId ~= nil then print("Incoming exist call") return end
	if fs.IsHideStatus() or (not fs.IsRelativeNum(num) and not fs.IsWhiteNum(num) and not IsFamilyNum(num) and not (num == nil) and not (num == "")) then
		cc.hangup()
		if num and num ~= "" and fs.IsRelativeNum(num) then
			dataapp.SndToSvr(dataapp.TERM_RPT,dataapp.REL_INCOMING_RPT,nil,nil,false,nil,nil)
		end
		return
	end
	num = num or ""
	
	pm.wake("cc")
	appId = sys.regapp(ccApp)
	state = INCOMING
	PlayCallRing(num)
end
local function PlayOutgoingAudioCb(res,num)
	ShutLink()
	playOutgoingAudio = nil
	if not cc.dial(num,2000) then
		audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("Î´ÕÒµ½GSMÍøÂç")),false,4,nil)
		ReopenLink()
		return false
	end	
	print("dial "..num)
	curNum = num
	curConnTm = ""
	curConnSecs = 0
	appId = sys.regapp(ccApp)
	state = DIALING
	StartSosDialTimer()	
	StartMonitorDialTimer()	
	audioapp.SetChannel(audioapp.RECEIVER,false,(isProcMonitor or isProcSos) and 0 or fs.GetPara(fs.PARA_CALLVOL))
	return true
end
function DialNum(num)	
	if appId ~= nil then print("DialNum exist call") return false end
	if fs.IsHideStatus() and not isProcMonitor and not isProcSos then
		print("IsHideStatus")
		return false
	end
	if not num or num == "" then
		audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("ºÅÂëÎª¿Õ")),false,4,nil)
		return false
	end
	if playOutgoingAudio then return false end
	if isProcMonitor or isProcSos then
		return PlayOutgoingAudioCb(true,num)
	elseif isProcSos then
		if isSosTts then
			return PlayOutgoingAudioCb(true,num)
		else
			isSosTts = true
			playOutgoingAudio = true
			if not audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("ÕýÔÚ½ô¼±ºô½Ð£¬ÇëÉÔºó")),false,4,PlayOutgoingAudioCb,num) then
				return PlayOutgoingAudioCb(true,num)
			end			
		end
	else
		playOutgoingAudio = true
		if not audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("ÕýÔÚºô½Ð£¬ÇëÉÔºó")),false,4,PlayOutgoingAudioCb,num) then
			return PlayOutgoingAudioCb(true,num)
		end
	end
	return true
end
function ProcMonitorBgn(num)
	if appId ~= nil then return false end
	isProcMonitor = true
	if not DialNum(num) then
		isProcMonitor = false
	end
end
function ProcMonitorEnd()
	if isProcMonitor then
		isProcMonitor = false				
	end
end
local function SosDialTimerFun()	
	cc.hangup()
	state = DISCONNECTING	
end
function StopSosDialTimer()
	if isProcSos then sys.timer_stop(SosDialTimerFun) end
end
function StartSosDialTimer()
	if isProcSos then sys.timer_start(SosDialTimerFun,SOS_TIMER_PERIOD) end
end
function ProcSosNumEnd()
	print("ProcSosNumEnd",isProcSos)
	if isProcSos then
		StopSosDialTimer()
		isProcSos,isSosTts = false,false
		sosNumTable = {}		
	end
end
function ProcSosNum()
	print("ProcSosNum",isProcSos)
	if not isProcSos then return end
	if #sosNumTable <= 0 then
		ProcSosNumEnd()
		return
	end	
	StopSosDialTimer()
	if not DialNum(table.remove(sosNumTable,1)) then ProcSosNum() end	
end
function ProcSosNumBegin(numTable)
	if appId ~= nil then print("exist cc") return end		
	if type(numTable) ~= "table" then print("para err",type(numTable)) return end		
	isProcSos,isSosTts = true,false
	sosNumTable = numTable
	ProcSosNum()
end
local function MonitorDialTimerFun()	
	cc.hangup()
	state = DISCONNECTING	
end
function StopMonitorDialTimer()
	if isProcMonitor then sys.timer_stop(MonitorDialTimerFun) end
end
function StartMonitorDialTimer()
	if isProcMonitor then sys.timer_start(MonitorDialTimerFun,MONITOR_TIMER_PERIOD) end
end
function ProcMonitorNumEnd()
	print("ProcMonitorNumEnd",isProcMonitor)
	if isProcMonitor then
		StopMonitorDialTimer()
		isProcMonitor = false
		monitorNumTable = {}		
	end
end
function ProcMonitorNum()
	print("ProcMonitorNum",isProcMonitor)
	if not isProcMonitor then return end
	if #monitorNumTable <= 0 then
		ProcMonitorNumEnd()
		return
	end	
	StopMonitorDialTimer()
	if not DialNum(table.remove(monitorNumTable,1)) then ProcMonitorNum() end	
end
function ProcMonitorNumBegin(numTable)
	if appId ~= nil then print("exist cc") return end		
	if type(numTable) ~= "table" then print("para err",type(numTable)) return end		
	isProcMonitor = true
	monitorNumTable = numTable
	ProcMonitorNum()
end
function IsCcing()
	return state ~= IDLE
end
function GetSosCcInf()
	local res = sosCcInf
	sosCcInf = ""
	return res
end
sys.regapp(Incoming,"CALL_INCOMING")
