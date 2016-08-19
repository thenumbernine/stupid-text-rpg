require 'vec'

dirs = {
	'up',
	'down',
	'left',
	'right',
	
	up = vec2(0,-1),
	down = vec2(0,1),
	left = vec2(-1,0),
	right = vec2(1,0),
}


function setFieldsByRange(obj, fields)
	for _,field in ipairs(fields) do
		local range = obj[field..'Range']
		if range then
			local lo, hi = table.unpack(range)
			assert(hi >= lo, "item "..obj.name.." field "..field.." has interval "..tostring(hi)..","..tostring(lo))
			obj[field] = math.random() * (hi - lo) + lo
		end
	end
end


function capitalize(s)
	return s:sub(1,1):upper()..s:sub(2)
end


function serializeTable(obj)
	local lines = table()
	lines:insert('{')
	for _,row in ipairs(obj) do
		local s = table()
		for k,v in pairs(row) do
			if type(k) ~= 'string' then k = '['..k..']' end
--[[
			if k:sub(-5) == 'Range' then
				local baseK = k:sub(1,-6)
				if Entity[baseK] then
					v = v + Entity[baseK]
				end
				v = v:floor()
			end
--]]
			v = ('%q'):format(tostring(v))
			s:insert(k..'='..v)
		end
		lines:insert('\t{'..s:concat('; ')..'};')
	end
	lines:insert('}')
	return lines:concat('\n')
end
