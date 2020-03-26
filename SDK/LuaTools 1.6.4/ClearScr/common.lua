






module(..., package.seeall)


local tinsert, ssub, sbyte, schar, sformat, slen = table.insert, string.sub, string.byte, string.char, string.format, string.len







function ucs2ToAscii(inNum)
local tonum = {}
for i = 1, slen(inNum), 4 do
tinsert(tonum, tonumber(ssub(inNum, i, i + 3), 16) % 256)
end
return schar(unpack(tonum))
end






function nstrToUcs2Hex(inNum)
local hexs = ""
local elem = ""
for i = 1, slen(inNum) do
elem = ssub(inNum, i, i)
if elem == "+" then
hexs = hexs .. "002B"
else
hexs = hexs .. "003" .. elem
end
end
return hexs
end








function numToBcdNum(inStr,destLen)
local l,t,num = string.len(inStr or ""),{}

destLen = destLen or (inStr:len()+1)/2

for i=1,l,2 do
num = tonumber(inStr:sub(i,i+1),16)

if i==l then
num = 0xf0+num
else
num = (num%0x10)*0x10 + (num-(num%0x10))/0x10
end

table.insert(t,num)
end

local s = string.char(unpack(t))

l = slen(s)
if l < destLen then
s = s .. string.rep("\255",destLen-l)
elseif l > destLen then
s = ssub(s,1,destLen)
end

return s
end







function bcdNumToNum(num)
local byte,v1,v2
local t = {}

for i=1,num:len() do
byte = num:byte(i)
v1,v2 = bit.band(byte,0x0f),bit.band(bit.rshift(byte,4),0x0f)

if v1 == 0x0f then break end
table.insert(t,v1)

if v2 == 0x0f then break end
table.insert(t,v2)
end

return table.concat(t)
end





function ucs2ToGb2312(ucs2s)
local cd = iconv.open("gb2312", "ucs2")
return cd:iconv(ucs2s)
end





function gb2312ToUcs2(gb2312s)
local cd = iconv.open("ucs2", "gb2312")
return cd:iconv(gb2312s)
end





function ucs2beToGb2312(ucs2s)
local cd = iconv.open("gb2312", "ucs2be")
return cd:iconv(ucs2s)
end





function gb2312ToUcs2be(gb2312s)
local cd = iconv.open("ucs2be", "gb2312")
return cd:iconv(gb2312s)
end





function ucs2ToUtf8(ucs2s)
local cd = iconv.open("utf8", "ucs2")
return cd:iconv(ucs2s)
end





function utf8ToUcs2(utf8s)
local cd = iconv.open("ucs2", "utf8")
return cd:iconv(utf8s)
end





function ucs2beToUtf8(ucs2s)
local cd = iconv.open("utf8", "ucs2be")
return cd:iconv(ucs2s)
end





function utf8ToUcs2be(utf8s)
local cd = iconv.open("ucs2be", "utf8")
return cd:iconv(utf8s)
end





function utf8ToGb2312(utf8s)
local cd = iconv.open("ucs2", "utf8")
local ucs2s = cd:iconv(utf8s)
cd = iconv.open("gb2312", "ucs2")
return cd:iconv(ucs2s)
end





function gb2312ToUtf8(gb2312s)
local cd = iconv.open("ucs2", "gb2312")
local ucs2s = cd:iconv(gb2312s)
cd = iconv.open("utf8", "ucs2")
return cd:iconv(ucs2s)
end

local function timeAddzone(y, m, d, hh, mm, ss, zone)
if not y or not m or not d or not hh or not mm or not ss then
return
end
hh = hh + zone
if hh >= 24 then
hh = hh - 24
d = d + 1
if m == 4 or m == 6 or m == 9 or m == 11 then
if d > 30 then
d = 1
m = m + 1
end
elseif m == 1 or m == 3 or m == 5 or m == 7 or m == 8 or m == 10 then
if d > 31 then
d = 1
m = m + 1
end
elseif m == 12 then
if d > 31 then
d = 1
m = 1
y = y + 1
end
elseif m == 2 then
if (((y + 2000) % 400) == 0) or (((y + 2000) % 4 == 0) and ((y + 2000) % 100 ~= 0)) then
if d > 29 then
d = 1
m = 3
end
else
if d > 28 then
d = 1
m = 3
end
end
end
end
local t = {}
t.year, t.month, t.day, t.hour, t.min, t.sec = y, m, d, hh, mm, ss
return t
end
local function timeSubZone(y, m, d, hh, mm, ss, zone)
if not y or not m or not d or not hh or not mm or not ss then
return
end
hh = hh + zone
if hh < 0 then
hh = hh + 24
d = d - 1
if m == 2 or m == 4 or m == 6 or m == 8 or m == 9 or m == 11 then
if d < 1 then
d = 31
m = m - 1
end
elseif m == 5 or m == 7 or m == 10 or m == 12 then
if d < 1 then
d = 30
m = m - 1
end
elseif m == 1 then
if d < 1 then
d = 31
m = 12
y = y - 1
end
elseif m == 3 then
if (((y + 2000) % 400) == 0) or (((y + 2000) % 4 == 0) and ((y + 2000) % 100 ~= 0)) then
if d < 1 then
d = 29
m = 2
end
else
if d < 1 then
d = 28
m = 2
end
end
end
end
local t = {}
t.year, t.month, t.day, t.hour, t.min, t.sec = y, m, d, hh, mm, ss
return t
end














function timeZoneConvert(y, m, d, hh, mm, ss, srcTimeZone, dstTimeZone)
local t = {}
local zone = dstTimeZone-srcTimeZone

if zone >= 0 and zone < 23 then
t = timeAddzone(y, m, d, hh, mm, ss, zone)
elseif zone < 0 and zone >= -24 then
t = timeSubZone(y, m, d, hh, mm, ss, zone)
end
return t
end
