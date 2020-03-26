module(...,package.seeall)
--��ʱ��1��ѭ����ʱ����ѭ������Ϊ1���ӣ�ÿ�ζ���ӡ"TimerFunc1 check1"�����һ�ζ�ʱ��2����ʱ��5�Ƿ��ڼ���״̬����ӡ�������ڼ���״̬�Ķ�ʱ��
--��ʱ��2�����ζ�ʱ����������5���Ӵ�������ӡ"TimerFunc2"��Ȼ���Զ��ر��Լ�
--��ʱ��3�����ζ�ʱ����������10���Ӵ�������ӡ"TimerFunc3"��Ȼ���Զ��ر��Լ�
--��ʱ��4��ѭ����ʱ����ѭ������Ϊ2���ӣ�ÿ�ζ���ӡ"TimerFunc4"
--��ʱ��5�����ζ�ʱ����������60���Ӵ�������ӡ"TimerFunc5"���رն�ʱ��4��������ʱ��6��7��8��Ȼ���Զ��ر��Լ�
--��ʱ��6��ѭ����ʱ����ѭ������Ϊ1���ӣ�ÿ�ζ���ӡ"TimerFunc1 check6"
--��ʱ��7��ѭ����ʱ����ѭ������Ϊ1���ӣ�ÿ�ζ���ӡ"TimerFunc1 check7"
--��ʱ��8�����ζ�ʱ����������5���Ӵ�������ӡ"CloseTimerFunc1 check check6 check7"��Ȼ���Զ��ر��Լ�
local function TimerFunc2AndTimerFunc3(id)
	print("TimerFunc"..id)
end
local function TimerFunc4()
	print("TimerFunc4")
end
local function TimerFunc5()
	print("TimerFunc5")
	sys.timer_stop(TimerFunc4)
	sys.timer_loop_start(TimerFunc1,1000,"check6")
	sys.timer_loop_start(TimerFunc1,1000,"check7")
	sys.timer_start(CloseTimerFunc1,5000)
end
function CloseTimerFunc1()
	print("CloseTimerFunc1 check check6 check7")
	sys.timer_stop_all(TimerFunc1)
end
function TimerFunc1(id)
	print("TimerFunc1 "..id)
	if id=="check1" then		
		if sys.timer_is_active(TimerFunc2AndTimerFunc3,2) then print("Timer2 active") end
		if sys.timer_is_active(TimerFunc2AndTimerFunc3,3) then print("Timer3 active") end
		if sys.timer_is_active(TimerFunc4) then print("Timer4 active") end
		if sys.timer_is_active(TimerFunc5) then print("Timer5 active") end
	end
end
sys.timer_loop_start(TimerFunc1,1000,"check1")
sys.timer_start(TimerFunc2AndTimerFunc3,5000,2)
sys.timer_start(TimerFunc2AndTimerFunc3,10000,3)
sys.timer_loop_start(TimerFunc4,2000)
sys.timer_start(TimerFunc5,60000)
