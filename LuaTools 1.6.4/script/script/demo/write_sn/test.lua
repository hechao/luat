module(...,package.seeall)

require"misc"

--��Ҫд���豸����SN��
local newsn = "1234567890123456"

--5���ʼдSN
sys.timer_start(misc.setsn,5000,newsn)
