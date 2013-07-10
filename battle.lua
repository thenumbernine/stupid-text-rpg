require 'ext'

Battle = class()

Battle.radius = 4	-- how far around the pos

function Battle:init(args)
	if args.bbox then
		self.bbox = box2(args.bbox)
	else
		self.pos = vec2(assert(args.pos))
		self.bbox = box2(self.pos - self.radius, self.pos + self.radius):clamp(map.bbox)
	end
	self.armies = table(assert(args.armies))
	self.ents = table()
	for _,army in ipairs(self.armies) do
		for _,ent in ipairs(army.ents) do
			self.ents:insert(ent)
		end
	end
	self.index = 1	-- used for cycling through the ent list
	
	for _,army in ipairs(self.armies) do
		army:beginBattle(self)
	end
	
	-- atm all battles get registered
	battles:insert(self)
	
	for i,ent in ipairs(self.ents) do
		ent:beginBattle(self)
		
		local s = table{'name='..ent.name, 'affil='..tostring(ent.army.affiliation)}
		for _,field in ipairs(Entity.statFields) do
			s:insert(field..'='..ent:stat(field))
		end
		log('Entity '..i..': '..s:concat(', '))
	end
	
	log('starting battle...')
end

function Battle:update()
	while not self.done do

		-- get a new currentEnt
		self:getCurrentEnt()
		
		-- if the next ent is player-driven then break out of the loop and take its turn
		if not self.currentEnt or self.currentEnt.client then break end
		
		-- if it's an enemy then have it go until it's no longer its turn
		if self.currentEnt and not self.currentEnt.client then
			-- run through the AI's turns all at once
			while self.currentEnt do
				self.currentEnt:update()
			end
		end
	end
end

function Battle:removeEnt(ent)
	self.ents:removeObject(ent)
	if self.currentEnt == ent then
		self.index = self.index - 1
		self:endTurn()
	end
end

function Battle:getCurrentEnt()
	if not self.currentEnt then
		-- note that this will lock up if everyone's stopped or something...
		while true do
			-- mind you this will preserve order
			--  however it'll skip turns if an ent gets removed mid-battle
			local ent = self.ents[((self.index - 1) % #self.ents) + 1]
			self.index = (self.index % #self.ents) + 1
			
			ent.ct = math.min(ent.ct + ent:stat('speed'), 100)
			
			-- log(ent.name..' ct is now '..ent.ct)
			
			if ent.ct == 100 then
				self.currentEnt = ent
				ent:beginTurn()
				break
			end
		end
	end
end

function Battle:enemiesOf(ent)
	local enemies = table()
	for _,army in ipairs(self.armies) do
		if army ~= ent.army then 
			for _,enemy in ipairs(army.ents) do
				enemies:insert(enemy)
			end
		end
	end
	return enemies
end

-- called by Entity.endTurn, which the entity calls when it is done
function Battle:endTurn()
	self.currentEnt = nil
	
	local armiesForAffiliation = table()
	for _,army in ipairs(self.armies) do
		local affiliation = army.affiliation or 'nil'
		for _,ent in ipairs(army.ents) do
			if not ent.dead then
				local armies = armiesForAffiliation[affiliation]
				if not armies then
					armies = table()
					armiesForAffiliation[affiliation] = armies
				end
				armies:insert(army)
				break
			end
		end
	end
	
	local affiliationsAlive = armiesForAffiliation:keys()

	if #affiliationsAlive > 1 then return end
	
	-- end battle:
	
	log('ending battle')
	self.currentEnt = nil
	
	self.done = true
	for _,ent in ipairs(self.ents) do
		ent:endBattle()
	end
	for _,army in ipairs(self.armies) do
		army:endBattle(self)
	end
	battles:removeObject(self)
	
	-- revive anyone that was dead
	if #affiliationsAlive == 1 then
		for _,affiliation in ipairs(affiliationsAlive) do
			for _,army in ipairs(armiesForAffiliation[affiliation]) do
				for _,ent in ipairs(army.ents) do
					if ent.dead then ent:setDead(false) end
				end
			end
		end
	end
end
