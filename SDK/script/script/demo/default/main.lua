--��Ҫ���ѣ����������λ�ö���MODULE_TYPE��PROJECT��VERSION����
--MODULE_TYPE��ģ���ͺţ�Ŀǰ��֧��Air201��Air202��Air800
--PROJECT��ascii string���ͣ�������㶨�壬ֻҪ��ʹ��,����
--VERSION��ascii string���ͣ����ʹ��Luat������ƽ̨�̼������Ĺ��ܣ����밴��"X.X.X"���壬X��ʾ1λ���֣��������㶨��
MODULE_TYPE = "Air202"
PROJECT = "DEFAULT"
VERSION = "1.0.4"
require"sys"
--[[
���ʹ��UART���trace��������ע�͵Ĵ���"--sys.opntrace(true,1)"���ɣ���2������1��ʾUART1���trace�������Լ�����Ҫ�޸��������
�����������������trace�ڵĵط�������д��������Ա�֤UART�ھ����ܵ�����������ͳ��ֵĴ�����Ϣ��
���д�ں��������λ�ã����п����޷����������Ϣ���Ӷ����ӵ����Ѷ�
]]
--sys.opntrace(true,1)

--����Ӳ�����Ź�����ģ��
--�����Լ���Ӳ�����þ�����1���Ƿ���ش˹���ģ�飻2������Luatģ�鸴λ��Ƭ�����źͻ���ι������
--����ٷ����۵�Air201����������Ӳ�����Ź�������ʹ�ùٷ�Air201������ʱ��������ش˹���ģ��
require "wdt"
wdt.setup(pio.P0_30, pio.P0_31)

require"linkair"
require"factory1"
if MODULE_TYPE~="Air800" and MODULE_TYPE~="Air801" then
require"factory2"
end
require"keypad"

sys.init(0,0)
sys.run()
