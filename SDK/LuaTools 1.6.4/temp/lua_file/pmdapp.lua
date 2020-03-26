local base = _G
module("pmdapp",package.seeall)
local gb2312toucs2 = common.gb2312toucs2
local binstohexs = common.binstohexs
local bat = {}
local LOW_POWER_LEVEL = 20
local IsNeedLowRpt = true
local IsNeedLowTts = true
local IsUpdateSuc = false
local function ProcessChg(chgmsg)
	if chgmsg ~= nil then
		if (bat.chg ~= chgmsg.charger and bat.chg ~= nil) or (bat.state ~= chgmsg.state) then
			sys.dispatch("CHG_IND")
		end
		bat.chg = chgmsg.charger
		bat.lev = chgmsg.level
		bat.vol = chgmsg.voltage	
		bat.state = chgmsg.state
		if bat.lev > 100 then
			bat.lev = 100
		end
		if bat.lev == 0 and not bat.chg then
			if not bat.poweroffing then
				bat.poweroffing = true
				sys.timer_start(rtos.poweroff,30000,"chg")
			end
		elseif bat.poweroffing then
			sys.timer_stop(rtos.poweroff,"chg")
			bat.poweroffing = false
		end
		print("ProcessChg ",bat.chg,bat.lev,bat.vol,bat.state)
		sys.dispatch("BAT_INFO_IND",bat.chg,bat.lev,bat.vol,bat.state)
	end
end
local function LowPowerPlayCb()
	IsNeedLowTts = false
end
function SetNeedLowRpt(need)
	IsNeedLowRpt = valid
end
local function BatInd(chg,lev,vol,state)	
	if lev < LOW_POWER_LEVEL and not chg then
		sys.dispatch("CHG_IND")
	end	
	if chg then
		IsNeedLowTts = true
		SetNeedLowRpt(true)
	end
	if lev < LOW_POWER_LEVEL then
		if not chg then
			if IsNeedLowTts then
				if not filestore.IsHideStatus() then	
					audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2("电池快没电了，请充电")),false,4,LowPowerPlayCb)
				end
			end
			if IsNeedLowRpt then
				dataapp.SndToSvr(dataapp.POWERALM,dataapp.LOWALM,nil,nil,false,nil,nil,LOW_POWER_LEVEL.."%")
			end
		end		
	end
end
function GetBatLev()
	if bat.lev == nil then
		return 20
	end
	return bat.lev
end
function IsLowPower()
	if bat.lev and bat.lev < LOW_POWER_LEVEL and not bat.chg then
		return true
	end
	return false
end
function IsChargerOn()
	return bat.chg
end
function IsCharging()
	if bat.chg and bat.state == 1 then
		return true
	else
		return false
	end
end
function IsChargeFinish()
	return bat.state == 2
end
local function SetChargePara()
	bat.poweroffing = false
	local param = {}
	param.currentFirst = 300 
	param.currentSecond = 200
	param.currentThird = 100
	pmd.init(param)
end
local pmdApp =
{
	BAT_INFO_IND = BatInd,		
}
sys.regapp(pmdApp)
sys.regmsg(rtos.MSG_PMD,ProcessChg)
SetChargePara()
