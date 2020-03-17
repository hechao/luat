module(...,package.seeall)
local para,PARA_FILE,SEP,d1,d2 = {},"/para_A5315_AIR.txt",","
local paratable =
{
	{x="RPTFREQ",y=600,z="%d+",w=1},
	{x="HEARTBEAT",y=360,z="%d+",w=1},
	{x="RXPROT",y="TCP",z="%w+",w=0},
	{x="RXADDR",y="180.97.81.170",z="[%w%.]+",w=0},
	{x="RXPORT",y="19001",z="%d+",w=0},
	{x="RXPHONENUM",y="",z="%d*",w=0},
	{x="RXADMINNUM",y="",z="%d*",w=0},
	{x="RXPWD",y="123456",z="%d+",w=0},
	{x="LNG",y="",z="[%d%.]*",w=0},
	{x="LAT",y="",z="[%d%.]*",w=0},
	{x="RXRPTFREQ",y=600,z="%d+",w=1},
	{x="RXHEART",y=300,z="%d+",w=1},
	{x="RXADDR1",y="gps.xdiot.net",z="[%w%.]+",w=0},
}
local function readtxt(f)
	local file,rt = io.open(f,"rb")
	if not file then print("can't open file",f) return end
	rt = file:read("*a")
	print("config_r",rt)
	file:close()
	return rt
end
local function writetxt(f,v)
	local file = io.open(f,"wb")
	if not file then print("open file to write err",f) return end
	file:write(v)
	file:close()
end
local function writepara(save)
	if save then
		local para_w = ""
		for k,v in pairs(paratable) do
			para_w = para_w .. para[v.x] .. SEP
		end
		print("para_w",para_w)
		if para_w ~= "" then
			writetxt(PARA_FILE,para_w)
		end
	end
end
local function tonum(val)
    if val then
       para[val] = tonumber(para[val])
	end
end
local function initpara()
	for k,v in pairs(paratable) do
		para[v.x] = v.y
	end
end
function restore()
	initpara()
	writepara(true)
end
local function init()
	local para_r,n,prt,writeback = readtxt(PARA_FILE),{},""
	if not para_r then
		print("read para txt err and init")
		restore()
		return
	end
	local tmp = para_r
	d2 = 0
	for k,v in pairs(paratable) do
		if not d2 then break end
		tmp = string.sub(tmp,d2+1,-1)
		d1,d2,n[v.x] = string.find(tmp,"(" .. v.z .. ")" .. SEP)
		if n[v.x] ~= nil then
			prt = prt .. v.x .. "=" .. n[v.x] .. SEP
		end
	end
	para = n
	print(prt)
	for k,v in pairs(paratable) do
		if v.w == 1 then tonum(v.x) end
	end
	for k,v in pairs(paratable) do
		if para[v.x] == nil then
			print("nil,",v.x)
			para[v.x] = v.y
			if not writeback then
				writeback = true
			end
		end
	end
	if writeback then
		print("WriteBack")
		writepara(true)
	end
end
function get(name)
	return para[name]
end
function set(name,val,save)
	if val ~= para[name] then
		para[name] = val
		writepara(save)
	end
end
function flush()
	writepara(true)
end
init()
