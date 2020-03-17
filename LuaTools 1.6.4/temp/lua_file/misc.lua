
local string = require"string"
local ril = require"ril"
local sys = require"sys"
local base = _G
local os = require"os"
local io = require"io"
local rtos = require"rtos"
local pmd = require"pmd"
module(...)
local tonumber,tostring,print,req,smatch = base.tonumber,base.tostring,base.print,ril.request,string.match
local sn,snrdy,imeirdy,imei,clkswitch,updating,dbging,flypending
local calib,setclkcb,wimeicb

local function rsp(cmd,success,response,intermediate)
	local prefix = string.match(cmd,"AT(%+%u+)")
	if cmd == "AT+WISN?" then
		sn = intermediate
		if not snrdy then sys.dispatch("SN_READY") snrdy = true end
	--[[elseif cmd == "AT+VER" then
		ver = intermediate]]
	elseif cmd == "AT+CGSN" then
		imei = intermediate
		if not imeirdy then sys.dispatch("IMEI_READY") imeirdy = true end
	elseif smatch(cmd,"AT%+WIMEI=") then
		if wimeicb then wimeicb(success) end
	elseif smatch(cmd,"AT%+WISN=") then
		req("AT+WISN?")
	elseif prefix == "+CCLK" then
		startclktimer()
		if setclkcb then
			setclkcb(cmd,success,response,intermediate)
		end
	elseif cmd == "AT+ATWMFT=99" then
		print('ATWMFT',intermediate)
		if intermediate == "SUCC" then
			calib = true
		else
			calib = false
		end
	elseif smatch(cmd,"AT%+CFUN=[01]") then
		sys.dispatch("FLYMODE_IND",smatch(cmd,"AT%+CFUN=(%d)")=="0")
	end
end

function setclock(t,rspfunc)
	if t.year - 2000 > 38 then return end
	setclkcb = rspfunc
	req(string.format("AT+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d+32\"",string.sub(t.year,3,4),t.month,t.day,t.hour,t.min,t.sec),nil,rsp)
end

function getclockstr()
	local clk = os.date("*t")
	clk.year = string.sub(clk.year,3,4)
	return string.format("%02d%02d%02d%02d%02d%02d",clk.year,clk.month,clk.day,clk.hour,clk.min,clk.sec)
end

function getweek()
	local clk = os.date("*t")
	return ((clk.wday == 1) and 7 or (clk.wday - 1))
end

function getclock()
	return os.date("*t")
end

function startclktimer()
	if clkswitch or sys.getworkmode()==sys.FULL_MODE then
		sys.dispatch("CLOCK_IND")
		print('CLOCK_IND',os.date("*t").sec)
		sys.timer_start(startclktimer,(60-os.date("*t").sec)*1000)
	end
end

function setclkswitch(v)
	clkswitch = v
	if v then startclktimer() end
end

function getsn()
	return sn or ""
end

function getimei()
	return imei or ""
end

function setimei(s,cb)
	if s==imei then
		if cb then cb(true) end
	else
		req("AT+AMFAC="..(cb and "0" or "1"))
		req("AT+WIMEI=\""..s.."\"")
		wimeicb = cb
	end
end

function setflymode(val)
	if val then
		if updating or dbging then flypending = true return end
	end
	req("AT+CFUN="..(val and 0 or 1))
	flypending = false
end

function set() end

function getcalib()
	return calib
end

function getvbatvolt()
	local v1,v2,v3,v4,v5 = pmd.param_get()
	return v2
end

local function ind(id,para)
	if id=="SYS_WORKMODE_IND" then
		startclktimer()
	elseif id=="UPDATE_BEGIN_IND" then
		updating = true
	elseif id=="UPDATE_END_IND" then
		updating = false
		if flypending then setflymode(true) end
	elseif id=="DBG_BEGIN_IND" then
		dbging = true
	elseif id=="DBG_END_IND" then
		dbging = false
		if flypending then setflymode(true) end
	end
	return true
end
ril.regrsp("+ATWMFT",rsp)
ril.regrsp("+WISN",rsp)
--ril.regrsp("+VER",rsp,4,"^[%w_]+$")
ril.regrsp("+CGSN",rsp)
ril.regrsp("+WIMEI",rsp)
ril.regrsp("+AMFAC",rsp)
ril.regrsp("+CFUN",rsp)
req("AT+ATWMFT=99")
req("AT+WISN?")
--req("AT+VER")
req("AT+CGSN")
startclktimer()
sys.regapp(ind,"SYS_WORKMODE_IND","UPDATE_BEGIN_IND","UPDATE_END_IND","DBG_BEGIN_IND","DBG_END_IND")
