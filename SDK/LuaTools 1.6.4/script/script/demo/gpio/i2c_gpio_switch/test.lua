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

--i2cuse�����ŵ�ǰ�Ƿ���Ϊi2c����ʹ�ã�true��ʾ�ǣ�����ı�ʾ����
local i2cid,i2cuse = 0,true
--[[
��������i2copn
����  ����i2c
����  ����
����ֵ����
]]
local function i2copn()
	--��������ַ����0x15ֻ��һ�����ӣ�ʵ��ʹ��ʱ����Χ�豸����
	if i2c.setup(i2cid,i2c.SLOW,0x15) ~= i2c.SLOW then
		print("i2copn fail")
	end
end

--[[
��������i2close
����  ���ر�i2c
����  ����
����ֵ����
]]
local function i2close()
	i2c.close(i2cid)
end

--[[
��������switchtoi2c
����  ���л���i2c����ʹ��
����  ����
����ֵ����
]]
local function switchtoi2c()
	print("switchtoi2c",i2cuse)
	if not i2cuse then
		--�ر�gpio����
		pio.pin.close(pio.P0_6)
		pio.pin.close(pio.P0_7)
		--��i2c����
		i2copn()
		i2cuse = true
	end
end

--[[
��������switchtogpio
����  ���л���gpio����ʹ��
����  ����
����ֵ����
]]
local function switchtogpio()
	print("switchtogpio",i2cuse)
	if i2cuse then
		--�ر�i2c����
		i2close()
		--����gpio����
		pio.pin.setdir(pio.OUTPUT,pio.P0_6)
		pio.pin.setdir(pio.OUTPUT,pio.P0_7)
		--���gpio��ƽ
		pio.pin.setval(1,pio.P0_6)
		pio.pin.setval(0,pio.P0_7)
		i2cuse = false
	end	
end

--[[
��������switch
����  ���л�i2c��gpio����
����  ����
����ֵ����
]]
local function switch()
	if i2cuse then
		switchtogpio()
	else
		switchtoi2c()
	end
end

i2copn()
--ѭ����ʱ����5���л�һ�ι���
sys.timer_loop_start(switch,5000)
