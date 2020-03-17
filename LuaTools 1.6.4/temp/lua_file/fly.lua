local base = _G
local sys  = require"sys"
local misc = require"misc"
local table = require"table"
module(...)
local print = base.print
local assert = base.assert
local pairs = base.pairs
DEFAULT,TIMER = "DEFAULT","TIMER"
FORBID,ALLOW = "FORBID","ALLOW"
local sta,forbidlist,cblist = FORBID,{},{}
local function delitem(mode,para)
	local i
	for i=1,#forbidlist do
		if forbidlist[i].flag and forbidlist[i].mode == mode and forbidlist[i].para.cause == para.cause then
			forbidlist[i].flag = false
			break
		end
	end
end
local function additem(mode,para)
	delitem(mode,para)
	local item,i,fnd = {flag = true, mode = mode, para = para}
	if mode == TIMER then item.para.remain = para.val end
	for i=1,#forbidlist do
		if not forbidlist[i].flag then
			forbidlist[i] = item
			fnd = true
			break
		end
	end
	if not fnd then table.insert(forbidlist,item) end
end
local function isexisttimeritem()
	local i
	for i=1,#forbidlist do
		if forbidlist[i].flag and (forbidlist[i].mode == TIMER) then return true end
	end
end
local function timerfunc()
	local i
	for i=1,#forbidlist do
		print("fly.timerfunc@"..i,forbidlist[i].flag,forbidlist[i].mode,forbidlist[i].para.cause,forbidlist[i].para.remain)
		if forbidlist[i].flag and (forbidlist[i].mode == TIMER) then
			forbidlist[i].para.remain = forbidlist[i].para.remain - 1
			if forbidlist[i].para.remain == 0 then
				allow(forbidlist[i].mode,forbidlist[i].para)
			end
		end
	end
	if not isexisttimeritem() then sys.timer_stop(timerfunc) end
end
function isactive(mode,para)
	local i
	for i=1,#forbidlist do
		if forbidlist[i].flag and forbidlist[i].mode == mode and forbidlist[i].para.cause == para.cause then
			return true
		end
	end
end
function isallow()
	local valid,i
	for i=1,#forbidlist do
		if forbidlist[i].flag then
			valid = true
		end
	end
	return not valid and sta == ALLOW
end
function force(sta)
	misc.setflymode(sta)
end
function delete(mode,para)
	assert(mode and para and para.cause,"fly.allow para err")
	print("fly.ctl delete",mode,para.cause,para.val)
	delitem(mode,para)
end
function allow(mode,para)
	assert(mode and para and para.cause,"fly.allow para err")
	print("fly.ctl allow",mode,para.cause,para.val)
	delitem(mode,para)	
	if isallow() then
		local result,k,v
		for k,v in pairs(cblist) do
			if v() then
				result = true
			end
		end
		if not result then
			force(true)
		end
	end
end
function forbid(mode,para)
	assert(mode and para and para.cause,"fly.forbid para err")
	print("fly.ctl forbid",mode,para.cause,para.val)
	additem(mode,para)
	misc.setflymode(false)
	if isexisttimeritem() and not sys.timer_is_active(timerfunc) then
		sys.timer_loop_start(timerfunc,1000)
	end
end
function setsta(s)
	print("fly.ctl setsta",s)
	sta = s
end
function setcb(cb)
	print("fly.setcb",cb)
	table.insert(cblist,cb)
end
