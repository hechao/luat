local base = _G
module("ttssmsapp",package.seeall)
local gb2312toucs2 = common.gb2312toucs2
local ucs2betogb2312 = common.ucs2betogb2312
local binstohexs = common.binstohexs
local appId,smsCnt,unReadCnt,smsIdx
local TTS_SMS_MAX_CNT =  5
local smsTable = {}
local function TtsSms(text)	
	audioapp.Play(audioapp.TTS,binstohexs(gb2312toucs2(text)),false,4,nil)
end
local function GetTtsSmsInfo()
	local unReadCnt = 0
	for k,v in pairs(smsTable) do
		if v.unRead then
			unReadCnt = unReadCnt + 1
		end
	end
	return #smsTable,unReadCnt
end
local function ProcKey(key)
	if key == keypad.KEY_SOS then
		smsCnt,unReadCnt = GetTtsSmsInfo()
		if smsCnt == 0 then
			TtsSms("û�ж���")
		else
			TtsSms("����"..smsCnt.."�����ţ�"..unReadCnt.."��δ��")
		end
		--print("smsCnt,unReadCnt",smsCnt,unReadCnt)
	elseif key == keypad.KEY_1 and smsCnt > 0 then
		smsIdx = ((smsIdx - 1) > 0) and (smsIdx - 1) or smsCnt
		--print("smsIdx",smsIdx)
		TtsSms("��"..smsIdx.."�����ţ�"..smsTable[smsIdx].sms)
		smsTable[smsIdx].unRead = false
	elseif key == keypad.KEY_2 and smsCnt > 0 then
		smsIdx = ((smsIdx + 1) > smsCnt) and 1 or (smsIdx + 1)
		--print("smsIdx",smsIdx)
		TtsSms("��"..smsIdx.."�����ţ�"..smsTable[smsIdx].sms)
		smsTable[smsIdx].unRead = false
	elseif key == keypad.KEY_4 then
		--TtsSms("�˳����Ų���")
		audioapp.Stop()
		ExitTtsSmsApp()
	end	
end
local ttsSmsApp = {
	MMI_KEYPAD_IND = ProcKey,	
}
function ExitTtsSmsApp()
	if appId ~= nil then
		sys.deregapp(appId)
		appId = nil		
	end	
end
function EnterTtsSmsApp()
	if filestore.IsHideStatus() then
		return
	end
	if appId == nil then
		appId = sys.regapp(ttsSmsApp)
		smsIdx = 0
		--TtsSms("SOS������������Ŀ��1�ż�����2�ż������������ݣ�4�ż��˳�")
		smsCnt,unReadCnt = GetTtsSmsInfo()
		if smsCnt == 0 then
			TtsSms("û�ж���")
			ExitTtsSmsApp()
		else
			TtsSms("����"..smsCnt.."�����ţ�"..unReadCnt.."��δ��")
		end
	end
end
function AddTtsSms(cont)
	if cont and string.len(cont) > 0 then
		local item = 
		{
			sms = cont,
			unRead = true,
		}
		table.insert(smsTable,1,item)
		if #smsTable > TTS_SMS_MAX_CNT then
			table.remove(smsTable)
		end
	end
end
local function Proc(id,data)
	ExitTtsSmsApp()
	return true
end
sys.regapp(Proc,"AUDIOAPP_STOP")
