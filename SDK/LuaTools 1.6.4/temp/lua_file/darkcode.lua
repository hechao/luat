module(...,package.seeall)
local tKeyChar =
{
	[keypad.KEY_1] = "1",
	[keypad.KEY_2] = "2",
	[keypad.KEY_3] = "3",
	[keypad.KEY_4] = "4",
}
local tDarkCode =
{	
	["111"] = ttssmsapp.EnterTtsSmsApp,
	["222"] = ttsalarmapp.PlayCurTime,
	["223443"] = eng.AtoTst,
}
local sDarkCode = ""
function Clear()
	sDarkCode = ""
end
function Parse(key)
	local c,bFind = tKeyChar[key]
	if not c then Clear() return end
	sDarkCode = sDarkCode..c
	for k,v in pairs(tDarkCode) do
		if string.find(k,"^"..sDarkCode) then
			bFind = true
			break
		end
	end	
	if not bFind then Clear() return end
	if tDarkCode[sDarkCode] then
		tDarkCode[sDarkCode]()
		Clear()
	end
end
