require 'ext'


local function getvalue(x, dim)
	if type(x) == 'number' then return x end
	if type(x) == 'table' then
		x = x[dim]
		if type(x) ~= 'number' then
			error("expected a table of numbers, got a table with index "..dim.." of "..type(x))
		end
		return x
	end
	error("tried to getvalue from an unknown type "..type(x))
end


vec2 = class()
vec2.dim = 2

function vec2:init(x,y)
	if x then
		self:set(x,y)
	else
		self:set(0,0)
	end
end

function vec2:set(x,y)
	if type(x) == 'table' then
		self[1] = assert(x[1])
		self[2] = assert(x[2])
	else
		self[1] = assert(x)
		if y then
			self[2] = assert(y)
		else
			self[2] = x
		end
	end
end

function vec2:volume()
	local v = 1
	for i=1,self.dim do
		v = v * self[i]
	end
	return v
end

-- inplace
function vec2:clamp(a, b)
	local mins = a
	local maxs = b
	if type(a) == 'table' and a.min and a.max then	
		mins = a.min
		maxs = a.max
		-- assertion for table-based params
		assert(mins)
		assert(maxs)
	else	-- assertion for param-based mins & maxs
		assert(mins)
		assert(maxs)
	end
	for i=1,self.dim do
		self[i] = math.clamp(self[i], getvalue(mins, i), getvalue(maxs, i))
	end
	return self
end

-- inplace
function vec2:floor()
	for i=1,self.dim do
		self[i] = math.floor(self[i])
	end
	return self
end

-- inplace
function vec2:ceil()
	for i=1,self.dim do
		self[i] = math.ceil(self[i])
	end
	return self
end

-- returns the x abs + y abs
function vec2.l1Length(v)
	local d = 0
	for i=1,v.dim do
		d = d + math.abs(v[i])
	end
	return d
end

-- returns the max abs
function vec2.lInfLength(v)
	local d = 0
	for i=1,v.dim do
		d = math.max(d, math.abs(v[i]))
	end
	return d
end


function vec2.__add(a,b)
	local c = vec2()
	for i=1,a.dim do
		c[i] = getvalue(a,i) + getvalue(b,i)
	end
	return c
end

function vec2.__sub(a,b)
	local c = vec2()
	for i=1,a.dim do
		c[i] = getvalue(a,i) - getvalue(b,i)
	end
	return c
end

function vec2.__mul(a,b)
	local c = vec2()
	for i=1,a.dim do
		c[i] = getvalue(a,i) * getvalue(b,i)
	end
	return c
end

function vec2.__div(a,b)
	local c = vec2()
	for i=1,a.dim do
		c[i] = getvalue(a,i) / getvalue(b,i)
	end
	return c
end

function vec2.__eq(a,b)
	for i=1,a.dim do
		if a[i] ~= b[i] then return false end
	end
	return true
end

function vec2.__tostring(v)
	return v[1]..','..v[2]
end

function vec2.__concat(a,b)
	return tostring(a)..tostring(b)
end
