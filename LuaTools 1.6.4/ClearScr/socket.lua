





require "link"
require "utils"
module(..., package.seeall)

local req = ril.request

local valid = {"0", "1", "2", "3", "4", "5", "6", "7"}
local validSsl = {"0", "1", "2", "3", "4", "5", "6", "7"}
local sockets = {}
local socketsSsl = {}

local SENDSIZE = 1460

local INDEX_MAX = 49


local dnsParser
local dnsParserToken = 0



socket.isReady = link.isReady


local function isSocketActive(ssl)
for _, c in pairs(ssl and socketsSsl or sockets) do
if c.connected then
return true
end
end
end

local function socketStatusNtfy()
sys.publish("SOCKET_ACTIVE", isSocketActive() or isSocketActive(true))
end

local function stopConnectTimer(tSocket, id)
if id and tSocket[id] and tSocket[id].co and coroutine.status(tSocket[id].co) == "suspended"
and (tSocket[id].wait == "+SSLCONNECT" or (tSocket[id].protocol == "UDP" and tSocket[id].wait == "+CIPSTART")) then
sys.timerStop(coroutine.resume, tSocket[id].co, false, "TIMEOUT")
end
end

local function errorInd(error)
local coSuspended = {}

for k, v in pairs({sockets, socketsSsl}) do

for _, c in pairs(v) do 

if error == 'CLOSED' and not c.ssl then c.connected = false socketStatusNtfy() end
c.error = error
if c.co and coroutine.status(c.co) == "suspended" then
stopConnectTimer(v, c.id)

table.insert(coSuspended,c.co)
end

end

end

for k, v in pairs(coSuspended) do
if v and coroutine.status(v) == "suspended" then
coroutine.resume(v, false)
end
end
end

sys.subscribe("IP_ERROR_IND", function()errorInd('IP_ERROR_IND') end)
sys.subscribe('IP_SHUT_IND', function()errorInd('CLOSED') end)


local function onSocketURC(data, prefix)
local tag, id, result = string.match(data, "([SSL]*)[&]*(%d), *([%u :%d]+)")
tSocket = (tag == "SSL" and socketsSsl or sockets)
if not id or not tSocket[id] then
log.error('socket: urc on nil socket', data, id, tSocket[id], socketsSsl[id])
return
end

if result == "CONNECT OK" or result:match("CONNECT ERROR") or result:match("CONNECT FAIL") then
if tSocket[id].wait == "+CIPSTART" or tSocket[id].wait == "+SSLCONNECT" then
stopConnectTimer(tSocket, id)
coroutine.resume(tSocket[id].co, result == "CONNECT OK")
else
log.error("socket: error urc", tSocket[id].wait)
end
return
end

if tag == "SSL" and string.find(result, "ERROR:") == 1 then return end

if string.find(result, "ERROR") or result == "CLOSED" then
if result == 'CLOSED' and not tSocket[id].ssl then tSocket[id].connected = false socketStatusNtfy() end
tSocket[id].error = result
stopConnectTimer(tSocket, id)
coroutine.resume(tSocket[id].co, false)
end
end

local mt = {}
mt.__index = mt
local function socket(protocol, cert)
local ssl = protocol:match("SSL")
local id = table.remove(ssl and validSsl or valid)
if not id then
log.warn("socket.socket: too many sockets")
return nil
end

local co = coroutine.running()
if not co then
log.warn("socket.socket: socket must be called in coroutine")
return nil
end

local o = {
id = id,
protocol = protocol,
ssl = ssl,
cert = cert,
co = co,
input = {},
output = {},
wait = "",
connected = false,
iSubscribe = false,
subMessage = nil,
}

tSocket = (ssl and socketsSsl or sockets)
tSocket[id] = o

return setmetatable(o, mt)
end
















function tcp(ssl, cert)
return socket("TCP" .. (ssl == true and "SSL" or ""), (ssl == true) and cert or nil)
end



function udp()
return socket("UDP")
end

local sslInited
local tSslInputCert, sSslInputCert = {}, ""

local function sslInit()
if not sslInited then
sslInited = true
req("AT+SSLINIT")
end

local i, item
for i = 1, #tSslInputCert do
item = table.remove(tSslInputCert, 1)
req(item.cmd, item.arg)
end
tSslInputCert = {}
end

local function sslTerm()
if sslInited then
if not isSocketActive(true) then
sSslInputCert, sslInited = ""
req("AT+SSLTERM")
end
end
end

local function sslInputCert(t, f)
if sSslInputCert:match(t .. f .. "&") then return end
if not tSslInputCert then tSslInputCert = {} end
local s = io.readFile((f:sub(1, 1) == "/") and f or ("/ldata/" .. f))
if not s then log.error("inputcrt err open", path) return end
table.insert(tSslInputCert, {cmd = "AT+SSLCERT=0,\"" .. t .. "\",\"" .. f .. "\",1," .. s:len(), arg = s or ""})
sSslInputCert = sSslInputCert .. t .. f .. "&"
end






function mt:connect(address, port)
assert(self.co == coroutine.running(), "socket:connect: coroutine mismatch")

if not link.isReady() then
log.info("socket.connect: ip not ready")
return false
end

if cc and cc.anyCallExist() then
log.info("socket:connect: call exist, cannot connect")
return false
end

if self.ssl then
local tConfigCert, i = {}
if self.cert then
if self.cert.caCert then
sslInputCert("cacrt", self.cert.caCert)
table.insert(tConfigCert, "AT+SSLCERT=1," .. self.id .. ",\"cacrt\",\"" .. self.cert.caCert .. "\"")
end
if self.cert.clientCert then
sslInputCert("localcrt", self.cert.clientCert)
table.insert(tConfigCert, "AT+SSLCERT=1," .. self.id .. ",\"localcrt\",\"" .. self.cert.clientCert .. "\",\"" .. (self.cert.clientPassword or "") .. "\"")
end
if self.cert.clientKey then
sslInputCert("localprivatekey", self.cert.clientKey)
table.insert(tConfigCert, "AT+SSLCERT=1," .. self.id .. ",\"localprivatekey\",\"" .. self.cert.clientKey .. "\"")
end
end

sslInit()
self.address = address
req(string.format("AT+SSLCREATE=%d,\"%s\",%d", self.id, address .. ":" .. port, (self.cert and self.cert.caCert) and 0 or 1))
self.created = true
for i = 1, #tConfigCert do
req(tConfigCert[i])
end
req("AT+SSLCONNECT=" .. self.id)
else
req(string.format("AT+CIPSTART=%d,\"%s\",\"%s\",%s", self.id, self.protocol, address, port))
end
if self.ssl or self.protocol == "UDP" then sys.timerStart(coroutine.resume, 120000, self.co, false, "TIMEOUT") end

ril.regUrc((self.ssl and "SSL&" or "") .. self.id, onSocketURC)
self.wait = self.ssl and "+SSLCONNECT" or "+CIPSTART"

local r, s = coroutine.yield()

if r == false and s == "DNS" then
if self.ssl then self:sslDestroy()self.error = nil end

require "http"

http.request("GET", "119.29.29.29/d?dn=" .. address, nil, nil, nil, 40000,
function(result, statusCode, head, body)
log.info("socket.httpDnsCb", result, statusCode, head, body)
sys.publish("SOCKET_HTTPDNS_RESULT", result, statusCode, head, body)
end)
local _, result, statusCode, head, body = sys.waitUntil("SOCKET_HTTPDNS_RESULT")


if result and statusCode == "200" and body and body:match("^[%d%.]+") then
return self:connect(body:match("^([%d%.]+)"), port)

else
if dnsParser then
dnsParserToken = dnsParserToken + 1
dnsParser(address, dnsParserToken)
local result, ip = sys.waitUntil("USER_DNS_PARSE_RESULT_" .. dnsParserToken, 40000)
if result and ip and ip:match("^[%d%.]+") then
return self:connect(ip:match("^[%d%.]+"), port)
end
end
end
end

if r == false then
if self.ssl then self:sslDestroy() end
return false
end
self.connected = true
socketStatusNtfy()
return true
end





function mt:asyncSelect(keepAlive, pingreq)
assert(self.co == coroutine.running(), "socket:asyncSelect: coroutine mismatch")
if self.error then
log.warn('socket.client:asyncSelect', 'error', self.error)
return false
end

self.wait = "SOCKET_SEND"
while #self.output ~= 0 do
local data = table.concat(self.output)
self.output = {}
for i = 1, string.len(data), SENDSIZE do

local stepData = string.sub(data, i, i + SENDSIZE - 1)

req(string.format("AT+" .. (self.ssl and "SSL" or "CIP") .. "SEND=%d,%d", self.id, string.len(stepData)), stepData)
self.wait = self.ssl and "+SSLSEND" or "+CIPSEND"
if not coroutine.yield() then
if self.ssl then self:sslDestroy() end
return false
end
end
end
self.wait = "SOCKET_WAIT"
sys.publish("SOCKET_SEND", self.id)
sys.timerStart(self.asyncSend, (keepAlive or 300) * 1000, self, pingreq or "\0")
return coroutine.yield()
end




function mt:asyncSend(data)
if self.error then
log.warn('socket.client:asyncSend', 'error', self.error)
return false
end
table.insert(self.output, data or "")
if self.wait == "SOCKET_WAIT" then coroutine.resume(self.co, true) end
return true
end





function mt:asyncRecv()
if #self.input == 0 then return "" end
if self.protocol == "UDP" then
return table.remove(self.input)
else
local s = table.concat(self.input)
self.input = {}
return s
end
end





function mt:send(data)
assert(self.co == coroutine.running(), "socket:send: coroutine mismatch")
if self.error then
log.warn('socket.client:send', 'error', self.error)
return false
end
if self.id == nil then
log.warn('socket.client:send', 'closed')
return false
end

for i = 1, string.len(data or ""), SENDSIZE do

local stepData = string.sub(data, i, i + SENDSIZE - 1)

req(string.format("AT+" .. (self.ssl and "SSL" or "CIP") .. "SEND=%d,%d", self.id, string.len(stepData)), stepData)
self.wait = self.ssl and "+SSLSEND" or "+CIPSEND"
if not coroutine.yield() then
if self.ssl then self:sslDestroy() end
return false
end
end
return true
end









function mt:recv(timeout, msg)
assert(self.co == coroutine.running(), "socket:recv: coroutine mismatch")
if self.error then
log.warn('socket.client:recv', 'error', self.error)
return false
end
if msg and not self.iSubscribe then
self.iSubscribe = msg
self.subMessage = function(data)
if data then table.insert(self.output, data) end
if self.wait == "+RECEIVE" or self.wait == "+SSL RECEIVE" then coroutine.resume(self.co, 0xAA) end
end
sys.subscribe(msg, self.subMessage)
end
if msg and #self.output ~= 0 then sys.publish(msg, false) end
if #self.input == 0 then
self.wait = self.ssl and "+SSL RECEIVE" or "+RECEIVE"
if timeout and timeout > 0 then
local r, s = sys.wait(timeout)








if r == nil then
return false, "timeout"
elseif r == 0xAA then
local dat = table.concat(self.output)
self.output = {}
return false, msg, dat
else
if self.ssl and not r then self:sslDestroy() end
return r, s
end
else
return coroutine.yield()
end
end

if self.protocol == "UDP" then
return true, table.remove(self.input)
else
local s = table.concat(self.input)
self.input = {}
return true, s
end
end

function mt:sslDestroy()
assert(self.co == coroutine.running(), "socket:sslDestroy: coroutine mismatch")
if self.ssl and (self.connected or self.created) then
self.connected = false
self.created = false
req("AT+SSLDESTROY=" .. self.id)
self.wait = "+SSLDESTROY"
coroutine.yield()
socketStatusNtfy()
end
end



function mt:close()
assert(self.co == coroutine.running(), "socket:close: coroutine mismatch")
if self.iSubscribe then
sys.unsubscribe(self.iSubscribe, self.subMessage)
self.iSubscribe = false
end
if self.connected or self.created then
self.connected = false
self.created = false
req(self.ssl and ("AT+SSLDESTROY=" .. self.id) or ("AT+CIPCLOSE=" .. self.id .. ",0"))
self.wait = self.ssl and "+SSLDESTROY" or "+CIPCLOSE"
coroutine.yield()
socketStatusNtfy()
end
if self.id ~= nil then
ril.deRegUrc((self.ssl and "SSL&" or "") .. self.id, onSocketURC)
table.insert((self.ssl and validSsl or valid), 1, self.id)
if self.ssl then
socketsSsl[self.id] = nil
else
sockets[self.id] = nil
end
self.id = nil
end
end
local function onResponse(cmd, success, response, intermediate)
local prefix = string.match(cmd, "AT(%+%u+)")
local id = string.match(cmd, "AT%+%u+=(%d)")
if response == '+PDP: DEACT' then sys.publish('PDP_DEACT_IND') end 
local tSocket = prefix:match("SSL") and socketsSsl or sockets
if not tSocket[id] then
log.warn('socket: response on nil socket', cmd, response)
return
end

if cmd:match("^AT%+SSLCREATE") then
tSocket[id].createResp = response
end
if tSocket[id].wait == prefix then
if (prefix == "+CIPSTART" or prefix == "+SSLCONNECT") and success then

return
end
if (prefix == '+CIPSEND' or prefix == "+SSLSEND") and response:match("%d, *([%u%d :]+)") ~= 'SEND OK' then
success = false
end

local reason, address
if not success then
if prefix == "+CIPSTART" then
address = cmd:match("AT%+CIPSTART=%d,\"%a+\",\"(.+)\",%d+")
elseif prefix == "+SSLCONNECT" and (tSocket[id].createResp or ""):match("SSL&%d+,CREATE ERROR: 4") then
address = tSocket[id].address or ""
end
if address and not address:match("^[%d%.]+$") then
reason = "DNS"
end
end

if not reason and not success then tSocket[id].error = response end
stopConnectTimer(tSocket, id)
coroutine.resume(tSocket[id].co, success, reason)
end
end

local function onSocketReceiveUrc(urc)
local tag, id, len = string.match(urc, "([SSL]*) *RECEIVE,(%d), *(%d+)")
tSocket = (tag == "SSL" and socketsSsl or sockets)
len = tonumber(len)
if len == 0 then return urc end
local cache = {}
local function filter(data)

if string.len(data) >= len then 

table.insert(cache, string.sub(data, 1, len))

data = string.sub(data, len + 1, -1)
if not tSocket[id] then
log.warn('socket: receive on nil socket', id)
else
sys.publish("SOCKET_RECV", id)
local s = table.concat(cache)
if tSocket[id].wait == "+RECEIVE" or tSocket[id].wait == "+SSL RECEIVE" then
coroutine.resume(tSocket[id].co, true, s)
else 
if #tSocket[id].input > INDEX_MAX then tSocket[id].input = {} end
table.insert(tSocket[id].input, s)
end
end
return data
else
table.insert(cache, data)
len = len - string.len(data)
return "", filter
end
end
return filter
end

ril.regRsp("+CIPCLOSE", onResponse)
ril.regRsp("+CIPSEND", onResponse)
ril.regRsp("+CIPSTART", onResponse)
ril.regRsp("+SSLDESTROY", onResponse)
ril.regRsp("+SSLCREATE", onResponse)
ril.regRsp("+SSLSEND", onResponse)
ril.regRsp("+SSLCONNECT", onResponse)
ril.regUrc("+RECEIVE", onSocketReceiveUrc)
ril.regUrc("+SSL RECEIVE", onSocketReceiveUrc)

function printStatus()
log.info('socket.printStatus', 'valid id', table.concat(valid), table.concat(validSsl))

for m, n in pairs({sockets, socketsSsl}) do
for _, client in pairs(n) do
for k, v in pairs(client) do
log.info('socket.printStatus', 'client', client.id, k, v)
end
end
end
end








function setTcpResendPara(retryCnt, retryMaxTimeout)
req("AT+TCPUSERPARAM=6," .. (retryCnt or 4) .. ",7200," .. (retryMaxTimeout or 16))
ril.setDataTimeout(((retryCnt or 4) * (retryMaxTimeout or 16) + 60) * 1000)
end

















function setDnsParser(parserFnc)
dnsParser = parserFnc
end

setTcpResendPara(4, 16)
