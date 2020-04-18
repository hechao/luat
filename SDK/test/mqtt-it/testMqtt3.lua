require "mqtt"
module(..., package.seeall)


local host, port = "iot.electrodragon.com", 1883


sys.taskInit(function()
    while true do
        while not socket.isReady() do sys.wait(1000) end
        local mqttc = mqtt.client(misc.getImei(), 300, "user", "password")
        while not mqttc:connect(host, port) do sys.wait(2000) end
		
        if mqttc:subscribe("/1") then
		
            if mqttc:publish("/2", "test publish 123") then
                while true do
                    local r, data, param = mqttc:receive(120000, "pub_msg")
                    if r then
                        log.info("这是收到了服务器下发的消息:", data.payload or "nil")
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
