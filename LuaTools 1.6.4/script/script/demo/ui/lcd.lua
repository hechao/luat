--[[
ģ�����ƣ�lcd
ģ�鹦�ܣ�lcd����ӿ�
ģ������޸�ʱ�䣺2017.08.17
]]

--�����Լ���lcd�����Լ�ʹ�õ�spi���ţ������������һ���ļ����в���
--mono��ʾ�ڰ�����color��ʾ����
--std_spi��ʾʹ�ñ�׼��SPI���ţ�lcd_spi��ʾʹ��LCDר�õ�SPI����
require"mono_std_spi_ssd1306"
--require"mono_std_spi_st7567"
--require"color_std_spi_st7735"
--require"color_std_spi_ILI9341"
--require"color_lcd_spi_ILI9341"
--require"mono_lcd_spi_ssd1306"
--require"mono_lcd_spi_st7567"
--require"color_lcd_spi_st7735"
--require"color_lcd_spi_gc9106"
module(...,package.seeall)

--LCD�ֱ��ʵĿ�Ⱥ͸߶�(��λ������)
WIDTH,HEIGHT,BPP = disp.getlcdinfo()
--1��ASCII�ַ����Ϊ8���أ��߶�Ϊ16���أ����ֿ�Ⱥ͸߶ȶ�Ϊ16����
CHAR_WIDTH = 8

--[[
��������getxpos
����  �������ַ���������ʾ��X����
����  ��
		str��string���ͣ�Ҫ��ʾ���ַ���
����ֵ��X����
]]
function getxpos(str)
	return (WIDTH-string.len(str)*CHAR_WIDTH)/2
end
