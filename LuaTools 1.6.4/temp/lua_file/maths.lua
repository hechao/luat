
module("maths")

function sqrt(a)
	local x
	if a == 0 or a == 1 then return a end
	x=a/2
	for i=1,100 do
		x=(x+a/x)/2
	end
	return x
end
