require"pins"
module(...,package.seeall)

--[[
��Ҫ����!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

ʹ��ĳЩGPIOʱ�������ڽű���д�����GPIO�����ĵ�ѹ�����õ�ѹ�������ȼ�����ЩGPIO������������
������GPIOʹ��ǰ(�����ļ���pins.regǰ)����pmd.ldoset(��ѹ�ȼ�,��ѹ������)
��ѹ�ȼ����Ӧ�ĵ�ѹ���£�
0--------�ر�
1--------1.8V
2--------1.9V
3--------2.0V
4--------2.6V
5--------2.8V
6--------3.0V
7--------3.3V
IO����Ϊ���ʱ���ߵ�ƽʱ�������ѹ��Ϊ���õĵ�ѹ�ȼ���Ӧ�ĵ�ѹ
IO����Ϊ��������ж�ʱ����������ĸߵ�ƽ��ѹ���������õĵ�ѹ�ȼ��ĵ�ѹƥ��

��ѹ������Ƶ�GPIO�Ķ�Ӧ��ϵ���£�
pmd.LDO_VMMC��GPIO8��GPIO9��GPIO10��GPIO11��GPIO12��GPIO13
pmd.LDO_VLCD��GPIO14��GPIO15��GPIO16��GPIO17��GPIO18
pmd.LDO_VCAM��GPIO19��GPIO20��GPIO21��GPIO22��GPIO23��GPIO24
һ��������ĳһ����ѹ��ĵ�ѹ�ȼ����ܸõ�ѹ����Ƶ�����GPIO�ĸߵ�ƽ�������õĵ�ѹ�ȼ�һ��

���磺GPIO8�����ƽʱ��Ҫ�����2.8V�������pmd.ldoset(5,pmd.LDO_VMMC)
]]

--���������˿�Դģ�������п�����GPIO�����ţ�ÿ������ֻ����ʾ��Ҫ
--�û�����������Լ������������޸�
--ģ�������GPIO��֧���ж�

--pinֵ�������£�
--pio.P0_XX����ʾGPIOXX���ɱ�ʾGPIO 0 �� GPIO 31������pio.P0_15����ʾGPIO15
--pio.P1_XX����ʾGPIO(XX+32)���ɱ�ʾGPIO 32���ϵ�GPIO������pio.P1_2����ʾGPIO34

--dirֵ�������£�Ĭ��ֵΪpio.OUTPUT����
--pio.OUTPUT����ʾ�������ʼ��������͵�ƽ
--pio.OUTPUT1����ʾ�������ʼ��������ߵ�ƽ
--pio.INPUT����ʾ���룬��Ҫ��ѯ����ĵ�ƽ״̬
--pio.INT����ʾ�жϣ���ƽ״̬�����仯ʱ���ϱ���Ϣ�����뱾ģ���intmsg����

--validֵ�������£�Ĭ��ֵΪ1����
--valid��ֵ��pins.lua�е�set��get�ӿ����ʹ��
--dirΪ���ʱ�����pins.set�ӿ�ʹ�ã�pins.set�ĵ�һ���������Ϊtrue��������validֵ��ʾ�ĵ�ƽ��0��ʾ�͵�ƽ��1��ʾ�ߵ�ƽ
--dirΪ������ж�ʱ�����get�ӿ�ʹ�ã�������ŵĵ�ƽ��valid��ֵһ�£�get�ӿڷ���true�����򷵻�false
--dirΪ�ж�ʱ��cbΪ�ж����ŵĻص����������жϲ���ʱ�����������cb�������cb����������жϵĵ�ƽ��valid��ֵ��ͬ����cb(true)������cb(false)

--�ȼ���PIN8 = {pin=pio.P0_1,dir=pio.OUTPUT,valid=1}
--��8�����ţ�GPIO_1������Ϊ�������ʼ������͵�ƽ��valid=1������pins.set(true,PIN8),������ߵ�ƽ������pins.set(false,PIN8),������͵�ƽ
PIN8 = {pin=pio.P0_1}

--��9�����ţ�GPIO_0������Ϊ�������ʼ������ߵ�ƽ��valid=0������pins.set(true,PIN9),������͵�ƽ������pins.set(false,PIN9),������ߵ�ƽ
PIN9 = {pin=pio.P0_0,dir=pio.OUTPUT1,valid=0}

--�������ú����PIN8����
PIN6 = {pin=pio.P0_3}
PIN7 = {pin=pio.P0_2}
PIN12 = {pin=pio.P0_29}
PIN10 = {pin=pio.P0_31}
PIN11 = {pin=pio.P0_30}
--PIN27 = {pin=pio.P0_4}
PIN30 = {pin=pio.P0_7}
PIN2 = {pin=pio.P0_10}
PIN3 = {pin=pio.P0_8}
PIN4 = {pin=pio.P0_11}
PIN5 = {pin=pio.P0_12}


local function pin29cb(v)
	print("pin29cb",v)
end
--��29�����ţ�GPIO_6������Ϊ�жϣ�valid=1
--intcb��ʾ�жϹܽŵ��жϴ������������ж�ʱ�����Ϊ�ߵ�ƽ����ص�intcb(true)�����Ϊ�͵�ƽ����ص�intcb(false)
--����pins.get(PIN29)ʱ�����Ϊ�ߵ�ƽ���򷵻�true�����Ϊ�͵�ƽ���򷵻�false
PIN29 = {pin=pio.P0_6,dir=pio.INT,valid=1,intcb=pin29cb}


local function pin27cb(v)
	print("pin27cb",v)
end
PIN27 = {pin=pio.P0_4,dir=pio.INT,valid=1,intcb=pin27cb}


--��28�����ţ�GPIO_5������Ϊ���룻valid=0
--����pins.get(PIN28)ʱ�����Ϊ�ߵ�ƽ���򷵻�false�����Ϊ�͵�ƽ���򷵻�true
PIN28 = {pin=pio.P0_5,dir=pio.INPUT,valid=0}

--����GPIO8��GPIO9��GPIO10��GPIO11��GPIO12��GPIO13�ĸߵ�ƽ��ѹΪ2.8V
pmd.ldoset(5,pmd.LDO_VMMC)
pins.reg(PIN8,PIN9,PIN6,PIN7,PIN12,PIN10,PIN11,PIN27,PIN28,PIN30,PIN2,PIN3,PIN4,PIN29,PIN5)
