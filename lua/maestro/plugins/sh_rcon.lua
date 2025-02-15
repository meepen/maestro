maestro.command("rcon", {"string:command"}, function(caller, cmd)
	cmd = string.Explode(" ", cmd)
	RunConsoleCommand(unpack(cmd))
	return false, "ran command %1 on the server"
end, [[
Runs a console command on the server.]])

local function lua(code, caller)
	local func, a1, a2, a3 = CompileString(code, "maestro_lua", false)
	local env = setmetatable({}, {
		__index = function(tab, key)
			if _G[key] then return _G[key] end
			if key == "this" then
				return caller:GetEyeTrace().Entity
			elseif key == "me" then
				return caller
			else
				local plys = player.GetAll()
				for i = 1, #plys do
					if string.lower(plys[i]:Nick()) == string.lower(key) then
						return plys[i]
					end
				end
				for i = 1, #plys do
					if string.find(string.lower(plys[i]:Nick()), string.lower(key)) then
						return plys[i]
					end
				end
			end
		end,
		__newindex = _G,
	})
	if type(func) == "string" then
		return true, func
	end
	setfenv(func, env)
	local ran, err = pcall(func)
	if err then
		return true, err
	end
	return false, "ran code %1 on the server"
end
maestro.command("lua", {"string:lua"}, function(caller, code)
	return lua(code, caller)
end, [[
Runs Lua on the server.]])
maestro.command("l", {"string:lua"}, function(caller, code)
	return lua(code, caller)
end, [[
Runs Lua on the server.]])

maestro.command("ent", {"class", "keyvalues(multiple)"}, function(caller, class, ...)
	if not caller then
		return true, "You cannot create an entity from the console!"
	elseif not class then
		return true, "Invalid class!"
	end
	local params = {...}
	local ent = ents.Create(class)
	if not IsValid(ent) then
		return true, "Invalid entity \"" .. class .. "\"."
	end
	ent:SetPos(caller:GetEyeTrace().HitPos + Vector(0, 0, 25))

	for i = 1, #params do
		if tonumber(params[i]) then
			ent:AddFlags(tonumber(params[i]))
		else
			local key, value = string.match(params[i], "([^:]+):([^:]+)")
			if not key or not value then
				ent:Remove()
				return true, "Invalid keyvalue pair \"" .. params[i] .. "\". Keyvalues are colon separated."
			end
			ent:SetKeyValue(key, value)
		end
	end

	ent:Spawn()
	ent:Activate()

	undo.Create("ms ent")
		undo.AddEntity(ent)
		undo.SetPlayer(caller)
	undo.Finish()
	if #params > 0 then
		return false, "created ent %1 with params %%"
	end
	return false, "created ent %1"
end, [[
Creates an entity and sets properties on it.
Keyvalues are formatted as such:
key:value
Flags are numbers.]])
maestro.command("fire", {"input", "param", "number:delay"}, function(caller, input, param, delay)
	if not caller then
		return true, "You cannot fire an ent from the console!"
	end
	local ent = caller:GetEyeTrace().Entity
	if not IsValid(ent) or ent == Entity(0) then
		return true, "You need to be looking at an entity!"
	end
	if not input then
		return true, "You must specify an input!"
	end
	ent:Fire(input, param, delay)
	if delay then
		return false, "fired input %1 on " .. tostring(ent) .. " with param %2 and delay %3"
	elseif param then
		return false, "fired input %1 on " .. tostring(ent) .. " with param %2"
	end
	return false, "fired input %1 on " .. tostring(ent)
end, [[
Fires an input on an entity. Can be used to do virtually anything.]])
