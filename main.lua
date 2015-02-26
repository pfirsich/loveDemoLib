demoLib = require "demos"

function love.load()
	love.filesystem.setIdentity("demoLib_Test")
	if false then
		local n, version, v, device = love.graphics.getRendererInfo()
		demoLib.init("record", "demo_*.demo", {seed = tostring(love.math.getRandomSeed()), os = love.system.getOS(), glVersion = version, glDevice = device})
	else
		local header = demoLib.init("playback", "demo_5.demo")
		print(header.os .. " --- " .. header.glDevice)
	end
	str = ""
end

function love.keypressed(key, isrepeat) 
	str = str .. key
end

function love.draw()
	love.graphics.printf(str, 0, 0, 400)
	
	if love.keyboard.isDown(" ") then
		love.graphics.rectangle("fill", 100, 100, 200, 200)
	end
	
	if love.mouse.isDown("l") then
		love.graphics.rectangle("fill", 400, 400, 100, 100)
	end
	
	local squareOffsetX, squareOffsetY = 0, 0
	local squareSize = 10
	local offsetRadius = 120

	for i, joystick in ipairs(love.joystick.getJoysticks()) do
		squareOffsetX = squareOffsetX + joystick:getGamepadAxis("leftx") * offsetRadius
		squareOffsetY = squareOffsetY + joystick:getGamepadAxis("lefty") * offsetRadius
		squareSize = squareSize + (joystick:isGamepadDown("a") and 1 or 0) * 10
	end
	
	love.graphics.rectangle("fill", 600 + squareOffsetX - squareSize/2, 400 + squareOffsetY - squareSize/2, squareSize, squareSize)
end

function love.quit()
	demoLib.quit()
	demoLib.finalize()
	return false
end

function love.update()
	demoLib.update() -- advance and set/get mouse position / other data
end