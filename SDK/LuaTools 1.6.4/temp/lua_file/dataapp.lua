module(...,package.seeall)
local fs = require"filestore"
local lstate = link.getstate
local bintohex,gb2312toucs2 = common.binstohexs,common.gb2312toucs2
local sformat,smatch,sfind,ssub,slen = string.format,string.match,string.find,string.sub,string.len
LOGIN,LOGIN_HDSHK,POWERALM,SYNCTIME,SOSALM,SMSRPT,CCRPT,SETKEYNUMRSP,LOCATIONQRYRSP,CELLQRYRSP,SETHIDERSP,HEART = "T01","T31","T05","T21","T94","T32","T34","T12","T08","T73","T76","T30"
LOGINRSP,POWERALMRSP,SYNCTIMERSP,SOSALMRSP,SMSRPTRSP,CCRPTRSP = "T02","T06","T22","T23","T33","T35"
LOWALM,OFFALM = "1","2"
local SCK_IDX = 1
FRM_HEAD,FRM_SEP,BODY_SEP,DATA_SEP,FRM_TAIL = "[",",","@","!","]"
TERM_RPT,SVR_RSP,TERM_PARA_RPT,SVR_PARA_RSP = "T0A","T0B","T0C","T0D"
NEWIP,NEWCEN,NEWMO,NEWSIM,NEWQQ,NEWSOS,NEWBMD,NEWXJ,NEWSKYS,NEWGJ,NEWDS,NEWQU = 1,2,3,4,5,6,7,8,9,10,11,12
NEWPARACNT = 12
NEWSEP,NEWHFCC = "$",255
HEART_RPT,POWERON_RPT,POWERLOW_RPT,SOSALM_RPT,TIMER_RPT,TRACE_RPT,AREAALM_RPT,POWEROFF_RPT,OTHER_RPT,QRYLOCATION_RPT,DW_RPT,MODIFY_PARA_RPT,REL_INCOMING_RPT = "0","1","2","3","4","5","6","7","8","9","A","C","F"
local SOS_TRACE_GPS_INTERVAL = 15000
SOS_GPS,TRACE_GPS,SMS_GPS,SMS_FIXGPS = 1,2,3,4
local inf,curFramePara,serachGpsPendingFrm = {},{},{}
local function FrmHead(typ)
	return FRM_HEAD
end
local function GetGps3DStatus(bodyTyp)
	local ret = gpsapp.GetGpsAppState()
	if bodyTyp == TRACE_RPT then
		return ((ret == GPSAPP_SEARCH) and GPSAPP_OFF or ret)
	end
	return ret
end
local function GetGpsLocation()
	return gpsapp.GetGpsAppLocation()
end
local function GetGpsHwCtl()
	return ""
end
local function CheckSum(s)
	return ""
end
local function FrmBody(frmTyp,bodyTyp,gpsInfo,gpsState,para)
	local fsep,bsep = FRM_SEP,BODY_SEP
	local ret = ((para and type(para)== "table" and para.seq) or ("20"..misc.getclockstr()..sformat("%04d",inf.termRptSeqNum)))..fsep..frmTyp..fsep
	local bdy = ""
	if frmTyp == LOGIN then
		bdy = fs.GetPara(fs.PARA_PHONENUM)..bsep.."4"..bsep.."1;2;3;4"..bsep.."1"..bsep.."1"..bsep.."1"..bsep.."1"
	elseif frmTyp == LOGIN_HDSHK or frmTyp == SETKEYNUMRSP or frmTyp == SETHIDERSP then	
		bdy = para and "0" or "1"
	elseif frmTyp == POWERALM then
		bdy = bodyTyp..bsep..fs.GetPara(fs.PARA_PHONENUM)..bsep..para		
	elseif frmTyp == SYNCTIME then
		bdy = "01"..bsep..(misc.getimei() or "")..bsep..(sim.getimsi() or "")..bsep..(sim.geticcid() or "")
	elseif frmTyp == SOSALM then
		bdy = "0"
	elseif frmTyp == SMSRPT or frmTyp == CCRPT then
		bdy = fs.GetPara(fs.PARA_PHONENUM)..bsep..para..bsep..bodyTyp
	elseif frmTyp == LOCATIONQRYRSP then
		bdy = fs.GetPara(fs.PARA_PHONENUM)..bsep..para.parentNum..bsep..gpsInfo..bsep..para.typ
	elseif frmTyp == CELLQRYRSP then
		bdy = fs.GetPara(fs.PARA_PHONENUM)..bsep..para.parentNum..bsep..inf.cellInfo..bsep..para.typ
	elseif frmTyp == HEART then
		bdy = ""
	end
	ret = ret..slen(bdy)..fsep..bdy
	inf.termRptSeqNum = (inf.termRptSeqNum + 1 > inf.seqMaxNum) and 1 or (inf.termRptSeqNum + 1)
	return ret
end
local function FrmTail()
	return FRM_TAIL
end
local function PackPost(l)
	return "POST "..fs.GetPara(fs.PARA_PATH).."  HTTP/1.1\r\nUser-Agent: "..fs.GetPara(fs.PARA_PHONENUM).."\r\nContent-Length: "..l.."\r\nHost: "..fs.GetPara(fs.PARA_ADDR).."\r\n\r\n"
end
local function CalcLength(frm)
	return PackPost(slen(frm))..frm
end
local function GpsDistance(old,new,distance)
	print("GpsDistance",old,new,distance)		
	if not old and new then return true end
	if not new then return false end
	local oldLong,oldLati = smatch(old,"([%d.]*)[EW]|([%d.]*)[NS]")
	local newLong,newLati = smatch(new,"([%d.]*)[EW]|([%d.]*)[NS]")
	if (oldLong == "" or oldLong == nil or oldLati == "" or oldLati == nil) and newLong and newLong ~= "" and newLati and newLati ~= "" then return true end
	return gps.diffofloc(oldLati,oldLong,newLati,newLong) >= distance*distance	
end
local function GpsAppLocationInd(id,result,data,para)
	if para then
		print("GpsAppLocationInd",result,data,para.mode,para.cellChange,para.lastGps,#serachGpsPendingFrm)
		if para.mode == SOS_GPS or para.mode == SMS_GPS or para.mode == SMS_FIXGPS then
			while #serachGpsPendingFrm > 0 do
				local dataItem = table.remove(serachGpsPendingFrm,1)
				
				linkapp.SckSend(SCK_IDX,CalcLength(FrmHead(dataItem.frmTyp)..FrmBody(dataItem.frmTyp,dataItem.bodyTyp,data,dataItem.gpsAppState,dataItem.bodyPara)..FrmTail()),dataItem.pos,dataItem.para,true)
			end
		elseif para.mode == TRACE_GPS then
			if result then
				if GpsDistance(para.lastGps,data,inf.traceDistance) then
					linkapp.SckSend(SCK_IDX,CalcLength(FrmHead(TERM_RPT)..FrmBody(TERM_RPT,TRACE_RPT,data,nil)..FrmTail()),nil,nil,false)
					inf.traceLastGps = data
				end
			else
				inf.traceLastGps = nil
				if para.cellChange then
					linkapp.SckSend(SCK_IDX,CalcLength(FrmHead(TERM_RPT)..FrmBody(TERM_RPT,TRACE_RPT,data,nil)..FrmTail()),nil,nil,false)
				end
			end					
		end	
	end
end
function SndToSvr(frmTyp,bodyTyp,pos,para,searchGps,gpsAppState,searchGpsMode,bodyPara)
	print("SndToSvr",frmTyp,bodyTyp,pos,para,searchGps,gpsAppState,searchGpsMode,bodyPara)
	local par =	{mode = searchGpsMode}
	if searchGps and gpsapp.StartGpsApp(gpsapp.GPSAPP_FIX_OPEN,180000,par) then
		local dataItem = 
		{
			frmTyp = frmTyp,
			bodyTyp = bodyTyp,
			bodyPara = bodyPara,
			pos = pos,
			para = para,
			gpsAppState = gpsAppState,
		}
		table.insert(serachGpsPendingFrm,dataItem)
		return true
	else
		local bdy = FrmBody(frmTyp,bodyTyp,"0E0N0T0",gpsAppState,bodyPara)
		local inf = {seq=smatch(bdy,"^(%d+)"..FRM_SEP)}
		result = linkapp.SckSend(SCK_IDX,CalcLength(FrmHead(frmTyp)..bdy..FrmTail()),pos,para,true)
		return result,inf
	end	
end
local function IsFrmComplete(data)
	local para,sep,d1,d2,len,body = {},FRM_SEP
	d1,d2,para.time,para.typ,len,body =
		sfind(data,"%"..FRM_HEAD.."(%d%d%d%d%d%d%d%d%d%d%d%d%d%d)".."%d%d%d%d"..sep.."(T%d%d)"..sep.."(%d+)"..sep.."(.*)".."%"..FRM_TAIL)
	if not d1 or not d2 then
		print("IsFrmComplete format err")
		return false,data
	end
	return true,ssub(data,d2+1,-1),para,body
end
local function OnLineTimerFunc()
	linkapp.SckDisconnect(SCK_IDX)
end
local function StopOnLineTimer()
	sys.timer_stop(OnLineTimerFunc)
end
local function StartOnLineTimer()
	local mode,secs = smatch(fs.GetPara(fs.PARA_SAVEMODE),"(M%d*):(%d+)")
	if (mode == "M1" or mode == "M") and secs then
		secs = tonumber(secs)
		if secs == 0 then
			StopOnLineTimer()
			linkapp.SckDisconnect(SCK_IDX)
			gpsapp.StopGpsApp()
		elseif secs == 999*60 then
			StopOnLineTimer()
		else
			print("StartOnLineTimer secs",secs)
			sys.timer_start(OnLineTimerFunc,secs*1000)			
		end
	end
end
local function WaitingRspTimerFunc()
	inf.waitingRspDataResendCnt = inf.waitingRspDataResendCnt + 1
	if inf.waitingRspDataResendCnt < inf.waitingRspDataResendMaxCnt then
		if not linkapp.SckSend(SCK_IDX,inf.waitingRspData.data,1,inf.waitingRspData.para,false) then
			ResetWaitingRspTimer()
		else
			linkapp.SetWaitingRspData(SCK_IDX,{})
			inf.waitingRspData = ""
		end		
	else
		ResetWaitingRspTimer()
	end
end
function ResetWaitingRspTimer()
	sys.timer_stop(WaitingRspTimerFunc)
	inf.waitingRspDataResendCnt = 0
	inf.waitingRspData = ""
	linkapp.SetWaitingRspData(SCK_IDX,{})
end
local function StartWaitingRspTimer()
	sys.timer_start(WaitingRspTimerFunc,inf.waitingRspTimerPeriod)
end
local function GetLongLati(data)
	if data then return smatch(data,"([%.%d]*)[EW]|([%.%d]*)[NS]") end	
end
local function decode(s)
	--print("decode",s)
	local ret,remain,i,d1,d2,unicode = "",s
	while true do
		d1,d2 = string.find(remain,"\\\u")
		--print("decode",d1,d2)
		if not d1 or not d2 then ret = ret..remain break end
		ret = ret..ssub(remain,1,d1-1)..common.ucs2betogb2312(common.hexstobins(ssub(remain,d2+1,d2+4)))
		remain = ssub(remain,d2+5,-1)
	end
	return ret
end
local function ProcLoginRsp(frmPara,frmBody)
	local sep = BODY_SEP
	ResetWaitingRspTimer()
	print("ProcLoginRsp",frmPara,frmBody)
	local d1,d2,stat,relativeNum,sosTyp,sosNum,dadFix,mumFix,dadAlm,mumAlm,almFreq,dadRptTime,mumRptTime = 
		sfind(frmBody,"(%d)"..sep.."([%u%d!=]*)"..sep.."(%w*)".."=".."([%d!=]*)"..sep.."([%d%u%-:!=]*)"..sep.."([%d%u%-:!=]*)"..sep.."([%d%u%-:!=]*)"..sep.."([%d%u%-:!=]*)"..sep.."([%d%u%-:!=]*)"..sep.."([%d%u%-:!=]*)"..sep.."([%d%u%-:!=]*)")
	if not d1 or not d2 then print("ProcLoginRsp format err") return end
	fs.SetPara(fs.PARA_RELATIVENUM,relativeNum,false)
	fs.SetPara(fs.PARA_SOSTYP,sosTyp,false)
	fs.SetPara(fs.PARA_SOSNUM,sosNum,false)
	fs.SetPara(fs.PARA_DADFIX,dadFix,false)
	fs.SetPara(fs.PARA_MUMFIX,mumFix,false)
	fs.SetPara(fs.PARA_DADALM,dadAlm,false)
	fs.SetPara(fs.PARA_MUMALM,mumAlm,false)
	fs.SetPara(fs.PARA_ALMFREQ,almFreq,false)
	fs.SetPara(fs.PARA_DADRPTTIME,dadRptTime,false)
	fs.SetPara(fs.PARA_MUMRPTTIME,mumRptTime,false)
	fs.FlushPara()
	SndToSvr(LOGIN_HDSHK,nil,nil,nil,false,nil,nil,true)
end
local function ProcSyncTimeRsp(frmPara,frmBody)
	local sep = BODY_SEP
	ResetWaitingRspTimer()
	print("ProcSyncTimeRsp",frmPara,frmBody)
	local d1,d2,stat,phoneNum,tm,url,surl,smsNum = 
		sfind(frmBody,"(%d)"..sep.."(%d*)"..sep.."(%d%d%d%d%d%d%d%d%d%d%d%d%d%d)"..sep.."([%w%./:]*)"..sep.."([%w%./:]*)"..sep.."(%d*)")
	if not d1 or not d2 then print("ProcSyncTimeRsp format err") return end	
	UpdateTime(tm)
	inf.tmSync = true
	fs.SetPara(fs.PARA_PHONENUM,phoneNum,false)
	fs.SetPara(fs.PARA_URL,url,false)
	fs.SetPara(fs.PARA_SURL,surl,false)
	fs.SetPara(fs.PARA_SMSNUM,smsNum,false)
	fs.FlushPara()
end
local function ProcSosAlmRsp(frmPara,frmBody)
end
local function ProcSmsRptRsp(frmPara,frmBody)
end
local function ProcCcRptRsp(frmPara,frmBody)
end
local proc = 
{
	[LOGINRSP] = ProcLoginRsp,
	[SYNCTIMERSP] = ProcSyncTimeRsp,
	[SOSALMRSP] = ProcSosAlmRsp,
	[SMSRPTRSP] = ProcSmsRptRsp,
	[CCRPTRSP] = ProcCcRptRsp,	
}
local function ProcFrmPara(frmPara,frmBody)
	print("ProcFrmPara",frmPara.typ)
	if proc[frmPara.typ] then
		proc[frmPara.typ](frmPara,frmBody)
	end
end
function SckRcv(idx,data)
	if idx ~= SCK_IDX or data == nil or data == "" then
		print("SckRcv err",idx,data)
	end
	inf.rcvData = inf.rcvData..data
	if inf.rcvData ~= "" then
		local unprocData,result,frmPara,frmBody = inf.rcvData		
		while true do
			result,unprocData,frmPara,frmBody = IsFrmComplete(unprocData)
			if result then ProcFrmPara(frmPara,frmBody) end
			if not unprocData or unprocData == "" or not result then break end
		end
		inf.rcvData = ""
		if unprocData and unprocData ~= "" then
			inf.rcvData = unprocData
		end			
	end
end
local function Init()
	inf.seqMaxNum = 9999
	inf.termRptSeqNum = 1
	inf.gpsInfo = ""
	inf.cellInfo = ""
	inf.location = ""
	inf.powerOnRpt = false
	inf.traceValid = false
	inf.traceFreq = 120
	inf.traceDistance = 100
	inf.traceLastGps = nil
	inf.lbsDwHandle = 0
	inf.waitingRspTimerPeriod = 10000
	inf.waitingRspDataResendCnt = 0
	inf.waitingRspDataResendMaxCnt = 2
	inf.waitingRspData = ""
	inf.rcvData = ""
	inf.isSckConnect = false	
	inf.simIns = false
	inf.notAudioPlaySIM = true
	inf.engMode = false	
	inf.cengqry = 0
	curFramePara.sendingFrmTyp = ""
	curFramePara.sendingBodyTyp = ""
end
local function clkRsp(cmd,success)
	if success then CheckOpenTrace() end
end
function UpdateTime(newTime)
	local t = 
	{
		year = tonumber(ssub(newTime,1,4)),
		month = tonumber(ssub(newTime,5,6)),
		day = tonumber(ssub(newTime,7,8)),
		hour = tonumber(ssub(newTime,9,10)),
		min = tonumber(ssub(newTime,11,12)),
		sec = tonumber(ssub(newTime,13,14)),
	}
	misc.setclock(t,clkRsp)
end
function CheckOpenTrace()
	local valid,freq,dist = fs.IsTraceValidPeriod()
	print("CheckOpenTrace",valid,freq,dist,inf.traceValid,inf.traceFreq,inf.traceDistance)
	if valid then
		inf.traceValid,inf.traceFreq,inf.traceDistance = valid,freq,dist
		if freq and freq ~= 0 then
			if inf.cengqry >= 4 then
				net.setcengqueryperiod(freq*1000)
			else
				net.setcengqueryperiod(20000)
			end			
		end
	else
		if inf.cengqry >= 4 then
			net.setcengqueryperiod(60000)
		else
			net.setcengqueryperiod(20000)
		end	
	end	
end
local function ClkInd(id,data)
	CheckOpenTrace()	
	return true
end
local function NetAbnormalRestartTimerFunc()
	if not inf.engMode then rtos.restart() end
end
local function IsNormalPowerOn()
	return rtos.poweron_reason() == rtos.POWERON_KEY or rtos.poweron_reason() == rtos.POWERON_CHARGER
end
local netTts = "IDLE"
local function NetTts(suc)
	print("NetTts",suc,netTts)
	if suc and netTts ~= "SUC" then
		if not fs.IsHideStatus() and IsNormalPowerOn() and inf.notAudioPlaySIM then
			audioapp.Play(audioapp.TTS,bintohex(gb2312toucs2("找到GSM网络，设备工作正常")),false,4,nil)
			inf.notAudioPlaySIM = false			
		end
		netTts = "SUC"
	elseif not suc and netTts ~= "FAIL" then
		if not fs.IsHideStatus() and IsNormalPowerOn() and inf.notAudioPlaySIM then
			audioapp.Play(audioapp.TTS,bintohex(gb2312toucs2("未找到GSM网络")),false,4,nil)
			inf.notAudioPlaySIM =false			
		end
		netTts = "FAIL"
	end
end
local function NetAbnormalTtsTimerFunc()
	NetTts(false)
end
local function NetStateChanged(id,data)
	print("NetStateChanged",data)
	if data == "REGISTERED" then	
		CheckOpenTrace()
	end
	if data == "REGISTERED" then
		sys.timer_stop(NetAbnormalRestartTimerFunc)
		sys.timer_stop(NetAbnormalTtsTimerFunc)
		NetTts(true)
	else
		sys.timer_start(NetAbnormalTtsTimerFunc,20000)
		if inf.simIns then
			sys.timer_start(NetAbnormalRestartTimerFunc,1800000)
		end
	end
	return true
end
function IsSckConnect()
	return inf.isSckConnect
end
function GetLbsDwHandle()
	return inf.lbsDwHandle
end
function SetLbsDwHandle(status)
	if status then
		inf.lbsDwHandle = inf.lbsDwHandle + 1
		sys.dispatch("DW_IND")
	else
		if inf.lbsDwHandle > 0 then
			inf.lbsDwHandle = inf.lbsDwHandle - 1
		end
	end
end
local function GetFrmTyp(data)
	if data then
		local sep = FRM_SEP
		return smatch(data,"%"..FRM_HEAD.."%d+"..sep.."(%w+)"..sep)
	end
end
local function GetBodyTyp(data)
	if data then
		if GetFrmTyp(data) == TERM_RPT then
			local sep = FRM_SEP
			return smatch(data,"%"..FRM_HEAD.."%d+"..sep.."%d+"..sep.."%w+"..sep.."%d+"..sep.."%w+"..sep.."%d+"..BODY_SEP.."(%d)"..BODY_SEP)
		end
	end
end
local function SckRsp(idx,evt,result,data)
	if idx ~= SCK_IDX then
		print("SckRsp err",idx)
		return
	end
	print("SckRsp",idx,evt,result)
	
	if evt == "CONNECT" then
		inf.isSckConnect = result
		sys.dispatch("SCK_CONNECT_IND")		
		if result then	
			if not inf.powerOnRpt then
				inf.powerOnRpt = true
				if IsNormalPowerOn() then
					SndToSvr(LOGIN,nil,nil,nil,false,nil,nil)
				end
			end
			if not inf.tmSync then
				SndToSvr(SYNCTIME,nil,nil,nil,false,nil,nil)
			end
			fs.SetPara(fs.PARA_SAVEMODE,"M1:65",true)
			StartOnLineTimer()
		end
	elseif evt == "SEND" and data then
		curFramePara.sendingFrmTyp = GetFrmTyp(data.data)
		curFramePara.sendingBodyTyp = GetBodyTyp(data.data)
		if result then			
			inf.TAPara = data.para
			if curFramePara.sendingFrmTyp == TERM_RPT then
				StartWaitingRspTimer()
				linkapp.SetWaitingRspData(SCK_IDX,data)
				inf.waitingRspData = data
				SetLbsDwHandle(true)	
				if curFramePara.sendingBodyTyp == POWERLOW_RPT then
					pmdapp.SetNeedLowRpt(false)
					linkapp.SckDisconnect(SCK_IDX)
				elseif curFramePara.sendingBodyTyp == POWEROFF_RPT then
					linkapp.SckDisconnect(SCK_IDX)
					sys.timer_start(rtos.poweroff,2500)
				end
			end	
			sys.timer_start(SndToSvr,1800000,HEART,nil,nil,nil,false,nil,nil,nil)
		end	
		if curFramePara.sendingFrmTyp == SOSALM then			
			if data.para.valid then
				local number
				for number in string.gmatch(data.para.num, "(%d+)") do
					smsapp.SndSms(number,"您的亲友遇到突发情况，请尽快联络您的亲友或相关部门")
				end
				sosapp.EnterSosDialNum()
			end
		elseif curFramePara.sendingFrmTyp == LOCATIONQRYRSP then
			if data.para and data.para.mode == SOS_GPS then
				SndToSvr(SMSRPT,"SOS",nil,nil,false,nil,nil,smsapp.GetSosSmsInf()..BODY_SEP..common.binstohexs(common.gb2312toucs2("您的亲友遇到突发情况，请尽快联络您的亲友或相关部门")))
				SndToSvr(CCRPT,"SOS",nil,nil,false,nil,nil,ccapp.GetSosCcInf())
			end
		end
	elseif evt == "DISCONNECT" then
		inf.isSckConnect = false
		StopOnLineTimer()
		sys.dispatch("SCK_DISCONNECT_IND")
	elseif evt == "STATE" and result == "CLOSED" then
		inf.isSckConnect = false
		StopOnLineTimer()
	elseif evt == "STATE" and result == "ERROR" then
		inf.isSckConnect = false
		StopOnLineTimer()
		StartSckConnect()
	end
end
local function SimInd(id,data)
	if data ~= "NIST" then
		inf.simIns = true
	end
	if data == "NIST" then
		if not fs.IsHideStatus() and IsNormalPowerOn() and inf.notAudioPlaySIM then
			audioapp.Play(audioapp.TTS,bintohex(gb2312toucs2("未插卡")),false,4,nil)
			inf.notAudioPlaySIM = false			
		end
	elseif data == "NORDY" then
		if not fs.IsHideStatus() and IsNormalPowerOn() and inf.notAudioPlaySIM then
			audioapp.Play(audioapp.TTS,bintohex(gb2312toucs2("西亩卡异常")),false,4,nil)
			inf.notAudioPlaySIM = false
		end
	end
	return true
end
local function SetEngMode(id,data)
	inf.engMode = data
	return true
end
local function CellInfoInd(id,data)
	local i
	for i=1,data.cnt do
		if data[i].lac ~= 0 and data[i].ci ~= 0 then
			if i == 1 then
				inf.cellInfo = data[i].lac.."/"..data[i].ci.."@"
			else
				inf.cellInfo = inf.cellInfo..data[i].lac.."/"..data[i].ci.."!"
			end			
		end
	end	
	return true
end
function StartSckConnect()
	linkapp.SckConnect(SCK_IDX,linkapp.NORMAL_CAUSE,fs.GetPara(fs.PARA_PROT),fs.GetPara(fs.PARA_ADDR),fs.GetPara(fs.PARA_PORT),SckRsp,SckRcv)
end
function Relogin()
	inf.powerOnRpt = false
	
	linkapp.SckConnect(SCK_IDX,linkapp.SVR_CHANGE_CAUSE,fs.GetPara(fs.PARA_PROT),fs.GetPara(fs.PARA_ADDR),fs.GetPara(fs.PARA_PORT),SckRsp,SckRcv)
end
sys.regapp(SimInd,"SIM_IND")
sys.regapp(CellInfoInd,"CELL_INFO_IND")
sys.regapp(ClkInd,"CLOCK_IND")
sys.regapp(NetStateChanged,"NET_STATE_CHANGED")
sys.regapp(SetEngMode,"ENG_APP_IND")
net.startquerytimer()
net.setcengqueryperiod(20000)
Init()
ril.request("AT+TCPUSERPARAM=6,2,7200")
if fs.GetPara(fs.PARA_PHONENUM) and fs.GetPara(fs.PARA_PHONENUM) ~= "" then
	StartSckConnect()
else
	linkapp.SckCreate(SCK_IDX,linkapp.NORMAL_CAUSE,fs.GetPara(fs.PARA_PROT),fs.GetPara(fs.PARA_ADDR),fs.GetPara(fs.PARA_PORT),SckRsp,SckRcv)
end
sys.regapp(GpsAppLocationInd,gpsapp.GPSAPP_LOCATION_IND)
