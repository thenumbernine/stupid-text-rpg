require 'ext'

Army = class()
Army.gold = 0

function Army:init(args)
	if args then
		self.affiliation = args.affiliation
	end
	self.ents = table()
	self.items = table()
end

--[[
ents, items, and armies ...
armies have all items, including those that ents link to for equipment
if an army disbands an ent, they lose all equipment
if they are added, make sure they're disbanded from where they came from first
 then claim their equipment as ours
--]]

function Army:addEnt(ent)
	if ent.army then
		ent.army:removeEnt(ent)
	end
	
	-- now that we know the ent has no army (and therefore any items it has that another army had are disequipped)
	--  lets add its equipment
	for _,field in ipairs(ent.equipFields) do
		if ent[field] then
			self:addItem(ent[field])
		end
	end
	
	ent.army = self
	self.ents:insert(ent)
	
	if not self.leader then
		self.leader = ent
	end
end

function Army:removeEnt(ent)
	assert(self.ents:find(ent))
	self.ents:removeObject(ent)
	-- remove all items from inventory upon disbanding
	for _,field in ipairs(ent.equipFields) do
		local item = ent[field]
		-- do this after the ent is out of the list so the item doesn't get disequipped from the ent
		if item then self:removeItem(item) end
	end
	if ent == self.leader then
		self.leader = self.ents[1]
	end
end

function Army:deleteAll()
	assert(not self.battle, "i don't have deleting armies mid-battle done yet")
	for i=#self.ents,1,-1 do
		self.ents[i]:delete()
	end
end

function Army:addItem(item)
	self.items:insert(item)
end

-- disequips the item from any ent in the army and removes it from the army item list
function Army:removeItem(item)
	-- make sure it isn't anything equipped ...
	for _,ent in ipairs(self.ents) do
		for _,field in ipairs(ent.equipFields) do
			if ent[field] == item then
				ent[field] = nil
			end
		end
	end

	self.items:removeObject(item)
end

-- add an entire army
function Army:addArmy(army)
	assert(army ~= self)
	for _,ent in ipairs(army.ents) do
		self:addEnt(ent)
	end
	for i=#army.items,1,-1 do
		local item = army.items[i]
		self:addItem(item)
		army.items:remove(i)
	end
end

function Army:beginBattle(battle)
	self.battle = battle
end

function Army:endBattle()
	self.battle = nil
end



ClientArmy = class(Army)

function ClientArmy:init(client)
	ClientArmy.super.init(self)
	self.client = client
end

function ClientArmy:addEnt(ent)
	ClientArmy.super.addEnt(self, ent)
	ent.client = client
end

function ClientArmy:removeEnt(ent)
	ClientArmy.super.removeEnt(self, ent)
	ent.client = nil
end

function ClientArmy:beginBattle(battle)
	ClientArmy.super.beginBattle(self, battle)

	self.client:removeToState(Client.mainCmdState)
	self.client:pushState(Client.battleCmdState)
end

function ClientArmy:endBattle(battle)
	ClientArmy.super.endBattle(self, battle)

	assert(self.client.cmdstate == Client.battleCmdState, "expected client cmdstate to be battleCmdState")
	self.client:popState()
end