require 'ext'
require 'util'
require 'battle'

function entsAtPos(pos)
	if not map.bbox:contains(pos) then return table() end	
	return table(map.tiles[pos[1]][pos[2]].ents)
end

function entsAtPositions(positions)
	local es = table()
	for _,pos in ipairs(positions) do
		es:append(entsAtPos(pos))
	end
	return es
end

function entsWithinRadius(pos, radius)
	assert(pos)
	assert(radius)
	local mins = (pos - radius):clamp(map.bbox)
	local maxs = (pos + radius):clamp(map.bbox)
	
	local closeEnts = table()
	for x=mins[1],maxs[1] do
		for y=mins[2],maxs[2] do
			closeEnts:append(entsAtPos(vec2(x,y)))
		end
	end
	return closeEnts
end

-- returns an array of tiles within the l-inf distance from the radius
function floodFillTiles(pos, bbox)
	bbox = box2(bbox):clamp(map.bbox)	-- make sure it's in the map
	pos = vec2(table.unpack(pos))
	local positions = table{pos}
	local allpositionset = table()
	allpositionset[tostring(pos)] = true
	while #positions > 0 do
		local srcpos = positions:remove(1)
		for _,dir in ipairs(dirs) do
			local newpos = srcpos + dirs[dir]
			if bbox:contains(newpos)
			then
				local tile = map.tiles[newpos[1]][newpos[2]]
				if not tile.type.solid then
					if not allpositionset[tostring(newpos)]
					then
						positions:insert(newpos)
						allpositionset[tostring(newpos)] = true
					end
				end
			end
		end
	end
	return allpositionset:keys():map(function(v)
		return vec2(table.unpack(v:split(','):map(function(x) return tonumber(x) end)))
	end)
end

--[[
- starts at 'start', searches to 'dest'
- search is restricted to 'bbox'
- search is blocked by solid entities
args:
	start = where we start
	dest = where we're going
	bbox = bounding box
	entBlocking = callback to determine whether an ent is blocking the path or not

TODO: an option to use A* and just give the best option available (rather than "right" or "none")
--]]
function pathSearchToPoint(args)
	local bbox = assert(args.bbox)
	local start = assert(args.src)
	local dest = assert(args.dst)
	local entBlocking = args.entBlocking
	
	assert(bbox:contains(start))
	assert(bbox:contains(dest))
	
	local states = table{
		{pos = vec2(table.unpack(start))}
	}
	local allpositions = table()
	allpositions[tostring(vec2(table.unpack(start)))] = true

	local bestState
	local bestDist
	while bestDist ~= 0 and #states > 0 do
		local laststate = states:remove(1)
		for _,dir in ipairs(dirs) do
			local newstate = {
				pos = laststate.pos + dirs[dir],
				laststate = laststate,
				dir = dir,
			}
			local dist = (newstate.pos - dest):l1Length()
			if not bestDist or dist < bestDist then
				bestDist = dist
				bestState = newstate
				if bestDist == 0 then break end
			end
			if bbox:contains(newstate.pos)
			and map.bbox:contains(newstate.pos)
			then
				local tile = map.tiles[newstate.pos[1]][newstate.pos[2]]
				if not tile.type.solid then
					local blocked
					if tile.ents then
						for _,ent in ipairs(tile.ents) do
							if entBlocking(ent) then
								blocked = true
								break
							end
						end
					end				
					if not blocked
					and not allpositions[tostring(newstate.pos)]
					then
						states:insert(newstate)
						allpositions[tostring(newstate.pos)] = true
					end
				end
			end
		end
	end

	local path
	if bestState then
		path = table()
		local state = bestState
		while state do
			path:insert(1, state)
			state = state.laststate
		end
		-- path[i] will have the dir that path[i-1] has to go ...
		for i=1,#path-1 do
			path[i].dir = path[i+1].dir
		end
		path[#path].dir = nil
		path:remove()	-- now remove the last state
	end
	return path, bestDist
end


Entity = class()
Entity.name = 'Entity'
Entity.ct = 0

Entity.level = 1	-- start at zero, compute level-ups from there
Entity.exp = 0

Entity.hpMax = 50
Entity.move = 3.5
Entity.speed = 7
Entity.attack = 10
Entity.defense = 10
Entity.hitChance = 75
Entity.evade = 5

Entity.speedLevelUpRange = {0, .1}
Entity.attackLevelUpRange = {0, 1}
Entity.defenseLevelUpRange = {0, 1}
Entity.hitChanceLevelUpRange = {0, 1}
Entity.evadeLevelUpRange = {0,1}

Entity.solid = true
Entity.attackable = true
Entity.zOrder = 0
Entity.char = '?'

Entity.statFields = {
	'level',
	'exp',
	'hpMax',
	'move',
	'speed',
	'attack',
	'defense',
	'hitChance',
	'evade',
}

Entity.equipFields = {
	'weapon',
	'shield',
	'armor',
	'helmet',
}


function Entity:init(args)
	assert(args.pos)
	self.pos = vec2()
	self.lastpos = vec2()	-- something for trailing players...
	self:setPos(assert(args.pos))

	-- prep stats by init ranges
	setFieldsByRange(self, self.statFields)
	
	-- atm all ents get registered
	ents:insert(self)
	
	-- atm everyone has an army ...
	-- units need it for battles
	-- treasure chests need it for items
	assert(args.army):addEnt(self)
	
	self.hp = self:stat('hpMax')
end

function Entity:delete()
	self:setTile(nil)
	if self.army then self.army:removeEnt(self) end
	ents:removeObject(self)
	for _,battle in ipairs(battles) do
		battle:removeEnt(self)
	end
end

function Entity:addExp(exp)
	assert(exp)
	exp = math.floor(exp)
	log(self.name..' got '..exp..' experience')
	self.exp = self.exp + exp
	local oldLevel = self.level
	self.level = 10 * math.log(self.exp + 1) / math.log(1.1) + 1
	if math.floor(self.level) > math.floor(oldLevel) then
		for level = math.floor(oldLevel) + 1, math.floor(self.level) do
			for _,field in ipairs(self.equipFields) do
				local range = self[field..'LevelUpRange']
				if range then
					local lo, hi = table.unpack(range)
					assert(hi >= lo, "item "..obj.name.." field "..field.." has interval "..tostring(hi)..","..tostring(lo))
					self[field] = math.random() * (hi - lo) + lo
				end
			end
		end
		log(self.name..' is now at level '..math.floor(self.level))
	end
end

function Entity:getChar()
	local char = self.char
	if self.dead then char = 'd' end
	return char
end

function Entity:setPos(pos)
	assert(pos)
	self:setTile(nil)
	self.lastpos:set(self.pos)
	self.pos:set(pos)
	if map.bbox:contains(self.pos) then
		self:setTile(map.tiles[self.pos[1]][self.pos[2]])
	end
end

function Entity:setTile(tile)
	if self.tile then
		self.tile:removeEnt(self)
	end
	self.tile = tile
	if self.tile then
		self.tile:addEnt(self)
	end
end

function Entity:update()
	if self.dead then
		if self.battle and self.battle.currentEnt == self then
			self:endTurn()
		end
		return
	end
end

function Entity:setDead(dead)
	self.dead = dead
	-- TODO function to override behavior?
	self.attackable = not dead
	self:setSolid(not dead)
end

function Entity:setSolid(solid)
	self.solid = solid
	if not self.solid then
		self.zOrder = -1
	else
		self.zOrder = nil	-- default
	end
end

function Entity:walk(dir)
	if self.dead then return end
	
	-- if we're in battle mode then no moving unless we're the current ent
	if self.battle then
		if self.battle.currentEnt ~= self then
			return
		else
			-- in case we start a turn with zero moves to go
			if self.movesLeft <= 0 then
				return
			end
		end
	end

	local newpos = self.pos + assert(dirs[dir], "failed to find dir "..tostring(dir))
	
	if self.battle then
		newpos:clamp(self.battle.bbox)
	else
		-- make sure we're not in any other battles' ranges
		for _,battle in ipairs(battles) do
			if battle.bbox:contains(newpos) then
				return
			end
		end
	end
	newpos:clamp(map.bbox)

	local tiletype = map.tiles[newpos[1]][newpos[2]].type
	if tiletype.solid then return end
	
	for _,ent in ipairs(entsAtPos(newpos)) do
		if ent.army.affiliation ~= self.army.affiliation
		and ent.solid
		then
			return
		end
	end

	self:setPos(newpos)
	
	--if self.battle then log(self.name..' walked '..dir) end
	
	-- if we're in battle mode and we did move
	if self.battle then
		assert(self.battle.currentEnt == self)
		self.movesLeft = self.movesLeft - 1
	end
	
	return true	-- true means we did move
end

function Entity:beginBattle(battle)
	self.battle = battle
	self.ct = 0
	self.hp = self:stat('hpMax')
	self.movesLeft = 0
end

function Entity:endBattle()
	self.battle = nil
end

function Entity:beginTurn()
	self.ct = 100
	self.movesLeft = self:stat('move')
	self.turnStartPos = vec2(table.unpack(self.pos))
	self.acted = false
	self.army.currentEnt = self
end

function Entity:endTurn()
	assert(self.battle)
	assert(self.battle.currentEnt == self)
	self.army.currentEnt = nil

	self.ct = 0
	if self.movesLeft == self:stat('move') then
		self.ct = self.ct + 20
	end
	if not self.acted then
		self.ct = self.ct + 20
	end
	
	self.battle:endTurn()
end

function Entity:stat(field)
	assert(table.find(self.statFields, field))
	local value = self[field]
	assert(type(value) == 'number', "expected stat "..field.." to be a number, but got "..type(value))
	local equipSources = table()

	-- use job as a source
	if self.job then equipSources:insert(self.job) end

	-- use equipment as a source
	for _,equipField in ipairs(self.equipFields) do
		local equip = self[equipField]
		if equip then equipSources:insert(equip) end
	end

	-- accumulate from sources
	for _,src in ipairs(equipSources) do
		local equipValue = src[field]
		if equipValue then
			assert(type(equipValue) == 'number', "expected equipment "..equipValue.." stat "..field.." to be a number, but got "..type(equipValue))
			value = value + equipValue
		end
	end
	
	return math.floor(value)
end

function Entity:attackDir(dir)
	self.acted = true
	-- if you attacked mid-move then stop any further moves
	if self.movesLeft ~= self:stat('move') then self.movesLeft = 0 end

	assert(self.battle)
	assert(self.battle.currentEnt == self)

	local newpos = self.pos + dirs[dir]
	newpos:clamp(self.battle.bbox)
	
	for _,other in ipairs(entsAtPos(newpos)) do
		if other.attackable then
			self:attackTarget(other)
		end
	end
end

function Entity:attackTarget(target)
	local hitChance = math.clamp(self:stat('hitChance') - target:stat('evade'), 5, 100)
	log(self.name..' attacks '..target.name..' with a '..hitChance..'% chance to hit')
	
	if math.random(100) > hitChance then
		log('...miss')
		return
	end
	local defense = target:stat('defense') - .5 * self:stat('attack')
	defense = 1 - math.clamp(defense, 0, 95) / 100
	local dmg = math.ceil(self:stat('attack') * defense)
	target:takeDamage(dmg, self)
end

function Entity:getExpGiven()
	return self.level
end

function Entity:takeDamage(dmg, inflicter)
	self.hp = math.max(self.hp - dmg, 0)
	log(self.name..' receives '..dmg..' dmg and is at '..self.hp..' hp')
	if self.hp == 0 then
		log(self.name..' is dead')

		-- where should we get exp?  per turn? per kill? per battle? mix and match?
		inflicter:addExp(self:getExpGiven())

		self:die()
	end
end

function Entity:die()
	self:setDead(true)
end

