module(..., package.seeall)
require"pins"  --用到了pin库，该库为luatask专用库，需要进行引用


-- button
local led8 = pins.setup(pio.P0_8,1) -- call led8 to read

-- led
local led4 = pins.setup(pio.P0_3,0) -- call led4 to set status


local ledon = false --led status flag
function changeLED()
    if ledon then
        led4(1)

    else
        led4(0)
    end
    ledon = not ledon
	
	-- uart 1
	uart.setup(1,115200,8,uart.PAR_NONE,uart.STOP_1)
	
	-- print("test ... \r\n")
	uart.write(1,"TEST ...".."\r\n")
	
	log.info("testGpioSingle.getGpio5Fnc",getGpio5Fnc())
	
	
    sys.timerStart(changeLED,1000)--一秒后执行指定函数
end

changeLED() --开机后立刻运行该函数

