
local base = _G
local string = require"string"
local io = require"io"
local os = require"os"
local rtos = require"rtos"
local sys  = require"sys"
local link = require"link"
local misc = require"misc"
local common = require"common"
module(...)
local print = base.print
local send = link.send
local dispatch = sys.dispatch
local updmode = base.UPDMODE or 0
local PROTOCOL,SERVER,PORT
local UPDATEPACK = "/luazip/update.bin"
local CMD_GET_TIMEOUT = 10000
local ERROR_PACK_TIMEOUT = 10000
local CMD_GET_RETRY_TIMES = 5
local lid
local state = "IDLE"
local projectid,total,last
local packid,getretries = 1,1
timezone = nil
BEIJING_TIME = 8
GREENWICH_TIME = 0

local function save(data)
	local mode = packid == 1 and "wb" or "a+"
	local f = io.open(UPDATEPACK,mode)
	if f == nil then
		print("update.save:file nil")
		return
	end
	f:write(data)
	f:close()
end

local function retry(param)
	if state ~= "UPDATE" and state ~= "CHECK" then
		return
	end
	if param == "STOP" then
		getretries = 0
		sys.timer_stop(retry)
		return
	end
	if param == "ERROR_PACK" then
		sys.timer_start(retry,ERROR_PACK_TIMEOUT)
		return
	end
	getretries = getretries + 1
		if getretries < CMD_GET_RETRY_TIMES then
		if state == "UPDATE" then
			reqget(packid)
		else
			reqcheck()
		end
	else
		upend(false)
	end
end

function reqget(index)
	send(lid,string.format("Get%d,%d",index,projectid))
	sys.timer_start(retry,CMD_GET_TIMEOUT)
end

local function getpack(data)
	local len = string.len(data)
	if (packid < total and len ~= 1024) or (packid >= total and (len - 1) ~= last) then
		print("getpack:len not match",packid,len,last)
		retry("ERROR_PACK")
		return
	end
	local id = string.byte(data,1)
	if id ~= packid then
		print("getpack:packid not match",id,packid)
		retry("ERROR_PACK")
		return
	end
	retry("STOP")
	save(string.sub(data,2,-1))
	if updmode == 1 then
		dispatch("UP_EVT","UP_PROGRESS_IND",packid*100/total)
	end
	if packid == total then
		upend(true)
	else
		packid = packid + 1
		reqget(packid)
	end
end

function upbegin(data)
	local p1,p2,p3 = string.match(data,"LUAUPDATE,(%d+),(%d+),(%d+)")
	p1,p2,p3 = base.tonumber(p1),base.tonumber(p2),base.tonumber(p3)
	if p1 and p2 and p3 then
		projectid,total,last = p1,p2,p3
		getretries = 0
		state = "UPDATE"
		packid = 1
		reqget(packid)
	else
		upend(false)
	end
end

function upend(succ)
	local tmpsta = state
	state = "IDLE"
	sys.timer_stop(retry)
	link.close(lid)
	if succ == true and updmode == 0 then
		sys.restart("update.upend")
	end
	if updmode == 1 and tmpsta ~= "IDLE" then
		dispatch("UP_EVT","UP_END_IND",succ)
	end
	dispatch("UPDATE_END_IND")
end

function reqcheck()
	state = "CHECK"
	send(lid,string.format("%s,%s,%s",misc.getimei(),base.PROJECT.."_"..sys.getcorever(),base.VERSION))
	sys.timer_start(retry,CMD_GET_TIMEOUT)
end

local function nofity(id,evt,val)
	if evt == "CONNECT" then
		dispatch("UPDATE_BEGIN_IND")
		if val == "CONNECT OK" then
			reqcheck()
		else
			upend(false)
		end
	elseif evt == "STATE" and val == "CLOSED" then		 
		upend(false)
	end
end
local chkrspdat

local upselcb = function(sel)
	if sel then
		upbegin(chkrspdat)
	else
		link.close(lid)
		dispatch("UPDATE_END_IND")
	end
end

local function recv(id,data)
	sys.timer_stop(retry)
	if state == "CHECK" then
		if string.find(data,"LUAUPDATE") == 1 then
			if updmode == 0 then
				upbegin(data)
			elseif updmode == 1 then
				chkrspdat = data
				dispatch("UP_EVT","NEW_VER_IND",upselcb)
			else
				upend(false)
			end
		else
			upend(false)
		end
		if timezone then
			local clk,a,b = {}
			a,b,clk.year,clk.month,clk.day,clk.hour,clk.min,clk.sec = string.find(data,"(%d+)%-(%d+)%-(%d+) *(%d%d):(%d%d):(%d%d)")
			if a and b then
				clk = common.transftimezone(clk.year,clk.month,clk.day,clk.hour,clk.min,clk.sec,BEIJING_TIME,timezone)
				misc.setclock(clk)
			end
		end
	elseif state == "UPDATE" then
		if data == "ERR" then
			upend(false)
		else
			getpack(data)
		end
	else
		upend(false)
	end	
end

function settimezone(zone)
	timezone = zone
end

function setup(prot,server,port)
	if prot and server and port then
		PROTOCOL,SERVER,PORT = prot,server,port
		if base.PROJECT ~= nil and base.VERSION ~= nil and updmode ~= nil then
			lid = link.open(nofity,recv,"update")
			link.connect(lid,PROTOCOL,SERVER,PORT)
		end
	end
end
