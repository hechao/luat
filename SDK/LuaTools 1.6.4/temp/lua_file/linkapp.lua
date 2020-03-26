local base = _G
module("linkapp",package.seeall)
local print = base.print
local lstate = link.getstate
local slen = string.len
local scks = {}
local MAX_SCK_CNT = 4
local CONNECT_FAIL_RETRY_MAX_CNT = 3
local SEND_FAIL_RETRY_MAX_CNT = 3
NORMAL_CAUSE = 0
SVR_CHANGE_CAUSE = 1
local function GetSckIdxById(id)
	local i
	for i=1,MAX_SCK_CNT do
		if scks[i] and scks[i].id == id then
			return i
		end
	end
	return nil
end
local function ConnResetPara(sckIdx,suc)
	if sckIdx and scks[sckIdx] then
		scks[sckIdx].connectCause = nil
		scks[sckIdx].connFailRetryCnt = 0
		if not suc then
			scks[sckIdx].sendPendingQ = {}
		end
		scks[sckIdx].sendingData = {}
		scks[sckIdx].waitingRspData = {}
	end
end
local function SendResetPara(sckIdx)
	if sckIdx and scks[sckIdx] then
		scks[sckIdx].sendFailRetryCnt = 0
		scks[sckIdx].sendingData = {}
	end	
end
local function DisconnectResetPara(sckIdx)
	if sckIdx and scks[sckIdx] then
		scks[sckIdx].disconnectCause = nil
	end	
end
local function ResumeSckSend(sckIdx)
	if scks[sckIdx] == nil then
		print("ResumeSckSend",sckIdx)
		return false
	end
	if lstate(scks[sckIdx].id) ~= "CONNECTED" then
		if link.connect(scks[sckIdx].id,scks[sckIdx].prot,scks[sckIdx].addr,scks[sckIdx].port) == false then
			return false
		end		
	else
		if #scks[sckIdx].sendPendingQue ~= 0 and not scks[sckIdx].sendingData.data and not scks[sckIdx].waitingRspData.data then
			local data = table.remove(scks[sckIdx].sendPendingQue,1)
			if link.send(scks[sckIdx].id,data.data) then
				scks[sckIdx].sendingData = data
			else
				table.insert(scks[sckIdx].sendPendingQue,1,data)
			end
		end
	end
	return true
end
function SetWaitingRspData(sckIdx,data)
	if sckIdx and scks[sckIdx] then
		scks[sckIdx].waitingRspData = data
		if not data.data then
			ResumeSckSend(sckIdx)
		end
	end
end
local function SckNotify(id,evt,val)
	local sckIdx = GetSckIdxById(id)
	if sckIdx == nil then
		print("SckNotify err sckIdx == nil",id,evt,val)
		return
	end
	print("SckNotify",id,evt,val)
	if evt == "CONNECT" then
		local cause = scks[sckIdx].connectCause
		if val ~= "CONNECT OK" then
			scks[sckIdx].connFailRetryCnt = scks[sckIdx].connFailRetryCnt + 1
			if scks[sckIdx].connFailRetryCnt >= scks[sckIdx].connFailRetryMaxCnt then
				ConnResetPara(sckIdx,false)
				if #scks[sckIdx].sendPendingQue ~= 0 then
					while #scks[sckIdx].sendPendingQue ~= 0 do
						scks[sckIdx].rsp(sckIdx,"SEND",false,table.remove(scks[sckIdx].sendPendingQue,1))
					end
				else
					scks[sckIdx].rsp(sckIdx,"CONNECT",false,cause)
				end
			else
				if not link.connect(id,scks[sckIdx].prot,scks[sckIdx].addr,scks[sckIdx].port) then
					ConnResetPara(sckIdx,false)
					if #scks[sckIdx].sendPendingQue ~= 0 then
						while #scks[sckIdx].sendPendingQue ~= 0 do
							scks[sckIdx].rsp(sckIdx,"SEND",false,table.remove(scks[sckIdx].sendPendingQue,1))
						end
					else
						scks[sckIdx].rsp(sckIdx,"CONNECT",false,cause)
					end
				end
			end
		else
			ConnResetPara(sckIdx,true)
			scks[sckIdx].rsp(sckIdx,"CONNECT",true,cause)
			if #scks[sckIdx].sendPendingQue ~= 0 then
				local data = table.remove(scks[sckIdx].sendPendingQue,1)
				if link.send(id,data.data) then
					scks[sckIdx].sendingData = data
				else
					table.insert(scks[sckIdx].sendPendingQue,1,data)
				end
			end			
		end				
	elseif evt == "SEND" then
		local data = scks[sckIdx].sendingData
		if val ~= "SEND OK" then
			scks[sckIdx].sendFailRetryCnt = scks[sckIdx].sendFailRetryCnt + 1
			if scks[sckIdx].sendFailRetryCnt >= scks[sckIdx].sendFailRetryMaxCnt then
				SendResetPara(sckIdx)				
				scks[sckIdx].rsp(sckIdx,"SEND",false,data)
			else
				if not link.send(id,data.data) then
					SendResetPara(sckIdx)
					scks[sckIdx].rsp(sckIdx,"SEND",false,data)
				end
			end
		else
			SendResetPara(sckIdx)
			scks[sckIdx].rsp(sckIdx,"SEND",true,data)
			if #scks[sckIdx].sendPendingQue ~= 0 and not scks[sckIdx].sendingData.data and not scks[sckIdx].waitingRspData.data then
				local data = table.remove(scks[sckIdx].sendPendingQue,1)
				if link.send(id,data.data) then
					scks[sckIdx].sendingData = data
				else
					table.insert(scks[sckIdx].sendPendingQue,1,data)
				end
			end
		end		
	elseif evt == "DISCONNECT" then
		local cause = scks[sckIdx].disconnectCause
		DisconnectResetPara(sckIdx)
		if cause == SVR_CHANGE_CAUSE then
			link.connect(id,scks[sckIdx].prot,scks[sckIdx].addr,scks[sckIdx].port)
			scks[sckIdx].connectCause = SVR_CHANGE_CAUSE
		elseif #scks[sckIdx].sendPendingQue ~= 0 then
			link.connect(id,scks[sckIdx].prot,scks[sckIdx].addr,scks[sckIdx].port)
		end		
		scks[sckIdx].rsp(sckIdx,"DISCONNECT",true,cause)
	elseif evt == "STATE" and val == "CLOSED" then
		if #scks[sckIdx].sendPendingQue ~= 0 then
			link.connect(id,scks[sckIdx].prot,scks[sckIdx].addr,scks[sckIdx].port)
		end
		scks[sckIdx].rsp(sckIdx,evt,val,nil)
	else
		scks[sckIdx].rsp(sckIdx,evt,val,nil)
	end
	if string.find(val,"TCP ERROR") or string.find(val,"UDP ERROR") or (string.find(val,"ERROR") and evt ~= "CONNECT" and evt ~= "STATE") then
		link.disconnect(id)
	end
end
local function SckRcv(id,data)
	local sckIdx = GetSckIdxById(id)
	scks[sckIdx].rcv(sckIdx,data)
end
local function IsSckExist(idx)
	return scks[idx] ~= nil
end
function SckClrSendingQ(idx)
	if idx > MAX_SCK_CNT then
		print("SckClrSendingQ err idx > MAX_SCK_CNT",idx)
		return false
	end
	if scks[idx] then
		scks[idx].sendPendingQue = {}
	end
end
function SckCreate(idx,cause,prot,addr,port,rspCb,rcvCb)
	if idx > MAX_SCK_CNT then
		print("SckCreate err idx > MAX_SCK_CNT",idx)
		return false
	end
	if IsSckExist(idx) then
		print("SckCreate err IsSckExist",idx)
		return false
	end
	local sckId = link.open(SckNotify,SckRcv)
	scks[idx] = 
	{
		id = sckId,
		addr = addr,
		port = port,
		prot = prot,
		connFailRetryCnt = 0,
		connFailRetryMaxCnt = CONNECT_FAIL_RETRY_MAX_CNT,
		sendFailRetryCnt = 0,
		sendFailRetryMaxCnt = SEND_FAIL_RETRY_MAX_CNT,
		sendPendingQue = {},
		sendingData = {},
		waitingRspData = {},
		rsp = rspCb,
		rcv = rcvCb,
		connectCause = cause,
		disconnectCause = nil,
	}	
	return true
end
function SckConnect(idx,cause,prot,addr,port,rspCb,rcvCb)
	if idx > MAX_SCK_CNT then
		print("SckConnect err idx > MAX_SCK_CNT",idx)
		return false
	end
	local exist,disconnCause,sckId = IsSckExist(idx),nil
	if exist then
		sckId = scks[idx].id
		if link.getstate(sckId) == "CONNECTED" then
			if scks[idx].addr == addr and scks[idx].port == port and scks[idx].prot == prot then
				return true
			else
				if link.disconnect(sckId) then
					disconnCause = cause
				end
			end
		else
			if not link.connect(sckId,prot,addr,port) then
				print("connect fail1")
				return false
			end
		end
	else
		sckId = link.open(SckNotify,SckRcv)
		if not link.connect(sckId,prot,addr,port) then
			print("connect fail2")
			return false
		end	
	end
	scks[idx] = 
	{
		id = sckId,
		addr = addr,
		port = port,
		prot = prot,
		connFailRetryCnt = 0,
		connFailRetryMaxCnt = CONNECT_FAIL_RETRY_MAX_CNT,
		sendFailRetryCnt = 0,
		sendFailRetryMaxCnt = SEND_FAIL_RETRY_MAX_CNT,
		sendPendingQue = {},
		sendingData = {},
		waitingRspData = {},
		rsp = rspCb,
		rcv = rcvCb,
		connectCause = cause,
		disconnectCause = disconnCause,
	}
	return true
end
function SckSend(idx,data,pos,para,ins)
	if idx > MAX_SCK_CNT then
		print("SckSend err idx > MAX_SCK_CNT",idx)
		return false
	end
	if not IsSckExist(idx) then
		print("SckSend IsSckExist err",idx)
		return false
	end
	if not data or slen(data) == 0 then
		print("SckSend data empty")
		return false
	end
	local sckId = scks[idx].id
	local dataItem = 
	{
		data = data,
		para = para,
	}
	if lstate(sckId) ~= "CONNECTED" then
		if link.connect(sckId,scks[idx].prot,scks[idx].addr,scks[idx].port) == false then
			print("SckSend connect err")
			if ins then
				if dataItem.para then
					dataItem.para.valid = false
				end
				if pos then
					table.insert(scks[idx].sendPendingQue,pos,dataItem)
				else
					table.insert(scks[idx].sendPendingQue,dataItem)
				end
			end
			return false
		end
		if pos then
			table.insert(scks[idx].sendPendingQue,pos,dataItem)
		else
			table.insert(scks[idx].sendPendingQue,dataItem)
		end
	else
		if scks[idx].sendingData.data or scks[idx].waitingRspData.data then
			if pos then
				table.insert(scks[idx].sendPendingQue,pos,dataItem)
			else
				table.insert(scks[idx].sendPendingQue,dataItem)
			end
		else
			if link.send(sckId,data) then
				scks[idx].sendingData = dataItem
			end
		end		
	end
	return true
end
function SckDisconnect(idx)
	if idx > MAX_SCK_CNT then
		print("SckDisconnect err idx > MAX_SCK_CNT",idx)
		return false
	end
	if not IsSckExist(idx) then
		print("SckDisconnect IsSckExist err",idx)
		return false
	end
	return link.disconnect(scks[idx].id)	
end
link.setconnectnoretrestart(true,90000)
