math.randomseed(os.time())

require 'ext'
require 'map'
require 'player'
require 'monster'
require 'items'
require 'log'
require 'client'
require 'view'

con.init(80,24)

game = {
	time = 0,
	done = false,
	paused = false,
}

-- init globals before we create anything that goes into them
ents = table()
battles = table()

client = Client()
client.army.affiliation = 'good'
Player{pos = (map.size / 2):floor(), army=client.army}

for i=1,math.floor(map.size:volume() / 131) do
	local e = Monster{
		pos = vec2( math.random(map.size[1]), math.random(map.size[2]) ),
		army = Army{affiliation='evil'..math.random(4)},
	}
	map.tiles[e.pos[1]][e.pos[2]].type = tiletypes.floor
end

for i=1,math.floor(map.size:volume() / 262) do
	local e = Treasure{
		pos = vec2( math.random(map.size[1]), math.random(map.size[2]) ),
		gold = math.random(100) + 10,
		army = Army(),
		pickupRandom = true,
	}
	--[[ add crap to chests up front ...
	for i=1,math.random(3) do
		local item = items[math.random(#items)]
		e.army:addItem(item())	-- new instance
	end
	--]]
	map.tiles[e.pos[1]][e.pos[2]].type = tiletypes.floor
end

-- [=[
for i=1,math.floor(map.size:volume() / 500) do
	local e = Player{
		pos = vec2( math.random(map.size[1]), math.random(map.size[2]) ),
		gold = math.random(10),
		army = Army{affiliation='good'},
	}
	map.tiles[e.pos[1]][e.pos[2]].type = tiletypes.floor
end
--]=]


function render()
	
	con.clear()

	if client.army.currentEnt then
		view:update(client.army.currentEnt.pos)
	else
		view:update(client.army.leader.pos)
	end
	
	local v = vec2()
	for i=1,view.size[1] do
		v[1] = view.delta[1] + i
		for j=1,view.size[2] do
			v[2] = view.delta[2] + j
			
			if map.bbox:contains(v) then
				local tile = map.tiles[v[1]][v[2]]
				if tile:isRevealed() then
					con.goto(i,j)
				
					local topEnt
					if tile.ents then	-- we only keep the array if there's something in it
						topEnt = assert(tile.ents[1])
						for k=2,#tile.ents do
							local ent = tile.ents[k]
							if ent.zOrder > topEnt.zOrder then
								topEnt = ent
							end
						end
						
						con.write(topEnt:getChar())
					else
						con.write(tile:getChar())
					end
				else
					con.goto(i,j)
					con.write(' ')
				end
			else
				con.goto(i,j)
				con.write(' ')
			end
		end
		con.clearline()
	end
	
	-- now draw battles
	for _,battle in ipairs(battles) do
		-- adjust to screen coords, expand by one
		local mins = battle.bbox.min - view.delta - 1
		local maxs = battle.bbox.max - view.delta + 1
		-- draw box
		view:drawBorder(box2(mins,maxs))
	end

	local y = 1
	local function printright(s)
		if s then
			con.goto(view.size[1]+2,y)
			con.write(s)
		end
		y = y + 1
	end

	-- TODO all or nothing for client in battle
	if client.army.battle then
		printright('Battle:')
		printright('-------')
		for _,ent in ipairs(client.army.ents) do
			printright('hp '..ent.hp..'/'..ent:stat('hpMax'))
			printright('move '..ent.movesLeft..'/'..ent:stat('move'))
			printright('ct '..ent.ct..'/100')
			printright()
		end
	end
	
	printright('Commands:')
	printright('---------')
	
	if client.cmdstate then
		for k,cmd in pairs(client.cmdstate.cmds) do
			if not (cmd.disabled and cmd.disabled(client, cmd)) then
				printright(k..' = '..cmd.name)
			end
		end
	end
	
	-- client ui render
	for _,state in ipairs(client.cmdstack) do
		if state and state.draw then
			state.draw(client, state)
		end
	end
	if client.cmdstate and client.cmdstate.draw then
		client.cmdstate.draw(client, client.cmdstate)
	end
	
	log:render()
	
	con.draw()
	io.flush()
end

local stupid = {}

function stupid.update()
	if not game.paused then
		for _,ent in ipairs(ents) do
			ent:update()
		end
		
		for _,battle in ipairs(battles) do
			battle:update()
		end
	end
	
	render()
	
	client:update()

	game.time = game.time + 1
end


function stupid.run()
	repeat
		stupid.update()
	until game.done
end

return stupid
