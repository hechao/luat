--[[
ģ�����ƣ����Ӳ���(֧�ֿ������Ӻ͹ػ����ӣ�ͬʱֻ�ܴ���һ�����ӣ������ʵ�ֶ�����ӣ��ȵ�ǰ���Ӵ������ٴε����������ýӿ�ȥ������һ������)
ģ�鹦�ܣ��������ӹ���
ģ������޸�ʱ�䣺2017.12.19
]]

--����ntpģ�飬ͬ�����������ʱ��
require"ntp"
module(...,package.seeall)

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

--[[
��������ntpind
����  �����������ͬ��ʱ����Ϣ�Ĵ�����
����  ��id����Ϣid���˴�Ϊ"NTP_IND"
		result����ϢЯ���Ĳ������˴�Ϊ����ͬ��ʱ��Ľ����trueΪ�ɹ���falseΪʧ��
����ֵ��true��true��ʾ�����ط�������ע��NTP_IND��Ϣ�Ĵ����������NTP_IND�����˺��������ͷ���false����nil
]]
local function ntpind(id,result)
	print("ntpind",id,result)
	--��������������ͬ��ʱ��ɹ���ֱ�Ӳο���ǰʱ���������Ӽ���
	if result then
		--��������ʱ��Ϊ2017��12��19��12��25��0�룬�û�����ʱ�����ݵ�ǰʱ���޸Ĵ�ֵ
		--set_alarm�ӿڲ���˵������һ������1��ʾ�������ӣ�0��ʾ�ر����ӣ���������6��������ʾ������ʱ���룬�ر�����ʱ����6����������0,0,0,0,0,0
		rtos.set_alarm(1,2017,12,19,12,25,0)
		--���Ҫ���Թػ����ӣ����������д���
		rtos.poweroff()
	end
	return true
end

--[[
��������alarmsg
����  �����������¼��Ĵ�����
����  ����
����ֵ����
]]
local function alarmsg()
	print("alarmsg")
end

--����ǹػ����ӿ���������Ҫ�����������һ�Σ���������GSMЭ��ջ
if rtos.poweron_reason()==rtos.POWERON_ALARM then
	sys.restart("ALARM")
end

--ע�����������ͬ��ʱ����Ϣ�Ĵ�����
sys.regapp(ntpind,"NTP_IND")

--ע������ģ��
rtos.init_module(rtos.MOD_ALARM)
--ע��������Ϣ�Ĵ�����������ǿ������ӣ������¼�����ʱ�����alarmsg��
sys.regmsg(rtos.MSG_ALARM,alarmsg)
