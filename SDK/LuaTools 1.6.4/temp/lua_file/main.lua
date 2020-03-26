PROJECT = "5303_CHONGQING_V1572_B3492"
VERSION = "1.0.0"
UPDMODE = 1
MEM_CRITICAL_VALUE = 400
_G.collectgarbage("setpause",90)
require"pio"
require"ril"
require"sys"
require"pm"
require"update"
require"updateapp"
require"rtos"
require"bit"
require"pmd"
require"audio"
require"cc"
require"common"
require"link"
require"misc"
require"net"
require"sim"
require"sms"
require"dbg"
require"gps"
require"pmdapp"
require"ccapp"
require"gpsapp"
require"filestore"
require"linkapp"
require"gpslocation"
require"dataapp"
require"keypad"
require"idleapp"
require"eng"
require"sosapp"
require"lightapp"
require"audioapp"
require"smsapp"
require"ttssmsapp"
require"ttsalarmapp"
require"darkcode"
local req = ril.request
function GarbageCollect()
	if collectgarbage("count") >= MEM_CRITICAL_VALUE then
		collectgarbage()
	end
end
sys.init(0,0)
req("AT*EXASSERT=0")
req("AT*TRACE=\"SXS\", 0, 0")
req("AT*TRACE=\"DSS\", 0, 0")
req("AT*TRACE=\"RDA\", 0, 0")
idleapp.EnterIdleApp()
sys.run()
