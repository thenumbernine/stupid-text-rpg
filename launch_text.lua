launcher = {
	getInput = function(callback)
		os.execute("stty raw -echo")	-- read single keystrokes
		local ch = io.stdin:read(1)
		os.execute("stty sane")			-- reset read
		return ch
	end,
}

con = {}

function con.init()
end

function con.draw()
end

function con.locate(x,y)
	io.write('\027['..y..';'..x..'H')
end

function con.write(s)
	io.write(s)
end

function con.clearline()
	io.write('\027[K')
end

function con.clear()
	io.write('\027[2J')
end

local stupid = require 'stupid'

stupid.run()
