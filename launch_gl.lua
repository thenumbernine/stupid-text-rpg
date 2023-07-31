local ffi = require 'ffi'
local glfw = require 'ffi.req' 'glfw'
local gl = require 'ffi.req' 'gl'
local glu = require 'ffi.req' 'glu'

launcher = {
	getInput = function()
	end,
}

local stupid = require 'stupid'

local x, width, height

local oldupdate = stupid.update
stupid.update = function()

	local t = glfw.glfwGetTime()
	glfw.glfwGetMousePos(x, nil)
	
	glfw.glfwGetWindowSize(width, height)
	height[0] = math.max(height[0], 1)
	
	gl.glViewport(0, 0, width[0], height[0])
	
	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)
	
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	
	glu.gluPerspective(65, width[0] / height[0], 1, 100)
	
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	gl.gluLookAt(0,1,0,	
				0,20,0,
				0,0,1)
				
	gl.glTranslatef(0, 14, 0)
	gl.glRotatef(.3 * x[0] + t * 100, 0, 0, 1)
	gl.glBegin(gl.GL_TRIANGLES)
	gl.glColor3f( 1.0, 0.0, 0.0 )
	gl.glVertex3f( -5.0, 0.0, -4.0 )
	gl.glColor3f( 0.0, 1.0, 0.0 )
	gl.glVertex3f( 5.0, 0.0, -4.0 )
	gl.glColor3f( 0.0, 0.0, 1.0 )
	gl.glVertex3f( 0.0, 0.0, 6.0 )
	gl.glEnd()
	
	
	if glfw.glfwGetKey(glfw.GLFW_KEY_ESC) == glfw.GLFW_PRESS
	or glfw.glfwGetWindowParam(glfw.GLFW_OPENED) == 0		
	then
		game.done = true
	end
	
	oldupdate()

	glfw.glfwSwapBuffers()
end

assert(glfw.glfwInit(), "glfw init failed")
xpcall(function()
	assert(glfw.glfwOpenWindow(640, 480, 0, 0, 0, 0, 0, 0, glfw.GLFW_WINDOW), "failed to create window")
	glfw.glfwSetWindowTitle("Spinning Triangle")
	glfw.glfwEnable(glfw.GLFW_STICKY_KEYS)
	glfw.glfwSwapInterval(1)
	
	x = ffi.new("int[1]")
	width = ffi.new("int[1]")
	height = ffi.new("int[1]")
	stupid.run()
end, function(err)
	io.stderr:write(err..'\n')
	io.stderr:write(debug.traceback())
end)

glfw.glfwTerminate()
