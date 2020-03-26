module("gpsapp",package.seeall)
local print = _G.print
GPSAPP_OFF = "Off"	
GPSAPP_SEARCH = "Search" 
local GPSAPP_INDOOR = "INdoor" 
local GPSAPP_ONLINE = "Online" 
local SEARCH_TO_WEAK_INTERVAL = 20000
local SEARCH_TO_OFF_INTERVAL = 280000
local OFF_SIGNAL = 20
local FIRST_STEP = 1
local SECOND_STEP = 2
local FIX_STEP = 3
local ONLINE_NOUSE_OFF_INTERVAL = 300000
GPSAPP_NONE_OPEN = 0
GPSAPP_AUTO_OPEN = 1
GPSAPP_PLATFORM_OPEN = 2
GPSAPP_INTERVAL_OPEN = 3
GPSAPP_FIX_OPEN = 4
GPSAPP_ENGINE_OPEN = 5
local gpsAppOpenMode = GPSAPP_NONE_OPEN
local gpsAppOpenPara
local gpsAppLocationSuc = false
local gpsAppState = GPSAPP_OFF
local gpsAppSearchCnt = 0
local GPS_SEARCH_INTERVAL = 1000
local GPS_SEARCH_RPT_INTERVAL = 20000
local gpsFuncSup = nil
GPSAPP_LOCATION_IND = "GPSAPP_LOCATION_IND"
local function OnlineNouseOffTimerFunc()
	StopGpsApp()
end
local function StopOnlineNouseOffTimer()
	sys.timer_stop(OnlineNouseOffTimerFunc)
end
local function StartOnlineNouseOffTimer()
	sys.timer_start(OnlineNouseOffTimerFunc,ONLINE_NOUSE_OFF_INTERVAL)
end
local function GpsAppSearchTimerFunc(step)
	print("GpsAppSearchTimerFunc",gpsAppState,gps.getgpssatenum(),gps.getgpssn(),step)
	if gpsAppState == GPSAPP_SEARCH then
		if step == FIRST_STEP then
			sys.timer_start(GpsAppSearchTimerFunc,SEARCH_TO_OFF_INTERVAL,SECOND_STEP)			
		elseif step == SECOND_STEP then
			StopGpsApp()
			local para = 
			{
				mode = dataapp.LOCATION_GPS_IND
			}
			sys.dispatch(GPSAPP_LOCATION_IND,false,nil,para)
		elseif step == FIX_STEP then
			sys.dispatch(GPSAPP_LOCATION_IND,false,GetGpsAppLocation(),gpsAppOpenPara)
			StopGpsApp(true)
		end	
	elseif gpsAppState == GPSAPP_ONLINE then
		if step == FIRST_STEP then			
			sys.dispatch(GPSAPP_LOCATION_IND,false,GetGpsAppLocation(),gpsAppOpenPara)
			StopGpsApp(true)
		end
	end
end
local function GpsStateInd(id,data)
	print("GpsStateInd",id,data,gpsAppOpenMode)
	if data == gps.GPS_LOCATION_SUC_EVT then
		if gpsAppState == GPSAPP_ONLINE or gpsAppOpenMode == GPSAPP_FIX_OPEN then
			if gpsAppOpenPara then
				sys.dispatch(GPSAPP_LOCATION_IND,true,GetGpsAppLocation(),gpsAppOpenPara)
			end
		elseif gpsAppOpenMode == GPSAPP_AUTO_OPEN or gpsAppOpenMode == GPSAPP_PLATFORM_OPEN then
			local para = 
			{
				mode = dataapp.LOCATION_GPS_IND
			}
			sys.dispatch(GPSAPP_LOCATION_IND,true,GetGpsAppLocation(),para)
		end
		if gpsAppOpenMode == GPSAPP_ENGINE_OPEN then
			sys.dispatch("GPSAPP_ENGINE_LOCATION_IND",false)
		end
		sys.timer_stop(GpsAppSearchTimerFunc,FIRST_STEP)
		sys.timer_stop(GpsAppSearchTimerFunc,SECOND_STEP)
		sys.timer_stop(GpsAppSearchTimerFunc,FIX_STEP)
		gpsAppState = GPSAPP_ONLINE
		gpsAppLocationSuc = true		
		StopGpsApp()
	elseif data == gps.GPS_LOCATION_FAIL_EVT then
	elseif data == gps.GPS_NO_CHIP_EVT then
		gpsFuncSup = false
		StopGpsApp()
	elseif data == gps.GPS_HAS_CHIP_EVT then
		gpsFuncSup = true
		StopGpsApp()
	end
	return true
end
local function GpsAppSearchRptTimerFunc()
	--print("GpsAppSearchRptTimerFunc",gpsAppState,gpsAppSearchCnt)
	gpsAppSearchCnt = gpsAppSearchCnt + 1
	if gpsAppState == GPSAPP_SEARCH then
		if gpsAppSearchCnt % (GPS_SEARCH_RPT_INTERVAL / GPS_SEARCH_INTERVAL) == 0 then
		end
		sys.timer_start(GpsAppSearchRptTimerFunc,GPS_SEARCH_INTERVAL)
	end
end
local function GpsAppSearchRpt()
	print("GpsAppSearchRpt",gpsAppState)
	if gpsAppState == GPSAPP_SEARCH and not sys.timer_is_active(GpsAppSearchRptTimerFunc) then
		sys.timer_start(GpsAppSearchRptTimerFunc,GPS_SEARCH_INTERVAL)
	end
end
function GetGpsAppLocation()
	if not gpsFuncSup then
		return ""
	end
	local longTyp,long,latiTyp,lati = string.match(gps.getgpslocation(),"([EW]*),([.%d]*),([NS]*),([.%d]*)")
	longTyp = longTyp and longTyp or "E"
	latiTyp = latiTyp and latiTyp or "N"
	if long and lati and long ~= "" and long ~= "0" and lati ~= "" and lati ~= "0" then
		--return long..longTyp.."|"..lati..latiTyp.."|"..gps.getgpssn()
		return "0"..longTyp..long..latiTyp..lati.."T20"..misc.getclockstr()
	else
		return "1"
	end
end
function GetGpsAppState()
	if not gpsFuncSup then
		return "NOGPS"
	end
	if gpsAppState == GPSAPP_SEARCH then		
		return gpsAppState.."|"..gps.getsatesinfo().."|"..(gpsAppSearchCnt*(GPS_SEARCH_INTERVAL/1000))
	else
		return gpsAppState
	end	
end
function StopGpsApp(force,isEng)
	if gpsFuncSup == nil then
		print("StopGpsApp err")
		return
	end
	print("StopGpsApp",force,gpsAppState,gpsAppOpenMode,isEng)
	if gpsAppOpenMode == GPSAPP_ENGINE_OPEN and not isEng then
		print("StopGpsApp eng err")
		return
	end
	gps.closegps("gpsapp")
	if force then
		gpsAppState = GPSAPP_OFF
	elseif gpsAppState ~= GPSAPP_ONLINE then
		gpsAppState = GPSAPP_OFF
	end	
	sys.timer_stop(GpsAppSearchTimerFunc,FIRST_STEP)
	sys.timer_stop(GpsAppSearchTimerFunc,SECOND_STEP)
	sys.timer_stop(GpsAppSearchTimerFunc,FIX_STEP)
	StopOnlineNouseOffTimer()
	gpsAppOpenMode = GPSAPP_NONE_OPEN
	gpsAppLocationSuc = false
	gpsAppOpenPara = nil
end
function StartGpsApp(mode,interval,para)
	if pmdapp.IsLowPower() and mode ~= GPSAPP_ENGINE_OPEN then
		print("StartGpsApp lowpower err")
		return false
	end
	
	if gpsFuncSup == nil and mode ~= GPSAPP_AUTO_OPEN then
		print("StartGpsApp err")
		return false
	elseif gpsFuncSup == false then
		return false
	end
	print("StartGpsApp",mode,interval,gpsAppOpenMode,gpsAppState,gpsAppLocationSuc)
	if mode == GPSAPP_AUTO_OPEN then
		if gpsAppOpenMode == GPSAPP_NONE_OPEN then			
			if gpsAppState == GPSAPP_OFF then
				gpsAppOpenMode = mode
				gps.opengps("gpsapp")
				gpsAppState = GPSAPP_SEARCH
				gpsAppSearchCnt = 0
				GpsAppSearchRpt()
				sys.timer_start(GpsAppSearchTimerFunc,SEARCH_TO_WEAK_INTERVAL,FIRST_STEP)
				return true
			end
		end
	elseif mode == GPSAPP_PLATFORM_OPEN then
		if gpsAppOpenMode == GPSAPP_NONE_OPEN or gpsAppOpenMode == GPSAPP_AUTO_OPEN then			
			gpsAppOpenMode = mode
			gps.opengps("gpsapp")
			gpsAppState = GPSAPP_SEARCH			
			gpsAppSearchCnt = 0
			GpsAppSearchRpt()
			sys.timer_start(GpsAppSearchTimerFunc,SEARCH_TO_WEAK_INTERVAL,FIRST_STEP)
			return true
		end
	elseif mode == GPSAPP_INTERVAL_OPEN then
		if gpsAppState == GPSAPP_ONLINE and (gpsAppOpenMode == GPSAPP_NONE_OPEN or gpsAppOpenMode == GPSAPP_AUTO_OPEN or gpsAppOpenMode == GPSAPP_PLATFORM_OPEN) then
			if gpsAppLocationSuc then
				sys.dispatch(GPSAPP_LOCATION_IND,true,GetGpsAppLocation(),para)
				return true
			end
			if not gpsAppOpenPara then
				gpsAppOpenMode = mode
				gpsAppOpenPara = para
				gps.opengps("gpsapp")
				sys.timer_start(GpsAppSearchTimerFunc,interval,FIRST_STEP)
				return true
			else
				return false
			end
		end
	elseif mode == GPSAPP_FIX_OPEN then
		if gpsAppOpenMode == GPSAPP_NONE_OPEN or gpsAppOpenMode == GPSAPP_AUTO_OPEN or gpsAppOpenMode == GPSAPP_PLATFORM_OPEN then
			if gpsAppLocationSuc then
				sys.dispatch(GPSAPP_LOCATION_IND,true,GetGpsAppLocation(),para)
				return true
			end
			gpsAppOpenMode = mode
			gps.opengps("gpsapp")
			gpsAppState = GPSAPP_SEARCH
			gpsAppOpenPara = para
			sys.timer_start(GpsAppSearchTimerFunc,interval,FIX_STEP)
			return true
		end
	elseif mode == GPSAPP_ENGINE_OPEN then
		gpsAppOpenMode = mode
		gps.opengps("gpsapp")
		print("StartGpsApp Engine")
		return true
	end	
	return false
end
function IsGpsAppFuncSup()
	print("IsGpsAppFuncSup",gpsFuncSup)
	return gpsFuncSup
end
sys.regapp(GpsStateInd,gps.GPS_STATE_IND)
gps.initgps(pio.P1_8,pio.OUTPUT,true,1000,0,9600,8,uart.PAR_NONE,uart.STOP_1)
gps.setgpsfilter(2)
StartGpsApp(GPSAPP_AUTO_OPEN)
