module(...,package.seeall)

require"common"

--[[
�ӽ����㷨������ɶ���
http://tool.oschina.net/encrypt?type=2
http://www.ip33.com/crc.html
http://tool.chacuo.net/cryptaes
���в���
]]

local slen = string.len

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������aliyuniotǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("test",...)
end

--[[
��������base64test
����  ��base64�ӽ����㷨����
����  ����
����ֵ����
]]
local function base64test()
	local originstr = "123456crypto.base64_encodemodule(...,package.seeall)sys.timer_start(test,5000)jdklasdjklaskdjklsa"
	local encodestr = crypto.base64_encode(originstr,slen(originstr))
	print("base64_encode",encodestr)
	print("base64_decode",crypto.base64_decode(encodestr,slen(encodestr)))
end

--[[
��������hmacmd5test
����  ��hmac_md5�㷨����
����  ����
����ֵ����
]]
local function hmacmd5test()
	local originstr = "asdasdsadas"
	local signkey = "123456"
	print("hmac_md5",crypto.hmac_md5(originstr,slen(originstr),signkey,slen(signkey)))
end

--[[
��������md5test
����  ��md5�㷨����
����  ����
����ֵ����
]]
local function md5test()
	--�����ַ�����md5ֵ
	local originstr = "sdfdsfdsfdsffdsfdsfsdfs1234"
	print("md5",crypto.md5(originstr,slen(originstr)))
	
	--�����ļ���md5ֵ(V0020�汾���lod��֧�ִ˹���)
	if tonumber(string.match(sys.getcorever(),"Luat_V(%d+)_"))>=20 then
		--crypto.md5����һ������Ϊ�ļ�·�����ڶ�������������"file"
		print("sys.lua md5",crypto.md5("/lua/sys.lua","file"))
	end	
end

--[[
��������hmacsha1test
����  ��hmac_sha1�㷨����
����  ����
����ֵ����
]]
local function hmacsha1test()
	local originstr = "asdasdsadasweqcdsjghjvcb"
	local signkey = "12345689012345"
	print("hmac_sha1",crypto.hmac_sha1(originstr,slen(originstr),signkey,slen(signkey)))
end

--[[
��������sha1test
����  ��sha1�㷨����
����  ����
����ֵ����
]]
local function sha1test()
	local originstr = "sdfdsfdsfdsffdsfdsfsdfs1234"
	print("sha1",crypto.sha1(originstr,slen(originstr)))
end

--[[
��������crctest
����  ��crc�㷨����
����  ����
����ֵ����
]]
local function crctest()
	local originstr = "sdfdsfdsfdsffdsfdsfsdfs1234"
	if tonumber(string.match(rtos.get_version(),"Luat_V(%d+)_"))>=21 then
		--crypto.crc16()��һ��������У�鷽��������Ϊ���¼������ڶ�������Ϊ����У����ַ���
		print("crc16_MODBUS",string.format("%04X",crypto.crc16("MODBUS",originstr)))
		print("crc16_IBM",string.format("%04X",crypto.crc16("IBM",originstr)))
		print("crc16_X25",string.format("%04X",crypto.crc16("X25",originstr)))
		print("crc16_MAXIM",string.format("%04X",crypto.crc16("MAXIM",originstr)))
		print("crc16_USB",string.format("%04X",crypto.crc16("USB",originstr)))
		print("crc16_CCITT",string.format("%04X",crypto.crc16("CCITT",originstr)))
		print("crc16_CCITT-FALSE",string.format("%04X",crypto.crc16("CCITT-FALSE",originstr)))
		print("crc16_XMODEM",string.format("%04X",crypto.crc16("XMODEM",originstr)))
		print("crc16_DNP",string.format("%04X",crypto.crc16("DNP",originstr)))
	end
	print("crc16_modbus",string.format("%04X",crypto.crc16_modbus(originstr,slen(originstr))))
	
	print("crc32",string.format("%08X",crypto.crc32(originstr,slen(originstr))))
end

--[[
��������aestest
����  ��aes�㷨���ԣ��ο�http://tool.chacuo.net/cryptaes��
����  ����
����ֵ����
]]
local function aestest()
	--aes.encrypt��aes.decrypt�ӿڲ���(V0020�汾���lod��֧�ִ˹���)
	if tonumber(string.match(sys.getcorever(),"Luat_V(%d+)_"))>=20 then
		local originStr = "AES128 ECB ZeroPadding test"
		--����ģʽ��ECB����䷽ʽ��ZeroPadding����Կ��1234567890123456����Կ���ȣ�128 bit
		local encodestr = crypto.aes_encrypt("ECB","ZERO",originStr,"1234567890123456")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","ZERO",encodestr,"1234567890123456"))	
		
		originStr = "AES128 ECB Pkcs5Padding test"
		--����ģʽ��ECB����䷽ʽ��Pkcs5Padding����Կ��1234567890123456����Կ���ȣ�128 bit
		encodestr = crypto.aes_encrypt("ECB","PKCS5",originStr,"1234567890123456")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","PKCS5",encodestr,"1234567890123456"))	
		
		originStr = "AES128 ECB Pkcs7Padding test"
		--����ģʽ��ECB����䷽ʽ��Pkcs7Padding����Կ��1234567890123456����Կ���ȣ�128 bit
		encodestr = crypto.aes_encrypt("ECB","PKCS7",originStr,"1234567890123456")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","PKCS7",encodestr,"1234567890123456"))
		
		originStr = "AES192 ECB ZeroPadding test"	
		--����ģʽ��ECB����䷽ʽ��ZeroPadding����Կ��123456789012345678901234����Կ���ȣ�192 bit
		local encodestr = crypto.aes_encrypt("ECB","ZERO",originStr,"123456789012345678901234")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","ZERO",encodestr,"123456789012345678901234"))	
		
		originStr = "AES192 ECB Pkcs5Padding test"
		--����ģʽ��ECB����䷽ʽ��Pkcs5Padding����Կ��123456789012345678901234����Կ���ȣ�192 bit
		encodestr = crypto.aes_encrypt("ECB","PKCS5",originStr,"123456789012345678901234")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","PKCS5",encodestr,"123456789012345678901234"))	
		
		originStr = "AES192 ECB Pkcs7Padding test"
		--����ģʽ��ECB����䷽ʽ��Pkcs7Padding����Կ��123456789012345678901234����Կ���ȣ�192 bit
		encodestr = crypto.aes_encrypt("ECB","PKCS7",originStr,"123456789012345678901234")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","PKCS7",encodestr,"123456789012345678901234"))
		
		originStr = "AES256 ECB ZeroPadding test"	
		--����ģʽ��ECB����䷽ʽ��ZeroPadding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit
		local encodestr = crypto.aes_encrypt("ECB","ZERO",originStr,"12345678901234567890123456789012")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","ZERO",encodestr,"12345678901234567890123456789012"))	
		
		originStr = "AES256 ECB Pkcs5Padding test"
		--����ģʽ��ECB����䷽ʽ��Pkcs5Padding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit
		encodestr = crypto.aes_encrypt("ECB","PKCS5",originStr,"12345678901234567890123456789012")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","PKCS5",encodestr,"12345678901234567890123456789012"))	
		
		originStr = "AES256 ECB Pkcs7Padding test"
		--����ģʽ��ECB����䷽ʽ��Pkcs7Padding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit
		encodestr = crypto.aes_encrypt("ECB","PKCS7",originStr,"12345678901234567890123456789012")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("ECB","PKCS7",encodestr,"12345678901234567890123456789012"))
		
		
		
		
		
		originStr = "AES128 CBC ZeroPadding test"
		--����ģʽ��CBC����䷽ʽ��ZeroPadding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		local encodestr = crypto.aes_encrypt("CBC","ZERO",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","ZERO",encodestr,"1234567890123456","1234567890666666"))	
		
		originStr = "AES128 CBC Pkcs5Padding test"
		--����ģʽ��CBC����䷽ʽ��Pkcs5Padding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CBC","PKCS5",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","PKCS5",encodestr,"1234567890123456","1234567890666666"))	
		
		originStr = "AES128 CBC Pkcs7Padding test"
		--����ģʽ��CBC����䷽ʽ��Pkcs7Padding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CBC","PKCS7",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","PKCS7",encodestr,"1234567890123456","1234567890666666"))
		
		originStr = "AES192 CBC ZeroPadding test"	
		--����ģʽ��CBC����䷽ʽ��ZeroPadding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		local encodestr = crypto.aes_encrypt("CBC","ZERO",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","ZERO",encodestr,"123456789012345678901234","1234567890666666"))	
		
		originStr = "AES192 CBC Pkcs5Padding test"
		--����ģʽ��CBC����䷽ʽ��Pkcs5Padding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CBC","PKCS5",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","PKCS5",encodestr,"123456789012345678901234","1234567890666666"))	
		
		originStr = "AES192 CBC Pkcs7Padding test"
		--����ģʽ��CBC����䷽ʽ��Pkcs7Padding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CBC","PKCS7",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","PKCS7",encodestr,"123456789012345678901234","1234567890666666"))
		
		originStr = "AES256 CBC ZeroPadding test"	
		--����ģʽ��CBC����䷽ʽ��ZeroPadding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		local encodestr = crypto.aes_encrypt("CBC","ZERO",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","ZERO",encodestr,"12345678901234567890123456789012","1234567890666666"))	
		
		originStr = "AES256 CBC Pkcs5Padding test"
		--����ģʽ��CBC����䷽ʽ��Pkcs5Padding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CBC","PKCS5",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","PKCS5",encodestr,"12345678901234567890123456789012","1234567890666666"))	
		
		originStr = "AES256 CBC Pkcs7Padding test"
		--����ģʽ��CBC����䷽ʽ��Pkcs7Padding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CBC","PKCS7",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CBC","PKCS7",encodestr,"12345678901234567890123456789012","1234567890666666"))

		
		
		
		
		originStr = "AES128 CTR ZeroPadding test"
		--����ģʽ��CTR����䷽ʽ��ZeroPadding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		local encodestr = crypto.aes_encrypt("CTR","ZERO",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","ZERO",encodestr,"1234567890123456","1234567890666666"))	
		
		originStr = "AES128 CTR Pkcs5Padding test"
		--����ģʽ��CTR����䷽ʽ��Pkcs5Padding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","PKCS5",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","PKCS5",encodestr,"1234567890123456","1234567890666666"))	
		
		originStr = "AES128 CTR Pkcs7Padding test"
		--����ģʽ��CTR����䷽ʽ��Pkcs7Padding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","PKCS7",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","PKCS7",encodestr,"1234567890123456","1234567890666666"))
		
		originStr = "AES128 CTR NonePadding test"
		--����ģʽ��CTR����䷽ʽ��NonePadding����Կ��1234567890123456����Կ���ȣ�128 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","NONE",originStr,"1234567890123456","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","NONE",encodestr,"1234567890123456","1234567890666666"))
		
		originStr = "AES192 CTR ZeroPadding test"	
		--����ģʽ��CTR����䷽ʽ��ZeroPadding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		local encodestr = crypto.aes_encrypt("CTR","ZERO",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","ZERO",encodestr,"123456789012345678901234","1234567890666666"))	
		
		originStr = "AES192 CTR Pkcs5Padding test"
		--����ģʽ��CTR����䷽ʽ��Pkcs5Padding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","PKCS5",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","PKCS5",encodestr,"123456789012345678901234","1234567890666666"))	
		
		originStr = "AES192 CTR Pkcs7Padding test"
		--����ģʽ��CTR����䷽ʽ��Pkcs7Padding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","PKCS7",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","PKCS7",encodestr,"123456789012345678901234","1234567890666666"))
		
		originStr = "AES192 CTR NonePadding test"
		--����ģʽ��CTR����䷽ʽ��NonePadding����Կ��123456789012345678901234����Կ���ȣ�192 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","NONE",originStr,"123456789012345678901234","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","NONE",encodestr,"123456789012345678901234","1234567890666666"))
		
		originStr = "AES256 CTR ZeroPadding test"	
		--����ģʽ��CTR����䷽ʽ��ZeroPadding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		local encodestr = crypto.aes_encrypt("CTR","ZERO",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","ZERO",encodestr,"12345678901234567890123456789012","1234567890666666"))	
		
		originStr = "AES256 CTR Pkcs5Padding test"
		--����ģʽ��CTR����䷽ʽ��Pkcs5Padding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","PKCS5",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","PKCS5",encodestr,"12345678901234567890123456789012","1234567890666666"))	
		
		originStr = "AES256 CTR Pkcs7Padding test"
		--����ģʽ��CTR����䷽ʽ��Pkcs7Padding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","PKCS7",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","PKCS7",encodestr,"12345678901234567890123456789012","1234567890666666"))
		
		originStr = "AES256 CTR NonePadding test"
		--����ģʽ��CTR����䷽ʽ��NonePadding����Կ��12345678901234567890123456789012����Կ���ȣ�256 bit��ƫ������1234567890666666
		encodestr = crypto.aes_encrypt("CTR","NONE",originStr,"12345678901234567890123456789012","1234567890666666")
		print(originStr,"encrypt",common.binstohexs(encodestr))
		print("decrypt",crypto.aes_decrypt("CTR","NONE",encodestr,"12345678901234567890123456789012","1234567890666666"))
	end
end

--[[
��������test
����  ���㷨�������
����  ����
����ֵ����
]]
local function test()
	base64test()
	hmacmd5test()
	md5test()
	hmacsha1test()
	sha1test()
	crctest()
	aestest()
end

sys.timer_start(test,5000)
