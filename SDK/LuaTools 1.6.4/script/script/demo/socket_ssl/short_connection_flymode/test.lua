require"socketssl"
require"misc"
module(...,package.seeall)

--[[
������Ϊ�����ӣ��������ݺ󣬽������ģʽ��Ȼ��ʱ�˳�����ģʽ�ٷ������ݣ����ѭ��
��������
1�����Ӻ�̨����GET�����̨����ʱʱ��Ϊ2���ӣ�2���������ʧ�ܣ���һֱ���ԣ����ͳɹ����߳�ʱ�󶼽������ģʽ��
2���������ģʽ5���Ӻ��˳�����ģʽ��Ȼ�������1��
ѭ������2������
2���յ���̨������ʱ����rcv�����д�ӡ����
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT��֧��������IP��ַ
]]

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--����ʱ���Լ��ķ�����
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","36.7.87.100",4433
--ÿ�����Ӻ�̨�����������쳣����
--һ�����������ڵĶ�����������Ӻ�̨ʧ�ܣ��᳢���������������ΪRECONN_PERIOD�룬�������RECONN_MAX_CNT��
--���һ�����������ڶ�û�����ӳɹ�����ȴ�RECONN_CYCLE_PERIOD������·���һ����������
--�������RECONN_CYCLE_MAX_CNT�ε��������ڶ�û�����ӳɹ������������
local RECONN_MAX_CNT,RECONN_PERIOD,RECONN_CYCLE_MAX_CNT,RECONN_CYCLE_PERIOD = 3,5,1,20
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
��������httpgetimeout
����  ��GET����ͳ�ʱ����ֱ�ӽ������ģʽ
����  ����  
����ֵ����
]]
local function httpgetimeout()
	print("httpgetimeout")
	httpgetcb(true)
end

--[[
��������httpget
����  ������GET�����̨
����  ���� 
����ֵ����
]]
function httpget()
	print("httpget")	
	--���÷��ͽӿڳɹ������������ݷ��ͳɹ������ݷ����Ƿ�ɹ�����ntfy�е�SEND�¼���֪ͨ
	if snd(sndata,"HTTPGET") then
		--����2���Ӷ�ʱ���������ʱ2�������ݶ�û�з��ͳɹ�����ֱ�ӽ������ģʽ
		sys.timer_start(httpgetimeout,120000)
	--���÷��ͽӿ�ʧ�ܣ�����������
	else
		httpgetcb()
	end	
end

--[[
��������httpgetcb
����  ��GET����ͻص������ͳɹ����߳�ʱ������������ģʽ������5���ӵġ��˳�����ģʽ�����Ӻ�̨����ʱ��
����  ��  
        result�� bool���ͣ����ͽ�������Ƿ�ʱ��trueΪ�ɹ����߳�ʱ������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������socketssl.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function httpgetcb(result,item)
	print("httpgetcb",result)
	if result then
		socketssl.disconnect(SCK_IDX)
		link.shut()
		misc.setflymode(true)
		sys.timer_start(connect,300000)
		sys.timer_stop(httpgetimeout)
	else
		sys.timer_start(reconn,RECONN_PERIOD*1000)
	end
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
		httpgetcb(result,item)
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
function reconn()
	print("reconn",reconncnt,conning,reconncyclecnt)
	--conning��ʾ���ڳ������Ӻ�̨��һ��Ҫ�жϴ˱����������п��ܷ��𲻱�Ҫ������������reconncnt���ӣ�ʵ�ʵ�������������
	if conning then return end
	--һ�����������ڵ�����
	if reconncnt < RECONN_MAX_CNT then		
		reconncnt = reconncnt+1
		socketssl.disconnect(SCK_IDX)
		link.shut()
	--һ���������ڵ�������ʧ��
	else
		reconncnt,reconncyclecnt = 0,reconncyclecnt+1
		if reconncyclecnt >= RECONN_CYCLE_MAX_CNT then
			sys.restart("connect fail")
		end
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
	print("ntfy",evt,result,item)
	--���ӽ��������socketssl.connect����첽�¼���
	if evt == "CONNECT" then
		conning = false
		--���ӳɹ�
		if result then
			reconncnt,reconncyclecnt = 0,0
			--ֹͣ������ʱ��
			sys.timer_stop(reconn)			
			--����GET�����̨
			httpget()
		--����ʧ��
		else
			--RECONN_PERIOD�������
			sys.timer_start(reconn,RECONN_PERIOD*1000)
		end	
	--���ݷ��ͽ��������socketssl.send����첽�¼���
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
	--���ӱ����Ͽ�
	elseif evt == "STATE" and result == "CLOSED" then
		--�����Զ��幦�ܴ���
	--���������Ͽ�������link.shut����첽�¼���
	elseif evt == "STATE" and result == "SHUTED" then
		--�����Զ��幦�ܴ���
	--���������Ͽ�������socketssl.disconnect����첽�¼���
	elseif evt == "DISCONNECT" then
		if not sys.timer_is_active(connect) then
			connect()
		end
		--�����Զ��幦�ܴ���			
	end
	--����������
	if smatch((type(result)=="string") and result or "","ERROR") then
		--�Ͽ�������·�����¼���
		link.shut()
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
