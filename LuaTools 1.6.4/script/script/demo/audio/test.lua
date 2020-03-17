module(...,package.seeall)

require"audio"
require"common"

--��Ƶ�������ȼ�����Ӧaudio.play�ӿ��е�priority��������ֵԽ�����ȼ�Խ�ߣ��û������Լ��������������ȼ�
--PWRON����������
--CALL����������
--SMS���¶�������
--TTS��TTS����
PWRON,CALL,SMS,TTS = 3,2,1,0

local function testcb(r)
	print("testcb",r)
end

--������Ƶ�ļ����Խӿڣ�ÿ�δ�һ�д�����в���
local function testplayfile()
	--���β�������������Ĭ�������ȼ�
	--audio.play(CALL,"FILE","/ldata/call.mp3")
	--���β������������������ȼ�7
	--audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7)
	--���β������������������ȼ�7�����Ž������߳������testcb�ص�����
	--audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,testcb)
	--ѭ���������������������ȼ�7��û��ѭ�����(һ�β��Ž���������������һ��)
	audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true)
	--ѭ���������������������ȼ�7��ѭ�����Ϊ2000����
	--audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true,2000)
end


--����tts���Խӿڣ�ÿ�δ�һ�д�����в���
--����ã��������Ϻ�����ͨ�ſƼ����޹�˾������ʱ��18��30�֡�
local ttstr = "��ã��������Ϻ�����ͨ�ſƼ����޹�˾������ʱ��18��30��"
local function testplaytts()
	--���β��ţ�Ĭ�������ȼ�
	--audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)))
	--���β��ţ������ȼ�7
	--audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)),audiocore.VOL7)
	--���β��ţ������ȼ�7�����Ž������߳������testcb�ص�����
	--audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)),audiocore.VOL7,testcb)
	--ѭ�����ţ������ȼ�7��û��ѭ�����(һ�β��Ž���������������һ��)
	audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)),audiocore.VOL7,nil,true)
	--ѭ�����ţ������ȼ�7��ѭ�����Ϊ2000����
	--audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)),audiocore.VOL7,nil,true,2000)
end


--���ų�ͻ���Խӿڣ�ÿ�δ�һ��if�����в���
local function testplayconflict()	

	if true then
		--ѭ��������������
		audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true)
		--5���Ӻ�ѭ�����ſ�������
		sys.timer_start(audio.play,5000,PWRON,"FILE","/ldata/pwron.mp3",audiocore.VOL7,nil,true)
		
	end

	
	--[[
	if true then
		--ѭ��������������
		audio.play(CALL,"FILE","/ldata/call.mp3",audiocore.VOL7,nil,true)
		--5���Ӻ󣬳���ѭ�������¶����������������ȼ����������Ქ��
		sys.timer_start(audio.play,5000,SMS,"FILE","/ldata/sms.mp3",audiocore.VOL7,nil,true)
		
	end
	]]
	
	--[[
	if true then
		--ѭ������TTS
		audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)),audiocore.VOL7,nil,true)
		--10���Ӻ�ѭ�����ſ�������
		sys.timer_start(audio.play,10000,PWRON,"FILE","/ldata/pwron.mp3",audiocore.VOL7,nil,true)
		
	end
	]]
end


local function testtsnew()
	--�������ȼ���ͬʱ�Ĳ��Ų��ԣ�1��ʾֹͣ��ǰ���ţ������µĲ�������
	audio.setstrategy(1)
	audio.play(TTS,"TTS",common.binstohexs(common.gb2312toucs2(ttstr)),audiocore.VOL7)
end


--ÿ�δ������һ�д�����в���
if string.match(sys.getcorever(),"TTS") then
	sys.timer_start(testplaytts,5000)
	--���Ҫ����tts����ʱ�����󲥷��µ�tts����������δ���
	--sys.timer_loop_start(testtsnew,5000)
else
	sys.timer_start(testplayfile,5000)
end
--sys.timer_start(testplayconflict,5000)
