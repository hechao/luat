module(..., package.seeall)
require"pins"  --用到了pin库，该库为luatask专用库，需要进行引用


-- button
local led8 = pins.setup(pio.P0_8,1) -- call led8 to read

-- led
local led3 = pins.setup(pio.P0_3,0) -- call led4 to set status


local output_flag = false --led status flag

function myTask()
    if output_flag then
        led3(1)
    else
        led3(0)
    end
    output_flag = not output_flag
	
	-- uart 1
    print("test ... \r\n")	
	log.info("test ... \r\n")
	uart.setup(1,115200,8,uart.PAR_NONE,uart.STOP_1)
	uart.write(1,"TEST ...".."\r\n")
	

	log.info("testGpioSingle.getGpio5Fnc",led8())
	
	-- set loop timer
    sys.timerStart(myTask,1000) -- loop
end

myTask() --开机后立刻运行该函数

