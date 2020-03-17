--[[
ģ�����ƣ�idle
ģ�鹦�ܣ���������
ģ������޸�ʱ�䣺2017.08.14
]]

module(...,package.seeall)

require"misc"

local ssub = string.sub

--appid������id
local appid

--[[
��������refresh
����  ������ˢ�´���
����  ����
����ֵ����
]]
local function refresh()
	--���LCD��ʾ������
	disp.clear()
	disp.puttext("��������",lcd.getxpos("��������"),0)
	local clkstr = "20"..misc.getclockstr()
	local datestr = ssub(clkstr,1,4).."-"..ssub(clkstr,5,6).."-"..ssub(clkstr,7,8)
	local timestr = ssub(clkstr,9,10)..":"..ssub(clkstr,11,12)
	--��ʾ����
	disp.puttext(datestr,lcd.getxpos(datestr),24)
	--��ʾʱ��
	disp.puttext(timestr,lcd.getxpos(timestr),44)
	--ˢ��LCD��ʾ��������LCD��Ļ��
	disp.update()
end

--�������͵���Ϣ��������
local winapp =
{
	onupdate = refresh,
}

--[[
��������clkind
����  ��ʱ����´���
����  ����
����ֵ����
]]
local function clkind()
	if uiwin.isactive(appid) then
		refresh()
	end
end

--�Ǵ������͵���Ϣ��������
local msgapp =
{
	CLOCK_IND = clkind,
}

--[[
��������open
����  ���򿪴������洰��
����  ����
����ֵ����
]]
function open()
	appid = uiwin.add(winapp)
	sys.regapp(msgapp)
end
