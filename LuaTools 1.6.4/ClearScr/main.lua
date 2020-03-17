


PROJECT = "LED-TEST"
VERSION = "0.0.1"


moduleType = string.find(rtos.get_version(),"8955") and 2 or 4



require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE

require "sys"

require "net"


net.startQueryAll(60000, 60000)





require "wdt"
wdt.setup(pio.P0_30, pio.P0_31)





require "netLed"

netLed.setup(true, pio.P1_1) 










require "errDump"
errDump.request("udp://ota.airm2m.com:9072")







require"pins"
require "ctrl"    


sys.init(0, 0)
sys.run()
