--[[
ģ�����ƣ�SSD 1306����оƬ��������
ģ�鹦�ܣ���ʼ��оƬ����
ģ������޸�ʱ�䣺2017.08.08
]]

--[[
ע�⣺���ļ������ã�Ӳ����ʹ�õ���LCDר�õ�SPI���ţ����Ǳ�׼��SPI����
disp��Ŀǰ��֧��SPI�ӿڵ�����Ӳ������ͼ���£�
Airģ��			LCD
GND-------------��
LCD_CS----------Ƭѡ
LCD_CLK---------ʱ��
LCD_DATA--------����
LCD_DC----------����/����ѡ��
VDDIO-----------��Դ
LCD_RST---------��λ
]]

module(...,package.seeall)

--[[
��������init
����  ����ʼ��LCD����
����  ����
����ֵ����
]]
local function init()
	local para =
	{
		width = 128, --�ֱ��ʿ�ȣ�128���أ��û��������Ĳ��������޸�
		height = 64, --�ֱ��ʸ߶ȣ�64���أ��û��������Ĳ��������޸�
		bpp = 1, --λ��ȣ�1��ʾ��ɫ����ɫ��������Ϊ1�������޸�
		bus = disp.BUS_SPI4LINE, --LCDר��SPI���Žӿڣ������޸�
		yoffset = 32, --Y��ƫ��
		hwfillcolor = 0xFFFF, --���ɫ����ɫ
		pinrst = pio.P0_14, --reset����λ����
		pinrs = pio.P0_18, --rs������/����ѡ������
		--��ʼ������
		initcmd =
		{
			0xAE, --display off
			0x20, --Set Memory Addressing Mode	
			0x10, --00,Horizontal Addressing Mode;01,Vertical Addressing Mode;10,Page Addressing Mode (RESET);11,Invalid
			0xb0, --Set Page Start Address for Page Addressing Mode,0-7
			0xc8, --Set COM Output Scan Direction
			0x00, ---set low column address
			0x10, ---set high column address
			0x60, --set start line address
			0x81, --set contrast control register
			0xdf, --
			0xa1, --set segment re-map 0 to 127
			0xa6, --set normal display
			0xa8, --set multiplex ratio(1 to 64)
			0x3f, --
			0xa4, --0xa4,Output follows RAM content;0xa5,Output ignores RAM content
			0xd3, --set display offset
			0x20, --not offset
			0xd5, --set display clock divide ratio/oscillator frequency
			0xf0, --set divide ratio
			0xd9, --set pre-charge period
			0x22, --
			0xda, --set com pins hardware configuration
			0x12, --
			0xdb, --set vcomh
			0x20, --0x20,0.77xVcc
			0x8d, --set DC-DC enable
			0x14, --
			0xaf, --turn on oled panel 
		},
		--��������
		sleepcmd = {
			0xAE,
		},
		--��������
		wakecmd = {
			0xAF,
		}
	}
	disp.init(para)
	disp.clear()
	disp.update()
end

--����SPI���ŵĵ�ѹ��
pmd.ldoset(6,pmd.LDO_VLCD)
init()
