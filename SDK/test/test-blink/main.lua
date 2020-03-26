--必须在这个位置定义PROJECT和VERSION变量
--PROJECT：ascii string类型，可以随便定义，只要不使用,就行
--VERSION：ascii string类型，如果使用Luat物联云平台固件升级的功能，必须按照"X.X.X"定义，X表示1位数字；否则可随便定义
PROJECT = "LED-TEST"
VERSION = "0.0.1"

--根据固件判断模块类型
moduleType = string.find(rtos.get_version(),"8955") and 2 or 4

--加载日志功能模块，并且设置日志输出等级
--如果关闭调用log模块接口输出的日志，等级设置为log.LOG_SILENT即可
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"

require "net"
--每1分钟查询一次GSM信号强度
--每1分钟查询一次基站信息
net.startQueryAll(60000, 60000)

--加载硬件看门狗功能模块
--根据自己的硬件配置决定：1、是否加载此功能模块；2、配置Luat模块复位单片机引脚和互相喂狗引脚
--合宙官方出售的Air201开发板上有硬件看门狗，所以使用官方Air201开发板时，必须加载此功能模块
--如果用的是720 4g模块，请注释掉这两行
require "wdt"
wdt.setup(pio.P0_30, pio.P0_31)


--加载网络指示灯功能模块
--根据自己的项目需求和硬件配置决定：1、是否加载此功能模块；2、配置指示灯引脚
--合宙官方出售的Air800和Air801开发板上的指示灯引脚为pio.P0_28，其他开发板上的指示灯引脚为pio.P1_1
require "netLed"
-- netLed.setup(true,moduleType == 2 and pio.P1_1 or pio.P2_0,moduleType == 2 and nil or pio.P2_1)--自动判断2/4g默认网络灯引脚配置
netLed.setup(true, pio.P1_1) -- air202
--setup(true, pio.P2_0)
--setup(true, pio.P2_1)

--网络指示灯功能模块中，默认配置了各种工作状态下指示灯的闪烁规律，参考netLed.lua中ledBlinkTime配置的默认值
--如果默认值满足不了需求，此处调用netLed.updateBlinkTime去配置闪烁时长


--加载错误日志管理功能模块【强烈建议打开此功能】
--如下2行代码，只是简单的演示如何使用errDump功能，详情参考errDump的api

require "errDump"
errDump.request("udp://ota.airm2m.com:9072")

--加载远程升级功能模块【强烈建议打开此功能】
--如下3行代码，只是简单的演示如何使用update功能，详情参考update的api以及demo/update
-- PRODUCT_KEY = "xxxxxx"
-- require "update"
-- update.request()

require "ledtest"    --新加上的代码

--启动系统框架
sys.init(0, 0)
sys.run()