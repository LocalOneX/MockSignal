TODO: Introduce a v3, using coroutine.yield and <T...> typing

Introduction to version 2 of `MockEvent`

Handling:
```lua
		local signal = MockEvent.new()
		
		signal:Once(function(str: string)
			print(str)
		end) --> 4:'Test':
		
		signal:Fire("Test")
	```
