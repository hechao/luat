require"pincfg"
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

-------------------------PIN8���Կ�ʼ-------------------------
local pin8flg = true
--[[
��������pin8set
����  ������PIN8���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin8set()
	pins.set(pin8flg,pincfg.PIN8)
	pin8flg = not pin8flg
end
--����1���ѭ����ʱ��������PIN8���ŵ������ƽ
sys.timer_loop_start(pin8set,1000)
-------------------------PIN8���Խ���-------------------------


-------------------------PIN9���Կ�ʼ-------------------------
local pin9flg = true
--[[
��������pin9set
����  ������PIN9���ŵ������ƽ��1�뷴תһ��
����  ����
����ֵ����
]]
local function pin9set()
	pins.set(pin9flg,pincfg.PIN9)
	pin9flg = not pin9flg
end
--����1���ѭ����ʱ��������PIN9���ŵ������ƽ
sys.timer_loop_start(pin9set,1000)
-------------------------PIN9���Խ���-------------------------


-------------------------PIN28���Կ�ʼ-------------------------
--[[
��������pin28get
����  ����ȡPIN28���ŵ������ƽ
����  ����
����ֵ����
]]
local function pin28get()
	local v = pins.get(pincfg.PIN28)
	print("pin28get",v and "low" or "high")
end
--����1���ѭ����ʱ������ȡPIN28���ŵ������ƽ
sys.timer_loop_start(pin28get,1000)
-------------------------PIN28���Խ���-------------------------
