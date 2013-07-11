launcher = {
	-- is this supposed to be blocking?
	getInput = function(callback)
		-- TODO read something buffered via the js.whatever API
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
		print('drawing!!!')
		js.outputElement.value = lines:concat('\n')
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
		lines = {}
		for y=1,height do
			lines[y] = (' '):rep(width)
		end
	end,
}

