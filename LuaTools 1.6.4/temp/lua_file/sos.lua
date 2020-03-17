module(...,package.seeall)
local function soslocrpt()
	linkrx.sosloc()
	linkair.sosloc()
end
local function keylngpresind()
	gpsapp.open(gpsapp.OPEN_TIMERORSUC,{cause="SOS",val=120,cb=soslocrpt})
	return true
end
local function keylocrpt()
	linkrx.keyloc()
	linkair.keyloc()
end
local function keyind()
	gpsapp.open(gpsapp.OPEN_TIMERORSUC,{cause="KEY",val=120,cb=keylocrpt})
	return true
end
local procer = {
	MMI_KEYPAD_LONGPRESS_IND = keylngpresind,
	MMI_KEYPAD_IND = keyind,
}
sys.regapp(procer)
