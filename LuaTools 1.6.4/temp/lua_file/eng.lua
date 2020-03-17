module(...,package.seeall)
local gb2312toucs2,binstohexs = common.gb2312toucs2,common.binstohexs
local atoTstStp,appId,findSim = 0
local loopbackChannel = audiocore.LOOPBACK_AUX_LOUDSPEAKER
local keyTstAudio = "0000"
local function AudioPlayCb(res)
	audio.setloopback(1,loopbackChannel,0,0)
	if keyTstAudio == "1111" then
		sys.dispatch("ATO_TST_NXT_IND",5)
		keyTstAudio = "0000"
		audio.setloopback(0,loopbackChannel,0,0)
	end
end
local function PlaySimFind()
	if findSim then
		audio.setloopback(0,loopbackChannel,0,0)
		audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("找到GSM网络")),false,7,AudioPlayCb)
	else
		audio.setloopback(0,loopbackChannel,0,0)
		audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("未插卡")),false,7,AudioPlayCb)
	end	
end
local function CloseEngApp()
	if appId ~= nil then
		sys.deregapp(appId)
	end
	appId = nil	
	atoTstStp = 0
	sys.dispatch("ENG_APP_IND",false)
	sys.dispatch("CLOSE_ENG_IND")
	gpsapp.StopGpsApp(false,true)
	print("CloseEngApp")
end
local lastKey
local AudioBatLev
local AudioRSSI
local KeySOSPressed = false
local function ProcKey(key)
	if atoTstStp == 4 and key >= keypad.KEY_1 and key <= keypad.KEY_4 then
		print("key test"..key)
		audio.setloopback(0,loopbackChannel,0,0)
		if key == keypad.KEY_1 or key == keypad.KEY_2 then
			net.csqquery()
			if audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2(key)),false,7,AudioPlayCb) then
				keyTstAudio = string.sub(keyTstAudio,1,key-keypad.KEY_1).."1"..string.sub(keyTstAudio,key-keypad.KEY_1+2,-1)
			end
		elseif key == keypad.KEY_3 then 
			net.csqquery()
			print("AudioBatLev",pmdapp.GetBatLev())
			AudioBatLev = "电量为"..(pmdapp.GetBatLev())
			if audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2(AudioBatLev)),false,7,AudioPlayCb) then
				keyTstAudio = string.sub(keyTstAudio,1,key-keypad.KEY_1).."1"..string.sub(keyTstAudio,key-keypad.KEY_1+2,-1)
			end
		elseif key == keypad.KEY_4 then
			print("AudioRSSI",smsapp.GetSignalPercentage())
			AudioRSSI = "信号强度为"..(smsapp.GetSignalPercentage())
			if audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2(AudioRSSI)),false,7,AudioPlayCb) then
				keyTstAudio = string.sub(keyTstAudio,1,key-keypad.KEY_1).."1"..string.sub(keyTstAudio,key-keypad.KEY_1+2,-1)
			end
		end
	elseif atoTstStp == 5 then
		if key == keypad.KEY_SOS then
			KeySOSPressed = true
			audio.setloopback(0,loopbackChannel,0,0)
			cc.dial("112")
			audioapp.SetChannel(audioapp.LOUDSPEAKER,false,7)
		elseif key ~=keypad.KEY_SOS and KeySOSPressed then
			KeySOSPressed = false
			audio.setloopback(0,loopbackChannel,0,0)
			cc.hangup()
			audioapp.SetChannel(audioapp.RECEIVER,false)
			sys.dispatch("ATO_TST_NXT_IND",6)
		end
	elseif atoTstStp == 6 then
		if (lastKey == keypad.KEY_2 and key == keypad.KEY_4) or (lastKey == keypad.KEY_4 and key == keypad.KEY_2) then
			lastKey = nil
			sys.timer_stop(CloseEngApp)
			CloseEngApp()
			print("key24 end test")
		else
			lastKey = key
		end
	end	
end
local engApp = {
	MMI_KEYPAD_IND = ProcKey,	
}
local function OpenEngApp()
    if appId == nil then
		appId = sys.regapp(engApp)
	end	
	net.csqquery()
	sys.dispatch("ENG_APP_IND",true)
	PlaySimFind()
	gpsapp.StartGpsApp(gpsapp.GPSAPP_ENGINE_OPEN,nil,nil)
end
function AtoTst()
	OpenEngApp()
	sys.dispatch("ATO_TST_NXT_IND",1)
end
local vibCnt = 0
local VIB_MAX_CNT = 3
local function VibTimerFun()
	vibCnt = vibCnt + 1
	if vibCnt % 2 == 1 then
		print("Vib Off")
		pmd.ldoset(0, pmd.LDO_VIB)
	else
		print("Vib On")
		pmd.ldoset(1, pmd.LDO_VIB)
	end
	if vibCnt < (VIB_MAX_CNT*2) - 1 then
		sys.timer_start(VibTimerFun,1000)
	else
		sys.dispatch("ATO_TST_NXT_IND",3)
		vibCnt = 0
	end
end
local function VibTst()
	--[[print("Vib On")
	pmd.ldoset(1, pmd.LDO_VIB)
	sys.timer_start(VibTimerFun,1000)]]
	sys.dispatch("ATO_TST_NXT_IND",3)
end
local function HandsetLoopTst()
	print("loop tst")
	sys.dispatch("ATO_TST_NXT_IND",4)
end
local function AtoCloseEngApp()
	sys.timer_start(CloseEngApp,30000)
	lastKey = nil
end
function AtoTstNxt(id,data)
	print("AtoTstNxt",data)
	atoTstStp = data
	if data == 1 then
		lightapp.AllLtOn()
		sys.dispatch("ATO_TST_NXT_IND",data+1)
	elseif atoTstStp == 2 then
		VibTst()
	elseif atoTstStp == 3 then	
		HandsetLoopTst()		
	elseif atoTstStp == 4 then
		print("key test")
	elseif atoTstStp == 5 then
		print("sos test")
	elseif atoTstStp == 6 then		
		print("end test")
		AtoCloseEngApp()
	end	
end
local function SimInd(id,data)
	if data == "RDY" then
		findSim = true
	elseif data == "NIST" then
		findSim = false
	end
	return true
end
local function ProcEngGps(id,GpsState)
	if GpsState then
		gpsapp.StartGpsApp(gpsapp.GPSAPP_ENGINE_OPEN,nil,nil)
	else
		gpsapp.StopGpsApp(false,true)
		print("StopGpsApp Engine")
		sys.timer_start(ProcEngGps,300000,"GPSAPP_ENGINE_LOCATION_IND",true)
	end
	return true
end
sys.regapp(AtoTstNxt,"ATO_TST_NXT_IND")
sys.regapp(SimInd,"SIM_IND")
sys.regapp(ProcEngGps,"GPSAPP_ENGINE_LOCATION_IND")
