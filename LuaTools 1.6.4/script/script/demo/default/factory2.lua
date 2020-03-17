--[[
ģ�����ƣ�Luat�����ʾ����
ģ�鹦�ܣ�ÿ2��ͨ���������"This is Luat software, not AT software, please check: wiki.openluat.com for more information!\n"����Ϣ
ģ������޸�ʱ�䣺2018.03.09
]]

module(...,package.seeall)

require"pm"

local UART_ID = 2

--[[
��������read
����  ����ȡ���ڽ��յ�������
����  ����
����ֵ����
]]
local function read()
	local s
	while true do
		s = uart.read(UART_ID,"*l")
		if not s or string.len(s) == 0 then break end
		print("read bin",s)
		print("read hex",common.binstohexs(s))
	end
end

sys.reguart(UART_ID,read)
uart.setup(UART_ID,115200,8,uart.PAR_NONE,uart.STOP_1)
sys.timer_loop_start(uart.write,1000,UART_ID,"This is Luat software, not AT software, please check: wiki.openluat.com for more information!\n")
pm.wake("factory2")
