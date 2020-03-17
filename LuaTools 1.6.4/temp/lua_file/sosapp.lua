module("sosapp",package.seeall)
local fs = require"filestore"
local SOS_DIAL_NUM_CYCLE_CNT,SOS_RELATIVE_NUM_CNT = 3,4
local MONITOR_DIAL_NUM_CYCLE_CNT = 3
function EnterSosApp()
	local str,i = ""
	for i=0,SOS_RELATIVE_NUM_CNT-1 do
		num = filestore.GetRelativeNum(i+1)
		if num and string.len(num) > 0 then
			str = str.."!"..num
		end
	end
	local para = {num=str,valid=true}
	local result,inf = dataapp.SndToSvr(dataapp.SOSALM,nil,1,para,false,nil,nil)
	dataapp.SndToSvr(dataapp.CELLQRYRSP,nil,nil,nil,false,nil,nil,{seq=inf.seq,parentNum=string.match(fs.GetPara(fs.PARA_DADFIX) or "","(%d+)=") or "",typ="SOS"})
	if not result then
		local number
		for number in string.gmatch(str, "(%d+)") do
			smsapp.SndSms(number,"您的亲友遇到突发情况，请尽快联络您的亲友或相关部门")
		end
		EnterSosDialNum()
	end
	local bdyPara = {mode=dataapp.SOS_GPS,parentNum=string.match(fs.GetPara(fs.PARA_DADFIX) or "","(%d+)=") or "",seq=inf.seq,typ="SOS"}
	dataapp.SndToSvr(dataapp.LOCATIONQRYRSP,nil,nil,{mode=dataapp.SOS_GPS},true,nil,dataapp.SOS_GPS,bdyPara)
end
function EnterSosDialNum()
	local sosDialNumTable = {}
	local i,num
	for i=0,SOS_RELATIVE_NUM_CNT*SOS_DIAL_NUM_CYCLE_CNT-1 do
		num = filestore.GetRelativeNum(i%SOS_RELATIVE_NUM_CNT+1)
		if num and string.len(num) > 0 then
			table.insert(sosDialNumTable,num)
		end
	end
	if #sosDialNumTable == 1 then
		ccapp.DialNum(table.remove(tmpTable,1))
	elseif #sosDialNumTable > 1 then
		ccapp.ProcSosNumBegin(sosDialNumTable)
	end	
end
function EnterMonitorDialNum(num)
	if num and num ~= "" then
		local monitorDialNumTable,i = {}
		for i=1,MONITOR_DIAL_NUM_CYCLE_CNT do
			table.insert(monitorDialNumTable,num)			
		end
		ccapp.ProcMonitorNumBegin(monitorDialNumTable)
	end
end
