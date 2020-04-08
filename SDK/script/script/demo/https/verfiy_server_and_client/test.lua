module(...,package.seeall)
require"misc"
--ssl�ͻ���ʹ��ca֤��У��������˵�֤��ʱ�����жϷ�������֤����Ч�ڣ����Ա��뱣֤ģ����ʱ�����ȷ��
--����ntpģ����Զ�ͬ������ʱ�䵽ģ����
require"ntp"
require"https"
require"common"

local ssub,schar,smatch,sbyte,slen = string.sub,string.char,string.match,string.byte,string.len
local ADDR,PORT ="36.7.87.100",4434
local httpclient

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
��������rcvcb
����  �����ջص�����
����  ��result�����ݽ��ս��(�˲���Ϊ0ʱ������ļ���������������)
				0:�ɹ�
				2:��ʾʵ�峬��ʵ��ʵ�壬���󣬲����ʵ������
				3:���ճ�ʱ
		statuscode��httpӦ���״̬�룬string���ͻ���nil
		head��httpӦ���ͷ�����ݣ�table���ͻ���nil
		body��httpӦ���ʵ�����ݣ�string���ͻ���nil
����ֵ����
]]
local function rcvcb(result,statuscode,head,body)
	print("rcvcb",result,statuscode,head,slen(body or ""))
	
	if result==0 then
		if head then
			print("rcvcb head:")
			--������ӡ������ͷ������Ϊ�ײ����֣�������Ӧ��ֵΪ�ײ����ֶ�ֵ
			for k,v in pairs(head) do		
				print(k..": "..v)
			end
		end
		print("rcvcb body:")
		print(body)
	end
	
	httpclient:disconnect(discb)
end

--[[
��������rcvcbfile
����  �����ջص������������ļ���
����  ��result�����ݽ��ս��(�˲���Ϊ0ʱ������ļ���������������)
				0:�ɹ�
				2:��ʾʵ�峬��ʵ��ʵ�壬���󣬲����ʵ������
				3:���ճ�ʱ
		statuscode��httpӦ���״̬�룬string���ͻ���nil
		head��httpӦ���ͷ�����ݣ�table���ͻ���nil
		filename: �����ļ�������·����
����ֵ����
]]
local function rcvcbfile(result,statuscode,head,filename)
	print("rcvcbfile",result,statuscode,head,filename)	
	
	if result==0 then
		local filehandle = io.open(filename,"rb")
		if not filehandle then print("rcvcbfile open file error") return end
		local current = filehandle:seek()
		local size = filehandle:seek("end")
		filehandle:seek("set", current)
		--����ļ�����
		print("rcvcbfile size",size)
		
		--����ļ����ݣ�����ļ�̫��һ���Զ����ļ����ݿ��ܻ�����ڴ治�㣬�ִζ������Ա��������
		print("rcvcbfile content:\r\n")
		if size<=4096 then
			print(filehandle:read("*all"))
		else
			
		end
		
		filehandle:close()
	end
	--�ļ�ʹ����֮������Ժ���������Ҫ����ɾ��
	if filename then os.remove(filename) end
	
	httpclient:disconnect(discb)
end

--[[
��������connectedcb
����  ��SOCKET connected �ɹ��ص�����
����  ��
����ֵ��
]]
local function connectedcb()
	--[[���ô˺����Żᷢ�ͱ���,request(cmdtyp,url,head,body,rcvcb),�ص�����rcvcb(result,statuscode,head,body)
		url����·��������"/XXX/XXXX"��headΪ�����ʽ������{"Connection: keep-alive","Content-Type: text/html; charset=utf-8"}��ע��:����
		���һ���ո�body������Ҫ�������ݣ�Ϊ�ַ������͡�
	]]
	httpclient:request("GET","/",{},"",rcvcb)
	--httpclient:request("GET","/",{},"",rcvcbfile,"download.bin")
end 

--[[
��������sckerrcb
����  ��SOCKETʧ�ܻص�����
����  ��
		r��string���ͣ�ʧ��ԭ��ֵ
		CONNECT: socketһֱ����ʧ�ܣ����ٳ����Զ�����
		SEND��socket��������ʧ�ܣ����ٳ����Զ�����
����ֵ����
]]
local function sckerrcb(r)
	print("sckerrcb",r)
	if r=="CONNECT" then
		--http.lua���Ѿ��Ͽ������ӣ������Լ������󣬴˴�����ֱ�ӵ���connect()ֱ������
	elseif r=="SEND" then
		--http.lua�з�������ʧ�ܣ�����û�жϿ����ӣ��˴�Ҫ�Լ����ƶϿ����ӣ�Ȼ����discb�����������߼�����
		httpclient:disconnect(discb)
	end
end
--[[
��������connect
���ܣ����ӷ�����
������
	 connectedcb:���ӳɹ��ص�����
	 sckerrcb��http lib��socketһֱ����ʧ�ܻ��߷���GET��POST����ʧ��ʱ�������Զ�������������ǵ���sckerrcb����
���أ�
]]
function connect()
	httpclient:connect(connectedcb,sckerrcb)
end
--[[
��������discb
����  ��HTTP���ӶϿ���Ļص�
����  ����		
����ֵ����
]]
function discb()
	print("http discb")
	--20������½���HTTP����
	sys.timer_start(connect,20000)
end

--[[
��������http_run
����  ������http�ͻ��ˣ�����������
����  ����		
����ֵ����
]]
function http_run()
	--��ΪhttpЭ�������ڡ�TCP��Э�飬���Բ��ش���PROT����
	httpclient=https.create(ADDR,PORT)
	--verifysvrcerts��У���������֤���CA֤���ļ� (Base64���� X.509��ʽ)
	--clientcert���ͻ��˵�֤���ļ� (Base64���� X.509��ʽ)
	--clientkey���ͻ��˵�RSA PRIVATE KEY˽Կ�ļ�(Base64���� X.509��ʽ)
	httpclient:configcrt({verifysvrcerts={"ca.crt"},clientcert="client.crt",clientkey="client.key"})
	--httpclient:setconnectionmode(true)
	--����http����
	connect()	
end


--���ú�������
http_run()



