--[[
ģ�����ƣ�prompt
ģ�鹦�ܣ���ʾ�򴰿�
ģ������޸�ʱ�䣺2017.08.14
]]

module(...,package.seeall)

--appid������id
--str1,str2,str3�������ʾ��3���ַ���
--callback,callbackpara����ʾ�򴰿ڹرպ�Ļص������Լ��ص������Ĳ���
local appid,str1,str2,str3,callback,callbackpara

local pos = 
{
	{24},--��ʾ1���ַ���ʱ��Y����
	{10,37},--��ʾ2���ַ���ʱ��ÿ���ַ�����Ӧ��Y����
	{4,24,44},--��ʾ3���ַ���ʱ��ÿ���ַ�����Ӧ��Y����
}

--[[
��������refresh
����  ������ˢ�´���
����  ����
����ֵ����
]]
local function refresh()
	disp.clear()
	if str3 then
		disp.puttext(str3,lcd.getxpos(str3),pos[3][3])
	end
	if str2 then
		disp.puttext(str2,lcd.getxpos(str2),pos[str3 and 3 or 2][2])
	end
	if str1 then
		disp.puttext(str1,lcd.getxpos(str1),pos[str3 and 3 or (str2 and 2 or 1)][1])
	end
	disp.update()
end

--[[
��������close
����  ���ر���ʾ�򴰿�
����  ����
����ֵ����
]]
local function close()
	if not appid then return end
	sys.timer_stop(close)
	if callback then callback(callbackpara) end
	uiwin.remove(appid)
	appid = nil
end

--���ڵ���Ϣ��������
local app = {
	onupdate = refresh,
}

--[[
��������open
����  ������ʾ�򴰿�
����  ��
		s1��string���ͣ���ʾ�ĵ�1���ַ���
		s2��string���ͣ���ʾ�ĵ�2���ַ���������Ϊ�ջ���nil
		s3��string���ͣ���ʾ�ĵ�3���ַ���������Ϊ�ջ���nil
		cb��function���ͣ���ʾ��ر�ʱ�Ļص�����������Ϊnil
		cbpara����ʾ��ر�ʱ�ص������Ĳ���������Ϊnil
		prd��number���ͣ���ʾ���Զ��رյĳ�ʱʱ�䣬��λ���룬Ĭ��3000����
����ֵ����
]]
function open(s1,s2,s3,cb,cbpara,prd)
	str1,str2,str3,callback,callbackpara = s1,s2,s3,cb,cbpara
	appid = uiwin.add(app)
	sys.timer_start(close,prd or 3000)
end
