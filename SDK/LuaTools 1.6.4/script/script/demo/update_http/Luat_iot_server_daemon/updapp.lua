require"updatehttp"
module(...,package.seeall)

local retry = 0

local function upevt(ind,para)
	--��������������para���Ƿ����سɹ��ı�־
	if ind == "UP_END_IND" then
		if para then
			sys.restart("updapp suc")
		else
			if retry<3 then
				link.shut()
				sys.timer_start(updatehttp.request,5000)
				retry = retry+1
			else
				sys.restart("updapp fail")
			end
		end
	end
end

local procer =
{
	UP_EVT = upevt,
}

sys.regapp(procer)
sys.timer_start(sys.restart,300000,"updapp timeout")
