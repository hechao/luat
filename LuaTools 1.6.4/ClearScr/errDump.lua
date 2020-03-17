















require"socket"
require"misc"
module(..., package.seeall)


local LIB_ERR_FILE,libErr,LIB_ERR_MAX_LEN = "/lib_err.txt","",5*1024
local LUA_ERR_FILE,luaErr = "/luaerrinfo.txt",""
local sReporting,sProtocol,sWritingFile




local function initErr()
libErr = io.readFile(LIB_ERR_FILE) or ""
if libErr~="" then
log.error("errDump.libErr", libErr)
end

luaErr = io.readFile(LUA_ERR_FILE) or ""
if luaErr~="" then
log.error("errDump.luaErr", luaErr)
end
end










function appendErr(s)
if s then
s=s.."\r\n"
log.error("errDump.appendErr",s)
if (s:len()+libErr:len())<=LIB_ERR_MAX_LEN then            
libErr = libErr..s
sWritingFile = true
local result = io.writeFile(LIB_ERR_FILE, libErr)
sWritingFile = false
return result
end
end
end

local function reportData()
return _G.PROJECT.."_"..rtos.get_version()..",".._G.VERSION..","..misc.getImei()..","..misc.getSn()..","..luaErr..(luaErr:len()>0 and "\r\n" or "")..libErr
end

local function httpPostCbFnc(result,statusCode)
log.info("errDump.httpPostCbFnc",result,statusCode)
sys.publish("ERRDUMP_HTTP_POST",result,statusCode)
end

function clientTask(protocol,addr,period)
sReporting = true
while true do
if not socket.isReady() then sys.waitUntil("IP_READY_IND") end

if luaErr~="" or libErr~="" then
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
if not sWritingFile then
libErr = ""
os.remove(LIB_ERR_FILE)
end
luaErr = ""
os.remove(LUA_ERR_FILE)
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
