launcher = {
	getInput = function()
		local ffi = require 'ffi'
		if ffi.os ~= 'Windows' then
			os.execute("stty raw -echo")	-- read single keystrokes
		end
		local ch = io.stdin:read(1)
		if ffi.os ~= 'Windows' then
			os.execute("stty sane")			-- reset read
		end
		return ch
	end,
	getChar = function()
		return io.stdin:read(1)
	end,
	getCmd = function()
		local ch = launcher.getInput()

		if ch == 'q' then
			return 'quit'
		end
		
		if ch == '`' then
			con.write('>>')
			local cmd = io.read('*l'):gsub('^=','return ')
			local status, result = pcall(function()
				return table.concat((table{assert(loadstring(cmd))()}):map(tostring), '\t')
			end)
			log('"'..cmd..'"')
			log(' '..result)
		else
			
			if ch == 13 then ch = 'enter' end
			if ch == ' ' then ch = 'space' end

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
		
			return ch
		end
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
