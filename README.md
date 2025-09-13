Handling:
```lua
		local signal = SignalClass.new()
		
		signal:Once(function(str: string)
			print(str)
		end) --> 4:'Test':
		
		signal:Fire("Test")
	```
