module(...,package.seeall)

require"aliyuniot"

--�������ϴ�����key��secret���û�����Լ��ڰ������ϴ�����Ŀ�������Լ�����Ŀ��Ϣ���޸�������ֵ
local PRODUCT_KEY,PRODUCT_SECRET = "1000163201","4K8nYcT4Wiannoev"
--���������������Ϣ�⣬����ҪDEVICE_NAME��DEVICE_SECRET
--lib�л�ʹ���豸��IMEI��SN������DEVICE_NAME��DEVICE_SECRET�������ڰ�����������豸ʱ��DEVICE_NAME����IMEI��Ȼ������ɵ�DEVICE_SECRET����SNд���豸��

local qos1cnt = 1

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
��������pubqos1testackcb
����  ������1��qosΪ1����Ϣ���յ�PUBACK�Ļص�����
����  ��
		usertag������mqttclient:publishʱ�����usertag
		result��true��ʾ�����ɹ���false����nil��ʾʧ��
����ֵ����
]]
local function pubqos1testackcb(usertag,result)
	print("pubqos1testackcb",usertag,result)
	sys.timer_start(pubqos1test,20000)
	qos1cnt = qos1cnt+1
end

--[[
��������pubqos1test
����  ������1��qosΪ1����Ϣ
����  ����
����ֵ����
]]
function pubqos1test()
	--ע�⣺�ڴ˴��Լ�ȥ����payload�����ݱ��룬aliyuniot���в����payload���������κα���ת��
	aliyuniot.publish("/"..PRODUCT_KEY.."/"..misc.getimei().."/update","qos1data",1,pubqos1testackcb,"publish1test_"..qos1cnt)
end

--[[
��������subackcb
����  ��MQTT SUBSCRIBE֮���յ�SUBACK�Ļص�����
����  ��
		usertag������mqttclient:subscribeʱ�����usertag
		result��true��ʾ���ĳɹ���false����nil��ʾʧ��
����ֵ����
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
end

--[[
��������rcvmessage
����  ���յ�PUBLISH��Ϣʱ�Ļص�����
����  ��
		topic����Ϣ���⣨gb2312���룩
		payload����Ϣ���أ�ԭʼ���룬�յ���payload��ʲô���ݣ�����ʲô���ݣ�û�����κα���ת����
		qos����Ϣ�����ȼ�
����ֵ����
]]
local function rcvmessagecb(topic,payload,qos)
	print("rcvmessagecb",topic,payload,qos)
end

--[[
��������connectedcb
����  ��MQTT CONNECT�ɹ��ص�����
����  ����		
����ֵ����
]]
local function connectedcb()
	print("connectedcb")
	--��������
	aliyuniot.subscribe({{topic="/"..PRODUCT_KEY.."/"..misc.getimei().."/get",qos=0}, {topic="/"..PRODUCT_KEY.."/"..misc.getimei().."/get",qos=1}}, subackcb, "subscribegetopic")
	--ע���¼��Ļص�������MESSAGE�¼���ʾ�յ���PUBLISH��Ϣ
	aliyuniot.regevtcb({MESSAGE=rcvmessagecb})
	--����һ��qosΪ1����Ϣ
	pubqos1test()
end

--[[
��������connecterrcb
����  ��MQTT CONNECTʧ�ܻص�����
����  ��
		r��ʧ��ԭ��ֵ
			1��Connection Refused: unacceptable protocol version
			2��Connection Refused: identifier rejected
			3��Connection Refused: server unavailable
			4��Connection Refused: bad user name or password
			5��Connection Refused: not authorized
����ֵ����
]]
local function connecterrcb(r)
	print("connecterrcb",r)
end

aliyuniot.config(PRODUCT_KEY,PRODUCT_SECRET)
aliyuniot.regcb(connectedcb,connecterrcb)
