module(...,package.seeall)
local print = _G.print
local inf = {}
local function init()
	setflag(true)
end
local function autoguard()
	setflag(true)
end
local function changegpsfilterdist()
	if not getflag() then manage.setgpsfilterdist(50) end
end
local function procguardoff()
	sys.timer_start(autoguard,7200000)
	sys.timer_start(changegpsfilterdist,300000)
end
local function proc(id,data)
	print("guard proc",id,data)
	if string.match(id,"SHK") then
		manage.setgpsfilterdist(30)
		if not getflag() then procguardoff() end
	end
	return true
end
function setflag(flag)
	print("guard setflag",inf.flag,flag)
	if inf.flag ~= flag then
		inf.flag = flag
		if not flag then
			procguardoff()
			sys.dispatch("DEV_GUARDOFF_IND")
		else			
			sys.timer_stop(autoguard)
			sys.timer_stop(changegpsfilterdist)
			sys.dispatch("DEV_GUARDON_IND")
		end
		manage.setgpsfilterdist(30)		
	end
end
function getflag()
	return inf.flag
end
sys.regapp(proc,"DEV_SHK_IND")
init()
