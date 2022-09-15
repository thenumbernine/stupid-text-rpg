require 'ext'
require 'unit'

local Item = class()

function Item.__lt(a,b)
	return (items:find(a.class) or 0) < (items:find(b.class) or 0)
end

local Potion = class(Item)
Potion.name = 'Potion'
Potion.healRange = {20,30}
function Potion:init(...)
	if Potion.super.init then Potion.super.init(self, ...) end
	setFieldsByRange(self, {'heal'})
	self.heal = math.floor(self.heal)
	self.name = self.name .. '(+'..self.heal..')'
end
function Potion:use(who)
	-- TODO heal function
	who.hp = math.min(who.hp + self.heal, who:stat('hpMax'))
end

local Equipment = class(Item)

function Equipment:init(maxLevel)
	assert(self.baseTypes, "tried to instanciate an equipment of type "..self.name.." with no basetypes")
	
	local baseTypeOptions = table(self.baseTypes)
	local modifierOptions = table(self.modifiers)
	if maxLevel then
		local filter = function(baseType)
			return not baseType.dropLevel or baseType.dropLevel <= maxLevel
		end
		baseTypeOptions = baseTypeOptions:filter(filter)
		modifierOptions = modifierOptions:filter(filter)
	end

	local baseType = baseTypeOptions[math.random(#baseTypeOptions)]
	local modifier = modifierOptions[math.random(#modifierOptions)]
	
	self.name = modifier.name
	if self.name ~= '' then self.name = self.name..' ' end
	self.name = self.name..baseType.name
	
	for _,baseField in ipairs(Entity.statFields) do
		if table.find(self.modifierFields, baseField) then
			local field = baseField..'Range'
			local range = vec2()
			if self[field] then range = range + vec2(self[field]) end
			if baseType[field] then range = range + vec2(baseType[field]) end
			if modifier[field] then range = range + vec2(modifier[field]) end
			self[field] = range
		end
	end
	
	setFieldsByRange(self, Entity.statFields)
end

local weaponBaseTypes = {
	{name='Derp', attackRange=5, hitChanceRange=5, dropLevel=0},
	{name='Dagger', attackRange=10, hitChanceRange=10, dropLevel=1},
	{name='Sword', attackRange=15, hitChanceRange=15, dropLevel=2},
	{name='Flail', attackRange=20, hitChanceRange=20, dropLevel=3},
	{name='Axe', attackRange=25, hitChanceRange=25, dropLevel=4},
	{name='Boomerang', attackRange=30, hitChanceRange=30, dropLevel=5},
	{name='Bow', attackRange=35, hitChanceRange=35, dropLevel=6},
	{name='Star', attackRange=40, hitChanceRange=40, dropLevel=7},
	{name='Bow', attackRange=45, hitChanceRange=45, dropLevel=8},
}
for _,weapon in ipairs(weaponBaseTypes) do
	weapon.attackRange = { math.floor(weapon.attackRange * .75), weapon.attackRange }
	weapon.hitChanceRange = { math.floor(weapon.hitChanceRange * .75), weapon.hitChanceRange }
end

local weaponModifiers = {
	{name="Plain ol'"},
	{name='Short', attackRange={0,5}, hitChanceRange={0,10}, dropLevel=0},
	{name='Long', attackRange={3,8}, hitChanceRange={5,15}, dropLevel=5},
	{name='Heavy', attackRange={3,8}, hitChanceRange={5,15}, dropLevel=10},
	{name='Bastard', attackRange={0,10}, hitChanceRange={10,20}, dropLevel=15},
	{name='Demon', attackRange={20,20}, hitChanceRange={30,35}, dropLevel=20},
	{name='Were', attackRange={20,25}, hitChanceRange={35,45}, dropLevel=25},
	{name='Rune', attackRange={30,35}, hitChanceRange={40,50}, dropLevel=30},
	{name='Dragon', attackRange={30,40}, hitChanceRange={40,50}, dropLevel=35},
	{name='Quick', attackRange={40,45}, hitChanceRange={90,100}, dropLevel=40},
}


local defenseModifiers = {
	{name="Cloth", defenseRange={1,2}, hpMaxRange={1,2}, evadeRange={1,2}, dropLevel=0},
	{name="Leather", defenseRange={2,3}, hpMaxRange={2,3}, evadeRange={2,3}, dropLevel=5},
	{name="Wooden", defenseRange={3,4}, hpMaxRange={3,4}, evadeRange={3,4}, dropLevel=10},
	{name="Chain", defenseRange={3,4}, hpMaxRange={3,4}, evadeRange={3,4}, dropLevel=15},
	{name="Plate", defenseRange={4,6}, hpMaxRange={4,6}, evadeRange={4,6}, dropLevel=20},
	{name="Copper", defenseRange={5,7}, hpMaxRange={5,7}, evadeRange={5,7}, dropLevel=25},
	{name="Iron", defenseRange={7,10}, hpMaxRange={7,10}, evadeRange={7,10}, dropLevel=30},
	{name="Bronze", defenseRange={9,13}, hpMaxRange={9,13}, evadeRange={9,13}, dropLevel=35},
	{name="Steel", defenseRange={12,16}, hpMaxRange={12,16}, evadeRange={12,16}, dropLevel=40},
	{name="Silver", defenseRange={15,21}, hpMaxRange={15,21}, evadeRange={15,21}, dropLevel=45},
	{name="Gold", defenseRange={21,28}, hpMaxRange={21,28}, evadeRange={21,28}, dropLevel=50},
	{name="Crystal", defenseRange={27,37}, hpMaxRange={27,37}, evadeRange={27,37}, dropLevel=55},
	{name="Opal", defenseRange={36,48}, hpMaxRange={36,48}, evadeRange={36,48}, dropLevel=60},
	{name="Platinum", defenseRange={48,64}, hpMaxRange={48,64}, evadeRange={48,64}, dropLevel=65},
	{name="Plutonium", defenseRange={63,84}, hpMaxRange={63,84}, evadeRange={63,84}, dropLevel=70},
	{name="Adamantium", defenseRange={82,110}, hpMaxRange={82,110}, evadeRange={82,110}, dropLevel=75},
	{name="Potassium", defenseRange={108,145}, hpMaxRange={108,145}, evadeRange={108,145}, dropLevel=80},
	{name="Osmium", defenseRange={143,191}, hpMaxRange={143,191}, evadeRange={143,191}, dropLevel=85},
	{name="Holmium", defenseRange={189,252}, hpMaxRange={189,252}, evadeRange={189,252}, dropLevel=90},
	{name="Mithril", defenseRange={249,332}, hpMaxRange={249,332}, evadeRange={249,332}, dropLevel=95},
	{name="Aegis", defenseRange={327,437}, hpMaxRange={327,437}, evadeRange={327,437}, dropLevel=100},
	{name="Genji", defenseRange={432,576}, hpMaxRange={432,576}, evadeRange={432,576}, dropLevel=105},
	{name="Pro", defenseRange={569,759}, hpMaxRange={569,759}, evadeRange={569,759}, dropLevel=110},
	{name="Diamond", defenseRange={750,1000}, hpMaxRange={750,1000}, evadeRange={750,1000}, dropLevel=115},
}

local Weapon = class(Equipment)
Weapon.name = 'Weapon'
Weapon.equip = 'weapon'
Weapon.baseTypes = weaponBaseTypes
Weapon.modifiers = weaponModifiers
Weapon.modifierFields = {'attack', 'hitChance'}

local Armor = class(Equipment)
Armor.name = 'Armor'
Armor.equip = 'armor'
Armor.baseTypes = {
	{name='Armor'},
}
Armor.modifiers = defenseModifiers
Armor.modifierFields = {'defense', 'hpMax'}

local Helmet = class(Equipment)
Helmet.name = 'Helmet'
Helmet.equip = 'helmet'
Helmet.baseTypes = {
	{name='Helmet'},
}
Helmet.modifiers = defenseModifiers
Helmet.modifierFields = {'defense'}

local Shield = class(Equipment)
Shield.name = 'Shield'
Shield.equip = 'shield'
Shield.baseTypes = {
	{name='Buckler'},
	{name='Shield', evadeRange={5,10}},
}
Shield.modifiers = defenseModifiers
Shield.modifierFields = {'defense', 'evade'}

items = table{
	Potion,
	Weapon,
	Armor,
	Helmet,
	Shield,
}

-- map from name to type
for _,item in ipairs(items) do
	items[assert(item.name)] = item
end

--[[
-- this modifies the table, so don't run this if you're running the rest of the game
local oldSer = serializeTable
local temprangemeta = {
	__tostring = function(v) return v[1] .. ' to ' .. v[2] end,
	__concat = function(a,b) return tostring(a) .. tostring(b) end,
}
local function serializeTable(t)
	for _,row in ipairs(t) do
		for k,v in pairs(row) do
			if type(v) == 'table' then setmetatable(v, temprangemeta) end
		end
	end
	return oldSer(t)
end
file'../csv/data/weaponBaseTypes.lua':write(serializeTable(Weapon.baseTypes))
file'../csv/data/weaponModifiers.lua':write(serializeTable(Weapon.modifiers))
file'../csv/data/weaponModifierFields.lua':write(serializeTable{Weapon.modifierFields})
file'../csv/data/defenseModifiers.lua':write(serializeTable(defenseModifiers))
file'../csv/data/armorBaseTypes.lua':write(serializeTable(Armor.baseTypes))
file'../csv/data/armorModifierFields.lua':write(serializeTable{Armor.modifierFields})
file'../csv/data/helmetBaseTypes.lua':write(serializeTable(Helmet.baseTypes))
file'../csv/data/helmetModifierFields.lua':write(serializeTable{Helmet.modifierFields})
file'../csv/data/shieldBaseTypes.lua':write(serializeTable(Shield.baseTypes))
file'../csv/data/shieldModifierFields.lua':write(serializeTable{Shield.modifierFields})
os.exit()
--]]
