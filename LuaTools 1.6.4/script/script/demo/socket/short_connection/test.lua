require"socket"
module(...,package.seeall)

--[[
������Ϊ������
��������
1��ÿ��10���ӷ���һ��λ�ð�"loc data\r\n"����̨�����۷��ͳɹ�����ʧ�ܣ�5��󶼶Ͽ����ӣ�
2���յ���̨������ʱ����rcv�����д�ӡ����
����ʱ���Լ��ķ������������޸������PROT��ADDR��PORT��֧��������IP��ַ
]]

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
--����ʱ���Լ��ķ�����
local SCK_IDX,PROT,ADDR,PORT = 1,"TCP","120.26.196.195",9999
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
	return socket.send(SCK_IDX,data,para)
end

--[[
��������locrpt
����  ������λ�ð����ݵ���̨
����  ���� 
����ֵ����
]]
function locrpt()
	print("locrpt",linksta)
	--if linksta then
		if not snd("loc data\r\n","LOCRPT")	then locrptcb({data="loc data\r\n",para="LOCRPT"},false) end	
	--end
end

--[[
��������locrptcb
����  ��λ�ð����ͽ������������ʱ����10���Ӻ��ٴη���λ�ð�2
����  ��  
        result�� bool���ͣ����ͽ�������Ƿ�ʱ��trueΪ�ɹ����߳�ʱ������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������socket.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function locrptcb(item,result)
	print("locrptcb",linksta)
	--if linksta then
		--5�����ȥ�Ͽ�socket���ӣ���5�����������շ������·�������
		sys.timer_start(socket.disconnect,5000,SCK_IDX)
		sys.timer_start(locrpt,10000)
	--end
end

--[[
��������sndcb
����  ���������ݽ���¼��Ĵ���
����  ��  
        result�� bool���ͣ���Ϣ�¼������trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ��������socket.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
local function sndcb(item,result)
	print("sndcb",item.para,result)
	if not item.para then return end
	if item.para=="LOCRPT" then
		locrptcb(item,result)
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
		socket.disconnect(SCK_IDX,"RECONNECT")
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
        idx��number���ͣ�socket.lua��ά����socket idx��������socket.connectʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
        evt��string���ͣ���Ϣ�¼�����
		result�� bool���ͣ���Ϣ�¼������trueΪ�ɹ�������Ϊʧ��
		item��table���ͣ�{data=,para=}����Ϣ�ش��Ĳ��������ݣ�Ŀǰֻ����SEND���͵��¼����õ��˴˲������������socket.sendʱ����ĵ�2���͵�3�������ֱ�Ϊdat��par����item={data=dat,para=par}
����ֵ����
]]
function ntfy(idx,evt,result,item)
	print("ntfy",evt,result,item,hasconnected)
	--���ӽ��������socket.connect����첽�¼���
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
				--����λ�ð�����̨
				locrpt()
			end
		--����ʧ��
		else
			if not hasconnected then
				--RECONN_PERIOD�������
				sys.timer_start(reconn,RECONN_PERIOD*1000)
			else				
				socket.disconnect(idx)
			end			
		end	
	--���ݷ��ͽ��������socket.send����첽�¼���
	elseif evt == "SEND" then
		if item then
			sndcb(item,result)
		end
		--����ʧ�ܣ�RECONN_PERIOD���������̨����Ҫ����reconn����ʱsocket״̬��Ȼ��CONNECTED���ᵼ��һֱ�����Ϸ�����
		--if not result then sys.timer_start(reconn,RECONN_PERIOD*1000) end
		if not result then socket.disconnect(idx) end
	--���ӱ����Ͽ�
	elseif evt == "STATE" and result == "CLOSED" then
		linksta = false
		--�����Զ��幦�ܴ���
	--���������Ͽ�������link.shut����첽�¼���
	elseif evt == "STATE" and result == "SHUTED" then
		linksta = false
		--�����Զ��幦�ܴ���
	--���������Ͽ�������socket.disconnect����첽�¼���
	elseif evt == "DISCONNECT" then
		linksta = false
		if item=="RECONNECT" then connect() end
		--�����Զ��幦�ܴ���			
	end
	--����������
	if smatch((type(result)=="string") and result or "","ERROR") then
		socket.disconnect(idx)
	end
end

--[[
��������rcv
����  ��socket�������ݵĴ�����
����  ��
        idx ��socket.lua��ά����socket idx��������socket.connectʱ����ĵ�һ��������ͬ��������Ժ��Բ�����
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
	socket.connect(SCK_IDX,PROT,ADDR,PORT,ntfy,rcv)
	conning = true
end

connect()
