--!strict
--[[
	Mock RBXScriptSignals efficiently using metatables instead of Instances.
	Version 2 of my original MockSignal repo; Mostly used to replace Instance.new("BindableEvent")
	@LocalOnex 6/12/2025
	
	```lua
		local signal = MockEvent.new()
		
		signal:Once(function(str: string)
			print(str)
		end) --> 4:'Test':
		
		signal:Fire("Test")
	```
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local promise = require(ReplicatedStorage:FindFirstChild("Promise"))

type EventDisconnectionObject = {
	Disconnect: () -> (),
} 

type RawEventObject = {
	_events: { (...any) -> () },
	_tempEvents: { (...any) -> () },
	_event: BindableEvent,
} 

export type EventObject = typeof(setmetatable(
	{} :: RawEventObject,
	{ __index = {} :: {
		new: () -> EventObject,
		Fire: (self: EventObject, ...any) -> (),
		Connect: (self: EventObject, callback: (...any) -> ()) -> EventDisconnectionObject,
		Once: (self: EventObject, callback: (...any) -> ()) -> EventDisconnectionObject,
		Wait: (self: EventObject) -> promise.AnyPromise
	}}
)) 

local module = {}

--[[
	Create a new Event Object.
--]]
module.new = function()
	return (setmetatable(
		{
			_events = {};
			_tempEvents = {}; 
			_event = Instance.new("BindableEvent");
		} :: RawEventObject, { __index = module }
	)) :: EventObject
end

--[[
	Fires the BindableEvent which in turn fires the event.
--]]
module.Fire = function(self: EventObject, ...)
	local args = {...}
	
	local function onConnection(callback: (...any) -> ()) 
		local success, response = pcall(callback, unpack(args))
		if not success then
			warn(debug.traceback(`:{response}:`))
		end
	end
	
	for _, callback in self._events do onConnection(callback) end
	for _, callback in self._tempEvents do onConnection(callback) end
	
	table.clear(self._tempEvents)
	self._event:Fire(...)
end
 
--[[
	Establishes a function to be called when the event fires. Returns an RBXScriptConnection object associated with the connection.
--]]
module.Connect = function(self: EventObject, callback: (...any) -> ())
	table.insert(self._events, callback)
	
	local object = setmetatable({}, {__index = self}) 
	function object:Disconnect()
		local i = table.find(self._events, callback)
		if i then
			table.remove(self._events, i)
		end
	end
	
	return object :: EventDisconnectionObject
end

--[[
	Connects the given function to the event (for a single invocation) and returns an RBXScriptConnection that represents it.
--]]
module.Once = function(self: EventObject, callback: (...any) -> ()) 
	table.insert(self._tempEvents, callback)

	local object = setmetatable({}, {__index = self}) 
	function object:Disconnect()
		local i = table.find(self._tempEvents, callback)
		if i then
			table.remove(self._tempEvents, i)
		end
	end

	return object :: EventDisconnectionObject
end

--[[
	Yields the current thread until the signal fires and returns the arguments provided by the signal.
--]]
module.Wait = function(self: EventObject)
	return promise.fromEvent(self._event.Event)
end

return module
