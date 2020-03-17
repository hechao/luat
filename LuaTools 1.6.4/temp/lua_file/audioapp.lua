module(...,package.seeall)
CALL_RING,TTS = 1,2
RECEIVER,LOUDSPEAKER,AUDIO_VOL_MAX_LEV = audiocore.DUMMY_AUX_LOUDSPEAKER,audiocore.AUX_LOUDSPEAKER,7
local audTyp,audPath,audDup,audVol,audCb,audPara
local function Reset()
	audTyp,audPath,audDup,audVol,audCb,audPara = nil
end
local function PlayFun(chan)
	if audTyp ~= TTS and audio.play(audPath) then
		print("PlayFun",audTyp,audPath,audDup)
		return true
	elseif audTyp == TTS then
		audio.playtts(audPath)
	else
		SetChannel(RECEIVER,false)
		Reset()
		return false
	end	
end
local function PlayEnd()
	print("PlayEnd",audTyp,audPath,audDup)
	if audTyp == TTS then
		audio.stoptts()
	end
	if audDup then
		if audCb then
			audCb(true,audPara)
		end
		Play(audTyp,audPath,audDup,audVol,audCb,audPara)		
	else
		audTyp,audPath,audVol = nil		
		SetChannel(RECEIVER,false)
		if audCb then
			audCb(true,audPara)
			audCb,audPara = nil			
		end
	end
end
local function PlayError()
	if audTyp == TTS then
		audio.stoptts()
	end 
	SetChannel(RECEIVER,false)
	audTyp,audPath,audDup,audVol = nil	
	if audCb then
		audCb(false,audPara)
		audCb,audPara = nil		
	end	
end
local audioApp =
{
	AUDIO_PLAY_END_IND = PlayEnd,
	AUDIO_PLAY_ERROR_IND = PlayError,
}
function Play(typ,name,dup,vol,cb,para)
	if typ == CALL_RING and audTyp ~= typ and audTyp then
		print("audio conflict1")
		Stop()
		return false
	end
	if audTyp and not dup then
		print("audio conflict2")
		return false
	end	
	audTyp,audPath,audDup,audVol,audCb,audPara = typ,name,dup,vol,cb,para
	SetChannel(LOUDSPEAKER,false,vol,PlayFun)
	return true
end
function Stop()
	print("Stop",audTyp)
	SetChannel(RECEIVER,false)
	if audTyp == TTS then
		audio.stoptts()
	else
		audio.stop()
	end	
	Reset()
	sys.dispatch("AUDIOAPP_STOP")	
end
function GetChannel()
	return audio.getaudiochannel() or LOUDSPEAKER
end
function SetChannel(chanel,mic,vol,cb)
	if chanel == RECEIVER or chanel == LOUDSPEAKER then
		audio.setaudiochannel(chanel)
		if vol then audio.setspeakervol(vol) end
		if mic then audio.setmicrophonegain(audiocore.MIC_VOL15) end
		if cb then cb(GetChannel()) end
		return true
	end
end
sys.regapp(audioApp)
