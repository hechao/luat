--[[
ģ�����ƣ�logo
ģ�鹦�ܣ���ʾ������ӭ���logoͼƬ
ģ������޸�ʱ�䣺2017.08.08
]]

module(...,package.seeall)

require"uiwin"
require"prompt"
require"idle"

--���LCD��ʾ������
disp.clear()
if lcd.WIDTH==128 and lcd.HEIGHT==128 then
--��ʾlogoͼƬ
disp.putimage("/ldata/logo_"..(lcd.BPP==1 and "mono.bmp" or "color.png"),lcd.BPP==1 and 41 or 0,lcd.BPP==1 and 18 or 0)
elseif lcd.WIDTH==240 and lcd.HEIGHT==320 then
disp.puttext("��ӭʹ��Luat",lcd.getxpos("��ӭʹ��Luat"),10)
--��ʾlogoͼƬ
disp.putimage("/ldata/logo_color_240X320.png",0,80)
else
--������16,0λ�ÿ�ʼ��ʾ"��ӭʹ��Luat"
disp.puttext("��ӭʹ��Luat",lcd.getxpos("��ӭʹ��Luat"),0)
--��ʾlogoͼƬ
disp.putimage("/ldata/logo_"..(lcd.BPP==1 and "mono.bmp" or "color.png"),lcd.BPP==1 and 41 or 1,lcd.BPP==1 and 18 or 33)
end
--ˢ��LCD��ʾ��������LCD��Ļ��
disp.update()

--5��󣬴���ʾ�򴰿ڣ���ʾ"3�������������"
--��ʾ�򴰿ڹرպ��Զ������������
sys.timer_start(prompt.open,5000,"3���","�����������",nil,idle.open)

