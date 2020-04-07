






module(...,package.seeall)
require"cc"
require"audio"





local function connected(num)
log.info("testCall.connected")

cc.sendDtmf("123")

sys.timerStart(audio.play,5000,0,"TTSCC","通话中播放TTS测试",7)

sys.timerStart(cc.hangUp,50000,num)
end



local function disconnected()
log.info("testCall.disconnected")
sys.timerStopAll(cc.hangUp)
end




local function incoming(num)
log.info("testCall.incoming:"..num)

cc.accept(num)
end



local function ready()
log.info("tesCall.ready")

cc.dial("18576608994")
end




local function dtmfDetected(dtmf)
log.info("testCall.dtmfDetected",dtmf)
end


sys.subscribe("CALL_READY",ready)
sys.subscribe("CALL_INCOMING",incoming)
sys.subscribe("CALL_CONNECTED",connected)
sys.subscribe("CALL_DISCONNECTED",disconnected)
cc.dtmfDetect(true)
sys.subscribe("CALL_DTMF_DETECT",dtmfDetected)
