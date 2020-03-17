module(...,package.seeall)--���г���ɼ�
--[[���ݸ�ʽת��demo
    ��ֵ�������������ַ�--]]
require "common"--������common��


--[[��������bittese
    ���ܣ�����bit���ʹ�ã�����ӡ����
    ����ֵ����--]]
local function bittest()
	print("bittest:")      --�������п�ʼ���
	print(bit.bit(2))--������λ����������1�����ƶ���λ����ӡ��4
	
	print(bit.isset(5,0))--��һ���������ǲ������֣��ڶ����ǲ���λ�á�����������0��7����1����true�����򷵻�false���÷���true
	print(bit.isset(5,1))--��ӡfalse
	print(bit.isset(5,2))--��ӡtrue
	print(bit.isset(5,3))--���ط���false
	
	print(bit.isclear(5,0))--��������෴
	print(bit.isclear(5,1))
	print(bit.isclear(5,2))
	print(bit.isclear(5,3))
	
	print(bit.set(0,0,1,2,3))--����Ӧ��λ����1����ӡ15
	
    print(bit.clear(5,0,2)) --����Ӧ��λ����0����ӡ0
	
	print(bit.bnot(5))--��λȡ��
	
	print(bit.band(1,1))--��,--���1
	
	print(bit.bor(1,2))--��--���3
	
	print(bit.bxor(1,2))--���,��ͬΪ0����ͬΪ1
	
	print(bit.lshift(1,2))--�߼����ƣ���100�������Ϊ4
	
	print(bit.rshift(4,2))--�߼����ƣ���001�������Ϊ1 
	
	print(bit.arshift(2,2))--�������ƣ������ӵ���������йأ����Ϊ0
  
end

--[[
	��������packedtest
    ���ܣ���չ��pack�Ĺ�����ʾ
    ��������
    ����ֵ����
    --]]
local function packedtest()
	--[[��һЩ�������ո�ʽ��װ���ַ���.'z'�������ַ�����'p'���ֽ����ȣ�'P'���ַ����ȣ�
	'a'���������ȣ�'A'�ַ����ͣ�'f'������,'d'˫������,'n'Lua ����,'c'�ַ���,'b'�޷����ַ���,'h'����,'H'�޷��Ŷ���
	'i'����,'I'�޷�������,'l'��������,'L'�޷��ų��ͣ�">"��ʾ��ˣ�"<"��ʾС�ˡ�]]
	print("pcak.pack test��")
	print(common.binstohexs(pack.pack(">H",0x3234)))
	print(common.binstohexs(pack.pack("<H",0x3234)))
	--�ַ������޷��Ŷ����ͣ��ֽ��ͣ�����ɶ������ַ��������ڶ����Ʋ������������ת��Ϊʮ�����������
	print(common.binstohexs(pack.pack(">AHb","LUAT",100,10)))
	
	print("pack.unpack test:")
	local stringtest = pack.pack(">AHb","luat",999,10)
	--"nextpos"������ʼ��λ�ã����������ĵ�һ��ֵval1���ڶ���val2��������val3�����ݺ���ĸ�ʽ����
	--������ַ���Ҫ��ȡ�����������ȡ�ַ���������Ķ����ͺ�һ���ֽڵ������ᱻ���ǡ�
	nextpox1,val1,val2 = pack.unpack(string.sub(stringtest,5,-1),">Hb")
	--nextpox1��ʾ���������λ�ã�������ĳ�����3��nextpox1�������4��ƥ�����999,10
	print(nextpox1,val1,val2) 
end

--[[
	������  ռ2���ֽ�
    ������ ռ��4���ֽڣ�32λ��
    double�� ռ4���ֽ�
    long double�� ռ8���ֽ�
 
    ��������	ȡֵ��Χ
    ���� [signed]int	-2147483648~+2147483648
    �޷�������unsigned[int]	0~4294967295
    ������ short [int]	-32768~32768
    �޷��Ŷ�����unsigned short[int]	0~65535
    ������ Long int	-2147483648~+2147483648
    �޷��ų�����unsigned [int]	0~4294967295
    �ַ���[signed] char	-128~+127
    �޷����ַ��� unsigned char	0~255 
	��֧��С������ --]]

--[[
	��������stringtest
    ���ܣ�sting�⼸���ӿڵ�ʹ����ʾ
    ��������
    ����ֵ����--]]
		
local function stringtest()
	print("stringtest:")
	--ע��string.char����string.byteֻ���һ���ֽڣ���ֵ���ɴ���256
	print(string.char(97,98,99))--����Ӧ����ֵת��Ϊ�ַ�
	print(string.byte("abc"),2) --��һ���������ַ������ڶ���������λ�á������ǣ����ַ�������������λ��ת��Ϊ��ֵ
	local i=100
	local string1="luat100great"
	print("string.format\r\n",string.format("%04d//%s",i,string1))--[[ָʾ����Ŀ��Ƹ�ʽ���ַ�����Ϊ��ʮ����'d'��ʮ������'x'
	�˽���'o'��������'f'���ַ���'s',���Ƹ�ʽ�ĸ��������Ĳ�������һ�¡����ܣ������ض���ʽ���������--]]
	--��ӡ��"luat great"
	print("string.gsub\r\n",string.gsub("luat is","is","great"))--��һ��������Ŀ���ַ������ڶ��������Ǳ�׼�ַ������������Ǵ��滻�ַ���
	--��ӡ��Ŀ���ַ����ڲ����ַ����е���βλ��
	print("string.find\r\n",string.find(string1,"great"))
	--ƥ���ַ���,��()ָ���Ƿ���ָ����ʽ���ַ���,��ȡ�ַ����е�����
	print("string.match\r\n",string.match(string1,"luat(%d+)great"))
	--��ȡ�ַ������ڶ��������ǽ�ȡ����ʼλ�ã�����������ֹλ�á�
	print("string.sub\r\n",string.sub(string1,1,4))
end



--[[��������bitstohexs()
   ���ܣ�������������ת��Ϊʮ�����ƣ������ת�����ʮ���������ִ���ÿ���ֽ�֮���÷ָ�������
   ��ӡ��ʮ���������ִ�
   ��������һ���������������֣��ڶ����Ƿָ���
   ����ֵ��          --]]

local function binstohexs(binstring,s)	
	print(common.binstohexs(binstring,s)) --�����˻������е�common�⣬���ʮ���������ִ�
end 
	
--[[�������� hexstobits
    ���ܣ���ʮ��������ת��Ϊ������������������������,���ת����Ķ�������
	������ʮ��������
	����ֵ��                           --]]
local function hexstobins(hexstring)--��ʮ����������ת��Ϊ�������ַ���
	print(common.hexstobins(hexstring)) --ע�����������Щ�ǿɴ�ӡ�ɼ��ģ���Щ����
end

--[[
��������ucs2togb2312
����  ��unicodeС�˱��� ת��Ϊ gb2312����,����ӡ��gd2312��������
����  ��
		ucs2s��unicodeС�˱�������,ע������������ֽ���
����ֵ��
]]
local function ucs2togb2312(ucs2s)
	print("ucs2togb2312")	
	local gd2312num = common.ucs2togb2312(ucs2s)--���õ���common.ucs2togb2312�����ص��Ǳ�������Ӧ���ַ���
	print("gb2312  code��",gd2312num)	
end

--[[
��������gb2312toucs2
����  ��gb2312���� ת��Ϊ unicodeʮ������С�˱������ݲ���ӡ
����  ��
		gb2312s��gb2312�������ݣ�ע������������ֽ���
����ֵ��
]]
local function gb2312toucs2(gd2312num)
	print("gb2312toucs2")
	local ucs2num=common.gb2312toucs2(gd2312num)
	print("unicode little-endian code:"..common.binstohexs(ucs2num))--Ҫ��������ת��Ϊʮ�����ƣ������޷����
end 

--[[
��������ucs2betogb2312
����  ��unicode��˱��� ת��Ϊ gb2312���룬����ӡ��gb2312��������,
��˱�����������С�˱�������λ�õ���
����  ��
		ucs2s��unicode��˱������ݣ�ע������������ֽ���
����ֵ��
]]
local function ucs2betogb2312(ucs2s)
	print("ucs2betogb2312")
	local gd2312num=common.ucs2betogb2312(ucs2s) --ת���������ֱ�ӱ���ַ�����ֱ����� 
	print("gd2312 code ��"..gd2312num)	
end

--[[
��������gb2312toucs2be
����  ��gb2312���� ת��Ϊ unicode��˱��룬����ӡ��unicode��˱���
����  ��
		gb2312s��gb2312�������ݣ�ע������������ֽ���
����ֵ��unicode��˱�������
]]
function gb2312toucs2be(gb2312s)
	print("gb2312toucs2be")
    local ucs2benum=common.gb2312toucs2be(gb2312s)
	print("unicode big-endian code :"..common.binstohexs(ucs2benum))
end
	
--[[
��������ucs2toutf8
����  ��unicodeС�˱��� ת��Ϊ utf8����,����ӡ��utf8ʮ�����Ʊ�������
����  ��
		ucs2s��unicodeС�˱������ݣ�ע������������ֽ���
����ֵ��
]]
local function ucs2toutf8(usc2)
	print("ucs2toutf8")
	local utf8num=common.ucs2toutf8(usc2)
	print("utf8  code��"..common.binstohexs(utf8num))
	
end

--[[
��������utf8togb2312
����  ��utf8���� ת��Ϊ gb2312����,����ӡ��gb2312��������
����  ��
		utf8s��utf8�������ݣ�ע������������ֽ���
����ֵ��
]]
local function utf8togb2312(utf8s)
	print("utf8togb2312")
	local gb2312num=common.utf8togb2312(utf8s)
	print("gd2312 code��"..gb2312num)
	
end

--[[ ��������--]]

bittest()
packedtest()
stringtest()

--[[���Գ��򣬽ӿھ�������ģ�����Ϳ���ֱ�Ӳ���,�ԡ��ҡ�Ϊ��--]]

binstohexs("ab")
hexstobins("3132")

ucs2togb2312(common.hexstobins("1162"))  --"1162"��"��"�ֵ�ucs2���룬���������common.hexstobins������ת��Ϊ�����ƣ�Ҳ���������ֽڡ�
gb2312toucs2(common.hexstobins("CED2")) --"CED2"��"��"�ֵ�gb22312����  
ucs2betogb2312(common.hexstobins("6211"))--"6211"��"��"�ֵ�ucs2be����
gb2312toucs2be(common.hexstobins("CED2"))
ucs2toutf8(common.hexstobins("1162"))
utf8togb2312(common.hexstobins("E68891"))--"E68891"��"��"�ֵ�utf8����
