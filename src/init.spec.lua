return function()
	local constants = require(script.Parent.constants)
	local mockRemotes = require(script.Parent.utils.mockRemotes)

	local IS_EDIT = constants.IS_EDIT

	beforeAll(function()
		-- Edit constants so tests run client and server with mock remotes
		constants.IS_EDIT = true
	end)

	afterAll(function()
		constants.IS_EDIT = IS_EDIT
	end)

	afterEach(function()
		mockRemotes.destroyAll()
	end)
end
