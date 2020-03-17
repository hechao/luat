--- 模块功能：录音功能测试.
-- @author openLuat
-- @module record.testRecord
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

require"record"
require"audio"

--每次读取的录音文件长度
local RCD_READ_UNIT = 1024
--rcdoffset：当前读取的录音文件内容起始位置
--rcdsize：录音文件总长度
--rcdcnt：当前需要读取多少次录音文件，才能全部读取
local rcdoffset,rcdsize,rcdcnt

--[[
函数名：playcb
功能  ：播放录音结束后的回调函数
参数  ：无
返回值：无
]]
local function playcb(r)
    print("playcb",r)
    --删除录音文件
    record.delete()
end

--[[
函数名：readrcd
功能  ：读取录音文件内容
参数  ：无
返回值：无
]]
local function readrcd()    
    local s = record.getData(rcdoffset,RCD_READ_UNIT)
    print("readrcd",rcdoffset,rcdcnt,string.len(s))
    rcdcnt = rcdcnt-1
    --录音文件内容已经全部读取出来
    if rcdcnt<=0 then
        sys.timerStop(readrcd)
        --播放录音内容
        audio.play(0,"RECORD",1,7,playcb)
    --还没有全部读取出来
    else
        rcdoffset = rcdoffset+RCD_READ_UNIT
    end
end

--[[
函数名：rcdcb
功能  ：录音结束后的回调函数
参数  ：
        result：录音结果，true表示成功，false或者nil表示失败
        size：number类型，录音文件的大小，单位是字节，在result为true时才有意义
返回值：无
]]
local function rcdcb(result,size)
    print("rcdcb",result,size)
    if result then
        rcdoffset,rcdsize,rcdcnt = 0,size,(size-1)/RCD_READ_UNIT+1
        sys.timerLoopStart(readrcd,1000)
    end    
end

--5秒后，开始录音
sys.timerStart(record.start,5000,5,rcdcb)
