require 'treasure'
require 'items'
require 'unit'



Monster = class(Unit)
Monster.wanderIdle = true

function Monster:init(...)
	-- pick a random basetype from start to goblin
--	self.baseType = Unit.baseTypes[math.random(Unit.baseTypes:find(Unit.baseTypes.Goblin))]	-- up to Goblin	
--	self.baseType = Unit.baseTypes[math.random(Unit.baseTypes:find(Unit.baseTypes.Troll))]	-- up to Troll
--	self.baseType = Unit.baseTypes[math.random(#Unit.baseTypes)]		-- all
		-- by weight:
	local smallest
	for _,baseType in ipairs(Unit.baseTypes) do
		local v = -math.log(baseType.weight)
		smallest = math.min(smallest or v, v)
	end	
	local weight = 0
	for _,baseType in ipairs(Unit.baseTypes) do
		weight = weight + (-math.log(baseType.weight) - smallest)
	end
	weight = math.random() * weight
	for _,baseType in ipairs(Unit.baseTypes) do
		weight = weight - (-math.log(baseType.weight) - smallest)
		if weight < 0 then
			self.baseType = baseType
			break
		end
	end
	
	
	self.name = self.baseType.name
	self.char = self.name:sub(1,1)

	Monster.super.init(self, ...)

	self.army.gold = self.army.gold + (math.random(11) - 1) * 10
end
