--!strict

local ConnectionClass = require("./ConnectionClass")

----------------------------------- Types -----------------------------------
type RawSchema<T...> = {
	_events: {[number]: (T...) -> ()},
	_threads: {[number]: thread},
}
type ProtoSchema<T...> = {
	Connect: (self: Schema<T...>, fn: (T...) -> ()) -> (),
	Wait: (self: Schema<T...>) -> (...any),
	Fire: (self: Schema<T...>, T...) -> (),
	Once: (self: Schema<T...>, fn: (T...) -> ()) -> ConnectionClass.Class,
}
export type Schema<T...> = typeof(setmetatable({}::RawSchema<T...>, {__index = {}::ProtoSchema<T...>}))
----------------------------------- Internal -----------------------------------
local Prototype = {}

--[[

	Calls a function once a signal is fired.

]] 
function Prototype:Connect<T...>(fn: (T...) -> ())
	local idx = #self._events + 1
	self._events[idx] = fn
	return ConnectionClass.new(function(...: any) 
		self._events[idx] = nil
	end)
end

--[[

	Waits for a signal to be fired.

]] 
function Prototype:Wait()
	local thread = coroutine.running()
	table.insert(self._threads, thread)
	return coroutine.yield()
end

--[[

	Fires a signal.

]] 
function Prototype:Fire<T...>(...: T...)
	for i = #self._events, 1, -1 do
		local fn = self._events[i]
		task.spawn(fn, ...)
		--table.remove(self._events, i)
	end 
	for i = #self._threads, 1, -1 do
		local thread = self._threads[i]
		coroutine.resume(thread)
		table.remove(self._threads, i)
	end
end

--[[

	Connects a function to the signal only for one fire.

]] 
function Prototype:Once<T...>(fn: (T...) -> ())
	local cn: ConnectionClass.Class?
	cn = self:Connect(function(...)
		if cn then
			cn:Disconnect()
			cn = nil
		end 
		fn(...)
	end)
	return cn
end
----------------------------------- External -----------------------------------
local module = {}

--[[

	Create a new SignalClass.

]]
function module.new<T...>(): Schema<T...>
	return (setmetatable({
		_events = {}:: {[number]: (T...) -> ()},
		_threads = {}:: {[number]: thread},
	}, {__index = Prototype}))::any
end

return module
