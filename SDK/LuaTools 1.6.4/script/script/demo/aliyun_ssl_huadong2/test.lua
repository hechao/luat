module(...,package.seeall)

require"aliyuniotssl"
require"misc"

--�����ƻ���2վ���ϴ����Ĳ�Ʒ��ProductKey���û�����ʵ��ֵ�����޸�
local PRODUCT_KEY = "b0FMK1Ga5cp"
--���������PRODUCT_KEY�⣬����Ҫ�豸���ƺ��豸֤��
--�豸����ʹ�ú���getDeviceName�ķ���ֵ��Ĭ��Ϊ�豸��IMEI
--�豸֤��ʹ�ú���getDeviceSecret�ķ���ֵ��Ĭ��Ϊ�豸��SN
--�������ʱ������ֱ���޸�getDeviceName��getDeviceSecret�ķ���ֵ
--��������ʱ��ʹ���豸��IMEI��SN������������ģ�飬����Ψһ��IMEI���û��������Լ��Ĳ�������д���IMEI���豸���ƣ���Ӧ��SN���豸֤�飩
--�����û��Խ�һ�����������豸�ϱ�IMEI�������������������ض�Ӧ���豸֤�飬Ȼ�����misc.setsn�ӿ�д���豸��SN��

--[[
��������getDeviceName
����  ����ȡ�豸����
����  ����
����ֵ���豸����
]]
local function getDeviceName()
	--Ĭ��ʹ���豸��IMEI��Ϊ�豸����
	--return "862991419835241"
	return misc.getimei()
end

--[[
��������getDeviceSecret
����  ����ȡ�豸֤��
����  ����
����ֵ���豸֤��
]]
local function getDeviceSecret()
	--Ĭ��ʹ���豸��SN��Ϊ�豸֤��
	--�û��������ʱ�������ڴ˴�ֱ�ӷ��ذ����Ƶ�iot����̨�����ɵ��豸֤�飬����return "y7MTCG6Gk33Ux26bbWSpANl4OaI0bg5Q"
	--return "y7MTCG6Gk33Ux26bbWSpANl4OaI0bg5Q"
	return misc.getsn()
end


local qos1cnt = 1

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������aliyuniotǰ׺
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
	aliyuniotssl.publish("/"..PRODUCT_KEY.."/"..getDeviceName().."/update","qos1data",1,pubqos1testackcb,"publish1test_"..qos1cnt)
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
	aliyuniotssl.publish("/"..PRODUCT_KEY.."/"..getDeviceName().."/update","device receive:"..payload,qos)
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
	aliyuniotssl.subscribe({{topic="/"..PRODUCT_KEY.."/"..getDeviceName().."/get",qos=0}, {topic="/"..PRODUCT_KEY.."/"..getDeviceName().."/get",qos=1}}, subackcb, "subscribegetopic")
	--ע���¼��Ļص�������MESSAGE�¼���ʾ�յ���PUBLISH��Ϣ
	aliyuniotssl.regevtcb({MESSAGE=rcvmessagecb})
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

--���ò�Ʒkey���豸���ƺ��豸֤�飻�ڶ����������봫��nil���˲�����Ϊ�˼��ݰ����ƺ���վ�㣩
--ע�⣺���ʹ��imei��sn��Ϊ�豸���ƺ��豸֤��ʱ����Ҫ��getDeviceName��getDeviceSecret�滻Ϊmisc.getimei()��misc.getsn()
--��Ϊ�����͵���misc.getimei()��misc.getsn()����ȡ����ֵ
aliyuniotssl.config(PRODUCT_KEY,nil,getDeviceName,getDeviceSecret)
--setMqtt�ӿڲ��Ǳ���ģ�aLiYun.lua��������ӿ����õĲ���Ĭ��ֵ�����Ĭ��ֵ���㲻�����󣬲ο�����ע�͵��Ĵ��룬ȥ���ò���
--aliyuniotssl.setMqtt(0)
aliyuniotssl.regcb(connectedcb,connecterrcb)





--[[
��Ҫ���ѣ�
һ��ʹ���˰�����OTAԶ������ģ��ű����ܣ�ǿ�ҽ���ʹ��dbg���ܣ�����������ע�͵Ĵ���
��Ϊͨ��Զ�������°汾�Ľű�������°汾�Ľű�����ʱ���﷨������������Զ����˵����һ�α�����д�İ汾
���˺�һ���������������������������Զ����������������һ����Զ�������°汾->�°汾���г�������->�Զ����˵��ɰ汾������ѭ�������¹����쳣���˷���������
���籾����д�İ汾��1.0.0����������������1.0.1�汾������1.0.1�汾����ʱ���﷨�������豸��ѭ����Զ��������1.0.1->1.0.1���г�������->�Զ����˵�1.0.0��
һ������dbg���ܺ󣬷����﷨���������󣬻Ὣ�﷨�����ϱ���dbg��������������Ա�鿴�﷨������־�����Լ�ʱ�����﷨���󣬳��������汾
dbg������֧��TCP��UDPЭ�飬�յ��κ��ϱ�����Ҫ�ظ���д��OK
����������Լ��dbg������������ʹ�ú����ṩ��"UDP","ota.airm2m.com",9072������
��iot.openluat.com�е�¼������һ����Ʒ��������"��ѯdebug"�п��Բ�ѯ�豸�ϱ��Ĵ�����Ϣ
]]
--require"dbg"
--sys.timer_start(dbg.setup,12000,"UDP","ota.airm2m.com",9072)

--Ҫʹ�ð�����OTA���ܣ�����ο����ļ�138��aliyuniotssl.config(PRODUCT_KEY,nil,getDeviceName,getDeviceSecret)ȥ���ò�Ʒkey���豸���ƺ��豸֤��
--Ȼ����ذ�����OTA����ģ��(������Ĵ���ע��)
--require"aliyuniotota"
--������ð�����OTA����ȥ������������ģ����¹̼���Ĭ�ϵĹ̼��汾�Ÿ�ʽΪ��_G.PROJECT.."_".._G.VERSION.."_"..sys.getcorever()���򵽴�Ϊֹ������Ҫ�ٿ�����˵��


--������ð�����OTA����ȥ��������������������ģ����ӵ�MCU�������������ʵ�������������Ĵ���ע�ͣ��������ýӿڽ������úʹ���
--����MCU��ǰ���еĹ̼��汾��
--aliyuniotota.setVer("MCU_VERSION_1.0.0")
--�����¹̼����غ󱣴���ļ���
--aliyuniotota.setName("MCU_FIRMWARE.bin")

--[[
��������otaCb
����  ���¹̼��ļ����ؽ�����Ļص�����
����  ��
		result�����ؽ����trueΪ�ɹ���falseΪʧ��
		filePath���¹̼��ļ����������·����ֻ��resultΪtrueʱ���˲�����������
����ֵ����
]]
--[[
local function otaCb(result,filePath)
	print("otaCb",result,filePath)
	if result then
		--�����Լ�������ȥʹ���ļ�filePath
		local fileHandle = io.open(filePath,"rb")
		if not fileHandle then print("otaCb open file error") return end
		local current = fileHandle:seek()
		local size = fileHandle:seek("end")
		fileHandle:seek("set",current)
		--����ļ�����
		print("otaCb size",size)
		
		--����ļ����ݣ�����ļ�̫��һ���Զ����ļ����ݿ��ܻ�����ڴ治�㣬�ִζ������Ա��������
		if size<=4096 then
			print(fileHandle:read("*all"))
		else
			--�ֶζ�ȡ�ļ�����
		end
		
		fileHandle:close()
		
		--�˴��ϱ��¹̼��汾�ţ���������ʹ�ã�
		--�û������Լ��ĳ���ʱ�����������������¹̼���ִ����������
		--�����ɹ��󣬵���aliyuniotota.setVer�ϱ��¹̼��汾��
		--�������ʧ�ܣ�����aliyuniotota.setVer�ϱ��ɹ̼��汾��
		aliyuniotota.setVer("MCU_VERSION_1.0.1")
	end
	
	--�ļ�ʹ����֮������Ժ���������Ҫ����ɾ��
	if filePath then os.remove(filePath) end
end
]]

--�����¹̼����ؽ���Ļص�����
--aliyuniotota.setCb(otaCb)
