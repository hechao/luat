--��Ҫ���ѣ����������λ�ö���MODULE_TYPE��PROJECT��VERSION����
--MODULE_TYPE��ģ���ͺţ�Ŀǰ��֧��Air201��Air202��Air800
--PROJECT��ascii string���ͣ�������㶨�壬ֻҪ��ʹ��,����
--VERSION��ascii string���ͣ����ʹ��Luat������ƽ̨�̼������Ĺ��ܣ����밴��"X.X.X"���壬X��ʾ1λ���֣��������㶨��
MODULE_TYPE = "Air202"
PROJECT = "SOCKET_SHORT_CONNECTION_FLYMODE"
VERSION = "1.0.0"
require"sys"
--[[
���ʹ��UART���trace��������ע�͵Ĵ���"--sys.opntrace(true,1)"���ɣ���2������1��ʾUART1���trace�������Լ�����Ҫ�޸��������
�����������������trace�ڵĵط�������д��������Ա�֤UART�ھ����ܵ�����������ͳ��ֵĴ�����Ϣ��
���д�ں��������λ�ã����п����޷����������Ϣ���Ӷ����ӵ����Ѷ�
]]
--sys.opntrace(true,1)
--�رսű��е�����trace��ӡ
--sys.opntrace(false)
require"dbg"
dbg.setup("udp","www.test.com",9072)
require"update"
update.setup("udp","www.test.com",2233)
require"test"

--����Ӳ�����Ź�����ģ��
--�����Լ���Ӳ�����þ�����1���Ƿ���ش˹���ģ�飻2������Luatģ�鸴λ��Ƭ�����źͻ���ι������
--����ٷ����۵�Air201����������Ӳ�����Ź�������ʹ�ùٷ�Air201������ʱ��������ش˹���ģ��
--[[
require "wdt"
wdt.setup(pio.P0_30, pio.P0_31)
]]


net.setled(true)
sys.init(0,0)
--��Ҫץcore�е�traceʱ������������
--ril.request("AT*TRACE=\"SXS\",1,0")
--ril.request("AT*TRACE=\"DSS\",1,0")
--ril.request("AT*TRACE=\"RDA\",1,0")
--���ù���ģʽΪ��ģʽ
sys.setworkmode(sys.SIMPLE_MODE)
sys.run()
