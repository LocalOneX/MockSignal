--!strict
--[=[@Onex
	3/10/2025
	Mocks RBXScriptConnection/RBXScriptSignal using Metatables.
]=]---TYPES----------
type Function = (...any) -> (...any)
type raw = {
	_events: {[number]:Function},
	_tempEvents: {[number]:Function},
	_lastFired: number,
	_tick: number,
	_wait: Function,
	_locked: boolean,
	_disconnected: boolean,
}
type proto = {
	new: (locked: boolean?) -> MockSignal,
	
	Fire: (self: MockSignal, ...any) -> nil,
	ConnectParallel: (self: MockSignal) -> nil,
	Connect: (self: MockSignal) -> nil,
	Disconnect: (self: MockSignal) -> nil,
	Once: (self: MockSignal) -> MockSignal,
	Wait: (self: MockSignal) -> number,
}
export type MockSignal = typeof(setmetatable( {}::raw, {__index = {}:: proto} ))--raw & proto
--[[--SETTINGS--]]-------------
local LOCKED_ERROR = "(signal is locked, please unlock it or use Disconnect)"
local DISCONNECTED_ERROR = "(signal is disconnected)"
local UNUSED_ERROR = "(unimplemented, please use %s)"
local WAIT_SENSITIVITY = 0.25


local RunService = game:GetService("RunService")


local module = {} 

function module.new(locked: boolean?): MockSignal--RBXScriptSignal
	local raw: raw = {
		_events = {},
		_tempEvents = {},
		_lastFired = 0,
		_tick = tick(),
		_wait = function() RunService.Heartbeat:Wait() end,
		_locked = ((locked == true) or false),
		_disconnected = false,
		--Event = function() end,
	}
	
	local self: MockSignal = setmetatable(raw:: raw, {__index = module:: proto})
	
	return self
end 

function module:Fire(...)
	if (self._locked) then error(LOCKED_ERROR, 2) end
	if (self._disconnected) then error(DISCONNECTED_ERROR, 2) end
	local args = {...}
	
	local function handle(func: Function)
		task.spawn(function()
			local success, err = pcall(function(...)
				func(unpack(args))
			end)

			if not success then
				error(debug.traceback(string.format(":%s:", err), 2), 2)
			end
		end)
	end
	
	for _, func in self._events do handle(func) end
	for _, func in self._tempEvents do handle(func) end table.clear(self._tempEvents)

	self._lastFired = tick()
end

function module:ConnectParallel(func: Function)
	if (self._locked) then error(LOCKED_ERROR, 2) end
	if (self._disconnected) then error(DISCONNECTED_ERROR, 2) end
	
	error(string.format(UNUSED_ERROR, "Connect"), 2)
end

function module:Connect(func: Function)
	if (self._locked) then error(LOCKED_ERROR, 2) end
	if (self._disconnected) then error(DISCONNECTED_ERROR, 2) end
	
	table.insert(self._events, func)
end

function module:Disconnect()
	self._disconnected = true
	do for _, t in {self._events, self._tempEvents} do table.clear(t) end end
end

function module:Once(func: Function)
	if (self._locked) then error(LOCKED_ERROR, 2) end
	if (self._disconnected) then error(DISCONNECTED_ERROR, 2) end 
	local signal = module.new(true)
	local callInstance = function(...)
		if (signal._disconnected == true) then return end
		func(...)
	end
	table.insert(self._tempEvents, callInstance)
	return signal
end

--[[
	Yields the current thread until the signal fires and returns the arguments provided by the signal.
--]]
function module:Wait(): number
	if (self._locked) then error(LOCKED_ERROR, 2) end
	if (self._disconnected) then error(DISCONNECTED_ERROR, 2) end
	do self._tick = (tick()) end
	repeat self._wait() until (tick() - self._lastFired) < WAIT_SENSITIVITY
	return tick() - self._tick
end 

return module
