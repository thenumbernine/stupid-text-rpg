require 'army'
require 'view'
require 'con'

--[[
TODO
move cmdstate stuff into here
--]]


Client = class()
Client.maxArmySize = 4

-- windows

WindowLine = class()
WindowLine.text = ''

--[[
args:
	text = what is shown
	cantSelect = whether this can be selected
	onSelect = what happens when the user selects this
--]]
function WindowLine:init(args)
	if type(args) == 'string' then args = {text=args} end
	self.text = args.text
	self.cantSelect = args.cantSelect
	self.onSelect = args.onSelect
end


Window = class()

--[[
args:
	lines = initial lines to use
	pos = initial pos (1,1 default)
	size = initial size (0,0 default)
	fixed = whether size is fixed
--]]
function Window:init(args)
	self.fixed = args.fixed
	self.currentLine = 1
	self.firstLine = 1		-- first visible line
	self.pos = vec2(args.pos or {1,1})
	self.size = vec2(args.size or {1,1})
	self:refreshBorder()
	self:setLines(args.lines or {})
end

function Window:setPos(pos)
	self.pos:set(assert(pos))
	self:refreshBorder()
end

function Window:refreshBorder()
	self.border = box2(self.pos, self.pos + self.size - 1)
end

--[[
sets the text to a list of lines
lines are either a string or a WindowLine object
--]]
function Window:setLines(lines)
	-- make sure to instanciate each line as a WindowLine object
	self.lines = table.map(lines, function(line)
		return (WindowLine(line))
	end)
	
	self.textWidth = 0
	self.selectableLines = table()
	for index,line in ipairs(self.lines) do
		self.textWidth = math.max(self.textWidth, #line.text)
		line.row = index
		if not line.cantSelect then
			self.selectableLines:insert(line)
		end
	end
	
	if not self.fixed then
		-- plus one to the width for the cursor position
		self.size = (vec2(self.textWidth + 1, #self.lines) + 2):clamp(view.bbox)
		self:refreshBorder()
	end
end

function Window:moveCursor(ch)
	if #self.selectableLines == 0 then 
		self.currentLine = 1
	else
		if ch == 'down' then
			self.currentLine = self.currentLine % #self.selectableLines + 1
		elseif ch == 'up' then
			self.currentLine = (self.currentLine - 2) % #self.selectableLines + 1
		end

		local row = self.selectableLines[self.currentLine].row
		if row < self.firstLine then
			self.firstLine = row
		elseif row > self.firstLine + (self.size[2] - 3) then
			self.firstLine = row - (self.size[2] - 3)
		end
	end
end

function Window:chooseCursor()
	if #self.selectableLines > 0 then
		self.currentLine = (self.currentLine - 1) % #self.selectableLines + 1
		local line = self.selectableLines[self.currentLine]
		if line.onSelect then line.onSelect() end
	end
end

function Window:draw()
	-- draw window
	view:drawBorder(self.border)
	local box = box2(self.border.min+1, self.border.max-1)
	view:fillBox(box)
	local cursor = vec2(box.min)
	
	local i = self.firstLine
	while cursor[2] < self.border.max[2]
	and i <= #self.lines
	do
		local line = self.lines[i]

		con.goto(unpack(cursor))
		if not self.noInteraction
		and line == self.selectableLines[self.currentLine]
		then
			con.write('>')
		else
			con.write(' ')
		end
		con.write(line.text)

		cursor[2] = cursor[2] + 1
		i = i + 1
	end
end


DoneWindow = class(Window)

function DoneWindow:init(args)
	DoneWindow.super.init(self, args)
end

function DoneWindow:refresh(text)
	self:setLines{text}
end

QuitWindow = class(Window)

function QuitWindow:init(args)
	local client = assert(args.client)
	QuitWindow.super.init(self, args)
	self:setLines{
		{text='Quit?', cantSelect=true},
		{text='-----', cantSelect=true},
		{text='Yes', onSelect=function() os.exit() end},
		{text='No', onSelect=function() client:popState() end},
	}
end


ClientBaseWindow = class(Window)

function ClientBaseWindow:init(args)
	ClientBaseWindow.super.init(self, args)
	self.client = assert(args.client)
	self.army = self.client.army
end


MoveFinishedWindow = class(ClientBaseWindow)

function MoveFinishedWindow:refresh()
	local lines = table()
	-- if there's a player beneath us ...
	local solidfound
	for _,e in ipairs(entsAtPos(self.client.army.currentEnt.pos)) do
		if e ~= self.client.army.currentEnt and e.solid then
			solidfound = true
			break
		end
	end
	if not solidfound then
		lines:insert{
			text = 'Ok',
			onSelect = function()
				self.client.army.currentEnt.movesLeft = 0
				self.client:popState()
				self.client:popState()
			end,
		}
	end
	lines:insert{
		text = 'Cancel',
		onSelect = function()
			local currentEnt = self.client.army.currentEnt
			currentEnt:setPos(currentEnt.turnStartPos)
			currentEnt.movesLeft = currentEnt:stat('move')
			self.client:popState()
			self.client:popState()
		end,
	}
	self:setLines(lines)
end


MapOptionsWindow = class(ClientBaseWindow)

function MapOptionsWindow:init(args)
	MapOptionsWindow.super.init(self, args)
	self:refresh()
end

function MapOptionsWindow:refresh()
	local lines = table()
	lines:insert{
		text = 'Status',
		onSelect = function()
			self.client:pushState(Client.armyCmdState)
		end,
	}
	lines:insert{
		text = 'Inspect',
		onSelect = function()
			self.client:pushState(Client.inspectCmdState)
		end
	}
	if #self.client.army.ents < Client.maxArmySize then
		lines:insert{
			text = 'Recruit',
			onSelect = function()
				if #self.client.army.ents < Client.maxArmySize then
					self.client:pushState(Client.recruitCmdState)
				end
			end,
		}
	end
	lines:insert{
		text = 'Quit',
		onSelect = function()
			self.client:pushState(Client.quitCmdState)
		end,
	}
	lines:insert{
		text = 'Done',
		onSelect = function()
			self.client:popState()
		end,
	}
	self:setLines(lines)
end


local function refreshWinPlayers(client)
	local player = client.army.ents[client.armyWin.currentLine]
	for _,field in ipairs{'statWin', 'equipWin', 'itemWin'} do
		local win = client[field]
		win.player = player
	end
end


ArmyWindow = class(ClientBaseWindow)

function ArmyWindow:refresh()
	local lines = table()
	for _,ent in ipairs(self.army.ents) do
		lines:insert(ent.name)
	end
	self:setLines(lines)
end

function ArmyWindow:moveCursor(ch)
	ArmyWindow.super.moveCursor(self, ch)
	
	refreshWinPlayers(self.client)
	self.client.statWin:refresh()
end


StatWindow = class(ClientBaseWindow)
StatWindow.noInteraction = true

function StatWindow:refresh(field, equip)
	local function recordStats(dest)
		local stats = table()
		for _,field in ipairs(self.player.statFields) do
			stats[field] = self.player:stat(field)
		end
		return stats
	end
	
	-- first get our stats
	local currentStats = recordStats()
	local equipStats
	
	-- next temp equip the item over us and then get our stats
	if field then
		local lastEquip = self.player[field]
		self.player[field] = equip
		
		-- record stats
		equipStats = recordStats()
		
		self.player[field] = lastEquip
	end
	
	-- then report (differences?)
	local lines = table()
	for _,field in ipairs(self.player.statFields) do
		local fieldName = field
		if field == 'hpMax' then fieldName = 'hp' end
		local value = currentStats[field]
		if equipStats and equipStats[field] then
			local dif = equipStats[field] - currentStats[field]
			if dif ~= 0 then
				local sign
				if dif > 0 then sign = '+' else sign = '' end
				value = '('..sign..dif..')'
			end
		end
		if self.client.army.battle and field == 'hpMax' then
			value = self.player.hp .. '/' .. value
		end
		local s = fieldName..' '..value
		lines:insert(s)
	end
	lines:insert('gold '..self.client.army.gold)

	self:setLines(lines)
end


EquipWindow = class(ClientBaseWindow)

function EquipWindow:refresh()
	local lines = table()
	local width = 0
	for _,field in ipairs(self.player.equipFields) do
		width = math.max(width, #field)
	end
	for _,field in ipairs(self.player.equipFields) do
		local s = (' '):rep(width - #field)..field..': '
		local equip = self.player[field]
		if equip then
			s = s .. equip.name
		else
			s = s .. '[Empty]'
		end
		lines:insert(s)
	end
	self:setLines(lines)
end


ItemWindow = class(ClientBaseWindow)

local function refreshEquipStatWin(client)
	local item = client.itemWin.items[client.itemWin.currentLine]
	if item then
		-- if we're in equip mode then ...
		local field = assert(client.itemWin.player.equipFields[client.equipWin.currentLine])
		if field then
			-- update stats, showing any changes compared to what we're currently equipped with
			client.statWin:refresh(field, item)
		end
	end
end

function ItemWindow:moveCursor(ch)
	ItemWindow.super.moveCursor(self, ch)
	
	-- only show stat differences if we're in the equip menu
	if self.client.cmdstate == Client.chooseEquipCmdState then
		refreshEquipStatWin(self.client)
	end
end

function ItemWindow:chooseCursor()
	ItemWindow.super.chooseCursor(self)
	
	if self.client.cmdstate == Client.chooseEquipCmdState then
		local player = client.equipWin.player
		local field = assert(player.equipFields[client.equipWin.currentLine])
		-- hack -- parallel list
		local equip = client.itemWin.items[client.itemWin.currentLine]
		if player[field] == equip then	
			player[field] = nil
		else
			player[field] = equip
		end

		client.equipWin:setPos(vec2(client.statWin.border.max[1]+1, client.statWin.border.min[2]))
		client.equipWin:refresh()

		-- TODO keep track of equipment bidirectionally?
		client.itemWin:refresh(function(item)
			if item.equip ~= field then return false end
			for _,p2 in ipairs(client.army.ents) do
				if p2 ~= player then
					for _,f2 in ipairs(p2.equipFields) do
						if p2[f2] == item then return false end
					end
				end
			end
			return true
		end)
		client.itemWin:setPos(vec2(client.equipWin.border.max[1]+1, client.equipWin.border.min[2]))
		refreshEquipStatWin(client)
	end
end

function ItemWindow:refresh(filter)
	local lines = table()
	self.items = table()
	
	for _,item in ipairs(self.client.army.items) do
		local good = true
		if filter then good = filter(item) end
		if good then
			self.items:insert(item)
			lines:insert(item.name)
		end
	end
	
	for _,player in ipairs(self.client.army.ents) do
		for _,field in ipairs(player.equipFields) do
			if player[field] then
				local index = self.items:find(player[field])
				if index then lines[index] = lines[index] .. ' (E)' end
			end
		end
	end
	
	self:setLines(lines)
end

PlayerWindow = class(ClientBaseWindow)

function PlayerWindow:init(args)
	PlayerWindow.super.init(self, args)
	self:setLines{
		{
			text = 'Equip',
			onSelect = function()
				self.client:pushState(Client.equipCmdState)
			end,
		},
		{
			text = 'Use Item',
			onSelect = function()
				self.client:pushState(Client.itemCmdState)
			end,
		},
		{
			text = 'Drop Item',
			onSelect = function()
				self.client:pushState(Client.dropItemCmdState)
			end,
		},
	}
end


BattleWindow = class(ClientBaseWindow)

function BattleWindow:refresh()
	local client = self.client
	local currentEnt = client.army.currentEnt

	local lines = table()
	if currentEnt.movesLeft > 0 then
		lines:insert{
			text = 'Move',
			onSelect = function()
				client:pushState(Client.battleMoveCmdState)
			end,
		}
	end
	if not currentEnt.acted then
		lines:insert{
			text = 'Attack',
			onSelect = function()
				client:pushState(Client.attackCmdState)
			end,
		}
		if #client.army.items > 0 then
			lines:insert{
				text = 'Use Item',
				onSelect = function()
					client:pushState(Client.itemCmdState)
				end,
			}
		end
	end
	
	local getEnt
	for _,ent in ipairs(entsAtPos(currentEnt.pos)) do
		if ent.get then
			getEnt = true
			break
		end
	end
	if getEnt then
		lines:insert{
			text = 'Get',
			onSelect = function()
				for _,ent in ipairs(entsAtPos(currentEnt.pos)) do
					if ent.get then
						currentEnt.movesLeft = 0
						ent:get(currentEnt)
					end
				end
			end,
		}
	end

	lines:insert{
		text = 'End Turn',
		onSelect = function()
			currentEnt:endTurn()
		end,
	}
	lines:insert{
		text = 'Party',
		onSelect = function()
			client:pushState(Client.armyCmdState)
		end,
	}
	lines:insert{
		text = 'Inspect',
		onSelect = function()
			self.client:pushState(Client.inspectCmdState)
		end
	}
	lines:insert{
		text = 'Quit',
		onSelect = function()
			client:pushState(Client.quitCmdState)
		end,
	}
	
	self:setLines(lines)
end

-- command menu

local cmdPopState = {
	name = 'Done',
	exec = function(client, cmd, ch)
		client:popState()
	end,
}

local function makeCmdPushState(name, state, disabled)
	assert(state)
	return {
		name = name,
		exec = function(self, cmd, ch)
			self:pushState(state)
		end,
		disabled = disabled,
	}
end

local function makeCmdWindowMoveCursor(winField)
	return {
		name = 'Scroll',
		exec = function(client, cmd, ch)
			local win = assert(client[winField])
			win:moveCursor(ch)
		end,
	}
end

local function makeCmdWindowChooseCursor(winField)
	return {
		name = 'Choose',
		exec = function(client, cmd, ch)
			local win = assert(client[winField])
			win:chooseCursor()
		end,
	}
end

local cmdMove = {
	name = 'Move',
	exec = function(client, cmd, ch)
		if not client.army.battle then
			client.army.leader:walk(ch)
		else
			client.army.currentEnt:walk(ch)
		end
	end,
}

local function refreshStatusToInspect(client)
	local ents = entsAtPos(client.inspectPos)
	if #ents > 0 then
		local ent = ents[os.time() % #ents + 1]
		client.statWin.player = ent
		client.statWin:refresh()
	else
		client.statWin:setLines{'>Close'}
	end
end

local cmdInspectMove = {
	name = 'Move',
	exec = function(client, cmd, ch)
		client.inspectPos = client.inspectPos + dirs[ch]
		refreshStatusToInspect(client)
	end
}


Client.inspectCmdState = {
	cmds = {
		up = cmdInspectMove,
		down = cmdInspectMove,
		left = cmdInspectMove,
		right = cmdInspectMove,
		space = cmdPopState,
	},
	enter = function(client, state)
		client.inspectPos = vec2(client.army.leader.pos)
		client.statWin:setPos(vec2(1,1))
		refreshStatusToInspect(client)
	end,
	draw = function(client, state)
		local viewpos = client.inspectPos - view.delta
		if view.bbox:contains(viewpos) then
			con.goto(unpack(viewpos))
			con.write('X')
		end
		client.statWin:draw()
	end,
}

Client.chooseEquipCmdState = {
	cmds = {
		left = cmdPopState,
		up = makeCmdWindowMoveCursor('itemWin'),
		down = makeCmdWindowMoveCursor('itemWin'),
		space = makeCmdWindowChooseCursor('itemWin'),
	},
	
	enter = function(client, state)
		local player = client.equipWin.player
		local field = assert(player.equipFields[client.equipWin.currentLine])
		
		-- filter out unequipped items
		-- TODO keep track of equipment bidirectionally
		client.itemWin:refresh(function(item)
			if item.equip ~= field then return false end
			for _,p2 in ipairs(client.army.ents) do
				if p2 ~= player then
					for _,f2 in ipairs(p2.equipFields) do
						if p2[f2] == item then return false end
					end
				end
			end
			return true
		end)

		client.itemWin.currentLine = 1
		if player[field] then
			client.itemWin.items:find(player[field])
		end
		refreshEquipStatWin(client)	-- make sure itemWin is refreshed first
		client.itemWin:setPos(vec2(client.equipWin.border.max[1]+1, client.equipWin.border.min[2]))
	end,
	
	draw = function(client, state)
		client.itemWin:draw()
	end,
}

Client.equipCmdState = {
	cmds = {
		e = cmdPopState,
		left = cmdPopState,
		up = makeCmdWindowMoveCursor('equipWin'),
		down = makeCmdWindowMoveCursor('equipWin'),
		space = makeCmdPushState('Choose', Client.chooseEquipCmdState),
		right = makeCmdPushState('Choose', Client.chooseEquipCmdState),
	},
	
	enter = function(client, state)
		client.statWin:refresh()
		client.equipWin:setPos(vec2(client.statWin.border.max[1]+1, client.statWin.border.min[2]))
		client.equipWin:refresh()
	end,
	
	draw = function(client, state)
		client.statWin:draw()
		client.equipWin:draw()
	end,
}

Client.itemCmdState = {
	cmds = {
		up = makeCmdWindowMoveCursor('itemWin'),
		down = makeCmdWindowMoveCursor('itemWin'),
		left = cmdPopState,
		
		space = {
			name = 'Use',
			exec = function(client, cmd, ch)
				local player = client.itemWin.player
				if #client.itemWin.items == 0 then return end
				client.itemWin.currentLine = (client.itemWin.currentLine - 1) % #client.itemWin.items + 1

				local item = client.itemWin.items[client.itemWin.currentLine]

				-- TODO separate message for using usable items and equipping items
				-- even better, separate screens
				--log(client.name..' using item '..item.name..'...')
				if item.use then
					item:use(player)
					-- always remove when we use?
					player:removeItem(item)
					client.itemWin:refresh()
				end
			end,
		},
	},
	
	enter = function(client, state)
		client.itemWin:setPos(vec2(1,1))
		client.itemWin:refresh()	-- refresh with no filters
	end,
	
	draw = function(client, state)
		client.itemWin:draw()
	end,
}

Client.dropItemCmdState = {
	cmds = {
		up = makeCmdWindowMoveCursor('itemWin'),
		down = makeCmdWindowMoveCursor('itemWin'),
		left = cmdPopState,
		
		space = {
			name = 'Drop',
			exec = function(client, cmd, ch)
				if #client.army.items == 0 then return end
				client.itemWin.currentLine = (client.itemWin.currentLine - 1) % #client.army.items + 1
				local item = client.itemWin.items[client.itemWin.currentLine]
				client.army:removeItem(item)
				if #client.army.items > 0 then
					client.itemWin.currentLine = (client.itemWin.currentLine - 1) % #client.army.items + 1
				end
				
				-- make sure to refresh the items
				client.itemWin:refresh()
			end,
		},
	},
	
	enter = function(client, state)
		client.itemWin:setPos(vec2(1,1))
		client.itemWin:refresh()	-- refresh with no filters
	end,
	
	draw = function(client, state)
		client.itemWin:draw()
	end,
}

Client.playerCmdState = {
	cmds = {
		left = cmdPopState,
		up = makeCmdWindowMoveCursor('playerWin'),
		down = makeCmdWindowMoveCursor('playerWin'),
		right = makeCmdWindowChooseCursor('playerWin'),
		space = makeCmdWindowChooseCursor('playerWin'),
	},
	
	enter = function(client, state)
		client.playerWin:setPos(vec2(client.statWin.border.max[1]+3, client.statWin.border.min[2]+1))
	end,
	
	draw = function(client, state)
		client.playerWin:draw()
	end,
}

Client.armyCmdState = {
	cmds = {
		left = cmdPopState,
		up = makeCmdWindowMoveCursor('armyWin'),
		down = makeCmdWindowMoveCursor('armyWin'),
		right = makeCmdPushState('Player', Client.playerCmdState),
		space = makeCmdPushState('Player', Client.playerCmdState),
	},
	
	enter = function(client, state)
		refreshWinPlayers(client)
		client.statWin:refresh()
		client.armyWin:setPos(vec2(client.statWin.border.max[1]+1, client.statWin.border.min[2]))
		client.armyWin:refresh()
		
		-- todo set visible and have focus and pause game based on that
		game.paused = true
	end,
	
	draw = function(client, state)
		game.paused = false

		client.statWin:draw()
		client.armyWin:draw()
	end,
}

local cmdRecruit = {
	name = 'Recruit',
	exec = function(client, cmd, ch)
		if #client.army.ents >= Client.maxArmySize then
			log("party is full")
		else
			local pos = client.army.leader.pos + dirs[ch]
			if map.bbox:contains(pos) then

				local armies = table()
				for _,ent in ipairs(entsAtPos(pos)) do
					if ent.army ~= client.army
					and ent.army.affiliation == client.army.affiliation
					then
						armies:insertUnique(ent.army)
					end
				end
				
				if #armies then
					for _,army in ipairs(armies) do
						client.army:addArmy(army)
					end
				end
			end
		end
		client:popState()
	end,
}

Client.recruitCmdState = {
	cmds = {
		up = cmdRecruit,
		down = cmdRecruit,
		left = cmdRecruit,
		right = cmdRecruit,
		space = cmdPopState,
	},
	enter = function(client, state)
		client.doneWin:refresh('Cancel')
		client.doneWin:setPos(vec2(1,1))
	end,
	draw = function(client, state)
		client.doneWin:draw()
	end,
}

Client.mapOptionsCmdState = {
	cmds = {
		left = cmdPopState,
		up = makeCmdWindowMoveCursor('mapOptionsWin'),
		down = makeCmdWindowMoveCursor('mapOptionsWin'),
		right = makeCmdWindowChooseCursor('mapOptionsWin'),
		space = makeCmdWindowChooseCursor('mapOptionsWin'),
	},
	enter = function(client, state)
		client.mapOptionsWin:setPos(vec2(1,1))
		client.mapOptionsWin:refresh()
	end,
	draw = function(client, state)
		client.mapOptionsWin:refresh()
		client.mapOptionsWin:draw()
	end,
}

Client.mainCmdState = {
	cmds = {
		up = cmdMove,
		down = cmdMove,
		left = cmdMove,
		right = cmdMove,
		space = makeCmdPushState('Party', Client.mapOptionsCmdState),
	},
}

local cmdAttack = {
	name = 'Attack',
	exec = function(client, cmd, ch)
		client.army.currentEnt:attackDir(ch)
		client:popState()
	end,
}

Client.attackCmdState = {
	cmds = {
		up = cmdAttack,
		down = cmdAttack,
		left = cmdAttack,
		right = cmdAttack,
		space = cmdPopState,
	},
	enter = function(client, state)
		client.doneWin:refresh('Cancel')
		client.doneWin:setPos(vec2(1,1))
	end,
	draw = function(client, state)
		client.doneWin:draw()
	end,
}

Client.battleMoveCmdFinishedState = {
	cmds = {
		up = makeCmdWindowMoveCursor('moveFinishedWin'),
		down = makeCmdWindowMoveCursor('moveFinishedWin'),
		space = makeCmdWindowChooseCursor('moveFinishedWin'),
	},
	draw = function(client, state)
		client.moveFinishedWin:refresh()
		client.moveFinishedWin:draw()
	end,
}

local cmdMoveDone = {
	name = 'Done',
	exec = function(client, cmd, ch)
		client:pushState(Client.battleMoveCmdFinishedState)
	end,
}

Client.battleMoveCmdState = {
	cmds = {
		up = cmdMove,
		down = cmdMove,
		left = cmdMove,
		right = cmdMove,
		space = cmdMoveDone,
	},
	
	enter = function(client, state)
		client.doneWin:refresh('Done')
		client.doneWin:setPos(vec2(1,1))
	end,
	
	draw = function(client, state)
		client.doneWin:draw()
	end,
}

Client.battleCmdState = {
	cmds = {
		up = makeCmdWindowMoveCursor('battleWin'),
		down = makeCmdWindowMoveCursor('battleWin'),
		space = makeCmdWindowChooseCursor('battleWin'),	
	},
	enter = function(client, state)
		client.battleWin:setPos(vec2(1,1))
	end,
	draw = function(client, state)
		client.battleWin:refresh()
		client.battleWin:draw()
	end
}


Client.quitCmdState = {
	cmds = {
		left = cmdPopState,
		up = makeCmdWindowMoveCursor('quitWin'),
		down = makeCmdWindowMoveCursor('quitWin'),
		space = makeCmdWindowChooseCursor('quitWin'),
	},
	
	draw = function(client, state)
		client.quitWin:draw()
	end,
}

function Client:setState(state)
	if self.cmdstate and self.cmdstate.exit then
		self.cmdstate.exit(self, self.cmdstate)
	end
	
	self.cmdstate = state
	
	if self.cmdstate and self.cmdstate.enter then
		self.cmdstate.enter(self, self.cmdstate)
	end
end

function Client:removeToState(state)
	assert(state)
	if state == self.cmdstate then return end
	local i = assert(self.cmdstack:find(state))
	for i=i,#self.cmdstack do
		self.cmdstack[i] = nil
	end
	self.cmdstate = state
end

function Client:pushState(state)
	assert(state)
	self.cmdstack:insert(self.cmdstate)
	self:setState(state)
end

function Client:popState()
	self:setState(self.cmdstack:remove())
end

function Client:processCmdState(state)
	local ch = launcher.getInput()

	local dodebug  = (function()
		if ch == 'q' then
			self:pushState(Client.quitCmdState)
		end
		
		if ch == '`' then
			return true
		end
		
		if ch == 13 then ch = 'enter' end
		if ch == ' ' then ch = 'space' end

		if self.dead then
			if self.cmdstate ~= Client.quitCmdState then
				self:pushState(Client.quitCmdState)
			end
		end

		-- hardcode these move cmds
		-- TODO separate escape from escape-codes
		local moveCmd
		if ch == string.char(27) then
			ch = io.stdin:read(1)
			if ch == '[' then
				ch = io.stdin:read(1)
				if ch == 'A' then
					moveCmd = 'up'
				elseif ch == 'B' then
					moveCmd = 'down'
				elseif ch == 'D' then
					moveCmd = 'left'
				elseif ch == 'C' then
					moveCmd = 'right'
				end
			end
		end
		if moveCmd then ch = moveCmd end
	end)()
	
	if dodebug then
		con.write('>>')
		local cmd = io.read('*l'):gsub('^=','return ')
		local status, result = pcall(function()
			return table.concat((table{assert(loadstring(cmd))()}):map(tostring), '\t')
		end)
		log('"'..cmd..'"')
		log(' '..result)
	end

	if self.dead and self.cmdstate ~= Client.quitCmdState then return end
	
	if state then
		local cmd = state.cmds[ch]
		if cmd then
			if not (cmd.disabled and cmd.disabled(self, cmd)) then
				cmd.exec(self, cmd, ch)
			end
		end
	end
end

-- holds our entities ...
function Client:init()
	self.army = ClientArmy(self)

	self.cmdstack = table()	-- for push/pop cmdstates
	self:setState(Client.mainCmdState)
	
	self.armyWin = ArmyWindow{client=self}
	self.statWin = StatWindow{client=self}
	self.equipWin = EquipWindow{client=self}
	self.itemWin = ItemWindow{client=self}
	self.quitWin = QuitWindow{client=self}
	self.playerWin = PlayerWindow{client=self}
	self.battleWin = BattleWindow{client=self}
	self.doneWin = DoneWindow{client=self}
	self.mapOptionsWin = MapOptionsWindow{client=self}
	self.moveFinishedWin = MoveFinishedWindow{client=self}
end

function Client:update()
	-- if this player is the main player ...
	if self.cmdstate and self.cmdstate.update then
		self.cmdstate.update(self, self.cmdstate)
	end
	
	-- make sure we at least process cmds before testing dead
	-- so we can quit even if we're dead
	self:processCmdState(self.cmdstate)
end

