--[[
ģ�����ƣ����Ų���
ģ�鹦�ܣ����ŷ��ͺͽ��ղ���
ģ������޸�ʱ�䣺2017.02.20
]]
require"sms"
module(...,package.seeall)

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������smsappǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end


-----------------------------------------���Ž��չ��ܲ���[��ʼ]-----------------------------------------
local function procnewsms(num,data,datetime)
	print("procnewsms",num,data,datetime)
end

sms.regnewsmscb(procnewsms)
-----------------------------------------���Ž��չ��ܲ���[����]-----------------------------------------





-----------------------------------------���ŷ��Ͳ���[��ʼ]-----------------------------------------
local function sendtest1(result,num,data)
	print("sendtest1",result,num,data)
end

local function sendtest2(result,num,data)
	print("sendtest2",result,num,data)
end

local function sendtest3(result,num,data)
	print("sendtest3",result,num,data)
end

local function sendtest4(result,num,data)
	print("sendtest4",result,num,data)
end

sms.send("10086","111111",sendtest1)
sms.send("10086","��2������",sendtest2)
sms.send("10086","qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432",sendtest3)
sms.send("10086","�����ǵ���qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432qeiuqwdsahdkjahdkjahdkja122136489759725923759823hfdskfdkjnbzndkjhfskjdfkjdshfkjdsfks83478648732432",sendtest4)
-----------------------------------------���ŷ��Ͳ���[����]-----------------------------------------
