
module(...,package.seeall)
local RST_SCMWD_PIN = pio.P0_6
local WATCHDOG_PIN = pio.P0_5
local scm_active,get_scm_cnt = true,20
local testcnt,testing = 0

local function getscm(tag)
	if tag=="normal" and testing then return end
	get_scm_cnt = get_scm_cnt - 1
	if tag=="test" then
		sys.timer_stop(getscm,"normal")
	end
	if get_scm_cnt > 0 then
		if tag=="test" then
			if pio.pin.getval(WATCHDOG_PIN) == 1 then				
				testcnt = testcnt+1
				if testcnt<3 then
					sys.timer_start(feed,100,"test")
					get_scm_cnt = 20
					return
				else
					testing = nil
				end
			end
		end
		sys.timer_start(getscm,100,tag)
	else
		get_scm_cnt = 20
		if tag=="test" then
			testing = nil
		end
		if tag=="normal" and not scm_active then
			pio.pin.setval(0,RST_SCMWD_PIN)
			sys.timer_start(pio.pin.setval,100,1,RST_SCMWD_PIN)
			print("wdt reset 153b")
			scm_active = true
		end
	end
	if pio.pin.getval(WATCHDOG_PIN) == 0 and not scm_active then
		scm_active = true
		print("wdt scm_active = true")
	end
end

local function feedend(tag)
	if tag=="normal" and testing then return end
	pio.pin.close(WATCHDOG_PIN)
	pio.pin.setdir(pio.INPUT,WATCHDOG_PIN)
	print("wdt feedend",tag)
	if tag=="test" then
		sys.timer_stop(getscm,"normal")
	end
	--ÿ100����ȥ��һ�Σ�������20�Σ�ֻҪ��һ�ζ����͵�ƽ������Ϊ"��Ƭ����ģ��ι��"����
	sys.timer_start(getscm,100,tag)
end

function feed(tag)
	if tag=="normal" and testing then return end
	if scm_active or tag=="test" then
		scm_active = false
	end
	--�໥ι����������Ϊ�����"ģ�鿪ʼ�Ե�Ƭ��ι��"�����2��ĵ͵�ƽ
	pio.pin.close(WATCHDOG_PIN)
	pio.pin.setdir(pio.OUTPUT,WATCHDOG_PIN)
	pio.pin.setval(0,WATCHDOG_PIN)
	print("wdt feed",tag)
	sys.timer_start(feed,120000,"normal")
	if tag=="test" then
		sys.timer_stop(feedend,"normal")
	end
	--2���ʼ���"��Ƭ����ģ��ι��"�Ƿ�����
	sys.timer_start(feedend,2000,tag)
end

function open()
	pio.pin.setdir(pio.OUTPUT,WATCHDOG_PIN)
	pio.pin.setval(1,WATCHDOG_PIN)
	feed("normal")
end

function test()
	if not testing then
		testcnt,testing = 0,true
		feed("test")
	end
end
pio.pin.setdir(pio.OUTPUT1,RST_SCMWD_PIN)
pio.pin.setval(1,RST_SCMWD_PIN)
open()
