module("updateapp",package.seeall)
local function updateEvt(evt,ind,para)
	if evt == "UP_EVT" then
		if ind == "NEW_VER_IND" then
			para(true)			
		elseif ind == "UP_PROGRESS_IND" then
		elseif ind == "UP_END_IND" then
			if para then
				if pmdapp.IsCharging() then
					rtos.restart()
				end
			else
			end
		end
	end
end
sys.regapp(updateEvt,"UP_EVT")
