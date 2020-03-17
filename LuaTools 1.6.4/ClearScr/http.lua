





require"socket"
require"utils"
module(..., package.seeall)

local function response(client,cbFnc,result,prompt,head,body)
if not result then log.error("http.response",result,prompt) end
if cbFnc then cbFnc(result,prompt,head,body) end
if client then client:close() end
end

local function receive(client,timeout,cbFnc,result,prompt,head,body)
local res,data = client:recv(timeout)
if not res then
response(client,cbFnc,result,prompt or "receive timeout",head,body)
end
return res,data
end

local function getFileBase64Len(s)
if s then return (io.fileSize(s)+2)/3*4 end
end

local function taskClient(method,protocal,auth,host,port,path,cert,head,body,timeout,cbFnc,rcvFilePath)
while not socket.isReady() do
if not sys.waitUntil("IP_READY_IND",timeout) then return response(nil,cbFnc,false,"network not ready") end
end


local bodyLen = 0
if body then
if type(body)=="string" then
bodyLen = body:len()
elseif type(body)=="table" then
for i=1,#body do
bodyLen = bodyLen + (type(body[i])=="string" and string.len(body[i]) or getFileBase64Len(body[i].file_base64) or io.fileSize(body[i].file))
end
end
end


local heads = head or {}
if not heads.Host then heads["Host"] = host end
if not heads.Connection then heads["Connection"] = "short" end
if bodyLen>0 and bodyLen~=tonumber(heads["Content-Length"] or "0") then heads["Content-Length"] = bodyLen end
if auth~="" and not heads.Authorization then heads["Authorization"] = ("Basic "..crypto.base64_encode(auth,#auth)) end
local headStr = ""
for k,v in pairs(heads) do
headStr = headStr..k..": "..v.."\r\n"
end
headStr = headStr.."\r\n"

local client = socket.tcp(protocal=="https",cert)
if not client then return response(nil,cbFnc,false,"create socket error") end
if not client:connect(host,port) then
return response(client,cbFnc,false,"connect fail")
end


if not client:send(method.." "..path.." HTTP/1.1".."\r\n"..headStr..(type(body)=="string" and body or "")) then
return response(client,cbFnc,false,"send head fail")
end


if type(body)=="table" then
for i=1,#body do
if type(body[i])=="string" then
if not client:send(body[i]) then
return response(client,cbFnc,false,"send body fail")
end
else
local file = io.open(body[i].file or body[i].file_base64,"rb")
if file then
while true do
local dat = file:read(body[i].file and 1460 or 1095)
if not dat then
io.close(file)
break
end
if body[i].file_base64 then dat=crypto.base64_encode(dat,#dat) end
if not client:send(dat) then
io.close(file)
return response(client,cbFnc,false,"send file fail")
end
end
else
return response(client,cbFnc,false,"send file open fail")
end
end
end
end

local rcvCache,rspHead,rspBody,d1,d2,result,data,statusCode,rcvChunked,contentLen = "",{},{}

while true do
result,data = receive(client,timeout,cbFnc,false,nil,rspHead,rcvFilePath or table.concat(rspBody))
if not result then return end
rcvCache = rcvCache..data
d1,d2 = rcvCache:find("\r\n\r\n")
if d2 then

_,d1,statusCode = rcvCache:find("%s(%d+)%s.-\r\n")
if not statusCode then
return response(client,cbFnc,false,"parse received status error",rspHead,rcvFilePath or table.concat(rspBody))
end

for k,v in string.gmatch(rcvCache:sub(d1+1,d2-2),"(.-):%s*(.-)\r\n") do
rspHead[k] = v
if (k=="Transfer-Encoding") and (v=="chunked") then rcvChunked = true end

end
if not rcvChunked then
contentLen = tonumber(rspHead["Content-Length"] or "2147483647")
end

rcvCache = rcvCache:sub(d2+1,-1)
break
end
end


if rcvChunked then
local chunkSize

while true do

if not chunkSize then
d1,d2,chunkSize = rcvCache:find("(%x+)\r\n")
if chunkSize then
chunkSize = tonumber(chunkSize,16)
rcvCache = rcvCache:sub(d2+1,-1)                    
else
result,data = receive(client,timeout,cbFnc,false,nil,rspHead,rcvFilePath or table.concat(rspBody))
if not result then return end
rcvCache = rcvCache..data
end
end




if chunkSize then
if rcvCache:len()<chunkSize+2 then
result,data = receive(client,timeout,cbFnc,false,nil,rspHead,rcvFilePath or table.concat(rspBody))
if not result then return end
rcvCache = rcvCache..data
else
if chunkSize>0 then
local chunkData = rcvCache:sub(1,chunkSize)

if rcvFilePath then
local file = io.open(rcvFilePath,"a+")
if not file then return response(client,cbFnc,false,"receive：open file error",rspHead,rcvFilePath or table.concat(rspBody)) end
if not file:write(chunkData) then response(client,cbFnc,false,"receive：write file error",rspHead,rcvFilePath or table.concat(rspBody)) end
file:close()

else
table.insert(rspBody,chunkData)
end                    
rcvCache = rcvCache:sub(chunkSize+3,-1)
chunkSize = nil
elseif chunkSize==0 then
return response(client,cbFnc,true,statusCode,rspHead,rcvFilePath or table.concat(rspBody))
end
end                
end
end
else
local rmnLen = contentLen
while true do
data = rcvCache:len()<=rmnLen and rcvCache or rcvCache:sub(1,rmnLen)

if rcvFilePath then
if data:len()>0 then
local file = io.open(rcvFilePath,"a+")
if not file then return response(client,cbFnc,false,"receive：open file error",rspHead,rcvFilePath or table.concat(rspBody)) end
if not file:write(data) then response(client,cbFnc,false,"receive：write file error",rspHead,rcvFilePath or table.concat(rspBody)) end
file:close()
end
else
table.insert(rspBody,data)
end
rmnLen = rmnLen-data:len()
if rmnLen==0 then break end
result,rcvCache = receive(client,timeout,cbFnc,contentLen==0x7FFFFFFF,contentLen==0x7FFFFFFF and statusCode or nil,rspHead,rcvFilePath or table.concat(rspBody))
if not result then return end
end
return response(client,cbFnc,true,statusCode,rspHead,rcvFilePath or table.concat(rspBody))
end
end

































































function request(method,url,cert,head,body,timeout,cbFnc,rcvFileName)
local protocal,auth,hostName,port,path,d1,d2,offset,rcvFilePath

d1,d2,protocal = url:find("^(%a+)://")
if not protocal then protocal = "http" end
offset = d2 or 0

d1,d2,auth = url:find("(.-:.-)@",offset+1)
offset = d2 or offset

if url:match("^[^/]+:(%d+)",offset+1) then
d1,d2,hostName,port = url:find("^([^/]+):(%d+)",offset+1)
else
d1,d2,hostName = url:find("(.-)/",offset+1)
if hostName then
d2 = d2-1
else
hostName = url:sub(offset+1,-1)
offset = url:len()
end
end

if not hostName then return response(nil,cbFnc,false,"Invalid url, can't get host") end
if port=="" or not port then port = (protocal=="https" and 443 or 80) end
offset = d2 or offset

path = url:sub(offset+1,-1)

if rcvFileName and rcvFileName:sub(1,1)~="/" and rtos.make_dir and rtos.make_dir("/http_down") then
rcvFilePath = "/http_down/"..rcvFileName
end

sys.taskInit(taskClient,method,protocal,auth or "",hostName,port,path=="" and "/" or path,cert,head,body or "",timeout or 30000,cbFnc,rcvFilePath or rcvFileName)

return rcvFilePath or rcvFileName
end

