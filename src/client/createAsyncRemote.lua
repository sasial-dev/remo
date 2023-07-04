local Promise = require(script.Parent.Parent.Promise)
local types = require(script.Parent.Parent.types)
local constants = require(script.Parent.Parent.constants)

local compose = require(script.Parent.Parent.utils.compose)
local mockRemotes = require(script.Parent.Parent.utils.mockRemotes)
local unwrap = require(script.Parent.Parent.utils.unwrap)

local container = script.Parent.Parent.container

local function promiseRemoteFunction(name: string): Promise.Promise<RemoteFunction>
	if container:FindFirstChild(name) then
		return Promise.resolve(container[name])
	end

	if constants.IS_EDIT then
		return Promise.resolve(mockRemotes.createMockRemoteFunction(name))
	end

	return Promise.fromEvent(container.ChildAdded, function(child)
		return child:IsA("RemoteFunction") and child.Name == name
	end)
end

local function createAsyncRemote(name: string, builder: types.RemoteBuilder): types.AsyncRemote
	local connected = true

	local function handler(...): any
		return
	end

	local function onRequest(self, callback)
		assert(connected, `Cannot use destroyed async remote '{name}'`)
		handler = callback
	end

	local function request(self, ...)
		assert(connected, `Cannot use destroyed async remote '{name}'`)

		local arguments = table.pack(...)

		return promiseRemoteFunction(name):andThen(function(instance)
			local response = table.pack(instance:InvokeServer(table.unpack(arguments, 1, arguments.n)))

			for index, validator in builder.metadata.returns do
				local value = response[index]
				assert(validator(value), `Invalid return value #{index} for async remote '{name}': got {value}`)
			end

			return table.unpack(response, 1, response.n)
		end, function(error): ()
			warn(`Failed to invoke async remote '{name}': {error}`)
		end) :: any
	end

	local function destroy()
		if connected then
			connected = false
			function handler() end
		end
	end

	local asyncRemote: types.AsyncRemote = {
		name = name,
		type = "function" :: "function",
		onRequest = onRequest,
		request = request,
		destroy = destroy,
	}

	local invoke = compose(builder.metadata.middleware)(function(...)
		return unwrap(handler(...))
	end, asyncRemote)

	promiseRemoteFunction(name):andThen(function(instance): ()
		if not connected then
			return
		end

		function instance.OnClientInvoke(...)
			assert(connected, `Async remote '{name}' was invoked after it was destroyed`)

			for index, validator in builder.metadata.parameters do
				local value = select(index, ...)
				assert(validator(value), `Invalid parameter #{index} for async remote '{name}': got {value}`)
			end

			return invoke(...)
		end
	end, function(error): ()
		warn(`Failed to initialize async remote '{name}': {error}`)
	end)

	return asyncRemote
end

return createAsyncRemote
