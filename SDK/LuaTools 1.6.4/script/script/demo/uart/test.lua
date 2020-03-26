module(...,package.seeall)

--[[
��������
uart����֡�ṹ������Χ�豸�����룬�յ���ȷ��ָ��󣬻ظ�ASCII�ַ���

֡�ṹ���£�
֡ͷ��1�ֽڣ�0x01��ʾɨ��ָ�0x02��ʾ����GPIO���0x03��ʾ���ƶ˿�����
֡�壺�ֽڲ��̶�����֡ͷ�й�
֡β��1�ֽڣ��̶�Ϊ0xC0

�յ���ָ��֡ͷΪ0x01ʱ���ظ�"CMD_SCANNER\r\n"����Χ�豸
�յ���ָ��֡ͷΪ0x02ʱ���ظ�"CMD_GPIO\r\n"����Χ�豸
�յ���ָ��֡ͷΪ0x03ʱ���ظ�"CMD_PORT\r\n"����Χ�豸
�յ���ָ��֡ͷΪ��������ʱ���ظ�"CMD_ERROR\r\n"����Χ�豸
]]


--����ID,1��Ӧuart1
--���Ҫ�޸�Ϊuart2����UART_ID��ֵΪ2����
local UART_ID = 1
--֡ͷ�����Լ�֡β
local CMD_SCANNER,CMD_GPIO,CMD_PORT,FRM_TAIL = 1,2,3,string.char(0xC0)
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

--[[
��������parse
����  ������֡�ṹ��������һ��������֡����
����  ��
		data������δ���������
����ֵ����һ������ֵ��һ������֡���ĵĴ��������ڶ�������ֵ��δ���������
]]
local function parse(data)
	if not data then return end	
	
	local tail = string.find(data,string.char(0xC0))
	if not tail then return false,data end	
	local cmdtyp = string.byte(data,1)
	local body,result = string.sub(data,2,tail-1)
	
	print("parse",common.binstohexs(data),cmdtyp,common.binstohexs(body))
	
	if cmdtyp == CMD_SCANNER then
		write("CMD_SCANNER")
	elseif cmdtyp == CMD_GPIO then
		write("CMD_GPIO")
	elseif cmdtyp == CMD_PORT then
		write("CMD_PORT")
	else
		write("CMD_ERROR")
	end
	
	return true,string.sub(data,tail+1,-1)	
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
		--print("read",data,common.binstohexs(data))
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
	uart.write(UART_ID,s.."\r\n")
end

--����ϵͳ���ڻ���״̬���˴�ֻ��Ϊ�˲�����Ҫ�����Դ�ģ��û�еط�����pm.sleep("test")���ߣ��������͹�������״̬
--�ڿ�����Ҫ�󹦺ĵ͡�����Ŀʱ��һ��Ҫ��취��֤pm.wake("test")���ڲ���Ҫ����ʱ����pm.sleep("test")
pm.wake("test")
--ע�ᴮ�ڵ����ݽ��պ����������յ����ݺ󣬻����жϷ�ʽ������read�ӿڶ�ȡ����
sys.reguart(UART_ID,read)
--���ò��Ҵ򿪴���
uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1)

--[[
�����Ҫ�򿪡����ڷ���������ɺ�ͨ���첽��Ϣ֪ͨ���Ĺ��ܣ�������������
local function txdone()
	print("txdone")
end
uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1,nil,1)
sys.reguartx(UART_ID,txdone)
]]

