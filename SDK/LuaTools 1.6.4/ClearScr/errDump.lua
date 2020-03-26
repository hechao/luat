

















require"socket"
require"misc"
module(..., package.seeall)


local LIB_ERR_FILE,libErr,LIB_ERR_MAX_LEN = "/lib_err.txt","",5*1024
local LUA_ERR_FILE,luaErr = "/luaerrinfo.txt",""
local sReporting,sProtocol
local sNetworkLog,stNetworkLog,sNetworkLogFlag = "",{}




local function initErr()
libErr = io.readFile(LIB_ERR_FILE) or ""
if libErr~="" then
log.error("errDump.libErr", libErr)
end

luaErr = io.readFile(LUA_ERR_FILE) or ""
if luaErr~="" then
log.error("errDump.luaErr", luaErr)
end

updateNetworkLog()
end










function appendErr(s)
if s then
s=s.."\r\n"
log.error("errDump.appendErr",s)
if (s:len()+libErr:len())<=LIB_ERR_MAX_LEN then            
libErr = libErr..s
return io.writeFile(LIB_ERR_FILE, libErr)
end
end
end

local function reportData()
return _G.PROJECT.."_"..rtos.get_version()..",".._G.VERSION..","..misc.getImei()..","..misc.getSn()..","..luaErr..(luaErr:len()>0 and "\r\n" or "")..libErr..sNetworkLog
end

local function httpPostCbFnc(result,statusCode)
log.info("errDump.httpPostCbFnc",result,statusCode)
sys.publish("ERRDUMP_HTTP_POST",result,statusCode)
end

function clientTask(protocol,addr,period)
sReporting = true
while true do
if not socket.isReady() then sys.waitUntil("IP_READY_IND") end

if luaErr~="" or libErr~="" or sNetworkLog~="" then
local retryCnt,result,data = 0
while true do
if protocol=="http" then
http.request("POST",addr,nil,nil,reportData(),20000,httpPostCbFnc)                     
_,result = sys.waitUntil("ERRDUMP_HTTP_POST")
else
local host,port = addr:match("://(.+):(%d+)$")
if not host then log.error("errDump.request invalid host port") return end

local sck = protocol=="udp" and socket.udp() or socket.tcp()

if sck:connect(host,port) then
result = sck:send(reportData())
if result and protocol=="udp" then
result,data = sck:recv(20000)
if result then
result = data=="OK"
end
end
end

sck:close()
end

if result then
libErr = ""
os.remove(LIB_ERR_FILE)
luaErr = ""
os.remove(LUA_ERR_FILE)
sNetworkLog = ""
stNetworkLog = {}
break
else
retryCnt = retryCnt+1
if retryCnt==3 then
break
end
sys.wait(5000)
end
end
end

if period then

sys.wait(period)
else
break
end
end
sReporting = false
end

function updateNetworkLog()
if sNetworkLogFlag then
sNetworkLog = ""
for k,v in pairs(stNetworkLog) do
if v and v~="" then
sNetworkLog = sNetworkLog.."\r\n"..k.."@"..v
end
end
end
end

local onceGsmRegistered,onceGprsAttached




function setNetworkLog(flag)
sNetworkLogFlag = flag
local procer = flag and sys.subscribe or sys.unsubscribe
if not flag then
sNetworkLog,stNetworkLog = "",{}
end

local function getTimeStr()
local clk = os.date("*t")
return string.format("%02d_%02d:%02d:%02d",clk.day,clk.hour,clk.min,clk.sec)
end

procer("FLYMODE",function(value)
if value then            
stNetworkLog["FLYMODE"] = getTimeStr()
updateNetworkLog()
end
end)
procer("SIM_IND",function(value)
if value~="RDY" then            
stNetworkLog["SIM_IND"] = getTimeStr()..":"..value
updateNetworkLog()
end
end)
procer("NET_STATE_UNREGISTER",function()
if onceGsmRegistered then
stNetworkLog["NET_STATE_UNREGISTER"] = getTimeStr()
updateNetworkLog()
end
end)
procer("NET_STATE_REGISTERED",function() onceGsmRegistered=true end)
procer("GPRS_ATTACH",function(value)
if value then
onceGprsAttached = true
elseif onceGprsAttached then
stNetworkLog["GPRS_ATTACH"] = getTimeStr()..":0"
updateNetworkLog()
end
end)
procer("LIB_SOCKET_CONNECT_FAIL_IND",function(ssl,prot,addr,port)           
stNetworkLog[(ssl and "ssl" or prot).."://"..addr..":"..port] = getTimeStr()..":connect fail"
updateNetworkLog()
end)
procer("LIB_SOCKET_SEND_FAIL_IND",function(ssl,prot,addr,port)           
stNetworkLog[(ssl and "ssl" or prot).."://"..addr..":"..port] = getTimeStr()..":send fail"
updateNetworkLog()
end)
procer("PDP_DEACT_IND",function()        
stNetworkLog["PDP_DEACT_IND"] = getTimeStr()
updateNetworkLog()
end)
procer("IP_SHUT_IND",function()        
stNetworkLog["IP_SHUT_IND"] = getTimeStr()
updateNetworkLog()
end)
end


































function request(addr,period)
local protocol = addr:match("(%a+)://")
if protocol~="http" and protocol~="udp" and protocol~="tcp" then
log.error("errDump.request invalid protocol",protocol)
return
end

if not sReporting then        
sys.taskInit(clientTask,protocol,addr,period or 600000)
end
return true
end

initErr()
