require"common"
module(...,package.seeall)

local i2cid = 2

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
��������init
����  ����i2c��д��ʼ����������豸�Ĵ��������Ӵ��豸�Ĵ�����ȡֵ
����  ����
����ֵ����
˵��  : �˺�����ʾsetup��send��recv�ӿڵ�ʹ�÷�ʽ
]]
local function init()
	local i2cslaveaddr = 0x0E
	--ע�⣺�˴���i2cslaveaddr��7bit��ַ
	--���i2c�����ֲ��и�����8bit��ַ����Ҫ��8bit��ַ����1λ����ֵ��i2cslaveaddr����
	--���i2c�����ֲ��и�����7bit��ַ��ֱ�Ӱ�7bit��ַ��ֵ��i2cslaveaddr��������
	--����һ�ζ�д����ʱ�������źź�ĵ�һ���ֽ��������ֽ�
	--�����ֽڵ�bit0��ʾ��дλ��0��ʾд��1��ʾ��
	--�����ֽڵ�bit7-bit1,7��bit��ʾ�����ַ
	--i2c�ײ������ڶ�����ʱ���� (i2cslaveaddr << 1) | 0x01 ���������ֽ�
	--i2c�ײ�������д����ʱ���� (i2cslaveaddr << 1) | 0x00 ���������ֽ�
	if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
		print("init fail")
		return
	end
	local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x00,0x1B,0xDA,0x1B,0xDA}
	for i=1,#cmd,2 do
		--����豸i2cslaveaddr���ͼĴ�����ַcmd[i]
		i2c.send(i2cid,i2cslaveaddr,cmd[i])
		--����豸i2cslaveaddr����Ҫд����豸�Ĵ����ڵ�����cmd[i+1]
		i2c.send(i2cid,i2cslaveaddr,cmd[i+1])
		
		--����豸i2cslaveaddr���ͼĴ�����ַcmd[i]
		i2c.send(i2cid,i2cslaveaddr,cmd[i])
		--��ȡ���豸i2cslaveaddr�Ĵ����ڵ�1���ֽڵ����ݣ����Ҵ�ӡ����
		print("init",string.format("%02X",cmd[i]),common.binstohexs(i2c.recv(i2cid,i2cslaveaddr,1)))
	end
end

--[[
��������init1
����  ����i2c��д��ʼ����������豸�Ĵ��������Ӵ��豸�Ĵ�����ȡֵ
����  ����
����ֵ����
˵��  : �˺�����ʾsetup��write��read�ӿڵ�ʹ�÷�ʽ
]]
local function init1()
	local i2cslaveaddr = 0x0E
	--ע�⣺�˴���i2cslaveaddr��7bit��ַ
	--���i2c�����ֲ��и�����8bit��ַ����Ҫ��8bit��ַ����1λ����ֵ��i2cslaveaddr����
	--���i2c�����ֲ��и�����7bit��ַ��ֱ�Ӱ�7bit��ַ��ֵ��i2cslaveaddr��������
	--����һ�ζ�д����ʱ�������źź�ĵ�һ���ֽ��������ֽ�
	--�����ֽڵ�bit0��ʾ��дλ��0��ʾд��1��ʾ��
	--�����ֽڵ�bit7-bit1,7��bit��ʾ�����ַ
	--i2c�ײ������ڶ�����ʱ���� (i2cslaveaddr << 1) | 0x01 ���������ֽ�
	--i2c�ײ�������д����ʱ���� (i2cslaveaddr << 1) | 0x00 ���������ֽ�
	if i2c.setup(i2cid,i2c.SLOW,i2cslaveaddr) ~= i2c.SLOW then
		print("init1 fail")
		return
	end
	local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x00,0x1B,0xDA,0x1B,0xDA}
	for i=1,#cmd,2 do
		--����豸�ļĴ�����ַcmd[i]��д1�ֽڵ�����cmd[i+1]
		i2c.write(i2cid,cmd[i],cmd[i+1])
		--�Ӵ��豸�ļĴ�����ַcmd[i]�ж�1�ֽڵ����ݣ����Ҵ�ӡ����
		print("init1",string.format("%02X",cmd[i]),common.binstohexs(i2c.read(i2cid,cmd[i],1)))
	end
end

--init��init1�ӿ���ʾ������i2c����ӿڵ�ʹ�÷�ʽ
init()
--init1()
--5���ر�i2c
sys.timer_start(i2c.close,5000,i2cid)
