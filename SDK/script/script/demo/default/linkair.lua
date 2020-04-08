--[[
ģ�����ƣ�mqtt clientӦ�ô���ģ��
ģ�鹦�ܣ����ӷ����������͵�½���ģ���ʱ�ϱ����վ��Ϣ
ģ������޸�ʱ�䣺2017.03.30
]]

require"misc"
require"mqtt"
module(...,package.seeall)

local lpack = require"pack"
local ssub,schar,smatch,sbyte,slen,sgmatch,sgsub,srep = string.sub,string.char,string.match,string.byte,string.len,string.gmatch,string.gsub,string.rep

--[[
��������nemacb
����  ��NEMA���ݵĴ���ص�����
����  ��
		data��һ��NEMA����
����ֵ����
]]
local function nemacb(data)
	print("nemacb",data)
end

--�Ƿ�֧��gps
local gpsupport = (_G.MODULE_TYPE=="Air800" or _G.MODULE_TYPE=="Air801")
--���֧��gps�����gps
if gpsupport then
	require"agps"
	require"gps"
	gps.init()
	gps.setnemamode(2,nemacb)
	gps.open(gps.DEFAULT,{cause="linkair"})
end

--������
local PROT,ADDR,PORT = "TCP","lbsmqtt.airm2m.com",1884
local mqttclient



--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������linkairǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("linkair",...)
end

--[[
��������pubqos0loginsndcb
����  ��������1��qosΪ0����Ϣ��(��½����)�����ͽ���Ļص�����
����  ��
		usertag������mqttclient:publishʱ�����usertag
		result��true��ʾ���ͳɹ���false����nil����ʧ��
����ֵ����
]]
local function pubqos0loginsndcb(usertag,result)
	print("pubqos0loginsndcb",usertag,result)
	sys.timer_start(pubqos0login,20000)
end

function bcd(d,n)
	local l = slen(d or "")
	local num
	local t = {}

	for i=1,l,2 do
		num = tonumber(ssub(d,i,i+1),16)

		if i == l then
			num = 0xf0+num
		else
			num = (num%0x10)*0x10 + (num-(num%0x10))/0x10
		end

		table.insert(t,num)
	end

	local s = schar(_G.unpack(t))

	l = slen(s)

	if l < n then
		s = s .. srep("\255",n-l)
	elseif l > n then
		s = ssub(s,1,n)
	end

	return s
end

--[[
��������pubqos0login
����  ������1��qosΪ0����Ϣ����½����
����  ����
����ֵ����
]]
function pubqos0login()
	local payload = lpack.pack(">bbHHbHHbHAbHbbHAbHAbHA",
								14,
								0,2,22,
								1,2,300,
								2,2,bcd(sgsub(_G.VERSION,"%.",""),2),
								3,1,gpsupport and 1 or 0,
								4,slen(sim.geticcid()),sim.geticcid(),
								8,slen(_G.PROJECT),_G.PROJECT,
								13,slen(sim.getimsi()),sim.getimsi())
	mqttclient:publish("/v1/device/"..misc.getimei().."/devdata",payload,0,pubqos0loginsndcb)
end


--[[
��������pubqos0locsndcb
����  ��������1��qosΪ0����Ϣ��(λ�ñ���)�����ͽ���Ļص�����
����  ��
		usertag������mqttclient:publishʱ�����usertag
		result��true��ʾ���ͳɹ���false����nil����ʧ��
����ֵ����
]]
local function pubqos0locsndcb(usertag,result)
	print("pubqos0locsndcb",usertag,result)
	sys.timer_start(pubqos0loc,60000)
end

--[[
��������encellinfoext
����  ����չ��վ��λ��Ϣ�������
����  ����
����ֵ����չ����վ��λ��Ϣ����ַ���
]]
local function encellinfoext()
	local info,ret,t,mcc,mnc,lac,ci,rssi,k,v,m,n,cntrssi = net.getcellinfoext(),"",{}
	print("encellinfoext",info)
	for mcc,mnc,lac,ci,rssi in sgmatch(info,"(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+);") do
		mcc,mnc,lac,ci,rssi = tonumber(mcc),tonumber(mnc),tonumber(lac),tonumber(ci),(tonumber(rssi) > 31) and 31 or tonumber(rssi)
		local handle = nil
		for k,v in pairs(t) do
			if v.lac == lac and v.mcc == mcc and v.mnc == mnc then
				if #v.rssici < 8 then
					table.insert(v.rssici,{rssi=rssi,ci=ci})
				end
				handle = true
				break
			end
		end
		if not handle then
			table.insert(t,{mcc=mcc,mnc=mnc,lac=lac,rssici={{rssi=rssi,ci=ci}}})
		end
	end
	for k,v in pairs(t) do
		ret = ret .. lpack.pack(">HHb",v.lac,v.mcc,v.mnc)
		for m,n in pairs(v.rssici) do
			cntrssi = bit.bor(bit.lshift(((m == 1) and (#v.rssici-1) or 0),5),n.rssi)
			ret = ret .. lpack.pack(">bH",cntrssi,n.ci)
		end
	end

	return schar(#t)..ret
end

local function getstatus()
	local t = {}

	t.shake = 0
	t.charger = 0
	t.acc = 0
	t.gps = gpsupport and 1 or 0
	t.sleep = 0
	t.volt = misc.getvbatvolt()
	t.fly = 0
	t.poweroff = 0
	t.poweroffreason = 0
	return t
end

local function getgps()
	local t = {}
	if gpsupport then
		print("getgps:",gps.getgpslocation(),gps.getgpscog(),gps.getgpsspd())
		t.fix = gps.isfix()
		t.lng,t.lat = smatch(gps.getgpslocation(),"[EW]*,(%d+%.%d+),[NS]*,(%d+%.%d+)")
		t.lng,t.lat = t.lng or "",t.lat or ""
		t.cog = gps.getgpscog()
		t.spd = gps.getgpsspd()
	end
	return t
end

local function getgpstat()
	local t = {}
	if gpsupport then
		t.satenum = gps.getgpssatenum()
	end
	return t
end

--[[
��������enstat
����  ������״̬��Ϣ�������
����  ����
����ֵ������״̬��Ϣ����ַ���
]]
local function enstat()	
	local stat = getstatus()
	local rssi = net.getrssi()
	local gpstat = getgpstat()
	local satenum = gpstat.satenum or 0

	local n1 = stat.shake + stat.charger*2 + stat.acc*4 + stat.gps*8 + stat.sleep*16+stat.fly*32+stat.poweroff*64
	rssi = rssi > 31 and 31 or rssi
	satenum = satenum > 7 and 7 or satenum
	local n2 = rssi + satenum*32
	return lpack.pack(">bbH",n1,n2,stat.volt)
end

local function enlnla(v,s)
	if not v then return common.hexstobins("FFFFFFFFFF") end
	
	local v1,v2 = smatch(s,"(%d+)%.(%d+)")

	if slen(v1) < 3 then v1 = srep("0",3-slen(v1)) .. v1 end

	return bcd(v1..v2,5)
end

--[[
��������pubqos0loc
����  ������1��qosΪ0����Ϣ��λ�ñ���
����  ����
����ֵ����
]]
function pubqos0loc()
	local payload
	if gpsupport then
		local t = getgps()
		lng = enlnla(t.fix,t.lng)
		lat = enlnla(t.fix,t.lat)
		payload = lpack.pack(">bAAHbAbA",7,lng,lat,t.cog,t.spd,encellinfoext(),net.getta(),enstat())
	else
		payload = lpack.pack(">bAbA",5,encellinfoext(),net.getta(),enstat())
	end
	mqttclient:publish("/v1/device/"..misc.getimei().."/devdata",payload,0,pubqos0locsndcb)
end


--[[
��������subackcb
����  ��MQTT SUBSCRIBE֮���յ�SUBACK�Ļص�����
����  ��
		usertag������mqttclient:subscribeʱ�����usertag
		result��true��ʾ���ĳɹ���false����nil��ʾʧ��
����ֵ����
]]
local function subackcb(usertag,result)
	print("subackcb",usertag,result)
end

--[[
��������rcvmessage
����  ���յ�PUBLISH��Ϣʱ�Ļص�����
����  ��
		topic����Ϣ����
		payload����Ϣ����
		qos����Ϣ�����ȼ�
����ֵ����
]]
local function rcvmessagecb(topic,payload,qos)
	print("rcvmessagecb",topic,common.binstohexs(payload),qos)
	if slen(payload)>2 and ssub(payload,1,2)==common.hexstobins("3C00") then
		sys.timer_stop(pubqos0login)
	end
end

--[[
��������connectedcb
����  ��MQTT CONNECT�ɹ��ص�����
����  ����		
����ֵ����
]]
local function connectedcb()
	print("connectedcb")
	--��������
	mqttclient:subscribe({{topic="/v1/device/"..misc.getimei().."/set",qos=0}},subackcb,"subscribetest")
	--ע���¼��Ļص�������MESSAGE�¼���ʾ�յ���PUBLISH��Ϣ
	mqttclient:regevtcb({MESSAGE=rcvmessagecb})
	--����һ��qosΪ0����Ϣ����½����
	pubqos0login()
	--����һ��qosΪ1����Ϣ��λ�ñ���
	pubqos0loc()
end

--[[
��������connecterrcb
����  ��MQTT CONNECTʧ�ܻص�����
����  ��
		r��ʧ��ԭ��ֵ
			1��Connection Refused: unacceptable protocol version
			2��Connection Refused: identifier rejected
			3��Connection Refused: server unavailable
			4��Connection Refused: bad user name or password
			5��Connection Refused: not authorized
����ֵ����
]]
local function connecterrcb(r)
	print("connecterrcb",r)
end

--[[
��������imeirdy
����  ��IMEI��ȡ�ɹ����ɹ��󣬲�ȥ����mqtt client�����ӷ���������Ϊ�õ���IMEI��
����  ����		
����ֵ����
]]
local function imeirdy()
	--����һ��mqtt client
	mqttclient = mqtt.create(PROT,ADDR,PORT)
	--����mqtt������
	mqttclient:connect(misc.getimei(),600,"user","password",connectedcb,connecterrcb)
end

local procer =
{
	IMEI_READY = imeirdy,
}
--ע����Ϣ�Ĵ�����
sys.regapp(procer)
--����30���Ӳ�ѯһ����վ��Ϣ
net.setcengqueryperiod(30000)
