--[[
ģ�����ƣ�¼������
ģ�鹦�ܣ�����¼�����ܡ���ȡ¼�������Լ�����¼��
ģ������޸�ʱ�䣺2017.04.05
]]

module(...,package.seeall)
require"record"

--ÿ�ζ�ȡ��¼���ļ�����
local RCD_READ_UNIT = 1024
--rcdoffset����ǰ��ȡ��¼���ļ�������ʼλ��
--rcdsize��¼���ļ��ܳ���
--rcdcnt����ǰ��Ҫ��ȡ���ٴ�¼���ļ�������ȫ����ȡ
local rcdoffset,rcdsize,rcdcnt



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
��������playcb
����  ������¼��������Ļص�����
����  ����
����ֵ����
]]
local function playcb(r)
	print("playcb",r)
	--ɾ��¼���ļ�
	record.delete()
end

--[[
��������readrcd
����  ����ȡ¼���ļ�����
����  ����
����ֵ����
]]
local function readrcd()	
	local s = record.getdata(rcdoffset,RCD_READ_UNIT)
	print("readrcd",rcdoffset,rcdcnt,string.len(s))
	rcdcnt = rcdcnt-1
	--¼���ļ������Ѿ�ȫ����ȡ����
	if rcdcnt<=0 then
		sys.timer_stop(readrcd)
		--����¼������
		audio.play(0,"RECORD",record.getfilepath(),audiocore.VOL7,playcb)
	--��û��ȫ����ȡ����
	else
		rcdoffset = rcdoffset+RCD_READ_UNIT
	end
end

--[[
��������rcdcb
����  ��¼��������Ļص�����
����  ��
		result��¼�������true��ʾ�ɹ���false����nil��ʾʧ��
		size��number���ͣ�¼���ļ��Ĵ�С����λ���ֽڣ���resultΪtrueʱ��������
����ֵ����
]]
local function rcdcb(result,size)
	print("rcdcb",result,size)
	if result then
		rcdoffset,rcdsize,rcdcnt = 0,size,(size-1)/RCD_READ_UNIT+1
		sys.timer_loop_start(readrcd,1000)
	end	
end

--5��󣬿�ʼ¼��
sys.timer_start(record.start,5000,5,rcdcb)
