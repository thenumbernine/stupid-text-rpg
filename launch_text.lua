launcher = {
	getInput = function(callback)
		os.execute("stty raw -echo")	-- read single keystrokes
		local ch = io.stdin:read(1)
		os.execute("stty sane")			-- reset read
		return ch
	end,
}

local stupid = require 'stupid'

stupid.run()
