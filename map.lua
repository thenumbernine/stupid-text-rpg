require 'ext'
require 'vec'
require 'box'

math.randomseed(os.time())

tiletypes = {
	floor = {
		char = '.',
	},
	wall = {
		char = '0',
		solid = true,
	},
}

MapTile = class()

function MapTile:init()
end

function MapTile:isRevealed()
	local visibleTime = -math.log(0)	--50
	return self.lastSeen and (game.time - self.lastSeen) < visibleTime
end

function MapTile:getChar()
	return self.char or self.type.char
end

function MapTile:addEnt(ent)
	if not self.ents then
		self.ents = table()
	end
	self.ents:insert(ent)
end

function MapTile:removeEnt(ent)
	assert(self.ents)
	self.ents:removeObject(ent)
	if #self.ents == 0 then
		self.ents = nil
	end
end

map = {}
map.size = vec2(256,256)
map.bbox = box2(1, map.size)
map.tiles = {}
for i=1,map.size[1] do
	map.tiles[i] = {}
	for j=1,map.size[2] do
		local tile = MapTile()
		tile.type = tiletypes.floor
		map.tiles[i][j] = tile
	end
end

local seeds = table()
for i=1,math.floor(map.size:volume() / 13) do
	local seed = {
		pos = vec2(math.random(map.size[1]), math.random(map.size[2])),
	}
	seed.mins = vec2(table.unpack(seed.pos))
	seed.maxs = vec2(table.unpack(seed.pos))
	
	seeds:insert(seed)
	map.tiles[seed.pos[1]][seed.pos[2]].seed = seed
end

local modified
repeat
	modified = false
	for _,seed in ipairs(seeds) do
		local mins = (seed.mins - 1):clamp(map.bbox)
		local maxs = (seed.maxs + 1):clamp(map.bbox)
		local seedcorners = {seed.mins, seed.maxs}
		local corners = {mins, maxs}
		for i,corner in ipairs(corners) do
			local found

			found = nil
			for y=seed.mins[2],seed.maxs[2] do
				if map.tiles[corner[1]][y].seed then
					found = true
					break
				end
			end
			if not found then
				for y=seed.mins[2],seed.maxs[2] do
					map.tiles[corner[1]][y].seed = seed
				end
				seedcorners[i][1] = corner[1]
				modified = true
			end

			found = nil
			for x=seed.mins[1],seed.maxs[1] do
				if map.tiles[x][corner[2]].seed then
					found = true
					break
				end
			end
			if not found then
				for x=seed.mins[1],seed.maxs[1] do
					map.tiles[x][corner[2]].seed = seed
				end
				seedcorners[i][2] = corner[2]
				modified = true
			end
		end
	end
until not modified

for _,seed in ipairs(seeds) do
	local size = seed.maxs - seed.mins - 1
	if size[1] < 1 then size[1] = 1 end
	if size[2] < 1 then size[2] = 1 end
	local wall = vec2(
		math.random(size[1]) + seed.mins[1],
		math.random(size[2]) + seed.mins[2])

	if seed.mins[2] > 1 then
		for x=seed.mins[1],seed.maxs[1] do
			if x ~= wall[1] then
				map.tiles[x][seed.mins[2]].type = tiletypes.wall
			end
		end
	end
	if seed.mins[1] > 1 then
		for y=seed.mins[2],seed.maxs[2] do
			if y ~= wall[2] then
				map.tiles[seed.mins[1]][y].type = tiletypes.wall
			end
		end
	end
end


for x=1,map.size[1] do
	for y=1,map.size[2] do
		map.tiles[x][y].seed = nil
	end
end

--[[
print('{{')
for x=1,map.size[1] do
	print('\t{')
	for y=1,map.size[2] do
		io.write('\t\t{')
		local heights
		local type
		if map.tiles[x][y].type == tiletypes.wall then
			heights = {3,3,3,3}
			type = 'Stone'
		else
			heights = {1,1,1,1}
			type = 'Brick'
		end
		for _,h in ipairs(heights) do
			io.write(h..', ')
		end
		io.write('base={0, 0, 0, 0}, type="'..type..'"')
		print('},')
	end
	print('\t},')
end
print('}}')
--]]
