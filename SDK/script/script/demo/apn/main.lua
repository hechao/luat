--重要提醒：必须在这个位置定义MODULE_TYPE、PROJECT和VERSION变量
--MODULE_TYPE：模块型号，目前仅支持Air201、Air202、Air800
--PROJECT：ascii string类型，可以随便定义，只要不使用,就行
--VERSION：ascii string类型，如果使用Luat物联云平台固件升级的功能，必须按照"X.X.X"定义，X表示1位数字；否则可随便定义
MODULE_TYPE = "Air202"
PROJECT = "APN"
VERSION = "1.0.0"
require"sys"
--[[
如果使用UART输出trace，打开这行注释的代码"--sys.opntrace(true,1)"即可，第2个参数1表示UART1输出trace，根据自己的需要修改这个参数
这里是最早可以设置trace口的地方，代码写在这里可以保证UART口尽可能的输出“开机就出现的错误信息”
如果写在后面的其他位置，很有可能无法输出错误信息，从而增加调试难度
]]
--sys.opntrace(true,1)
require"test"

--加载硬件看门狗功能模块
--根据自己的硬件配置决定：1、是否加载此功能模块；2、配置Luat模块复位单片机引脚和互相喂狗引脚
--合宙官方出售的Air201开发板上有硬件看门狗，所以使用官方Air201开发板时，必须加载此功能模块
--[[
require "wdt"
wdt.setup(pio.P0_30, pio.P0_31)
]]


sys.init(0,0)
sys.run()
