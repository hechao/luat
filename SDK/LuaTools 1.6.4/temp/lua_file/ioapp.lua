local base = _G
module("ioapp",package.seeall)
local print = base.print
local IO = {}
local function PowerLt(t)
	if t == IO.powerLtVal then
		return
	end
	if t then
		pio.pin.sethigh(IO.powerLt)
	else
		pio.pin.setlow(IO.powerLt)
	end
	IO.powerLtVal = t
end
local function GsmLt(t)
	if t then
		pio.pin.sethigh(IO.gsmLt)
	else
		pio.pin.setlow(IO.gsmLt)
	end
	IO.gsmLtVal = t
end
local function GpsLt(t)
	if t then
		pio.pin.sethigh(IO.gpsLt)
	else
		pio.pin.setlow(IO.gpsLt)
	end
	IO.gpsLtVal = t
end
function AllLtOn()
	PowerLt(true)
	GsmLt(true)
	GpsLt(true)	
end
local function AllLtOff()
	PowerLt(false)
	GsmLt(false)
	GpsLt(false)
end
local function SetEngMode(id,data)
	IO.engMode = data
	if not data then
		StartLtTimer()
	end
end
local function UpdatePowerLt()
	if IO.engMode then
		return
	end
	local lt = false
	if pmdapp.IsLowPower() then
		if IO.powerLtVal then
			lt = false
		else
			lt = true
		end		
	elseif filestore.IsHideStatus() or pmdapp.IsCharging() then
		if IO.ltTimerCnt % 5 == 0 then
			if IO.powerLtVal then
				lt = false
			else
				lt = true
			end			
		else
			lt = IO.powerLtVal
		end		
	elseif pmdapp.IsChargerOn() and pmdapp.IsChargeFinish() then
		lt = true		
	elseif not pmdapp.IsChargerOn() then
		lt = false		
	end
	PowerLt(lt)
end
local function UpdateGsmLt()
	if IO.engMode then
		return
	end
	local lt = false		
	--print("UpdateGsmLt",dataapp.IsSckConnect(),IO.ltTimerCnt,IO.gsmLtVal,net.getstate())
	if dataapp.IsSckConnect() then
		if IO.ltTimerCnt % 5 == 0 then
			if IO.gsmLtVal then
				lt = false
			else
				lt = true
			end			
		else
			lt = IO.gsmLtVal
		end	
	elseif net.getstate() == "REGISTERED" then
		lt = false
	else
		lt = true
	end
	GsmLt(lt)
end
local function UpdateGpsLt()
	if IO.engMode then
		return
	end
	local lt = false		
	if IO.lbsGpsLtCnt < (IO.lbsLtMaxCnt*2) and dataapp.GetLbsDwHandle() > 0 then
		if IO.ltTimerCnt % 2 == 0 then
			lt = false
		else
			lt = true
		end
		IO.lbsGpsLtCnt = IO.lbsGpsLtCnt + 1
	elseif IO.lbsGpsLtCnt >= (IO.lbsLtMaxCnt*2) then
		dataapp.SetLbsDwHandle(false)
		IO.lbsGpsLtCnt = 0
		lt = false
	end
	GpsLt(lt)
end
local function CheckOpenLtTimer()
	if pmdapp.IsCharging() then
		return true
	end		
	if pmdapp.IsLowPower() then
		return true
	end	
	if filestore.IsHideStatus() then
		return true
	end
	if dataapp.IsSckConnect() then
		return true
	end
	if IO.lbsGpsLtCnt <= (IO.lbsLtMaxCnt*2) and dataapp.GetLbsDwHandle() > 0 then
		return true
	end
end
local function LtTimerFun()
	GarbageCollect()
	IO.ltTimerOpen = false
	IO.ltTimerCnt = IO.ltTimerCnt + 1
	UpdatePowerLt()
	UpdateGsmLt()
	UpdateGpsLt()
	if CheckOpenLtTimer() then
		StartLtTimer()
	else
		StopLtTimer()
	end
end
function StartLtTimer()
	if not IO.ltTimerOpen then
		sys.timer_start(LtTimerFun,600)
		IO.ltTimerOpen = true		
	end
	return true
end
function StopLtTimer()
	if IO.ltTimerOpen then
		sys.timer_stop(LtTimerFun)
		IO.ltTimerOpen = false		
	end
	IO.ltTimerCnt = 0
end
local function InitIO()
	pio.pin.setdir( pio.OUTPUT, pio.P0_8, pio.P0_9,pio.P0_10)
	IO.powerLt = pio.P0_8
	IO.gsmLt = pio.P0_9
	IO.gpsLt = pio.P0_10
	IO.powerLtVal = false
	IO.gsmLtVal = false
	IO.gpsLtVal = false
	IO.engMode = false
	IO.lbsGpsLtCnt = 0
	IO.lbsLtMaxCnt = 1
	IO.gpsLtMaxCnt = 3
	IO.ltTimerOpen = false
	IO.ltTimerCnt = 0
	StartLtTimer()
end
sys.regapp(StartLtTimer,"NET_STATE_CHANGED","SCK_CONNECT_IND","SCK_DISCONNECT_IND","DW_IND","CLOCK_IND","CHG_IND","HIDE_IND")
sys.regapp(SetEngMode,"ENG_APP_IND")
InitIO()
