local base = _G
module("idleapp",package.seeall)
local print = base.print
local fs = require"filestore"
local function ProcKeyLongPress(key)
	if key == keypad.KEY_SOS then
		sosapp.EnterSosApp()
	elseif key >= keypad.KEY_1 and key <= keypad.KEY_4 then
		ccapp.DialNum(fs.GetRelativeNum(key - keypad.KEY_1 + 1))
	end
	darkcode.Clear()
end
local function ProcKeyInd(key)	
	darkcode.Parse(key)
end
local idleApp = {
	MMI_KEYPAD_IND = ProcKeyInd,
	MMI_KEYPAD_LONGPRESS_IND = ProcKeyLongPress,
}
function EnterIdleApp()
	sys.regapp(idleApp)
end
