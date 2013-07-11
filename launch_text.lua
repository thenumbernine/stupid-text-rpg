launcher = {
	getInput = function(callback)
		os.execute("stty raw -echo")	-- read single keystrokes
		local ch = io.stdin:read(1)
		os.execute("stty sane")			-- reset read
		return ch
	end,
}

con = {
	init = function() end,
	draw = function() end,
	locate = function(x,y)
		io.write('\027['..y..';'..x..'H')
	end,
	write = function(s)
		io.write(s)
	end,
	clearline = function()
		io.write('\027[K')
	end,
	clear = function()
		io.write('\027[2J')
	end,
}

local stupid = require 'stupid'
stupid.run()
