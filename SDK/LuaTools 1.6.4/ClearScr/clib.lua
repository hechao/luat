





local uartReceiveCallbacks = {}
local uartSentCallbacks = {}











uart.on = function(id, event, callback)
if event == "receive" then
uartReceiveCallbacks[id] = callback
elseif event == "sent" then
uartSentCallbacks[id] = callback
end
end

rtos.on(rtos.MSG_UART_RXDATA, function(id, length)
if uartReceiveCallbacks[id] then
uartReceiveCallbacks[id](id, length)
end
end)

rtos.on(rtos.MSG_UART_TX_DONE, function(id)
if uartSentCallbacks[id] then
uartSentCallbacks[id](id)
end
end)
