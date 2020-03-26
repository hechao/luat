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

--uartuse�����ŵ�ǰ�Ƿ���Ϊuart����ʹ�ã�true��ʾ�ǣ�����ı�ʾ����
local uartid,uartuse = 1,true
--[[
��������uartopn
����  ����uart
����  ����
����ֵ����
]]
local function uartopn()
	uart.setup(uartid,115200,8,uart.PAR_NONE,uart.STOP_1)	
end

--[[
��������uartclose
����  ���ر�uart
����  ����
����ֵ����
]]
local function uartclose()
	uart.close(uartid)
end

--[[
��������switchtouart
����  ���л���uart����ʹ��
����  ����
����ֵ����
]]
local function switchtouart()
	print("switchtouart",uartuse)
	if not uartuse then
		--�ر�gpio����
		pio.pin.close(pio.P0_1)
		pio.pin.close(pio.P0_0)
		--��uart����
		uartopn()
		uartuse = true
	end
end

--[[
��������switchtogpio
����  ���л���gpio����ʹ��
����  ����
����ֵ����
]]
local function switchtogpio()
	print("switchtogpio",uartuse)
	if uartuse then
		--�ر�uart����
		uartclose()
		--����gpio����
		pio.pin.setdir(pio.OUTPUT,pio.P0_1)
		pio.pin.setdir(pio.OUTPUT,pio.P0_0)
		--���gpio��ƽ
		pio.pin.setval(1,pio.P0_1)
		pio.pin.setval(0,pio.P0_0)
		uartuse = false
	end	
end

--[[
��������switch
����  ���л�uart��gpio����
����  ����
����ֵ����
]]
local function switch()
	if uartuse then
		switchtogpio()
	else
		switchtouart()
	end
end

uartopn()
--ѭ����ʱ����5���л�һ�ι���
sys.timer_loop_start(switch,5000)
