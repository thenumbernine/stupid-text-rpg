require 'entity'

Treasure = class(Entity)
Treasure.name = 'Treasure'
Treasure.char = '$'
Treasure.solid = false
Treasure.attackable = false
Treasure.zOrder = -.5	-- above bodies, below solids

function Treasure:init(args)
	Treasure.super.init(self, args)
	if args.gold then
		self.army.gold = self.army.gold + tonumber(args.gold)
	end
	self.pickupRandom = args.pickupRandom
end

function Treasure:get(who)
	-- [[ add crap to chests upon pickup (based on the getter's level)
	if self.pickupRandom then
		for i=1,math.random(3) do
			local item = items[math.random(#items)]
			self.army:addItem(item(who.level))	-- new instance
		end
	end
	--]]


	local gottext = table()
	if #self.army.items > 0 then
		gottext:insert(self.army.items:map(function(item) return item.name end):concat(', '))
	end
	if self.army.gold > 0 then
		gottext:insert(self.army.gold..' gold')
	end
	if #gottext > 0 then
		log(who.name..' got '..gottext:concat(', '))
	end
	for _,item in ipairs(self.army.items) do
		who.army:addItem(item)
	end
	who.army.gold = who.army.gold + self.army.gold
	self.army:deleteAll()	-- one "correct" way to remove the last ent from an army
end
