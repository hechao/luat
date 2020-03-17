module(...,package.seeall)

require"pm"

--����ID,1��Ӧuart1
local UART_ID = 1

--SND_UNIT_MAX��ÿ�η��������ֽ�����ֻҪ�ۻ��յ������ݴ��ڵ����������ֽ���������û�����ڷ������ݵ���̨������������ǰSND_UNIT_MAX�ֽ����ݸ���̨
--SND_DELAY��ÿ�δ����յ�����ʱ�������ӳ�SND_DELAY�����û���յ��µ����ݣ�����û�����ڷ������ݵ���̨���������������ǰSND_UNIT_MAX�ֽ����ݸ���̨
--�������������ʹ�ã�ֻҪ�κ�һ���������㣬���ᴥ�����Ͷ���
--���磺SND_UNIT_MAX,SND_DELAY = 1024,1000�������¼������
--�����յ���500�ֽ����ݣ���������1000����û���յ����ݣ�����û�����ڷ������ݵ���̨��������������500�ֽ����ݸ���̨
--�����յ���500�ֽ����ݣ�800��������յ���524�ֽ����ݣ���ʱû�����ڷ������ݵ���̨��������������1024�ֽ����ݸ���̨
local SND_UNIT_MAX,SND_DELAY = 1024,1000

--sndingtosvr���Ƿ����ڷ������ݵ���̨
local sndingtosvr

--unsndbuf����û�з��͵�����
--sndingbuf�����ڷ��͵�����
local readbuf--[[,sndingbuf]] = ""--[[,""]]

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������mcuartǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("mcuart",...)
end

--[[
��������sndtosvr
����  ��֪ͨ���ݷ��͹���ģ�飬����������׼���ã����Է���
����  ����
����ֵ����
]]
local function sndtosvr()
	--print("sndtosvr",sndingtosvr)
	if not sndingtosvr then
		sys.dispatch("SND_TO_SVR_REQ")
	end
end

--[[
��������getsndingbuf
����  ����ȡ��Ҫ���͵�����
����  ����
����ֵ��string���ͣ���Ҫ���͵�����
]]
local function getsndingbuf()
	print("getsndingbuf",string.len(readbuf),sndingtosvr,sys.timer_is_active(sndtosvr))
	if string.len(readbuf)>0 and not sndingtosvr and (not sys.timer_is_active(sndtosvr) or string.len(readbuf)>=SND_UNIT_MAX) then
		local endidx = string.len(readbuf)>=SND_UNIT_MAX and SND_UNIT_MAX or string.len(readbuf)
		local retstr = string.sub(readbuf,1,endidx)
		readbuf = string.sub(readbuf,endidx+1,-1)
		sndingtosvr = true
		return retstr
	else
		sndingtosvr = false
		return ""
	end	
end

--[[
��������resumesndtosvr
����  ����λ�����б�־����ȡ��Ҫ���͵�����
����  ����
����ֵ��string���ͣ���Ҫ���͵�����
]]
function resumesndtosvr()
	sndingtosvr = false
	return getsndingbuf()
end

--[[
��������sndcnf
����  �����ͽ��������
����  ��
		result�����ͽ����true�ɹ�������ֵʧ��
����ֵ����
]]
--[[local function sndcnf(result)
	print("sndcnf",result)
	--sndingbuf = ""
	sndingtosvr = false
end]]

--[[
��������proc
����  �������ڽ��յ�������
����  ��
		data����ǰһ�ζ�ȡ���Ĵ�������
����ֵ����
]]
local function proc(data)
	if not data or string.len(data) == 0 then return end
	--׷�ӵ�δ�������ݻ�����ĩβ
	readbuf = readbuf..data
	if string.len(readbuf)>=SND_UNIT_MAX then sndtosvr() end
	sys.timer_start(sndtosvr,SND_DELAY)
end


--[[
��������snd
����  ����ȡ���ڽ��յ�������
����  ����
����ֵ����
]]
local function read()
	local data = ""
	--�ײ�core�У������յ�����ʱ��
	--������ջ�����Ϊ�գ�������жϷ�ʽ֪ͨLua�ű��յ��������ݣ�
	--������ջ�������Ϊ�գ��򲻻�֪ͨLua�ű�
	--����Lua�ű����յ��ж϶���������ʱ��ÿ�ζ�Ҫ�ѽ��ջ������е�����ȫ���������������ܱ�֤�ײ�core�е��������ж���������read�����е�while����оͱ�֤����һ��
	while true do
		data = uart.read(UART_ID,"*l")
		if not data or string.len(data) == 0 then break end
		--print("read",string.len(data)--[[data,common.binstohexs(data)]])
		proc(data)
	end
end

--[[
��������write
����  ��ͨ�����ڷ�������
����  ��
		s��Ҫ���͵�����
����ֵ����
]]
function write(s)
	print("write",s)
	uart.write(UART_ID,s)	
end

--��Ϣ�������б�
local procer =
{
	SVR_TRANSPARENT_TO_MCU = write,
	--SND_TO_SVR_CNF = sndcnf,
}

--ע����Ϣ�������б�
sys.regapp(procer)
--����ϵͳ���ڻ���״̬����������
pm.wake("mcuart")
--ע�ᴮ�ڵ����ݽ��պ����������յ����ݺ󣬻����жϷ�ʽ������read�ӿڶ�ȡ����
sys.reguart(UART_ID,read)
--���ò��Ҵ򿪴���
uart.setup(UART_ID,9600,8,uart.PAR_NONE,uart.STOP_1)


