


PROJECT = "CALL"
VERSION = "2.0.0"



require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE








require "sys"

require "net"


net.startQueryAll(60000, 60000)


























require "errDump"
errDump.request("udp://ota.airm2m.com:9072")








require "testCall"


sys.init(0, 0)
sys.run()
