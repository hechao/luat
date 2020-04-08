module(...,package.seeall)

local schar,slen,sfind,sbyte,ssub = string.char,string.len,string.find,string.byte,string.sub

--[[
��������
uart����֡�ṹ���ս�����Χ�豸������

֡�ṹ���£�
��ʼ��־��1�ֽڣ��̶�Ϊ0x01
���ݸ�����1�ֽڣ�У��������ݸ���֮������������ֽڸ���
ָ�1�ֽ�
����1��1�ֽ�
����2��1�ֽ�
����3��1�ֽ�
����4��1�ֽ�
У���룺���ݸ���������4���������
������־��1�ֽڣ��̶�Ϊ0xFE
]]


--����ID,1��Ӧuart1
--���Ҫ�޸�Ϊuart2����UART_ID��ֵΪ2����
local UART_ID = 1
--��ʼ��������־
local FRM_HEAD,FRM_TAIL = 0x01,0xFE
--ָ��
local CMD_01 = 0x01
--���ڶ��������ݻ�����
local rdbuf = ""

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

--ָ��1�����ݽ���
local function cmd01(s)
	print("cmd01",common.binstohexs(s),slen(s))
	if slen(s)~=4 then return end
	local i,j,databyte
	for i=1,4 do
		databyte = sbyte(s,i)
		for j=0,7 do
			print("cmd01 data"..i.."_bit"..j..": "..(bit.isset(databyte,j) and 1 or 0))
		end
	end
end

--�����ַ���s��У����
local function checksum(s)
	local ret,i = 0
	for i=1,slen(s) do
		ret = bit.bxor(ret,sbyte(s,i))
	end
	return ret
end

--[[
��������parse
����  ������֡�ṹ��������һ��������֡����
����  ��
		data������δ���������
����ֵ����һ������ֵ��һ������֡���ĵĴ��������ڶ�������ֵ��δ���������
]]
local function parse(data)
	if not data then return end
	
	--��ʼ��־
	local headidx = string.find(data,schar(FRM_HEAD))
	if not headidx then print("parse no head error") return true,"" end
	
	--���ݸ���
	if slen(data)<=headidx then print("parse wait cnt byte") return false,data end
	local cnt = sbyte(data,headidx+1)
	
	if slen(data)<headidx+cnt+3 then print("parse wait complete") return false,data end
	
	--ָ��
	local cmd = sbyte(data,headidx+2)	
	local procer =
	{
		[CMD_01] = cmd01,
	}
	if not procer[cmd] then print("parse cmd error",cmd) return false,ssub(data,headidx+cnt+4,-1) end
	
	--������־
	if sbyte(data,headidx+cnt+3)~=FRM_TAIL then print("parse tail error",sbyte(data,headidx+cnt+3)) return false,ssub(data,headidx+cnt+4,-1) end
	
	--У����
	local sum1,sum2 = checksum(ssub(data,headidx+1,headidx+1+cnt)),sbyte(data,headidx+cnt+2)
	if sum1~=sum2 then print("parse checksum error",sum1,sum2) return false,ssub(data,headidx+cnt+4,-1) end
	
	procer[cmd](ssub(data,headidx+3,headidx+1+cnt))
	
	return true,ssub(data,headidx+cnt+4,-1)	
end

--[[
��������proc
����  ������Ӵ��ڶ���������
����  ��
		data����ǰһ�δӴ��ڶ���������
����ֵ����
]]
local function proc(data)
	if not data or string.len(data) == 0 then return end
	--׷�ӵ�������
	rdbuf = rdbuf..data	
	
	local result,unproc
	unproc = rdbuf
	--����֡�ṹѭ������δ�����������
	while true do
		result,unproc = parse(unproc)
		if not unproc or unproc == "" or not result then
			break
		end
	end

	rdbuf = unproc or ""
end

--[[
��������read
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
		--������Ĵ�ӡ���ʱ
		print("read",common.binstohexs(data))
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

--����ϵͳ���ڻ���״̬���˴�ֻ��Ϊ�˲�����Ҫ�����Դ�ģ��û�еط�����pm.sleep("test")���ߣ��������͹�������״̬
--�ڿ�����Ҫ�󹦺ĵ͡�����Ŀʱ��һ��Ҫ��취��֤pm.wake("test")���ڲ���Ҫ����ʱ����pm.sleep("test")
pm.wake("test")
--ע�ᴮ�ڵ����ݽ��պ����������յ����ݺ󣬻����жϷ�ʽ������read�ӿڶ�ȡ����
sys.reguart(UART_ID,read)
--���ò��Ҵ򿪴���
uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1)


