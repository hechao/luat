local base = _G
module("ttsalarmapp",package.seeall)
local gb2312toucs2 = common.gb2312toucs2
local ucs2betogb2312 = common.ucs2betogb2312
local binstohexs = common.binstohexs
local appId
local function TtsAlarm(text,dup)
	print("TtsAlarm",text)
	audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2(text)),dup,4,nil)
end
local function ProcKey(key)
	print("TtsAlarm ProcKey",key)
	if key == keypad.KEY_4 then
		audioapp.Stop()
		ExitTtsAlarmApp()
	end	
end
local ttsAlarmApp = {
	MMI_KEYPAD_IND = ProcKey,	
}
local function TtsAlmTimerFunc()
	audioapp.Stop()
	ExitTtsAlarmApp()
end
local function StopTtsAlmTimer()
	sys.timer_stop()
end
local function StartTtsAlmTimer()
	sys.timer_start(TtsAlmTimerFunc,30000)
end
function ExitTtsAlarmApp()
	if appId ~= nil then
		sys.deregapp(appId)
		appId = nil
		StopTtsAlmTimer()
	end
end
function EnterTtsAlarmApp(almTime)
	if filestore.IsHideStatus() then
		return
	end
	if appId == nil then
		appId = sys.regapp(ttsAlarmApp)
		TtsAlarm("闹钟：："..base.tonumber(string.sub(almTime,1,2)).."点"..((string.sub(almTime,3,4)=="00") and "整" or (string.sub(almTime,3,4).."分")),true)
		StartTtsAlmTimer()
	end
end
local function Proc(id,data)
	if id == "CLOCK_IND" then
		local alm,almTime = filestore.IsAlarmValid()
		if alm then
			EnterTtsAlarmApp(almTime)
		end
	elseif id == "AUDIOAPP_STOP" then
		ExitTtsAlarmApp()
	end	
	return true
end
function PlayCurTime()
	if filestore.IsHideStatus() then
		return
	end
	local clk = string.sub(misc.getclockstr(),7,10)
	TtsAlarm("现在时刻：："..base.tonumber(string.sub(clk,1,2)).."点"..((string.sub(clk,3,4)=="00") and "整" or (string.sub(clk,3,4).."分"))..";电量"..pmdapp.GetBatLev().."%",false)
end
sys.regapp(Proc,"CLOCK_IND","AUDIOAPP_STOP")
