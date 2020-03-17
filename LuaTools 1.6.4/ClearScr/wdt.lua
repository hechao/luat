





module(..., package.seeall)

require "pins"

local restarting






local function taskWdt(rst, wd, restartFlag)
local wdtRestartAirFlag = restartFlag

rst(1)
wd(1)

while true do

wd(0)
log.info("wdt.taskWdt", "AirM2M --> WATCHDOG : OK", wdtRestartAirFlag, restarting)
if not wdtRestartAirFlag and restarting then return end
sys.wait(2000)

wd(nil, true)
for i = 1, 30 do
if 0 ~= wd() then
if not wdtRestartAirFlag and restarting then return end
sys.wait(100)
else
log.info("wdt.taskWdt", "AirM2M <-- WatchDog : OK")
break
end

if 30 == i then

rst(0)
log.error("wdt.taskWdt", "WatchDog <--> AirM2M didn't respond : wdt reset 153b")
if not wdtRestartAirFlag and restarting then return end
sys.wait(100)
rst(1)
end
end

if not wdtRestartAirFlag and restarting then return end
sys.wait(wdtRestartAirFlag and 1500 or 120000)
wd(0, true)
end
end






function setup(rst, wd)
sys.taskInit(taskWdt, rst and pins.setup(rst, 0, pio.PULLUP) or function() end, pins.setup(wd, 0, pio.PULLUP))
end







function restart(rst, wd)
if not restarting then
restarting = true
if rst then pins.close(rst) end
pins.close(wd)
sys.taskInit(taskWdt, rst and pins.setup(rst, 0, pio.PULLUP) or function() end, pins.setup(wd, 0, pio.PULLUP),true)
end
end
