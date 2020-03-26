





module(..., package.seeall)










local tags = {}

local flag = true





function wake(tag)
assert(tag and tag ~= nil, "pm.wake tag invalid")

tags[tag] = 1

if flag == true then

flag = false

pmd.sleep(0)
end
end




function sleep(tag)
assert(tag and tag ~= nil, "pm.sleep tag invalid")

tags[tag] = 0

for k, v in pairs(tags) do
if v > 0 then
return
end
end
flag = true

pmd.sleep(1)
end







function isSleep(tag)
return tag and tags[tag] ~= 1 or flag
end
