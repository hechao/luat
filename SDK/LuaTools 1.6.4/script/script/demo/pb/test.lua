--[[
ģ�����ƣ��绰������
ģ�鹦�ܣ����Ե绰����д
ģ������޸�ʱ�䣺2017.05.23
]]

module(...,package.seeall)
require"pb"

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
��������storagecb
����  �����õ绰���洢�����Ļص�����
����  ��
		result�����ý����trueΪ�ɹ�������Ϊʧ��
����ֵ����
]]
local function storagecb(result)
	print("storagecb",result)
	--ɾ����1��λ�õĵ绰����¼
	pb.deleteitem(1,deletecb)
end

--[[
��������writecb
����  ��д��һ���绰����¼��Ļص�����
����  ��
		result��д������trueΪ�ɹ�������Ϊʧ��
����ֵ����
]]
function writecb(result)
	print("writecb",result)
	--��ȡ��1��λ�õĵ绰����¼
	pb.read(1,readcb)
end

--[[
��������deletecb
����  ��ɾ��һ���绰����¼��Ļص�����
����  ��
		result��ɾ�������trueΪ�ɹ�������Ϊʧ��
����ֵ����
]]
function deletecb(result)
	print("deletecb",result)
	--д��绰����¼����1��λ��
	pb.writeitem(1,"name1","11111111111",writecb)
end

--[[
��������readcb
����  ����ȡһ���绰����¼��Ļص�����
����  ��
		result����ȡ�����trueΪ�ɹ�������Ϊʧ��
		name������
		number������		
����ֵ����
]]
function readcb(result,name,number)
	print("readcb",result,name,number)
end


local function ready(result,name,number)
	print("ready",result)
	if result then
		sys.timer_stop(pb.read,1,ready)
		--���õ绰���洢����SM��ʾsim���洢��ME��ʾ�ն˴洢��������2���е�1�в��Լ���
		pb.setstorage("SM",storagecb)
		--pb.setstorage("ME",storagecb)
	end
end

--ѭ����ʱ��ֻ��Ϊ���ж�PB����ģ���Ƿ�ready
sys.timer_loop_start(pb.read,2000,1,ready)
