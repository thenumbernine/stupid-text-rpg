require 'entity'

Unit = class(Entity)
Unit.canBattle = true
Unit.name = 'Unit'
Unit.char = 'U'




local sizes = table{
	'tiny',	-- mouse
	'small',	-- cat
	'medium',	-- human
	'large',	-- bull
	'giant',	-- 2x human
	'super',	-- dragon
}

local elements = ([[
water
frost
fire
earth
]]):trim():split('\n')

local modifiers = ([[
mud
great
humanoid
beast
arachnid
demon
undead
bone
magic
were
sea
]]):trim():split('\n')

-- InitRange = range applied to the monster right off the bat
-- LevelUpRange = range applied to the monster on level up
Unit.baseTypes = table{
	{name='Spider', bodyType='arachnid', size='tiny', weight=.1},
	{name='Snake', bodyType='reptile', size='small', weight=.5},
	{name='Lobster', bodyType='crustacean', size='tiny', weight=1},
	{name='Cat', bodyType='beast', size='small', weight=10},
	{name='Blob', bodyType='gelatinous', size='small', weight=10},
	{name='Imp', bodyType='humaniod', size='medium', weight=50},
	{name='Wolf', bodyType='beast', size='medium', weight=85},
	{name='Goblin', bodyType='humaniod', size='medium', weight=120},
	{name='Dwarf', bodyType='humaniod', size='medium', weight=150},
	{name='Human', bodyType='humaniod', size='medium', weight=150},
	{name='Elf', bodyType='humaniod', size='medium', weight=140},
	{name='Zombie', bodyType='humaniod', size='medium', weight=150},
	{name='Troll', bodyType='humanoid', size='medium', weight=250},
	{name='Gargoyle', bodyType='bird', size='large', weight=10000},
	{name='Golem', bodyType='humanoid', size='large', weight=300},
	{name='Ogre', bodyType='humanoid', size='large', weight=300},
	{name='Bull', bodyType='beast', size='large', weight=1000},
	{name='Lion', bodyType='beast', size='large', weight=550},
	{name='Liger', bodyType='beast', size='giant', weight=1800},
	{name='Giant', bodyType='humanoid', size='giant', weight=1500},
	{name='Dragon', bodyType='reptile', size='super', weight=7500},
	{name='T-rex', bodyType='reptile', size='super', weight=15000},
}

for i=1,#Unit.baseTypes do
	local baseType = Unit.baseTypes[i]
	
-- [[ all random
	for _,stat in ipairs(Unit.statFields) do
		if stat ~= 'level'
		and stat ~= 'exp'
		then
			baseType[stat..'Range'] = vec2(
				-math.random() * Unit[stat] * .1,
				math.random() * Unit[stat] * .1
			)
		end
	end
--]]
	
--[[ some order
print()
print(baseType.name)
print('baseType.weight '..baseType.weight)
print('baseType.size '..(sizes:find(baseType.size) - sizes:find('medium')))

	local sizeOffset = assert(sizes:find(baseType.size) - sizes:find('medium'))	-- zero is medium
	
	-- zero is 150lbs, -1 at 120lbs
	-- .1lbs => -33
	-- 15000lbs => 21
	local weightOffset = (math.log(baseType.weight) - math.log(150)) / math.log(1.25) * .1
	
print('weightOffset '..weightOffset)
print('sizeOffset '..sizeOffset)

	local offset = sizeOffset + weightOffset
print('offset '..offset)
	
	baseType.hpMaxRange = vec2(-10, 10) + offset * 20
	baseType.moveRange = vec2(0,2 * math.max(0, offset / 4))
	baseType.speedRange = vec2(-2, 5 - offset)
	baseType.attackRange = vec2(10, 15) + offset * 5	-- 0=>0, -1 => -15, -20 min range :: 0 attack
	baseType.defenseRange = vec2(0, 20 + offset * 10)
	baseType.hitChanceRange = vec2(-25, 25 + offset * 25)
	baseType.evadeRange = vec2(0, 20 + offset * 10)
--]]
	
	for _,baseField in ipairs(Unit.statFields) do
		local rangeField = baseField..'Range'
		if baseType[rangeField] then
			local min = 1 - (Unit[baseField] or 0)
			if baseType[rangeField][1] < min then baseType[rangeField][1] = min end
		end
	end
	
	-- make sure maxs > mins ... set maxs to mins if it is lower
	for _,baseField in ipairs(Unit.statFields) do
		local field = baseField..'Range'
		if baseType[field] then
			if baseType[field][2] < baseType[field][1] then
				baseType[field][2] = baseType[field][1]
			end
		end
	end

	Unit.baseTypes[i] = baseType
	Unit.baseTypes[baseType.name] = baseType
end

--[[ output tables

-- this modifies the table, so don't run this if you're running the rest of the game
local temprangemeta = {
	__tostring = function(v) return v[1] .. ' to ' .. v[2] end,
	__concat = function(a,b) return tostring(a) .. tostring(b) end,
}

print('{')
for _,baseType in ipairs(Unit.baseTypes) do
	local s = table()
	for k,v in pairs(baseType) do
		if k:sub(-5) == 'Range' then
			local baseK = k:sub(1,-6)
			if Entity[baseK] then
				v = v + Entity[baseK]
			end
			v = v:floor()
		end
		if getmetatable(v) == vec2 then setmetatable(v, temprangemeta) end
		v = ('%q'):format(tostring(v))
		s:insert(k..'='..v)
	end
	print('{'..s:concat('; ')..'};')
end
print('}')
os.exit()

--]]



function Unit:init(args)
	-- modify init ranges by basetype
	-- NOTICE this goes by self[field] rather than self[field..'Range']
	-- which is cool cuz I'm not using [field..'Range'] in any of the monster Entity subclasses
	if self.baseType then
		for _,baseField in ipairs(self.statFields) do
			local field = baseField..'Range'
			if self[field] or self.baseType[field] then
				self[field] = vec2(self[baseField] or 0) + vec2(self.baseType[field] or 0)
			end
		end
	end
	
	Unit.super.init(self, args)
	
	--[[
	for _,field in ipairs(self.equipFields) do
		local possibleEquips = table()
		for _,itemType in ipairs(items) do
			if itemType.equip == field then
				for j=1,2 do
					possibleEquips:insert(itemType())
				end
			end
		end
		local equip = possibleEquips[math.random(#possibleEquips+1)]
		self[field] = equip
		self.army:addItem(equip)
	end
	--]]
end

function Unit:update()
	Unit.super.update(self)
	if self.dead then return end
	
	if not self.client then
		if self.battle then
			if self.battle.currentEnt == self then
				local pathsForEnemies = table()
				for _,enemy in ipairs(self.battle:enemiesOf(self)) do
					if not enemy.dead
					and enemy.army.affiliation ~= self.army.affiliation
					then
						local path, dist = pathSearchToPoint{
							src=self.pos,
							dst=enemy.pos,
							bbox=self.battle.bbox,
							entBlocking = function(ent)
								return ent.solid and ent.army.affiliation ~= self.army.affiliation
							end,
						}
						pathsForEnemies:insert{
							enemy = enemy,
							path = path,
						}
					end
				end
				if #pathsForEnemies == 0 then
					self:endTurn()
					return
				end
				pathsForEnemies:sort(function(a,b) return #a.path < #b.path end)
				local path = pathsForEnemies[1].path
				if path then
					if #path > 1 then
						self:walk(path:remove(1).dir)
					end
					if #path == 1 then
						self:attackDir(path:remove(1).dir)
					end
					if self.acted or self.movesLeft == 0 or #path == 0 then
						self:endTurn()
					end
				else
					log("*** failed to find path ***")
					self:endTurn()
				end
			end
		else
			if self.wanderIdle and math.random(4) == 4 then
				self:walk(dirs[math.random(#dirs)])
			end
		end	
	
	-- client-driven
	else
		if not self.battle then
			-- if we're not the leader then follow the next guy in line
			if self.army.leader ~= self then
				local i = self.army.ents:find(self)
				assert(i > 1)
				local followme = assert(self.army.ents[i-1])
				-- now do pathfinding 
				
				-- TODO A* ... so we don't have to search so far
				local followBox = box2(self.pos)
				followBox:stretch(followme.pos)
				followBox.min = followBox.min - 5
				followBox.max = followBox.max + 5
				
				local path, dist = pathSearchToPoint{
					src = self.pos,
					dst = followme.pos,		--lastpos
					bbox = followBox,
					entBlocking = function(ent)
						return ent.solid and ent.army.affiliation ~= self.army.affiliation
					end,
				}
				if #path > 1 then
					self:walk(path:remove(1).dir)
				end
			end
		
			-- auto pick up items we walk over
			local getEnts = entsAtPos(self.pos)
			if getEnts then
				for _,ent in ipairs(getEnts) do
					if ent.get then
						ent:get(self)
					end
				end
			end
		end
		
		self:checkBattle()
		self:updateFog()
	end
end

function Unit:updateFog()
	local radius = 4
	local fogTiles = floodFillTiles(self.pos, box2(self.pos - radius, self.pos + radius))
	for _,pos in ipairs(fogTiles) do
		for _,dir in ipairs(dirs) do
			local ofspos = (dirs[dir] + pos):clamp(map.bbox)			
			map.tiles[ofspos[1]][ofspos[2]].lastSeen = game.time
		end
	end
end

function Unit:checkBattle()
	if self.battle then return end
	
	local searchRadius = 3
	local closeEnts = entsAtPositions(floodFillTiles(self.pos, box2(self.pos-searchRadius,self.pos+searchRadius)))
	closeEnts = closeEnts:filter(function(ent)
		return ent.canBattle
			and not ent.dead
			and ent.army.affiliation ~= self.army.affiliation
	end)
	if #closeEnts > 0 then
	
		local battleBox = box2(self.pos - Battle.radius, self.pos + Battle.radius)
		local armies = table()
		local battlePositions
		
		while true do
			battlePositions = floodFillTiles(self.pos, battleBox)
		
			-- if we're into battle then include anything in a 4-unit radius
			local battleEnts = entsAtPositions(battlePositions):filter(function(ent)
				return ent.canBattle and not ent.dead
			end)
			
			-- stretch border too
			local stretchedBBox
			armies = table()
			for _,ent in ipairs(battleEnts) do
				armies:insertUnique(ent.army)
				if not stretchedBBox then
					stretchedBBox = box2(ent.pos, ent.pos)
				else
					stretchedBBox:stretch(ent.pos)
				end
			end
			
			local size = stretchedBBox:size()
			for i=1,2 do
				local width = 2 * Battle.radius + 1
				if size[i] < width then
					local diff = width - size[i]
					size[i] = width
					stretchedBBox.min[i] = stretchedBBox.min[i] - math.floor(diff / 2)
					stretchedBBox.max[i] = stretchedBBox.max[i] + math.ceil(diff / 2)
				end
			end
			
			-- if we stretched outside the battle box bounds
			if not battleBox:contains(stretchedBBox) then
				battleBox:stretch(stretchedBBox)
			else
			--otherwise use this size
				break
			end
		end
		
		-- TODO re-include all ents in the box, then re-stretch the box, and keep going?
		-- or TODO better borders on the battle, and don't use boxes (just collect valid floor tiles)
		
		Battle{armies=armies, bbox=battleBox}
		
		-- make all battle tiles visible
		for _,pos in ipairs(battlePositions) do
			for _,dir in ipairs(dirs) do
				local ofspos = (dirs[dir] + pos):clamp(map.bbox)
				map.tiles[ofspos[1]][ofspos[2]].lastSeen = game.time
			end
		end
	end
end

function Unit:die()
	Unit.super.die(self)
	
	local lastToDie = true
	for _,ent in ipairs(self.army.ents) do
		if ent ~= self and not ent.dead then
			lastToDie = false
			break
		end
	end
	
	local t = Treasure{
		pos = self.pos,
		army = Army(),
	}
	
	if lastToDie then
		t.army.gold = self.army.gold
		self.army.gold = 0
	end
	
	for _,equip in ipairs(self.equipFields) do
		local item = self[equip]
		if item then
			self.army:removeItem(item)	-- also disequips from self
			t.army:addItem(item)	-- should we take all items?
		end
	end
	
	-- or just only for monsters?  'dropItemsOnDeath' ?
	if lastToDie then
		for i=#self.army.items,1,-1 do
			local item = self.army.items[i]
			self.army:removeItem(item)
			t.army:addItem(item)	-- should we take all items?
		end
	end
end
