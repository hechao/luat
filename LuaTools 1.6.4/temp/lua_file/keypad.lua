local base = _G
module("keypad",package.seeall)
local print = base.print
local curkey
local KEY_LONG_PRESS_TIME_PERIOD = 3000
KEY_1 = "1"
KEY_2 = "2"
KEY_3 = "3"
KEY_4 = "4"
KEY_SOS = "SOS"
KEY_END = "END"
local keymap = {["01"] = KEY_1,["02"] = KEY_3, ["10"] = KEY_4, ["11"] = KEY_SOS,["12"] = KEY_2,["255255"] = KEY_END}
local keyToPowerOff = false
local keylongpresstimerfun = function()
	if curkey then
		if curkey == KEY_END then
			keyToPowerOff = true			
		else
			sys.dispatch("MMI_KEYPAD_LONGPRESS_IND",curkey)
		end
	end
end
local function stopkeylongpress()
	curkey = nil
	sys.timer_stop(keylongpresstimerfun)
end
local function startkeylongpress(key)
	stopkeylongpress()
	curkey = key
	sys.timer_start(keylongpresstimerfun,KEY_LONG_PRESS_TIME_PERIOD)
end
local function keymsg(msg)
	local key = keymap[msg.key_matrix_row..msg.key_matrix_col]
	if msg.pressed then			
		if key then
			sys.dispatch("MMI_KEYPAD_IND",key)
			startkeylongpress(key)
		end
	else
		stopkeylongpress()
		if key then
			if key == KEY_END and keyToPowerOff then
				keyToPowerOff = false				
				if not dataapp.SndToSvr(dataapp.POWERALM,dataapp.OFFALM,nil,nil,false,nil,nil,"") then
					rtos.poweroff()
				end
			else
				sys.dispatch("MMI_KEYPAD_PRESSUP",key)
			end
		end
	end
end
sys.regmsg(rtos.MSG_KEYPAD,keymsg)
rtos.init_module(rtos.MOD_KEYPAD, 0, 0x07, 0x03)
