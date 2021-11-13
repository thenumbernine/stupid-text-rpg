-- functionality

View = class()
View.size = vec2(60,20)
View.bbox = box2(1, View.size)
View.center = (View.size / 2):ceil()

function View:update(mapCenter)
	-- map coord = view.delta + screen coord
	-- screen coord = map coord - view.delta
	self.delta = mapCenter - self.center
end

function View:drawBorder(b)
	local mins = b.min
	local maxs = b.max
	for x=mins[1]+1,maxs[1]-1 do
		if mins[2] >= 1 and mins[2] <= view.size[2] then
			con.locate(x, mins[2])
			con.write('-')
		end
		if maxs[2] >= 1 and maxs[2] <= view.size[2] then
			con.locate(x, maxs[2])
			con.write('-')
		end
	end
	for y=mins[2]+1,maxs[2]-1 do
		if mins[1] >= 1 and mins[1] <= view.size[1] then
			con.locate(mins[1], y)
			con.write('|')
		end
		if maxs[1] >= 1 and maxs[1] <= view.size[1] then
			con.locate(maxs[1], y)
			con.write('|')
		end
	end
	local minmax = {mins, maxs}
	for x=1,2 do
		for y=1,2 do
			local v = vec2(minmax[x][1], minmax[y][2])
			if view.bbox:contains(v) then
				con.locate(table.unpack(v))
				con.write('+')
			end
		end
	end
end

function View:fillBox(b)
	b = box2(b):clamp(view.bbox)
	for y=b.min[2],b.max[2] do
		con.locate(b.min[1], y)
		con.write((' '):rep(b.max[1] - b.min[1] + 1))
	end
end

view = View()	-- singleton
