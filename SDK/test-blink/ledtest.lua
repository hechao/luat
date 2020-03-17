module(..., package.seeall)
require"pins"  --用到了pin库，该库为luatask专用库，需要进行引用

-- GPIO 0到GPIO 31表示为pio.P0_0到pio.P0_31 。
-- GPIO 32到GPIO XX表示为pio.P1_0到pio.P1_(XX-32)，例如GPIO33 表示为pio.P1_1
if moduleType == 2 then
    pmd.ldoset(5,pmd.LDO_VMMC)  --使用某些GPIO时，必须在脚本中写代码打开GPIO所属的电压域，配置电压输出输入等级，这些GPIO才能正常工作
end
--注意！！！4G模块无需设置电压域！


--设置led的GPIO口
local led1 = pins.setup(pio.P0_8,0)--如果你用的是4G模块，请更改这个gpio编号
local led2 = pins.setup(pio.P0_11,0)--如果你用的是4G模块，请更改这个gpio编号
local led3 = pins.setup(pio.P0_12,0)--如果你用的是4G模块，请更改这个gpio编号
local led4 = pins.setup(pio.P0_3,0)--如果你用的是4G模块，请更改这个gpio编号
local led5 = pins.setup(pio.P0_2,0)--如果你用的是4G模块，请更改这个gpio编号

local ledon = false --led是否开启
function changeLED()
    if ledon then
        led1(1)
        led2(1)
        led3(1)
        led4(1)
        led5(1)
    else
        led1(0)
        led2(0)
        led3(0)
        led4(0)
        led5(0)
    end
    ledon = not ledon
    sys.timerStart(changeLED,1000)--一秒后执行指定函数
end

changeLED() --开机后立刻运行该函数

