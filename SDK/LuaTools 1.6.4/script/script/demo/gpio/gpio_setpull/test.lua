require"pins"
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

TEST1={pin=pio.P0_7,dir=pio.INPUT,}
TEST2={pin=pio.P0_12,dir=pio.INPUT}
TEST3={pin=pio.P0_29,dir=pio.INPUT}
pmd.ldoset(5,pmd.LDO_VMMC)
pins.reg(TEST1,TEST2,TEST3)
local function pinget()
	print(1,pio.pin.getval(TEST1.pin))
	print(2,pio.pin.getval(TEST2.pin))
	print(3,pio.pin.getval(TEST3.pin))
end
--����1���ѭ����ʱ������ȡ3�����ŵ������ƽ
sys.timer_loop_start(pinget,1000)

--������Ĵ��룬GPIO����ʱΪ�ߵ�ƽ

pio.pin.setpull(pio.PULLUP, TEST1.pin)
pio.pin.setpull(pio.PULLUP, TEST2.pin)
pio.pin.setpull(pio.PULLUP, TEST3.pin)

--������Ĵ��룬GPIO����ʱΪ�͵�ƽ
--[[
pio.pin.setpull(pio.PULLDOWN, TEST1.pin)
pio.pin.setpull(pio.PULLDOWN, TEST2.pin)
pio.pin.setpull(pio.PULLDOWN, TEST3.pin)
]]
--������Ĵ��룬GPIO����ʱΪ��ȷ����ƽ
--[[
pio.pin.setpull(pio.NOPULL, TEST1.pin)
pio.pin.setpull(pio.NOPULL, TEST2.pin)
pio.pin.setpull(pio.NOPULL, TEST3.pin)
]]