--[[
ģ�����ƣ�ͨ������
ģ�鹦�ܣ����Ժ������
ģ������޸�ʱ�䣺2017.02.23
]]

module(...,package.seeall)
require"cc"
require"audio"
require"common"

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
��������connected
����  ����ͨ���ѽ�������Ϣ������
����  ����
����ֵ����
]]
local function connected()
	print("connected")
	--5��󲥷�TTS���Զˣ��ײ��������֧��TTS����
	sys.timer_start(audio.play,5000,0,"TTSCC",common.binstohexs(common.gb2312toucs2("ͨ���в���TTS����")),audiocore.VOL7)
	--50��֮����������ͨ��
	sys.timer_start(cc.hangup,50000,"AUTO_DISCONNECT")
end

--[[
��������disconnected
����  ����ͨ���ѽ�������Ϣ������
����  ��
		para��ͨ������ԭ��ֵ
			  "LOCAL_HANG_UP"���û���������cc.hangup�ӿڹҶ�ͨ��
			  "CALL_FAILED"���û�����cc.dial�ӿں�����at����ִ��ʧ��
			  "NO CARRIER"��������Ӧ��
			  "BUSY"��ռ��
			  "NO ANSWER"��������Ӧ��
����ֵ����
]]
local function disconnected(para)
	print("disconnected:"..(para or "nil"))
	sys.timer_stop(cc.hangup,"AUTO_DISCONNECT")
end

--[[
��������incoming
����  �������硱��Ϣ������
����  ��
		num��string���ͣ��������
����ֵ����
]]
local function incoming(num)
	print("incoming:"..num)
	--��������
	cc.accept()
end

--[[
��������ready
����  ����ͨ������ģ��׼����������Ϣ������
����  ����
����ֵ����
]]
local function ready()
	print("ready")
	--����10086
	cc.dial("10086")
end

--[[
��������dtmfdetected
����  ����ͨ�����յ��Է���DTMF����Ϣ������
����  ��
		dtmf��string���ͣ��յ���DTMF�ַ�
����ֵ����
]]
local function dtmfdetected(dtmf)
	print("dtmfdetected",dtmf)
end

--[[
��������alerting
����  �������й��������յ��Է����塱��Ϣ������
����  ����
����ֵ����
]]
local function alerting()
	print("alerting")
end

--ע����Ϣ���û��ص�����
cc.regcb("READY",ready,"INCOMING",incoming,"CONNECTED",connected,"DISCONNECTED",disconnected,"DTMF",dtmfdetected,"ALERTING",alerting)
