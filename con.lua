con = {}

function con.init()
end

function con.draw()
end

function con.goto(x,y)
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

