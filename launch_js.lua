OMIT_LOG_FILE = true
--USE_LUA = true

function io.popen() 
	return {
		read = function() return '' end,
	}
end

local stupid
launcher = {
	getCmd = function()
		local ch
		if USE_LUA then
			--os.execute("stty raw -echo")	-- read single keystrokes
			ch = io.stdin:read('*l')
			--os.execute("stty sane")			-- reset read
			ch = ({
				[' '] = 'space',
				['\n'] = 'enter',
				i = 'up',
				j ='left',
				k = 'right',
				m = 'down',
				q = 'quit',
			})[ch] or ch
		else
			ch = launcher.lastCmd
			launcher.lastCmd = nil
		end
		ch = tostring(ch or nil)
		return ch 
	end,

	update = function(lastCmd)
		launcher.lastCmd = lastCmd
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
		col = col + #s
	end,
	clearline = function()
		local line = lines[row]
		if not line then return end
		local lhs = line:sub(1,col-1)
		line = lhs .. (' '):rep(width - #lhs)
		lines[row] = line
	end,
	clear = function() 
		if USE_LUA then
			io.write('\027[2J')
		else
			js.global.clearOutput()
		end
		lines = {}
		for y=1,height do
			lines[y] = (' '):rep(width)
		end
	end,
}

print('getting stupid')
stupid = require 'stupid'
print('running stupid')

if USE_LUA then
	stupid.run()
else
	stupid.gameUpdate()
end
