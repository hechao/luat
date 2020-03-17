require"config"
require"nvm"
module(...,package.seeall)

--[[
��������
����config.lua��4������
ÿ�β������ݷ����ı�󣬶����ӡ�����в���
]]

local function print(...)
	_G.print("test",...)
end

local function getTablePara(t)
	if type(t)=="table" then
		local ret = "{"
		for i=1,#t do
			ret = ret..t[i]..(i==#t and "" or ",")
		end
		ret = ret.."}"
		return ret
	end
end

local function printAllPara()
	_G.print("\r\n\r\n")
	print("---printAllPara begin---")
	_G.print("strPara = "..nvm.get("strPara"))
	_G.print("numPara = "..nvm.get("numPara"))
	_G.print("boolPara = "..tostring(nvm.get("boolPara")))
	_G.print("tablePara = "..getTablePara(nvm.get("tablePara")))
	print("---printAllPara end  ---\r\n\r\n")
end

local function restoreFunc()
	print("restoreFunc")
	nvm.restore()
	printAllPara()
end

local function paraChangedInd(k,v,r)
	print("paraChangedInd",k,v,r)
    printAllPara()
	return true
end

local function tParaChangedInd(k,kk,v,r)
	print("tParaChangedInd",k,kk,v,r)
    printAllPara()
	return true
end

local procer =
{
	PARA_CHANGED_IND = paraChangedInd, --����nvm.set�ӿ��޸Ĳ�����ֵ�����������ֵ�����ı䣬nvm.lua�����sys.dispatch�ӿ��׳�PARA_CHANGED_IND��Ϣ
	TPARA_CHANGED_IND = tParaChangedInd,	--����nvm.sett�ӿ��޸�table���͵Ĳ����е�ĳһ���ֵ�����ֵ�����ı䣬nvm.lua�����sys.dispatch�ӿ��׳�TPARA_CHANGED_IND��Ϣ
}
--ע����Ϣ������
sys.regapp(procer)

--��ʼ����������ģ��
nvm.init("config.lua")

--��ӡ�����в���
printAllPara()

--�޸�strPara����ֵΪstr2���޸ĺ�nvm.lua�����sys.dispatch�ӿ��׳�PARA_CHANGED_IND��Ϣ��test.luaӦ�ô���PARA_CHANGED_IND��Ϣ����paraChangedInd(��ע��۲�paraChangedInd�д�ӡ����k,v,r)���Զ���ӡ�����в���
nvm.set("strPara","str2","strPara2")
--�޸�strPara����ֵΪstr3���޸ĺ���ȻstrPara��ֵ�����str3������nvm.lua�����׳�PARA_CHANGED_IND��Ϣ
--��Ϊ����nvm.setʱû�д������������
--nvm.set("strPara","str3")
sys.timer_start(nvm.set,1000,"strPara","str3")

--�޸�numPara����ֵΪ2���޸ĺ�nvm.lua�����sys.dispatch�ӿ��׳�PARA_CHANGED_IND��Ϣ��test.luaӦ�ô���PARA_CHANGED_IND��Ϣ����paraChangedInd(��ע��۲�paraChangedInd�д�ӡ����k,v,r)���Զ���ӡ�����в���
--nvm.set("numPara",2,"numPara2",false)
sys.timer_start(nvm.set,2000,"numPara",2,"numPara2",false)
--nvm.set("numPara",3,"numPara3",false)
sys.timer_start(nvm.set,3000,"numPara",3,"numPara3",false)
--nvm.set("numPara",4,"numPara4",false)
sys.timer_start(nvm.set,4000,"numPara",4,"numPara4",false)
--ִ������3��nvm.set����numPara��ֵ���ձ����4���������ڴ��б����4���ļ��д洢��ʵ���ϻ���1��ִ�������һ�����󣬲Ż�ȥд�ļ�ϵͳ
nvm.flush()
--Ҳ����˵nvm.set�еĵ�4�����������Ƿ�д���ļ�ϵͳ��false��д���ļ�ϵͳ�����඼д���ļ�ϵͳ����Ŀ��������������úܶ���������Լ���д�ļ��Ĵ���

--ͬnvm.set("strPara","str2","strPara2")��ԭ������
--nvm.set("tablePara",{"item2-1","item2-2","item2-3"},"tablePara2")
sys.timer_start(nvm.set,5000,"tablePara",{"item2-1","item2-2","item2-3"},"tablePara2")
--ֻ�޸�tablePara�еĵ�2��Ϊitem3-2
--nvm.sett("tablePara",2,"item3-2","tablePara3")
sys.timer_start(nvm.sett,6000,"tablePara",2,"item3-2","tablePara3")

--�ָ���������,��ӡ�����в���
sys.timer_start(restoreFunc,9000)
