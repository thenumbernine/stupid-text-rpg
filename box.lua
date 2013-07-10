require 'ext'

local function getminvalue(x)
	if x.min then return x.min end
	assert(x ~= nil, "getminvalue got nil value")
	return x
end

local function getmaxvalue(x)
	if x.max then return x.max end
	assert(x ~= nil, "getmaxvalue got nil value")
	return x
end


box2 = class()
box2.dim = 2

function box2:init(a,b)
	if type(a) == 'table' and a.min and a.max then
		self.min = vec2(a.min)
		self.max = vec2(a.max)
	else
		self.min = vec2(a)
		self.max = vec2(b)
	end
end

-- inplace
function box2:stretch(v)
	if getmetatable(v) == box2 then
		self:stretch(v.min)
		self:stretch(v.max)
	else
		for i=1,self.dim do
			self.min[i] = math.min(self.min[i], v[i])
			self.max[i] = math.max(self.max[i], v[i])
		end
	end
end

function box2:size()
	return self.max - self.min
end

-- inplace
function box2:floor()
	self.min:floor()
	self.max:floor()
	return self
end

-- inplace
function box2:ceil()
	self.min:ceil()
	self.max:ceil()
	return self
end

-- inplace
function box2:clamp(b)
	self.min:clamp(b)
	self.max:clamp(b)
	return self
end

-- inclusive
function box2:contains(v)
	if getmetatable(v) == box2 then
		return self:contains(v.min) and self:contains(v.max)
	else
		for i=1,v.dim do
			local x = v[i]
			if x < self.min[i] or x > self.max[i] then
				return false
			end
		end
		return true
	end
end


function box2:map(coordBox)
	local size = self:size()
	
	return coordBox * size + self.min		-- TODO one set of operators for everything?  so order doesn't change which call is made...
end

function box2.__add(a,b)
	return box2(
		getminvalue(a) + getminvalue(b),
		getmaxvalue(a) + getmaxvalue(b))
end

function box2.__sub(a,b)
	return box2(
		getminvalue(a) - getminvalue(b),
		getmaxvalue(a) - getmaxvalue(b))
end

function box2.__mul(a,b)
	return box2(
		getminvalue(a) * getminvalue(b),
		getmaxvalue(a) * getmaxvalue(b))
end

function box2.__div(a,b)
	return box2(
		getminvalue(a) / getminvalue(b),
		getmaxvalue(a) / getmaxvalue(b))
end


function box2.__tostring(b)
	return b.min..'..'..b.max
end

function box2.__concat(a,b)
	return tostring(a)..tostring(b)
end
