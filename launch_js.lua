-- macro for running and testing the js launcher through lua
--USE_LUA = true

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
		if USE_LUA then
			print(table.concat(lines, '\n'))
		else
			js.global.setOutput(table.concat(lines, '\n'))
		end
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

