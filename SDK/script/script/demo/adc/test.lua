--[[
ģ�����ƣ�ADC����(10bit����ѹ������ΧΪ0��1.85V���ֱ���Ϊ1850/1024=1.8MV�������������Ϊ20MV)
ģ�鹦�ܣ�����ADC����
ģ������޸�ʱ�䣺2017.07.22
]]

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

--adc id
local ADC_ID = 0

local function read()	
	--��adc
	adc.open(ADC_ID)
	--��ȡadc
	--adcvalΪnumber���ͣ���ʾadc��ԭʼֵ����ЧֵΪ0xFFFF
	--voltvalΪnumber���ͣ���ʾת����ĵ�ѹֵ����λΪ��������ЧֵΪ0xFFFF��adc.read�ӿڷ��ص�voltval�Ŵ���3����������Ҫ����3��ԭ��ԭʼ��ѹ
	local adcval,voltval = adc.read(ADC_ID)
	print("adc.read",adcval,(voltval-(voltval%3))/3,voltval)
	--���adcval��Ч
	if adcval and adcval~=0xFFFF then
	end
	--���voltval��Ч	
	if voltval and voltval~=0xFFFF then
		--adc.read�ӿڷ��ص�voltval�Ŵ���3�������Դ˴�����3
		voltval = (voltval-(voltval%3))/3
	end
end

sys.timer_loop_start(read,1000)

