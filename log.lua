require 'ext'

Log = class()	
if not OMIT_LOG_FILE then
	Log.file = io.open('log.txt', 'w')
end
Log.index = 0
Log.lines = table()
Log.size = 4
Log.__call = function(self, s)
	local lines = s:split('\n')
	for _,line in ipairs(lines) do
		line = self.index..'> '..line
		if self.file then
			self.file:write(line..'\n')
			self.file:flush()
		end
		self.lines:insert(line)
		self.index = self.index + 1
	end
	while #self.lines > self.size do
		self.lines:remove(1)
	end
end

function Log:render()
	for i=1,self.size do
		local line = self.lines[i]
		con.locate(1, view.size[2]+i)
		if line then
			con.write(line)
		end
		con.clearline()
	end
end

log = Log()	-- singleton
