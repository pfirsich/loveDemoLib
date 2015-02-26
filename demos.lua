require "dummyJoystick"

demoLib = {}

-- TODO: Make demoLib support plugging in/out of joysticks. As of now, the list returned by love.joystick.getJoysticks() must not change during recording
-- TODO: implement joystick API fully (not just the "gamepad" abstraction)
-- All in all the joystick part of demoLib is highly undeterministic if not properly accounted for

-- TODO: Compression
-- Rewind by making full state snapshots every N frames, which can then be seeked

do
	local chunkDelim = "\n"
	local valueDelim = ","

	-- game pad axes mostly only have 10-12 Bit precision and lua floats are 'tostringed' with 17 characters
	-- We're essentially using fixed point precision and spending only 6 bytes instead of four (if we would have saved it in binary)
	local GAMEPAD_AXIS_FP_PREC = 999999999

	-- IO
	function readData()
		local splitPos = demoLib.inputBuffer:find(chunkDelim)
		if splitPos == nil then
			return {}
		else
			local chunk = demoLib.inputBuffer:sub(1, splitPos - 1)
			demoLib.inputBuffer = demoLib.inputBuffer:sub(splitPos + 1) -- a little slow maybe?
			ret = {}
			for v in string.gmatch(chunk, "([^" .. valueDelim .. "]+)") do
				ret[#ret+1] = v
			end
			return ret
		end
	end

	function writeData(str)
		if demoLib.outputFile then demoLib.outputFile:write(str) end
	end

	function headerToString(header)
		str = ""
		for k, v in pairs(header) do
			if checkChar(v, valueDelim) or checkChar(k, valueDelim) then
				error("demoLib: '" .. valueDelim .. "' is not allowed in header keys/values.")
			end

			str = str .. k .. valueDelim .. v .. valueDelim
		end
		return str .. chunkDelim
	end

	function headerFromStrings(strings)
		tbl = {}
		for i = 1, #strings, 2 do
			tbl[strings[i]] = strings[i+1]
		end
		return tbl
	end

	-- helpers
	function checkChar(str, char)
		for i = 1, str:len() do
			if str:sub(i,i) == char then
				return true
			end
		end
		return false
	end

	function getJoystickByID(id)
		for i = 1, #demoLib.joysticks do
			if demoLib.joysticks[i]:getID() == id then return demoLib.joysticks[i] end
		end
		error("demoLib: events recorded from joystick not connected at the start of the program. Connecting/Disconnecting joysticks is currently not supported.")
	end

	-- callbacks for recording
	function demoLib.keypressed(key, isrepeat)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "kp" .. valueDelim .. key .. valueDelim .. (isrepeat and "1" or "0"))
			if love.keypressed then love.keypressed(key, isrepeat) end
		end
	end

	function demoLib.keyreleased(key)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "kr" .. valueDelim .. key)
			if love.keyreleased then love.keyreleased(key) end
		end
	end

	function demoLib.mousepressed(x, y, button)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "mp" .. valueDelim .. button)
			if love.mousepressed then love.mousepressed(x, y, button) end
		end
	end

	function demoLib.mousereleased(x, y, button)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "mr" .. valueDelim .. button)
			if love.mousereleased then love.mousereleased(x, y, button) end
		end
	end

	function demoLib.mousemoved(x, y, dx, dy)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "m" .. valueDelim .. tostring(dx) .. valueDelim .. tostring(dy))
			demoLib.mouse = {x, y}
			if love.mousemoved then love.mousemoved(x, y, dx, dy) end
		end
	end

	function demoLib.quit()
		writeData(valueDelim .. "q" .. chunkDelim)
	end

	function demoLib.gamepadaxis(joystick, axis, value)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "ga" .. valueDelim .. joystick:getID() .. valueDelim .. axis .. valueDelim .. tostring(math.floor(GAMEPAD_AXIS_FP_PREC*value)))
			if love.gamepadaxis then love.gamepadaxis(joystick, axis, value) end
		end
	end

	function demoLib.gamepadpressed(joystick, button)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "gp" .. valueDelim .. joystick:getID() .. valueDelim .. button)
			if love.gamepadpressed then love.gamepadpressed(joystick, button) end
		end
	end

	function demoLib.gamepadreleased(joystick, button)
		if demoLib.mode == "record" then
			writeData(valueDelim .. "gr" .. valueDelim .. joystick:getID() .. valueDelim .. button)
			if love.gamepadreleased then love.gamepadreleased(joystick, button) end
		end
	end

	-- overriden functions for recording / playback
	function demoLib.getJoysticks()
		if demoLib.mode == "playback" then
			return demoLib.joysticks
		end
	end

	-- overriden functions for playback
	function demoLib.keyboardIsDown(key)
		local v = demoLib.downMap.keyboard[key]
		return v == nil and false or v
	end

	function demoLib.mouseIsDown(button)
		local v = demoLib.downMap.mouse[button]
		return v == nil and false or v
	end

	function demoLib.pass() end

	function demoLib.init(mode, filename, header)
		header = header or {}

		demoLib.mode = mode
		demoLib.mouse = {0,0}
		demoLib.love = {}
		demoLib.state = mode

		if mode == "record" then
			-- find a file to write to
			for N = 1, 1000 do
				local fname = filename:gsub("%*", tostring(N))
				if not love.filesystem.isFile(fname) then
					demoLib.outputFile, errStr = love.filesystem.newFile(fname, "w")
					if demoLib.outputFile == nil then
						error("demoLib: demo file '" .. fname .. "' could not be opened for writing. Error: " .. errStr)
					end
					break
				end
			end

			if demoLib.outputFile == nil then
				error("demoLib: demo files from 1 to 1000 are all already existing.")
			end

			-- hook into love callbacks
			love.handlers.keypressed = demoLib.keypressed
			love.handlers.keyreleased = demoLib.keyreleased
			love.handlers.mousepressed = demoLib.mousepressed
			love.handlers.mousereleased = demoLib.mousereleased
			love.handlers.mousemoved = demoLib.mousemoved

			love.handlers.gamepadaxis = demoLib.gamepadaxis
			love.handlers.gamepadpressed = demoLib.gamepadpressed
			love.handlers.gamepadreleased = demoLib.gamepadreleased

			-- setup other stuff
			writeData(headerToString(header))

			-- save currently connected joysticks, actually this should be done for every getJoysticks call during recording
			local joysticks = love.joystick.getJoysticks()
			local jstr = valueDelim .. "j"
			for i = 1, #joysticks do
				jstr = jstr .. valueDelim .. tostring(joysticks[i]:getID())
			end
			writeData(jstr .. chunkDelim)
			return joysticks
		elseif mode == "playback" then
			demoLib.joysticks = {}

			demoLib.inputFile, errStr = love.filesystem.newFile(filename, "r")
			if demoLib.inputFile == nil then
				error("demoLib: demo file '" .. filename .. "' could not be opened for reading. Error: " .. errStr)
			end
			demoLib.inputBuffer = demoLib.inputFile:read()
			demoLib.inputFile:close()
			demoLib.inputFile = nil

			demoLib.love.keyboardIsDown = love.keyboard.isDown
			love.keyboard.isDown = demoLib.keyboardIsDown
			love.mouse.isDown = demoLib.mouseIsDown

			love.joystick.getJoysticks = demoLib.getJoysticks
			love.joystick.getJoystickCount = function() return #demoLib.joysticks end

			-- I don't need this.
			_ = [[
			hook(love.mouse.setPosition, "mouseSetPosition")
			hook(love.mouse.setX, "mouseSetX")
			hook(love.mouse.setY, "mouseSetY")
			]]

			-- other init
			demoLib.downMap = {}
			demoLib.downMap.keyboard = {}
			demoLib.downMap.mouse = {}

			local header = headerFromStrings(readData())

			local joystickIDs = readData()
			for i = 2, #joystickIDs do
				demoLib.joysticks[#demoLib.joysticks + 1] = newJoystick(tonumber(joystickIDs[i]))
			end

			return header
		else
			error("demoLib: initialization mode unknown.")
		end
	end

	function demoLib.update()
		if demoLib.mode == "record" then
			writeData(chunkDelim)
		else
			local currentChunk = readData()

			local i = 1 -- because apparently I can't modify the iteration variable of a for loop
			while i <= #currentChunk do
				local id = currentChunk[i]
				if id == "m" then
					local dmx, dmy = tonumber(currentChunk[i+1]), tonumber(currentChunk[i+2])
					demoLib.mouse = {demoLib.mouse[1] + dmx, demoLib.mouse[2] + dmy}
					i = i + 2
				elseif id == "kp" then
					demoLib.downMap.keyboard[currentChunk[i+1]] = true
					if love.keypressed then love.keypressed(currentChunk[i+1], currentChunk[i+2] == "1" and true or false) end
					i = i + 2
				elseif id == "kr" then
					demoLib.downMap.keyboard[currentChunk[i+1]] = false
					if love.keyreleased then love.keyreleased(currentChunk[i+1]) end
					i = i + 1
				elseif id == "mp" then
					demoLib.downMap.mouse[currentChunk[i+1]] = true
					if love.mousepressed then love.mousepressed(demoLib.mouse[1], demoLib.mouse[2], currentChunk[i+1]) end
					i = i + 1
				elseif id == "mr" then
					demoLib.downMap.mouse[currentChunk[i+1]] = false
					if love.mousereleased then love.mousereleased(demoLib.mouse[1], demoLib.mouse[2], currentChunk[i+1]) end
					i = i + 1
				elseif id == "ga" then
					local joystick, axis, value = getJoystickByID(tonumber(currentChunk[i+1])), currentChunk[i+2], tonumber(currentChunk[i+3])/GAMEPAD_AXIS_FP_PREC
					joystick:updateAxis(axis, value)
					if love.gamepadaxis then love.gamepadaxis(joystick, axis, value) end
					i = i + 3
				elseif id == "gp" then
					local joystick, button = getJoystickByID(tonumber(currentChunk[i+1])), currentChunk[i+2]
					joystick:updateButton(button, true)
					if love.gamepadpressed then love.gamepadpressed(joystick, button) end
					i = i + 2
				elseif id == "gr" then
					local joystick, button = getJoystickByID(tonumber(currentChunk[i+1])), currentChunk[i+2]
					joystick:updateButton(button, false)
					if love.gamepadreleased then love.gamepadreleased(joystick, button) end
					i = i + 2
				elseif id == "q" then
					love.event.push("quit")
				else
					error("demoLib: event not recognized - '" .. currentChunk[i] .. "'")
				end

				i = i + 1
			end

			love.mouse.setPosition(unpack(demoLib.mouse))
		end
	end

	function demoLib.finalize()
		if demoLib.mode == "record" then
			demoLib.outputFile:close()
			demoLib.outputFile = nil
		end
	end
end

return demoLib
