require"socketssl"
module(...,package.seeall)

--[[
������Ϊ������
��������
1��ÿ��10���ӷ���һ��GET�����̨�����۷��ͳɹ�����ʧ�ܣ�5��󶼶Ͽ����ӣ�
2���յ���̨������ʱ����rcv�����д�ӡ����
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT��֧��������IP��ַ
]]

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--����ʱ���Լ��ķ�����
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","36.7.87.100",4433
--linksta:���̨��socket����״̬
local linksta
--�Ƿ�ɹ����ӹ�������
local hasconnected
--���������һ��Ҳû�������Ϻ�̨�����������쳣����
--һ�����������ڵĶ�����������Ӻ�̨ʧ�ܣ��᳢���������������ΪRECONN_PERIOD�룬�������RECONN_MAX_CNT��
--���һ�����������ڶ�û�����ӳɹ�����ȴ�RECONN_CYCLE_PERIOD������·���һ����������
--�������RECONN_CYCLE_MAX_CNT�ε��������ڶ�û�����ӳɹ������������
local RECONN_MAX_CNT,RECONN_PERIOD,RECONN_CYCLE_MAX_CNT,RECONN_CYCLE_PERIOD = 3,5,3,20
--reconncnt:��ǰ���������ڣ��Ѿ������Ĵ���
--reconncyclecnt:�������ٸ��������ڣ���û�����ӳɹ�
--һ�����ӳɹ������Ḵλ���������
--conning:�Ƿ��ڳ�������
local reconncnt,reconncyclecnt,conning = 0,0

local sndata = "GET / HTTP/1.1\r\nHost: 36.7.87.100\r\nConnection: keep-alive\r\n\r\n"

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
��������snd
����  �����÷��ͽӿڷ�������
����  ��
        data�����͵����ݣ��ڷ��ͽ���¼�������ntfy�У��ḳֵ��item.data��
		para�����͵Ĳ������ڷ��ͽ���¼�������ntfy�У��ḳֵ��item.para�� 
����ֵ�����÷��ͽӿڵĽ�������������ݷ����Ƿ�ɹ��Ľ�������ݷ����Ƿ�ɹ��Ľ����ntfy�е�SEND�¼���֪ͨ����trueΪ�ɹ�������Ϊʧ��
]]
function snd(data,para)
	return socketssl.send(SCK_IDX,data,para)
end

--[[
��������httpget
����  ������GET�����̨
����  ����
����ֵ����
]]
function httpget()
	print("httpget",linksta)
	--if linksta then
		if not snd(sndata,"HTTPGET") then httpgetcb({data=sndata,para="HTTPGET"},false) end	
	--end
end

--[[
��������httpgetcb
����  ��GET����ͻص���������ʱ����10���Ӻ��ٴη���GET����
����  ��  
        result�� bool���ͣ����ͽ�������Ƿ�ʱ��trueΪ�ɹ����߳�ʱ������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������socketssl.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function httpgetcb(item,result)
	print("httpgetcb",linksta)
	--if linksta then
		--5�����ȥ�Ͽ�socket���ӣ���5�����������շ������·�������
		sys.timer_start(socketssl.disconnect,5000,SCK_IDX)
		sys.timer_start(httpget,10000)
	--end
end

--[[
��������sndcb
����  ���������ݽ���¼��Ĵ���
����  ��  
        result�� bool���ͣ���Ϣ�¼������trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������socketssl.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="HTTPGET" then
		httpgetcb(item,result)
	end
end

--[[
��������reconn
����  ��������̨����
        һ�����������ڵĶ�����������Ӻ�̨ʧ�ܣ��᳢���������������ΪRECONN_PERIOD�룬�������RECONN_MAX_CNT��
        ���һ�����������ڶ�û�����ӳɹ�����ȴ�RECONN_CYCLE_PERIOD������·���һ����������
        �������RECONN_CYCLE_MAX_CNT�ε��������ڶ�û�����ӳɹ������������
����  ����
����ֵ����
]]
local function reconn()
	print("reconn",reconncnt,conning,reconncyclecnt)
	--conning��ʾ���ڳ������Ӻ�̨��һ��Ҫ�жϴ˱����������п��ܷ��𲻱�Ҫ������������reconncnt���ӣ�ʵ�ʵ�������������
	if conning then return end
	--һ�����������ڵ�����
	if reconncnt < RECONN_MAX_CNT then
		reconncnt = reconncnt+1
		socketssl.disconnect(SCK_IDX,"RECONNECT")
	--һ���������ڵ�������ʧ��
	else
		reconncnt,reconncyclecnt = 0,reconncyclecnt+1
		if reconncyclecnt >= RECONN_CYCLE_MAX_CNT then
			sys.restart("connect fail")
		end
		socketssl.disconnect(SCK_IDX)
		sys.timer_start(reconn,RECONN_CYCLE_PERIOD*1000)
	end
end

--[[
��������ntfy
����  ��socket״̬�Ĵ�����
����  ��
        idx��number���ͣ�socketssl.lua��ά����socket idx��������socketssl.connectʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
        evt��string���ͣ���Ϣ�¼�����
		result�� bool���ͣ���Ϣ�¼������trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ�Ŀǰֻ����SEND���͵��¼����õ��˴˲������������socketssl.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function ntfy(idx,evt,result,item)
	print("ntfy",evt,result,item,hasconnected)
	--���ӽ��������socketssl.connect����첽�¼���
	if evt == "CONNECT" then
		conning = false
		--���ӳɹ�
		if result then
			reconncnt,reconncyclecnt,linksta = 0,0,true
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)
			--�������һ�����ӳɹ�
			if not hasconnected then
				hasconnected = true
				--����GET�����̨
				httpget()
			end
		--����ʧ��
		else
			if not hasconnected then
				--RECONN_PERIOD�������
				sys.timer_start(reconn,RECONN_PERIOD*1000)
			else				
				socketssl.disconnect(idx)
			end			
		end	
	--���ݷ��ͽ��������socketssl.send����첽�¼���
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
		--����ʧ�ܣ�RECONN_PERIOD���������̨����Ҫ����reconn����ʱsocket״̬��Ȼ��CONNECTED���ᵼ��һֱ�����Ϸ�����
		--if not result then sys.timer_start(reconn,RECONN_PERIOD*1000) end
		if not result then socketssl.disconnect(idx) end
	--���ӱ����Ͽ�
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		--�����Զ��幦�ܴ���
	--���������Ͽ�������link.shut����첽�¼���
	elseif evt == "STATE" and result == "SHUTED" then
		linksta = false
		--�����Զ��幦�ܴ���
	--���������Ͽ�������socketssl.disconnect����첽�¼���
	elseif evt == "DISCONNECT" then
		linksta = false
		if item=="RECONNECT" then connect() end
		--�����Զ��幦�ܴ���			
	end
	--����������
	if smatch((type(result)=="string") and result or "","ERROR") then
		socketssl.disconnect(idx)
	end
end

--[[
��������rcv
����  ��socket�������ݵĴ�����
����  ��
        idx ��socketssl.lua��ά����socket idx��������socketssl.connectʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
        data�����յ�������
����ֵ����
]]
function rcv(idx,data)
	print("rcv",data)
end

--[[
��������connect
����  ����������̨�����������ӣ�
        ������������Ѿ�׼���ã���������Ӻ�̨��������������ᱻ���𣬵���������׼���������Զ�ȥ���Ӻ�̨
		ntfy��socket״̬�Ĵ�����
		rcv��socket�������ݵĴ�����
����  ����
����ֵ����
]]
function connect()
	--verifysvrcerts��У���������֤���CA֤���ļ� (Base64���� X.509��ʽ)
	socketssl.connect(SCK_IDX,PROT,ADDR,PORT,ntfy,rcv,true,{verifysvrcerts={"ca.crt"}})
	conning = true
end

connect()
