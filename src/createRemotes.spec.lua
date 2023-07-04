return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local t = require(ReplicatedStorage.DevPackages.t)
	local types = require(script.Parent.types)
	local createRemotes = require(script.Parent.createRemotes)
	local builder = require(script.Parent.builder)
	local mockRemotes = require(script.Parent.utils.mockRemotes)

	local remotes: types.Remotes<{
		event: types.Remote<string, number>,
		callback: types.AsyncRemote<string, (string, number)>,
		namespace: {
			namespaceEvent: types.Remote<string, number>,
			namespaceCallback: types.AsyncRemote<string, (string, number)>,
		},
	}>

	beforeEach(function()
		-- This runs on the server, so don't test client APIs in this file
		remotes = createRemotes({
			event = builder.remote(t.string, t.number),
			callback = builder.remote(t.string, t.number).returns(t.string),
			namespace = builder.namespace({
				namespaceEvent = builder.remote(t.string, t.number),
				namespaceCallback = builder.remote(t.string, t.number).returns(t.string),
			}),
		})
	end)

	afterEach(function()
		remotes:destroy()
	end)

	it("should create top-level remotes", function()
		expect(remotes.event).to.be.ok()
		expect(remotes.callback).to.be.ok()
		expect(mockRemotes.getMockRemoteEvent("event")).to.be.ok()
		expect(mockRemotes.getMockRemoteFunction("callback")).to.be.ok()
	end)

	it("should create namespaced remotes", function()
		expect(remotes.namespace.namespaceEvent).to.be.ok()
		expect(remotes.namespace.namespaceCallback).to.be.ok()
		expect(mockRemotes.getMockRemoteEvent("namespaceEvent")).to.be.ok()
		expect(mockRemotes.getMockRemoteFunction("namespaceCallback")).to.be.ok()
	end)

	it("should fire a top-level event", function()
		local arg1, arg2, arg3

		remotes.event:connect(function(...)
			arg1, arg2, arg3 = ...
		end)

		mockRemotes.createMockRemoteEvent("event"):FireServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
	end)

	it("should fire a namespaced event", function()
		local arg1, arg2, arg3

		remotes.namespace.namespaceEvent:connect(function(...)
			arg1, arg2, arg3 = ...
		end)

		mockRemotes.createMockRemoteEvent("namespaceEvent"):FireServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
	end)

	it("should invoke a top-level callback", function()
		local arg1, arg2, arg3

		remotes.callback:onRequest(function(...)
			arg1, arg2, arg3 = ...
			return "test"
		end)

		local result = mockRemotes.createMockRemoteFunction("callback"):InvokeServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
		expect(result).to.equal("test")
	end)

	it("should invoke a namespaced callback", function()
		local arg1, arg2, arg3

		remotes.namespace.namespaceCallback:onRequest(function(...)
			arg1, arg2, arg3 = ...
			return "test"
		end)

		local result = mockRemotes.createMockRemoteFunction("namespaceCallback"):InvokeServer("test", 1)

		expect(arg1).to.be.ok() -- player
		expect(arg2).to.equal("test")
		expect(arg3).to.equal(1)
		expect(result).to.equal("test")
	end)
end
