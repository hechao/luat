require "mqtt"

require"pins"

module(..., package.seeall)


local host, port = "iot.electrodragon.com", 1883

--local led0 = pins.setup(pio.P0_0, 0) -- call led4 to set status
--local led1 = pins.setup(pio.P0_1, 0) -- call led4 to set status

local led2 = pins.setup(pio.P0_2, 1) -- call led4 to set status
local led3 = pins.setup(pio.P0_3, 1) -- call led4 to set status

led2(0)
led3(1)


function button0_int(msg)
    -- log.info("button0_int", msg, button0())
	
    if msg == cpu.INT_GPIO_NEGEDGE then
		log.info("button pressed")
		led2(1)
		led3(0)
    end
	
end

sys.taskInit(function()
    while true do
		led2(0)
		led3(1)
		sys.wait(5000)
    end
end)

--GPIO0配置为中断，可通过getGpio0Fnc()获取输入电平，产生中断时，自动执行gpio0IntFnc函数
button0 = pins.setup(pio.P0_0, button0_int)
	

sys.taskInit(function()
    while true do
        while not socket.isReady() do sys.wait(1000) end
        local mqttc = mqtt.client(misc.getImei(), 300, "user", "password")
        while not mqttc:connect(host, port) do sys.wait(2000) end
		
        if mqttc:subscribe("/1") then
		
            if mqttc:publish("/2", "test publish 321") then
                while true do
                    local r, data, param = mqttc:receive(120000, "pub_msg")
                    if r then
                        log.info( "这是收到了服务器下发的消息:", data.payload or "nil")
						log.info( string.format("%s", data.payload) )
							if data.payload == "11" then
								led2(1)
								led3(0)
							end	
                    else
                        break
                    end
                end
            end
        end
        mqttc:disconnect()
    end
end)


-- 测试代码,用于发送消息给socket
sys.taskInit(function()
    while true do
        sys.publish("pub_msg", "11223344556677889900AABBCCDDEEFF" .. os.time())
        sys.wait(180000)
    end
end)