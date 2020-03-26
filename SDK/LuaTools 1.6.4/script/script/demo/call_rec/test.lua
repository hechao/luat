--[[
ģ�����ƣ�ͨ������
ģ�鹦�ܣ����Ժ������
ģ������޸�ʱ�䣺2017.02.23
]]

module(...,package.seeall)
require"cc"
require"audio"
require"common"
require"record"
require"audiocore"


local RCD_READ_UNIT = 512
local rcdoffset,rcdsize,rcdcnt,rcdcur
local typ="incoming"
local total,cur

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������testǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("ljd test",...)
end

--[[
��������connected
����  ����ͨ���ѽ�������Ϣ������
����  ����
����ֵ����
]]
local function connected()
	print("connected")
	--5��󲥷�TTS���Զˣ��ײ��������֧��TTS����
	--sys.timer_start(audio.play,5000,0,"TTSCC",common.binstohexs(common.gb2312toucs2("ͨ���в���TTS����")),audiocore.VOL7)
	--50��֮����������ͨ��
	sys.timer_start(cc.hangup,50000,"AUTO_DISCONNECT")

    if typ=="outgoing" then
        print("connected play")
        audio.play(0,"FILE","/ldata/alarm.amr",audiocore.VOL3,playcb)
    end
end

--[[
��������disconnected
����  ����ͨ���ѽ�������Ϣ������
����  ��
		para��ͨ������ԭ��ֵ
			  "LOCAL_HANG_UP"���û���������cc.hangup�ӿڹҶ�ͨ��
			  "CALL_FAILED"���û�����cc.dial�ӿں�����at����ִ��ʧ��
			  "NO CARRIER"��������Ӧ��
			  "BUSY"��ռ��
			  "NO ANSWER"��������Ӧ��
����ֵ����
]]
local function disconnected(para)
	print("disconnected:"..(para or "nil"))
	sys.timer_stop(cc.hangup,"AUTO_DISCONNECT")
    if typ=="incoming" then
    sys.timer_start(openrcd,3000)
    end
    typ=nil
end

function playcb(r)
	print("playcb",r)
	--ɾ��¼���ļ�
	--record.delete()
end

--[[
��������getdata
����  ����ȡ¼���ļ�ָ��λ�����ָ����������
����  ��
		offset��number���ͣ�ָ��λ�ã�ȡֵ��Χ�ǡ�0 �� �ļ�����-1��
        len��number���ͣ�ָ�����ȣ�������õĳ��ȴ����ļ�ʣ��ĳ��ȣ���ֻ�ܶ�ȡʣ��ĳ�������
����ֵ��ָ����¼�����ݣ������ȡʧ�ܣ����ؿ��ַ���""
]]
function getdata(offset,len)
	local f,rt = io.open("/CallRec/rec001.wav","rb")
    --������ļ�ʧ�ܣ���������Ϊ�ա���
	if not f then print("getdata err��open") return "" end
	if not f:seek("set",offset) then print("getdata err��seek") return "" end
    --��ȡָ�����ȵ�����
	rt = f:read(len)
	f:close()
	
	return rt or ""
end

--[[
��������getsize
����  ����ȡ��ǰ¼���ļ����ܳ���
����  ����
����ֵ����ǰ¼���ļ����ܳ��ȣ���λ���ֽ�
]]
local function getsize()
	local f = io.open("/CallRec/rec001.wav","rb")
	if not f then print("getsize err��open") return 0 end
	local size = f:seek("end")
	if not size or size == 0 then print("getsize err��seek") return 0 end
	f:close()
    return size
end

function sndrcd()
    local data = getdata(rcdoffset,RCD_READ_UNIT)
    sys.dispatch("CMD_RCD_SEND",data)
end

function rcdsndcnf()
    print("rcdsndcnf:","rcdcur:",rcdcur,"rcdcnt:",rcdcnt)
    if rcdcur < rcdcnt then
        rcdcur = rcdcur+1
        rcdoffset = rcdoffset+(rcdcur-1)*RCD_READ_UNIT
        sndrcd()
    else
        print("rcdsnd finish")
        audio.play(0,"FILE","/CallRec/rec001.wav",audiocore.VOL3,playcb)
    end
end

function openrcd()
	print("openrcd:")
	
	rcdsize = getsize()
    rcdcnt = (rcdsize-1)/RCD_READ_UNIT+1
    rcdoffset,rcdcur = 0,1
    sndrcd()

    print("openrcd:","rcdsize:",rcdsize,"rcdcnt",rcdcnt)
    return 
end


--[[
��������incoming
����  �������硱��Ϣ������
����  ��
		num��string���ͣ��������
����ֵ����
]]
local function incoming(num)
	print("incoming:"..num)
	--��������
    typ="incoming"
	cc.accept()
    record.start(5)
end

local function ready()
	print("ready")
    ril.request("AT*EXASSERT=1")
    sys.timer_start(testdial,15000)
end

function testdial()
    typ="outgoing"
    cc.dial("18126324568")
end

local procer = {
	RCD_SEND_CNF = rcdsndcnf,
}
sys.regapp(procer)

--ע����Ϣ���û��ص�����
cc.regcb("INCOMING",incoming,"CONNECTED",connected,"READY",ready,"DISCONNECTED",disconnected)--"READY",ready,


