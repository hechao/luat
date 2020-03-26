local base = _G
module("smsapp",package.seeall)
local print = base.print
local tostring = base.tostring
local tonumber = base.tonumber
local binstohexs = common.binstohexs
local gb2312toucs2be = common.gb2312toucs2be
local hexstobins = common.hexstobins
local gb2312hexstobins = common.gb2312hexstobins
local ucs2betogb2312 = common.ucs2betogb2312
local smatch,sfind,sgmatch,slen,ssub = string.match,string.find,string.gmatch,string.len,string.sub
local fs = require"filestore"
local NO_ALLOW = "您没有权限操作此命令！"
local FORMAT_ERR = "短信指令格式错误！"
local SUCCESS,FAIL = "短信指令执行成功！","短信指令执行失败！"
local DW_FAIL = "定位失败，请稍侯再试！"
local smsList = {}
local sndingNum,sndingCont
local function AddSms(seq,idx,cnt,cont)
	if idx > cnt then return end
	if idx == cnt and idx == 1 then
		return true,cont
	end
	local complete,bdy,fnd,i,j = true,""
	for i=1,#smsList do
		if smsList[i].seq == seq then
			fnd = true
			if smsList[i].cnt == cnt then				
				smsList[i].cont[idx] = cont
				for j=1,cnt do
					if not smsList[i].cont[j] or slen(smsList[i].cont[j]) == 0 then
						complete = false
						break
					else
						bdy = bdy .. smsList[i].cont[j]
					end
				end
				if complete then
					table.remove(smsList,i)
					return true,bdy
				end	
			end
		end
	end
	if not fnd then
		local item = {seq=seq,cnt=cnt}
		item.cont = {[idx]=cont}
		table.insert(smsList,item)
	end	
end
function SndSms(num,cont)
	print("SndSms",binstohexs(gb2312toucs2be(cont)))
	if num and string.len(num) > 0 and cont and string.len(cont) > 0 and not fs.IsSmsNum(num) then
		sndingNum,sndingCont = num,cont
		if not sms.send(num,binstohexs(gb2312toucs2be(cont))) then
			sys.dispatch("SMS_SEND_CNF",false)
		end
	end
end
local function PowerOffTimerFunc()
	rtos.poweroff()
end
local function LaterPowerOff(sec)
	sys.timer_start(PowerOffTimerFunc,sec*1000)
end
local function ProcSetSms(num,data,datetime)
	local agent = smatch(data,"SET%(SMS=%d*,URL=[%w%./:]+,SURL=[%w%./:]+,AGENT=(%d+)%)")
	if agent then
		if fs.GetPara(fs.PARA_PHONENUM) ~= agent then
			fs.SetPara(fs.PARA_PHONENUM,agent,true)
			dataapp.Relogin()
		end
		return true
	end
end
local function ProcKeyNumSms(num,data,datetime)
	local stat,keyTyp,keyNum = smatch(data,"S11,%d@%d,([1-3])@([1-2])@([%w!=]*)")
	if stat and keyTyp and keyNum then
		local relativeNum,sosNum,result,idx,tmpNum,d1,d2 = fs.GetPara(fs.PARA_RELATIVENUM),fs.GetPara(fs.PARA_SOSNUM),true
		--[[if stat == "1" then
			if keyTyp == "1" then
				for idx in sgmatch(keyNum,"(%d)=%d+") do
					if smatch(relativeNum,idx.."=%d+") then
						result = false
						break
					end
				end
				if result then
					relativeNum = relativeNum.."!"..keyNum
					fs.SetPara(fs.PARA_RELATIVENUM,relativeNum,true)
				end
			elseif keyTyp == "2" then
				for tmpNum in sgmatch(keyNum,"(%d+)") do
					if smatch(sosNum,tmpNum) then
						result = false
						break
					end
				end
				if result then
					sosNum = sosNum.."!"..keyNum
					fs.SetPara(fs.PARA_SOSNUM,sosNum,true)
				end
			end
		else]]if stat == "2" or stat == "1" then
			if keyTyp == "1" then
				for idx,tmpNum in sgmatch(keyNum,"(%d)=(%d+)") do
					d1,d2 = sfind(relativeNum,idx.."=%d*")
					if d1 and d2 then
						relativeNum = ssub(relativeNum,1,d1-1)..idx.."="..tmpNum..ssub(relativeNum,d2+1,-1)
					else
						relativeNum = relativeNum.."!"..idx.."="..tmpNum.."!"
					end
				end
				if result then
					fs.SetPara(fs.PARA_RELATIVENUM,relativeNum,true)
				end
			elseif keyTyp == "2" then
				for tmpNum in sgmatch(keyNum,"(%d+)") do
					if not smatch(sosNum,tmpNum) then
						sosNum = sosNum.."!"..tmpNum.."!"
					end
				end
				if result then
					fs.SetPara(fs.PARA_SOSNUM,sosNum,true)
				end
			end
		elseif stat == "3" then
		end
		dataapp.SndToSvr(dataapp.SETKEYNUMRSP,nil,nil,nil,false,nil,nil,result)
		return true
 	end
end
local function ProcGpsLocationQrySms(num,data,datetime)
	local phoneNum,parentNum,typ = smatch(data,"S07,%d@%d,(%d+)@(%d+)@(%w+)")
	if typ == "GPSSS" then		
		local bdyPara = {parentNum=parentNum,typ=typ}
		dataapp.SndToSvr(dataapp.CELLQRYRSP,nil,nil,nil,false,nil,nil,bdyPara)
		dataapp.SndToSvr(dataapp.LOCATIONQRYRSP,nil,nil,nil,true,nil,dataapp.SMS_FIXGPS,bdyPara)
		return true
	elseif typ == "DSHHmm" then
	end
end
local function ProcCellQrySms(num,data,datetime)
	if smatch(data,"S72") then
		local phoneNum,parentNum,typ = smatch(data,"S72,%d@%d,(%d+)@(%d+)@(LAC%/CELLID)")
		if typ == "LAC/CELLID" then
			local bdyPara = {parentNum=parentNum,typ="LBSSS"}
			dataapp.SndToSvr(dataapp.CELLQRYRSP,nil,nil,nil,false,nil,nil,bdyPara)
			return true
		elseif typ == "DSHHmm" then
		end
	end	
end
local function ProcSetHideSms(num,data,datetime)	
	local seq,idx,cnt,cont = smatch(data,"(%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d),S75,(%d)@(%d),([^%)]*)")
	if seq and idx and cnt and cont then
		local res,bdy = AddSms(seq,tonumber(idx),tonumber(cnt),cont)
		print("ProcSetHideSms",res,bdy)
		if res then
			local cmd,stat,val,week,tm,result = smatch(bdy,"([1-3])@([0-1])@([%d%-!=]*)")
			if (cmd and stat == "0") or cmd == "3" then
				fs.SetPara(fs.PARA_HIDESTAT,"0",false)
				fs.SetPara(fs.PARA_HIDE,"",false)
				fs.FlushPara()
				result = true
			elseif cmd == "1" or cmd == "2" then
				local hide = fs.GetPara(fs.PARA_HIDE)
				fs.SetPara(fs.PARA_HIDESTAT,"1",false)
				--[[for week,tm in sgmatch(val,"(%d)=([%d%-!]+)") do
					local d1,d2 = sfind(hide,week.."=[%d%-!]*")
					if d1 and d2 then
						hide = ssub(hide,1,d1-1)..week.."="..tm..ssub(hide,d2+1,-1)
					else
						hide = hide..week.."="..tm
					end
				end]]
				fs.SetPara(fs.PARA_HIDE,val,false)
				fs.FlushPara()
				result = true
			end
			dataapp.SndToSvr(dataapp.SETHIDERSP,nil,nil,nil,false,nil,nil,result)
		end
		return true
	end	
end
local function ProcLocationSms(num,data,datetime)
	if string.find(data,"^DW") or string.find(data,"^1") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local para = {mode=dataapp.SMS_GPS,num="!"..num}
		if not dataapp.SndToSvr(dataapp.TERM_RPT,dataapp.DW_RPT,nil,para,true,nil,dataapp.SMS_GPS) then
			SndSms(num,DW_FAIL)
		end
		return true
	end
	return false	
end
local function ProcGpsLocationSms(num,data,datetime)
	if string.find(data,"^GPSDW") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local para = {mode=dataapp.SMS_FIXGPS,num="!"..num}
		if not dataapp.SndToSvr(dataapp.TERM_RPT,dataapp.DW_RPT,nil,para,true,nil,dataapp.SMS_FIXGPS) then
			SndSms(num,DW_FAIL)
		end
		return true
	end
	return false	
end
local function ProcMonitorSms(num,data,datetime)
	if string.find(data,"^JT") or string.find(data,"^2") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		sosapp.EnterMonitorDialNum(num)
		return true
	end
	return false	
end
local function ProcLqsxSms(num,data,datetime)
	if string.find(data,"^LQSX") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		gpsapp.StartGpsApp(gpsapp.GPSAPP_PLATFORM_OPEN)
		dataapp.SndToSvr(dataapp.TERM_RPT,dataapp.QRYLOCATION_RPT,nil,nil,false,nil,nil)
		return true
	end
	return false	
end
function GetSignalPercentage()
	local rssi = net.getrssi()
	return (100*rssi/31)
end
local function ProcQyrInfoSms(num,data,datetime)
	if string.find(data,"^CXDL$") then
		local cont = "bat="..pmdapp.GetBatLev().."%"
		SndSms(num,cont)
		return true
	end
	return false
end
local function ProcQryIpSms(num,data,datetime)
	if string.find(data,"^IP") or string.find(data,"^HTTP") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local cont = "IP="..fs.GetPara(fs.PARA_ADDR)..":"..fs.GetPara(fs.PARA_PORT)..","..misc.getimei() 
		SndSms(num,cont)
		cont = "VERSW_".."5303_NEW_HY_V1297_B3300".."_".."1.0.6"..",LED="..fs.GetPara(fs.PARA_LED)
		SndSms(num,cont)
		return true
	end
	return false
end
local function ProcQryHideSms(num,data,datetime)
	if data == "CK" or data == "CX" then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local hide = string.gsub(fs.GetPara(fs.PARA_HIDE),"%-"," ")
		hide = string.gsub(hide,"!"," ")
		hide = string.gsub(hide,":"," ")
		SndSms(num,"SET SKYS "..hide)
		return true
	end
	return false
end
local function ProcQryWhiteListSms(num,data,datetime)
	if string.find(data,"^LIST") then
		
		local list = fs.GetPara(fs.PARA_WHITENUM)
		if list and string.len(list) > 0 then
			list = "!"..list
			local d1,d2,last,name
			while true do
				d1,d2,name = string.find(list,"!(%w*)=")
				if d1 == nil or d2 == nil or name == nil then
					break
				end
				list = string.sub(list,1,d1)..hexstobins(name)..string.sub(list,d2,-1)
				list = string.gsub(list,"!",",",1)				
			end
			SndSms(num,string.sub(list,2,-1))
		end
		return true
	end
	return false
end
local function ProcLedSms(num,data,datetime)
	if string.find(data,"^LED=%d") then
		if not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local flag = string.match(data,"LED=(%d)")
		if flag ~= "0" and flag ~= "1" then
			SndSms(num,FORMAT_ERR)
			return true
		end
		fs.SetPara(fs.PARA_LED,tonumber(flag),true)
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcIpSms(num,data,datetime)
	if string.find(data,"^IP=.+:%d+") or string.find(data,"^HTTP=.+:%d+") then
		if not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local addr,port = string.match(data,"=(.+):(%d+)")
		if addr == nil and port == nil then
			SndSms(num,FORMAT_ERR)
			return true
		end
		fs.SetPara(fs.PARA_ADDR,addr,false)
		fs.SetPara(fs.PARA_PORT,port,false)
		fs.FlushPara()
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcRestoreSms(num,data,datetime)
	if string.find(data,"^SET HFCC") then
		if not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		fs.RestorePara()
		local bdy = dataapp.BODY_SEP
		local rpt = dataapp.NEWSEP..dataapp.NEWHFCC..dataapp.NEWSEP..bdy.."CEN="..bdy.."MO="..bdy.."SIM="..bdy.."QQ!"..bdy.."SOS="..bdy.."BMD!"..bdy.."XJ="..bdy.."SKYS!"..bdy.."GJ!"..bdy.."DS!"..bdy.."QU"
		dataapp.SndToSvr(dataapp.TERM_PARA_RPT,dataapp.MODIFY_PARA_RPT,nil,nil,false,nil,nil,rpt)
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcGpsSms(num,data,datetime)
	if string.find(data,"^GPS=%d") then
		if not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local flag = string.match(data,"GPS=(%d)")
		if flag ~= "0" and flag ~= "1" then
			SndSms(num,FORMAT_ERR)
			return true
		end
		fs.SetPara(fs.PARA_GPS,tonumber(flag),true)
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcDelHideSms(num,data,datetime)
	if string.find(data,"^DEL SKYS") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		if fs.GetPara(fs.PARA_HIDE) ~= "" then
			fs.SetPara(fs.PARA_HIDE,"",true)
			dataapp.SndToSvr(dataapp.TERM_PARA_RPT,dataapp.MODIFY_PARA_RPT,nil,nil,false,nil,nil,dataapp.NEWSEP..dataapp.NEWSKYS..dataapp.NEWSEP.."SKYS!")
		end
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcSetTimeSms(num,data,datetime)
	if string.find(data,"^SET TIME") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local dateTime = string.match(data,"SET TIME (%d+)")
		if string.len(dateTime) ~= 14 then
			SndSms(num,FORMAT_ERR)
			return true
		end
		local clk = {
			year = tonumber(string.sub(dateTime,1,4)),
			month = tonumber(string.sub(dateTime,5,6)),
			day = tonumber(string.sub(dateTime,7,8)),
			hour = tonumber(string.sub(dateTime,9,10)),
			min = tonumber(string.sub(dateTime,11,12)),
			sec = tonumber(string.sub(dateTime,13,14)),
		}
		misc.setclock(clk)
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcSetWhiteListSms(num,data,datetime)
	if string.find(data,"^SET LIST L") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local d1,d2,pa1,pa2,pa3,list="","","","","",""
		for pa1, pa2, pa3 in string.gmatch(data, "L([0-2][0-9])%*(%d+)%*(%d+)") do
			pa1 = binstohexs(pa1)
			list = list..pa1.."="..pa3.."!"
		end
		if string.len(list) == 0 then
			SndSms(num,FORMAT_ERR)
			return true
		else
			list = string.sub(list,1,-2)			
			if fs.GetPara(fs.PARA_WHITENUM) ~= list then
				fs.SetPara(fs.PARA_WHITENUM,list,true)
				dataapp.SndToSvr(dataapp.TERM_PARA_RPT,dataapp.MODIFY_PARA_RPT,nil,nil,false,nil,nil,dataapp.NEWSEP..dataapp.NEWBMD..dataapp.NEWSEP.."BMD"..list)
			end
			SndSms(num,SUCCESS)
			return true
		end	
	elseif string.find(data,"^SET LIST") then
		if not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		if fs.GetPara(fs.PARA_WHITENUM) ~= "" then
			fs.SetPara(fs.PARA_WHITENUM,"",true)
			dataapp.SndToSvr(dataapp.TERM_PARA_RPT,dataapp.MODIFY_PARA_RPT,nil,nil,false,nil,nil,dataapp.NEWSEP..dataapp.NEWBMD..dataapp.NEWSEP.."BMD!")
		end
		SndSms(num,SUCCESS)
		return true
	end
	return false	
end
local function ProcSetAlarmSms(num,data,datetime)
	if string.find(data,"^SET ALARM") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		local pa1,pa2,list="","",""
		for pa1, pa2 in string.gmatch(data, "(%d%d%d%d) ([01][01][01][01][01][01][01])") do
			list = list..pa1..":"..pa2.."!"
		end
		if string.len(list) == 0 then
			SndSms(num,FORMAT_ERR)
			return true
		else
			list = string.sub(list,1,-2)
			fs.SetPara(fs.PARA_ALARM,list,true)
			SndSms(num,SUCCESS)
			return true
		end	
	end
	return false	
end
local function ProcDelAlarmSms(num,data,datetime)
	if string.find(data,"^DEL ALARM") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		fs.SetPara(fs.PARA_ALARM,"",true)
		SndSms(num,SUCCESS)
		return true		
	end
	return false	
end
local function ProcQueryAlarmSms(num,data,datetime)
	if string.find(data,"^CX ALARM") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		SndSms(num,"SET ALARM "..string.gsub(fs.GetPara(fs.PARA_ALARM),"%D"," "))
		return true
	end
	return false	
end
local function ProcPoweroffSms(num,data,datetime)
	if string.find(data,"^YCGJ") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		LaterPowerOff(3)
		return true
	end
	return false	
end
local function ProcCxcsSms(num,data,datetime)
	if string.find(data,"^CXCS") then
		if not fs.IsRelativeNum(num) and not fs.IsSmsNum(num) and not fs.IsSosNum(num) then
			SndSms(num,NO_ALLOW)
			return true
		end
		dataapp.SndToSvr(dataapp.TERM_RPT,dataapp.QRYLOCATION_RPT,nil,nil,false,nil,nil)
		return true
	end
	return false	
end
local smsProcTable = 
{
	ProcSetSms,
	ProcKeyNumSms,
	ProcGpsLocationQrySms,
	ProcCellQrySms,
	ProcSetHideSms,
	ProcQryWhiteListSms,
	ProcSetWhiteListSms,
	ProcQyrInfoSms,
	
}
local function ProcSms(num,data,datetime)
	local k,v
	for k,v in pairs(smsProcTable) do
		if v(num,data,datetime) then
			return true
		end
	end
	return false
end
local tnewsms = {}
local function readsms()
	if #tnewsms ~= 0 then 
		sms.read(tnewsms[1])
	end
end
local function newsms(pos)	
	table.insert(tnewsms,pos)
	if #tnewsms == 1 then
		readsms()
	end
end
local function readcnf(result,num,data,pos,datetime,name)
	local proc,upperData = false	
	local convtNum
	if string.find(num,"^%+86") then
		convtNum = string.sub(num,4,-1)
	elseif string.find(num,"^86") then
		convtNum = string.sub(num,3,-1)
	else
		convtNum = num
	end
	print("readcnf num",num,convtNum,data)
	sms.delete(tnewsms[1])
	table.remove(tnewsms,1)
	upperData = string.upper(ucs2betogb2312(hexstobins(data)))
	local d1,d2,tmpData = string.find(upperData,"^【.*】(.+)")
	print(upperData,tmpData)
	if d1 and d2 and tmpData then
		proc = ProcSms(convtNum,tmpData,datetime)
	else
		proc = ProcSms(convtNum,upperData,datetime)
	end	
	if not proc then
		ttssmsapp.AddTtsSms(ucs2betogb2312(hexstobins(data)))
	end
	readsms()
end
local sosSmsInf = ""
function GetSosSmsInf()
	local res = sosSmsInf
	sosSmsInf = ""
	return res
end
local function sendcnf(suc)
	if sndingCont == "您的亲友遇到突发情况，请尽快联络您的亲友或相关部门" then
		sosSmsInf = sosSmsInf..sndingNum.."=20"..misc.getclockstr().."-"..(suc and "1" or "0").."!"
	end
end
local smsapp =
{
	SMS_NEW_MSG_IND = newsms,
	SMS_READ_CNF = readcnf,
	SMS_SEND_CNF = sendcnf,	
}
local function GpsLocParse(evt,loc,num)
	print("GpsLocParse",num)
	if not loc or string.len(loc) == 0 then
		loc = DW_FAIL
	end
	SndSms(num,loc)
end
sys.regapp(GpsLocParse,"GPS_LOCATION_PARSE_IND")
--sys.regapp(Snd,"SND_SMS_REQ")
sys.regapp(smsapp)
--sys.timer_start(ProcSetHideSms,40000,"18616233557","SET SKYS 0800 1200 1501 1520 1111000")
--sys.timer_start(ProcRestoreSms,60000,"18616233557","SET HFCC")
