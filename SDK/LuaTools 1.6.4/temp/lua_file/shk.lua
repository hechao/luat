module(...,package.seeall)
local i2cid,intregaddr = 1,0x1A
local function clrint()
	if pins.get(pins.GSENSOR) then
		i2c.read(i2cid,intregaddr,1)
	end
end
local function init()
	local i2cslaveaddr = 0x0E
	if i2c.setup(i2cid,i2c.SLOW,i2cslaveaddr) ~= i2c.SLOW then
		print("shk.init fail")
		return
	end
	local cmd,i = {0x1B,0x00,0x6A,0x01,0x1E,0x20,0x21,0x04,0x1B,0x00,0x1B,0x9A,0x1B,0x9A}
	for i=1,#cmd,2 do
		i2c.write(i2cid,cmd[i],cmd[i+1])
		print("shk.init",string.format("%02X",cmd[i]),string.format("%02X",string.byte(i2c.read(i2cid,cmd[i],1))))
	end
	clrint()
end
local function ind(id,data)
	print("shk.ind",id,data)
	if id == string.format("PIN_%s_IND",pins.GSENSOR.name) then
		if data then
			clrint()
			print("shk.ind DEV_SHK_IND")
			sys.dispatch("DEV_SHK_IND")
		end
	end
end
sys.regapp(ind,string.format("PIN_%s_IND",pins.GSENSOR.name))
init()
sys.timer_loop_start(clrint,30000)
