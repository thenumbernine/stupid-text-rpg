OMIT_LOG_FILE = true

local stupid
launcher = {
	getCmd = function(callback)
		local ch = tostring(js.global.getLastCmd() or '')
		--print('lua got cmd',ch,'byte',ch:byte())
		return ch 
	end,

	update = function()
		stupid.update()
	end,
}

local lines
local width, height
local col = 1
local row = 1
con = {
	init = function(width_, height_) 
		width = width_
		height = height_
		con.clear()
	end,
	draw = function() 
		print(table.concat(lines, '\n'))
	end,
	locate = function(x,y) 
		col = x
		row = y
	end,
	write = function(s) 
		local line = lines[row]
		if not line then return end
		local lhs = line:sub(1,col-1)
		local rhs = line:sub(col+#s)
		line = (lhs .. s .. rhs):sub(1,width)
		lines[row] = line
	end,
	clearline = function()
		local line = lines[row]
		if not line then return end
		local lhs = line:sub(1,col-1)
		line = lhs .. (' '):rep(width - #lhs)
		lines[row] = line
	end,
	clear = function() 
		js.global.clearOutput()
		lines = {}
		for y=1,height do
			lines[y] = (' '):rep(width)
		end
	end,
}

print('getting stupid')
stupid = require 'stupid'
print('running stupid')
stupid.update()

