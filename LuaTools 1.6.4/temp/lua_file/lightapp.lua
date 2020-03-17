local base = _G
module("lightapp",package.seeall)
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
	return true
end
function PowerTwinOn()
	if IO.powerTwinking then
		if not IO.engMode then
			PowerLt(true)
		end
		sys.timer_start(PowerTwinOff,IO.powerCurrentMode.ON)
	end
end
function PowerTwinOff()
	if IO.powerTwinking then
		if not IO.engMode then
			PowerLt(false)
		end
		sys.timer_start(PowerTwinOn,IO.powerCurrentMode.OFF)
	end
end
local function PowerLtTwinkle(TwinkleMode)
	IO.powerTwinking = true
	IO.powerCurrentMode = TwinkleMode
	if IO.powerLtVal then
		sys.timer_start(PowerTwinOff,IO.powerCurrentMode.ON)
	else
		sys.timer_start(PowerTwinOn,IO.powerCurrentMode.OFF)
	end
end
function GsmTwinOn()
	if IO.gsmTwinking then
		if not IO.engMode then
			GsmLt(true)
		end
		sys.timer_start(GmsTwinOff,IO.gsmTwin.ON)
	end
end
function GmsTwinOff()
	if IO.gsmTwinking then
		if not IO.engMode then
			GsmLt(false)
		end
		sys.timer_start(GsmTwinOn,IO.gsmTwin.OFF)
	end
end
local function gsmLtTwinkle()
	IO.gsmTwinking = true
	if IO.gsmLtVal then
		sys.timer_start(GmsTwinOff,IO.gsmTwin.ON)
	else
		sys.timer_start(GsmTwinOn,IO.gsmTwin.OFF)
	end
end
local function GpsTwinOff()
	if not IO.engMode then
		GpsLt(false)
	end
	if dataapp.GetLbsDwHandle() > 0 then
		sys.timer_start(gpsLtTwinkle,500)
	else
		IO.gpsTwinking = false
	end
end
function gpsLtTwinkle()
	IO.gpsTwinking = true
	if dataapp.GetLbsDwHandle() > 0 then
		dataapp.SetLbsDwHandle(false)
		if not IO.engMode then
			GpsLt(true)
		end
		sys.timer_start(GpsTwinOff,500)
	end
end
local function UpdatePowerLt()
	if pmdapp.IsLowPower() then
		print("lightapp powerTwinLow")
		PowerLtTwinkle(IO.powerTwinLow)
	elseif pmdapp.IsCharging() then
		print("lightapp powerTwinCharge")
		PowerLtTwinkle(IO.powerTwinCharge)
	elseif filestore.IsHideStatus() then
		print("lightapp powerTwinHide")
		PowerLtTwinkle(IO.powerTwinHide)
	elseif pmdapp.IsChargerOn() and pmdapp.IsChargeFinish() then
		IO.powerTwinking = false
		if not IO.engMode then
			PowerLt(true)
		end
	elseif not pmdapp.IsChargerOn() then
		print("lightapp isnotcharge")
		IO.powerTwinking = false
		if not IO.engMode then
			PowerLt(false)
		end
	end
end
local function UpdateGsmLt()
	if dataapp.IsSckConnect() then
		gsmLtTwinkle()
	elseif net.getstate() == "REGISTERED" then
		IO.gsmTwinking = false
		if not IO.engMode then
			GsmLt(false)
		end
	else
		IO.gsmTwinking = false
		if not IO.engMode then
			GsmLt(true)
		end
	end
end
local function UpdateGpsLt()
	if (not IO.gpsTwinking) and (dataapp.GetLbsDwHandle() > 0) then
		gpsLtTwinkle()
	elseif not IO.gpsTwinking then
		if not IO.engMode then
			GpsLt(false)
		end
	end
end
function StartLt()
	UpdatePowerLt()
	UpdateGsmLt()
	UpdateGpsLt()
	return true
end
local function InitIO()
	pio.pin.setdir(pio.OUTPUT, pio.P0_8, pio.P0_9,pio.P0_10)
	IO.powerLt = pio.P0_8
	IO.gsmLt = pio.P0_9
	IO.gpsLt = pio.P0_10
	IO.engMode = false
	IO.powerTwinHide = {ON=300,OFF=2700}
	IO.powerTwinCharge = {ON=1500,OFF=1500}
	IO.powerTwinLow = {ON=600,OFF=600}
	IO.powerCurrentMode = IO.powerTwinHide
	IO.powerTwinking = false
	IO.gsmTwin = {ON=300,OFF=2700}
	IO.gsmTwinking = false
	IO.gpsTwinking = false
	IO.powerLtVal = false
	IO.gsmLtVal = false
	IO.gpsLtVal = false
	StartLt()
end
sys.regapp(StartLt,"NET_STATE_CHANGED","SCK_CONNECT_IND","SCK_DISCONNECT_IND","DW_IND","CLOCK_IND","CHG_IND","HIDE_IND","CLOSE_ENG_IND")
sys.regapp(SetEngMode,"ENG_APP_IND")
InitIO()
