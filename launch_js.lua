local oldrequire = require
local myPackageLoaded = {}
function require(fn, ...)
	print('requiring file '..fn)
	--[[
	this relies on the lua.vm.js filesystem, which I suspect is slow
	and I"m hoping is buggy (since something is and I would like it to be something that I can circumvent)
	--]]
	--return oldrequire(fn, ...)
	--[[
	..so instead I'm going to recreate require()
	I can't do it all on the JS side -- since I have to store arbitrary return contents of require(), such as lua objects and functions
	so I will hold those here, and go to JS for the file contents
	--]]
	if myPackageLoaded[fn] then
		return myPackageLoaded[fn]
	end
	local reqfile = assert(js.global.getLuaRequiredFile(fn), "failed to find file "..fn)
	local reqfn = assert(loadstring(reqfile), "failed to load file "..fn)
	local result = reqfn() or true
	myPackageLoaded[fn] = result
	return result
end

-- macro for running and testing the js launcher through lua
--USE_LUA = true
OMIT_LOG_FILE = true

if not USE_LUA then
	package.path = package.path .. ';./?/init.lua'
end

launcher = {
	-- is this supposed to be blocking?
	getInput = function(callback)
		if USE_LUA then
			os.execute("stty raw -echo")	-- read single keystrokes
			local ch = io.stdin:read(1)
			os.execute("stty sane")			-- reset read
			return ch
		else
			return js.global.getLastKey()	-- read something buffered via the js API
		end
	end,
}

local lines
local width, height
local col = 1
local row = 1
con = {
	init = function(width_, height_) 
--print('con.init('..width..', '..height..')')
		width = width_
		height = height_
		con.clear()
	end,
	draw = function() 
--print('con.draw()')
		--if USE_LUA then
			print(table.concat(lines, '\n'))
		--else
		--	js.global.setOutput(table.concat(lines, '\n'))
		--end
	end,
	locate = function(x,y) 
--print('con.locate('..x..','..y..')')
		col = x
		row = y
	end,
	write = function(s) 
--print('con.write('..--[[s..--]]')')
		local line = lines[row]
		if not line then return end
		local lhs = line:sub(1,col-1)
		local rhs = line:sub(col+#s)
		line = (lhs .. s .. rhs):sub(1,width)
		lines[row] = line
	end,
	clearline = function()
--print('con.clearline()')
		local line = lines[row]
		if not line then return end
		local lhs = line:sub(1,col-1)
		line = lhs .. (' '):rep(width - #lhs)
		lines[row] = line
	end,
	clear = function() 
--print('con.clear()')
		js.global.clearOutput()
		lines = {}
		for y=1,height do
			lines[y] = (' '):rep(width)
		end
	end,
}

print('getting stupid')
local stupid = require 'stupid'
print('running stupid')
stupid.run()
print('done')

