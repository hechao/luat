

local base = _G
local pmd = require"pmd"
local pairs = base.pairs
local assert = base.assert
module("pm")
local tags = {}
local flag = true

function isleep()
	return flag
end

function wake(tag)
	assert(tag and tag~=nil,"pm.wake tag invalid")
	tags[tag] = 1
	if flag == true then
		flag = false
		pmd.sleep(0)
	end
end

function sleep(tag)
	assert(tag and tag~=nil,"pm.sleep tag invalid")
	tags[tag] = 0
	if tags[tag] < 0 then
		base.print("pm.sleep:error",tag)
		tags[tag] = 0
	end
	for k,v in pairs(tags) do
		if v > 0 then
			return
		end
	end
	flag = true
	pmd.sleep(1)
end
