--[[
ģ�����ƣ�PWM����
ģ�鹦�ܣ�����PWM����
ģ������޸�ʱ�䣺2017.07.31
ע�⣺
1��֧��2·PWM����֧���������
2��2·PWM���õ���uart2��tx��rx�����ʹ����uart2�Ĵ��ڹ��ܣ�����ʹ��PWM�����ʹ����PWM������ʹ��uart2�Ĵ��ڹ��ܣ�
   ���ڹ��ܻ���PWM����ʹ��ʱ�����뱣֤����һ�����ܴ��ڹر�״̬��������ܴ��ڿ���״̬����ͨ��uart.close����misc.closepwm�ӿڹر�
]]
require"misc"
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

--[[
��������testpwm0
����  ��PWMͨ��0�������
����  ����
����ֵ����
]]
local function testpwm0()
	--Ƶ��1000Hz��1����һ�����ڣ�ÿ�������ڣ�������0.5���룬������0.5����
	misc.openpwm(0,1000,50)
	--2���Ӻ�ر�PWM0
	sys.timer_start(misc.closepwm,120000,0)
end

--[[
��������testpwm1
����  ��PWMͨ��1�������
����  ����
����ֵ����
]]
local function testpwm1()
	--1024����һ�����ڣ�ÿ�������ڣ�������110���룬������1024-110=914����
	misc.openpwm(1,3,7)
	--2���Ӻ�ر�PWM0
	sys.timer_start(misc.closepwm,120000,1)
end

testpwm0()
testpwm1()
