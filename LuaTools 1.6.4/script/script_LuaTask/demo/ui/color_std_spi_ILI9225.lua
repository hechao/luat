--- 模块功能：GC 9106驱动芯片LCD命令配置
-- @author openLuat
-- @module ui.color_lcd_spi_gc9106
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

--[[
注意：disp库目前支持I2C接口和SPI接口的屏，此文件的配置，硬件上使用的是LCD专用的SPI引脚，不是标准的SPI引脚
硬件连线图如下：
Air模块			LCD
GND-------------地
LCD_CS----------片选
LCD_CLK---------时钟
LCD_DATA--------数据
LCD_DC----------数据/命令选择
VDDIO-----------电源
LCD_RST---------复位
]]

module(...,package.seeall)

--[[
函数名：init
功能  ：初始化LCD参数
参数  ：无
返回值：无
]]
function init()
    --控制SPI引脚的电压域
    pmd.ldoset(6,pmd.LDO_VMMC)
    local para =
    {
        width = 176, --分辨率宽度，128像素；用户根据屏的参数自行修改
        height = 220, --分辨率高度，128像素；用户根据屏的参数自行修改
        bpp = 16, --位深度，彩屏仅支持16位
        bus = disp.BUS_SPI, --LCD专用SPI引脚接口，不可修改
        xoffset = 0, --X轴偏移
        yoffset = 0, --Y轴偏移
        freq = 13000000,
        hwfillcolor = 0xffffff, --填充色，黑色
        pinrst = pio.P0_3, --reset，复位引脚
        pinrs = pio.P0_12, --rs，命令/数据选择引脚
        --初始化命令
        --前两个字节表示类型：0001表示延时，0000或者0002表示命令，0003表示数据
        --延时类型：后两个字节表示延时时间（单位毫秒）
        --命令类型：后两个字节命令的值
        --数据类型：后两个字节数据的值
        initcmd =
        {
            0x10,0x0030000,0x0030000,
            0x11,0x0030000,0x0030000,
            0x12,0x0030000,0x0030000,
            0x13,0x0030000,0x0030000,
            0x14,0x0030000,0x0030000,
            0x010028,
            0x11,0x0030000,0x0030018,
            0x12,0x0030011,0x0030021,
            0x13,0x0030000,0x0030063,
            0x14,0x0030039,0x0030061,
            0x10,0x0030008,0x0030000,
            0x01000a,
            0x11,0x0030010,0x0030038,
            0x01001e,
            0x02,0x0030001,0x0030000,
            
            0x01,0x0030001,0x003001c,
            0x03,0x0030010,0x0030030,
            
            0x07,0x0030000,0x0030000,
            0x08,0x0030008,0x0030008,
            0x0B,0x0030011,0x0030000,
            0x0C,0x0030000,0x0030000,
            0x0F,0x0030005,0x0030001,
            0x15,0x0030000,0x0030020,
            0x20,0x0030000,0x0030000,
            0x21,0x0030000,0x0030000,
            
            0x30,0x0030000,0x0030000,
            0x31,0x0030000,0x00300DB,
            0x32,0x0030000,0x0030000,
            0x33,0x0030000,0x0030000,
            0x34,0x0030000,0x00300DB,
            0x35,0x0030000,0x0030000,
            0x36,0x0030000,0x00300AF,
            0x37,0x0030000,0x0030000,
            0x38,0x0030000,0x00300DB,
            0x39,0x0030000,0x0030000,
            
            0x50,0x0030006,0x0030003,
            0x51,0x0030008,0x003000D,
            0x52,0x003000D,0x003000C,
            0x53,0x0030002,0x0030005,
            0x54,0x0030004,0x003000A,
            0x55,0x0030007,0x0030003,
            0x56,0x0030003,0x0030000,
            0x57,0x0030004,0x0030000,
            0x58,0x003000B,0x0030000,
            0x59,0x0030000,0x0030017,
            
            0x0F,0x0030007,0x0030001,
            0x07,0x0030000,0x0030012,
            0x010032,
            0x07,0x0030010,0x0030017,
        },
        --休眠命令
        sleepcmd = {
            0x00020010,
        },
        --唤醒命令
        wakecmd = {
            0x00020011,
        }
    }
    disp.init(para)
    disp.clear()
    disp.update()
end

init()
--打开背光
--实际使用时，用户根据自己的lcd背光控制方式，去修改背光控制代码
--pmd.ldoset(6,pmd.KP_LEDR)
