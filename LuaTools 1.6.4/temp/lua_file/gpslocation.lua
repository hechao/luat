local base = _G
module("gpslocation",package.seeall)
local print = base.print
local sfind = string.find
local slen = string.len
local SCK_IDX = 2
local param = {}
function SndToGpsSvr(long,lati,para)
	if not long or not lati or slen(long) <= 0 or slen(lati) <= 0 or long == "0" or lati == "0" then
		print("SndToGpsSvr para err")
		sys.dispatch("GPS_LOCATION_PARSE_IND","",para)
		return false
	end
	param.long = long
	param.lati = lati
	param.para = para
	return linkapp.SckSend(SCK_IDX,"GET /engine/api/regeocoder/json?points="..long..","..lati.."&type=1 HTTP/1.1\r\nHost: api.go2map.com\r\n\r\n",nil,nil,false)
end
function SckGpsRcv(idx,data)
	if idx ~= SCK_IDX or data == nil or data == "" then
		print("SckGpsRcv err",idx,data)
	end
	local d1,d2,addr,prov,dist,city,stat = sfind(data,
		"{\"response\":{\"data\":%[{\"address\":\"(.*)\",\"province\":\"(.*)\",\"pois\":.*,\"district\":\"(.*)\",\"city\":\"(.*)\"}%]},\"status\":\"(.*)\"}")	
	local gbCont = ""
	if d1 ~= nil and d2 ~= nil and stat == "ok" then		
		if prov ~= nil and prov ~= "" then
			gbCont = gbCont..prov
		end
		if city ~= nil and city ~= "" then
			gbCont = gbCont..city
		end
		if dist ~= nil and dist ~= "" then
			gbCont = gbCont..dist
		end
		if addr ~= nil and addr ~= "" then
			gbCont = gbCont..addr
		end		
	end
	print("SckGpsRcv",d1,d2,stat,common.binstohexs(common.gb2312toucs2be(gbCont)))
	sys.dispatch("GPS_LOCATION_PARSE_IND",gbCont,param.para)
	linkapp.SckDisconnect(SCK_IDX)
end
local function SckGpsRsp(idx,evt,result,data)
	if idx ~= SCK_IDX then
		print("SckGpsRsp err",idx)
		return
	end
	print("SckGpsRsp",idx,evt,result)	
end
linkapp.SckCreate(SCK_IDX,linkapp.NORMAL_CAUSE,"TCP","api.go2map.com","80",SckGpsRsp,SckGpsRcv)
