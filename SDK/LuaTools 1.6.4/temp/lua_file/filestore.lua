local base = _G
module("filestore",package.seeall)
local print = base.print
local tonumber = base.tonumber
local pairs = base.pairs
local para = {}
local PARA_FILE = "/para.txt"
local PARA_SEP = ","
PARA_PHONENUM = "PHONENUM"
PARA_URL = "URL"
PARA_PATH = "PATH"
PARA_SURL = "SURL"
PARA_SPATH = "SPATH"
PARA_PROT = "PROT"
PARA_ADDR = "ADDR"
PARA_PORT = "PORT"
PARA_SADDR = "SADDR"
PARA_SPORT = "SPORT"
PARA_SESSIONID = "SESSIONID"
PARA_IMSI = "IMSI"
PARA_SMSNUM = "SMSNUM"
PARA_SAVEMODE = "SAVEMODE"
PARA_RELATIVENUM = "RELATIVENUM"
PARA_SOSTYP = "SOSTYP"
PARA_SOSNUM = "SOSNUM"
PARA_WHITENUM = "WHITENUM"
PARA_STUDYNUM = "STUDYNUM"
PARA_HIDESTAT = "HIDESTAT"
PARA_HIDE = "HIDE"
PARA_PAUSEHIDEYEAR = "PAUSEHIDEYEAR"
PARA_PAUSEHIDE = "PAUSEHIDE"
PARA_TRACE = "TRACE"
PARA_AUTOLOCATION = "AUTOLOCATION"
PARA_AREAALARM = "AREAALARM"
PARA_RINGTYP = "RINGTYP"
PARA_RINGVOL = "RINGVOL"
PARA_CALLVOL = "CALLVOL"
PARA_LED = "LED"
PARA_GPS = "GPS"
PARA_ALARM = "ALARM"
PARA_DADFIX,PARA_MUMFIX,PARA_DADALM,PARA_MUMALM,PARA_ALMFREQ,PARA_DADRPTTIME,PARA_MUMRPTTIME = "DADFIX","MUMFIX","DADALM","MUMALM","ALMFREQ","DADRPTTIME","MUMRPTTIME"
local d1, d2
local function ReadTxt(f)
	local file, rt
	file = io.open(f,"r")
	if file == nil then
		print("can not open file",f)
		return
	end
	rt = file:read("*a")
	print("config_r",rt)
	file:close()
	return rt
end
local function WriteTxt(f,v)
	local file
	file = io.open(f,"w")
	if file == nil then
		print("open file to write err",f)
		return
	end
	file:write(v)
	file:close()
end
local paraTable = 
{
	{x=PARA_PHONENUM,y="",z="%d*",w=0},
	{x=PARA_URL,y="http://222.178.228.62:8805/index.aspx",z="[%w%./:]*",w=0},
	{x=PARA_PATH,y="/index.aspx",z="[%w%./]+",w=0},
	{x=PARA_SURL,y="http://58.17.161.202:8805/index.aspx",z="[%w%./:]*",w=0},
	{x=PARA_SPATH,y="/index.aspx",z="[%w%./]+",w=0},
	{x=PARA_PROT,y="TCP",z="%u+",w=0},
	{x=PARA_ADDR,y="222.178.228.62",z="[%w%.]+",w=0},
	{x=PARA_PORT,y="8805",z="%d+",w=0},
	{x=PARA_SADDR,y="58.17.161.202",z="[%w%.]+",w=0},
	{x=PARA_SPORT,y="8805",z="%d+",w=0},
	{x=PARA_SESSIONID,y="00000000",z="%w+",w=0},
	{x=PARA_IMSI,y="",z="%d*",w=0},
	{x=PARA_SMSNUM,y="",z="[%d!]*",w=0},
	{x=PARA_SAVEMODE,y="M1:120",z="[%w:!]*",w=0},
	{x=PARA_RELATIVENUM,y="",z="[%u%d!=]*",w=0},
	{x=PARA_SOSTYP,y="CELL",z="%w*",w=0},
	{x=PARA_SOSNUM,y="",z="[%d=!]*",w=0},
	{x=PARA_WHITENUM,y="",z="[%u%d!=]*",w=0},	
	{x=PARA_STUDYNUM,y="",z="%w*",w=0},
	{x=PARA_HIDESTAT,y="0",z="%d",w=0},
	{x=PARA_HIDE,y="",z="[%d%-:!=]*",w=0},
	{x=PARA_PAUSEHIDEYEAR,y="",z="%d*",w=0},
	{x=PARA_PAUSEHIDE,y="",z="[%d%u%-:!]*",w=0},
	{x=PARA_TRACE,y="",z="[%d%-=!]*",w=0},
	{x=PARA_AUTOLOCATION,y="",z="%d*",w=0},
	{x=PARA_AREAALARM,y="",z="%d*",w=0},
	{x=PARA_RINGTYP,y=1,z="%d+",w=1},
	{x=PARA_RINGVOL,y=7,z="%d+",w=1},
	{x=PARA_CALLVOL,y=4,z="%d+",w=1},
	{x=PARA_LED,y=0,z="%d",w=1},
	{x=PARA_GPS,y=0,z="%d",w=1},
	{x=PARA_ALARM,y="",z="[%d:!]*",w=0},
	{x=PARA_DADFIX,y="",z="[%d%u%-:!=]*",w=0},
	{x=PARA_MUMFIX,y="",z="[%d%u%-:!=]*",w=0},
	{x=PARA_DADALM,y="",z="[%d%u%-:!=]*",w=0},
	{x=PARA_MUMALM,y="",z="[%d%u%-:!=]*",w=0},
	{x=PARA_ALMFREQ,y="",z="[%d%u%-:!=]*",w=0},
	{x=PARA_DADRPTTIME,y="",z="[%d%u%-:!=]*",w=0},
	{x=PARA_MUMRPTTIME,y="",z="[%d%u%-:!=]*",w=0},
}
local function WritePara(save)
	if save then
		local para_w = ""
		for k,v in pairs(paraTable) do
			para_w = para_w..para[v.x]..PARA_SEP
		end
		print("para_w",para_w)
		if para_w ~= "" then
			WriteTxt(PARA_FILE,para_w)
		end
	end
end
local function tonum(val)
    if val ~= nil then
       para[val] = tonumber(para[val])
	end
end
local function Init()	
	for k,v in pairs(paraTable) do
		para[v.x] = v.y
	end
end
local function InitPara()
	local para_r = {}
    local n = {}
	local bWriteBack = false
	local prtstr = ""
	para_r = ReadTxt(PARA_FILE)    
	if para_r == nil then
		print("read para txt err and init")
		RestorePara()
		return
	end	
	local tmpPar = para_r
	d2 = 0
	for k,v in pairs(paraTable) do
		if not d2 then
			break
		end
		tmpPar = string.sub(tmpPar,d2+1,-1)
		d1,d2,n[v.x] = string.find(tmpPar,"("..v.z..")"..PARA_SEP)
		if n[v.x] ~= nil then
			prtstr = prtstr..v.x.."="..n[v.x]..PARA_SEP			
		end
	end
	para = n	
	print(prtstr)
	for k,v in pairs(paraTable) do
		if v.w == 1 then
			tonum(v.x)
		end				
	end
	for k,v in pairs(paraTable) do
		if para[v.x] == nil then
			print("nil,",v.x)
			para[v.x] = v.y
			if not bWriteBack then
				bWriteBack = true
			end
		end				
	end	
	if bWriteBack then
		print("WriteBack")
		WritePara(true)
	end
end
function GetServerPara(idx)
	return para[PARA_PROT],para[PARA_ADDR],para[PARA_PORT]
end
function IsSessionIdValid()
	return para[PARA_SESSIONID] ~= "00000000" and string.len(para[PARA_SESSIONID]) == 8
end
function IsTraceValidPeriod()
	local flag = (string.match(para[PARA_TRACE],"(%d)") == "1") and true or false	
	if not flag then
		return false
	end
	local freq,distance = string.match(string.sub(para[PARA_TRACE],-7,-1),"(%d+)%-(%d+)")
	if not freq or not distance then
		return false
	end
	freq = tonumber(freq)
	distance = tonumber(distance)
	local period = string.gsub(string.sub(para[PARA_TRACE],3,-8),"%D","")
	if not period or period == "" then
		return false
	end
	local curTime = string.sub(misc.getclockstr(),7,10)
	local i,valid = 1,false
	print("IsTraceValidPeriod",curTime,period)
	for i=1,string.len(period),8 do
		if curTime >= string.sub(period,i,i+3) and curTime <= string.sub(period,i+4,i+7) then
			valid = true
			break
		end
	end
	return valid,freq,distance
end

function GetRelativeNum(idx)
	local tmpPara = para[PARA_RELATIVENUM]
	if tmpPara and string.len(tmpPara) > 0 then
		tmpPara = tmpPara.."!"
	else
		return ""
	end
	local i,d1,d2,last,num
	d2 = 0
	for i=1,idx do
		last = d2
		d1,d2,num = string.find(string.sub(tmpPara,d2+1,-1),"=(%d*)!")
		if d2 == nil then
			break
		end
		d2 = last + d2		
	end
	if not num then
		return ""
	end
	return num
end
function IsRelativeNum(innum)
	local tmpPara = para[PARA_RELATIVENUM]
	print("IsRelativeNum",innum,tmpPara)
	if tmpPara and string.len(tmpPara) > 0 then
		tmpPara = tmpPara.."!"
	else
		return false
	end
	local d1,d2,last,num
	d2 = 0
	while true do
		last = d2
		d1,d2,num = string.find(string.sub(tmpPara,d2+1,-1),"=(%d*)!")
		if d1 == nil or d2 == nil or num == nil then
			break
		end
		d2 = last + d2	
		if num == innum then
			return true
		end
	end
	return false
end
function IsRelativeNumEmpty()
	local rel = para[PARA_RELATIVENUM]
	return ((rel == nil) or not string.match(rel,"=%d+"))
end
function IsSmsNum(innum)
	local tmpPara = para[PARA_SMSNUM]
	local para=""
	for para in string.gmatch(tmpPara, "(%d+)") do
		if string.find(innum, "^"..para) then
			return true
		end
	end
	return false
end
function IsSosNum(innum)
	if string.match(para[PARA_SOSNUM],innum) then return true end
end
function IsWhiteNumEmpty()
	return ((para[PARA_WHITENUM] == "") or (para[PARA_WHITENUM] == nil))
end
function IsWhiteNum(innum)
	local tmpPara = para[PARA_WHITENUM]
	if tmpPara and string.len(tmpPara) > 0 then
		tmpPara = tmpPara.."!"
	else
		return true
	end
	local d1,d2,last,num
	d2 = 0
	while true do
		last = d2
		d1,d2,num = string.find(string.sub(tmpPara,d2+1,-1),"=(%d*)!")
		if d1 == nil or d2 == nil or num == nil then
			break
		end
		d2 = last + d2	
		if num == innum then
			return true
		end
	end
	return false
end

function IsHideStatus()
	if GetPara(PARA_HIDESTAT) == "0" then return false end
	local tmpPara,result,curTm,wk,val,tm1,tm2 = para[PARA_HIDE],false,string.sub(misc.getclockstr(),7,10)
	for wk,val in string.gmatch(tmpPara,"(%d)=([%d%-!]+)") do
		if tonumber(wk) == misc.getweek() then
			for tm1,tm2 in string.gmatch(val,"(%d+)%-(%d+)") do
				if curTm >= tm1 and curTm <= tm2 then
					return true
				end
			end
		end
	end
	return false
end

function IsAlarmValid()
	local tmpPara = para[PARA_ALARM]	
	local pa1,pa2="",""
	local clk,week = string.sub(misc.getclockstr(),7,10),misc.getweek()
	for pa1, pa2 in string.gmatch(tmpPara, "(%d%d%d%d):([01][01][01][01][01][01][01])") do
		if pa1 == clk and string.sub(pa2,week,week) == "1" then
			return true,clk
		end
	end
	return false
end
function GetPara(name)
	return para[name]
end
function SetPara(name,val,save)
	if val ~= para[name] then
		if name == PARA_HIDE or name == PARA_PAUSE_HIDE then
			sys.dispatch("HIDE_IND")
		end
		para[name] = val
		WritePara(save)
	end
end
function FlushPara()
	WritePara(true)
end
function RestorePara()
	Init()
	WritePara(true)
end
local function ClkInd(id,data)
	local curDate = string.sub(misc.getclockstr(),1,6)
	local pauseHideDateYear,pauseHideDate = para[PARA_PAUSEHIDEYEAR],string.gsub(para[PARA_PAUSEHIDE],"%D","")
	local tmpPauseHideDate
	local clr = true
	for i=1,string.len(pauseHideDate),8 do
		if string.sub(pauseHideDate,i,i+3) <= string.sub(pauseHideDate,i+4,i+7) then
			tmpPauseHideDate = pauseHideDateYear..string.sub(pauseHideDate,i,i+3)..pauseHideDateYear..string.sub(pauseHideDate,i+4,i+7)
		elseif string.sub(pauseHideDate,i,i+3) > string.sub(pauseHideDate,i+4,i+7) and string.sub(pauseHideDate,i,i+1) == "12" and string.sub(pauseHideDate,i+4,i+5) == "01" then
			tmpPauseHideDate = pauseHideDateYear..string.sub(pauseHideDate,i,i+3)..(pauseHideDateYear+1)..string.sub(pauseHideDate,i+4,i+7)
		else
			tmpPauseHideDate = pauseHideDateYear..string.sub(pauseHideDate,i,i+3)..pauseHideDateYear.."1231"
		end
		if curDate >= string.sub(tmpPauseHideDate,1,6) and curDate <= string.sub(tmpPauseHideDate,7,12) then
			clr = false
			break
		end		
	end
	print("ClkInd",clr,curDate,pauseHideDateYear,pauseHideDate)
	if clr then
		SetPara(PARA_PAUSEHIDEYEAR,"",true)
		SetPara(PARA_PAUSEHIDE,"",true)
	end
	return true
end
sys.regapp(ClkInd,"CLOCK_IND")
InitPara()
