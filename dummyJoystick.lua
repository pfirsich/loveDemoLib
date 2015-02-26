local Joystick = {}
Joystick.__index = Joystick

function newJoystick(id)
	local self = setmetatable({}, Joystick)
	self.id = id
	self.axes = {}
	self.buttons = {}
	return self
end

function Joystick.getGUID(self)
	return "demoLibDummyJoystick"
end

function Joystick.getName(self)
	return "Dummy Joystick from demoLib"
end

function Joystick.getID(self)
	return self.id, 1
end

function Joystick.isGamepad(self)
	return true
end

function Joystick.isConnected(self)
	return true
end

function Joystick.isVibrationSupported(self)
	-- this is not copied from the previously recorded gamepad, so this breaks determinism if the program is not written in a way where this doesn''t matter!
	-- Also see setVibration, getVibration, which also behave not exactly like the recorded joystick
	return false 
end

function Joystick.getVibration(self)
	return 0, 0
end

function Joystick.setVibration(self, left, right, duration)
	return false
end

function Joystick.updateButton(self, button, state)
	self.buttons[button] = state
end

function Joystick.updateAxis(self, name, value)
	self.axes[name] = value
end

function Joystick.getGamepadAxis(self, name)
	return self.axes[name] or 0.0
end

function Joystick.isGamepadDown(self, ...) -- isGamepadDown(button1, button2, button3, ..., buttonN)
	for i, v in ipairs{...} do
		if not self.buttons[v] then return false end
	end
	return true
end
