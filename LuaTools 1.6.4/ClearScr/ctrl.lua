module(..., package.seeall)
require"pins"  


local function print(...)
_G.print("test",...)
end




local getGpio5Fnc = pins.setup(pio.P0_8,1)


local led4 = pins.setup(pio.P0_3,0)


local ledon = false 
function changeLED()
if ledon then
led4(1)

else
led4(0)
end
ledon = not ledon






log.info("testGpioSingle.getGpio5Fnc",getGpio5Fnc())


sys.timerStart(changeLED,1000)
end

changeLED() 

