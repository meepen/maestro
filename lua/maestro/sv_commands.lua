maestro.commands = maestro.commands or {}

util.AddNetworkString("maestro_commands")
util.AddNetworkString("maestro_cmd")
function maestro.sendcommands(ply)
	net.Start("maestro_commands")
		net.WriteTable(maestro.commands)
	net.Send(ply)
end

player.GetBySteamID = player.GetBySteamID or function()
	return false
end
player.GetBySteamID64 = player.GetBySteamID64 or function()
	return false
end

local function convertTo(val, t, ply, cmd)
	if t == "player" then
		return maestro.target(val, ply, cmd)
	elseif t == "rank" then
		if not ply then return val end
		local cr = maestro.rankget(maestro.userrank(ply)).canrank
		if cr then
			local ranks = maestro.targetrank(cr, maestro.userrank(ply))
			if ranks[val] then
				return val
			end
			return false, "You can't target this rank!"
		else
			return val
		end
	elseif t == "number" then
		return tonumber(val)
	elseif t == "boolean" then
		if val == "true" then
			return true
		elseif val == "1" then
			return true
		elseif val == "yes" then
			return true
		elseif val == "t" then
			return true
		end
		return false
	elseif t == "time" then
		return maestro.toseconds(val)
	elseif t == "steamid" and IsValid(ply) then
		local ret = maestro.cantargetid(ply:SteamID(), val, cmd)
		if not ret then
			return false, "You can't target this SteamID!"
		end
		return val
	end
	return val
end

local function handleError(ply, cmd, msg)
	if IsValid(ply) then
		maestro.chat(ply, maestro.orange,  cmd .. ": " .. msg)
	else
		MsgC(maestro.orange, cmd .. ": " .. msg .. "\n")
	end
end

local function handleMultiple(a, ret, cmd, num)
	local arg = maestro.commands[cmd].args[num] or maestro.commands[cmd].args[#maestro.commands[cmd].args]
	local t = string.match(arg, "[^:]+")
	if type(a) == "table" then
		table.sort(a, function(a, b)
			if type(a) == "Player" then
				return a:Nick() < b:Nick()
			end
			return a < b
		end)
		for j = 1, #a do
			if j == 1 then
				table.insert(ret, a[j])
			elseif j == #a then
				if #a > 2 then
					table.insert(ret, ", and ")
				else
					table.insert(ret, " and ")
				end
				table.insert(ret, a[j])
			else
				table.insert(ret, ", ")
				table.insert(ret, a[j])
			end
		end
	elseif t == "time" then
		table.insert(ret, maestro.blue)
		print(maestro.time(a))
		table.insert(ret, maestro.time(a))
	elseif t == "steamid" then
		table.insert(ret, "(")
		table.insert(ret, maestro.blue)
		table.insert(ret, a)
		table.insert(ret, Color(255, 255, 255))
		table.insert(ret, ")")
	else
		table.insert(ret, maestro.blue)
		table.insert(ret, tostring(a))
	end
end

function maestro.runcmd(silent, cmd, args, ply)
	if not maestro.commands[cmd] then
		print("Invalid command!")
		return
	end
	local endarg
	for i = 1, #args do
		local arg = maestro.commands[cmd].args[i]
		if not arg then
			if not endarg then
				endarg = i - 1
			end
			local desc = string.match(maestro.commands[cmd].args[endarg] or "", "[^:]+$")
			if not string.find(desc or "", "multiple") then
				args[endarg] = args[endarg] .. " " .. args[i]
				args[i] = nil
			end
		end
	end
	local ident = "(Console)"
	if IsValid(ply) then
		ident = ply:Nick() .. "(" .. ply:SteamID() .. ")"
	end
	maestro.log("log_" .. os.date("%y-%m-%d"), os.date("[%H:%M] ") .. ident .. ": ms " .. cmd .. " " .. table.concat(args, " "))
	for i = 1, #args do
		local err
		args[i], err = convertTo(args[i], string.match(maestro.commands[cmd].args[i] or "", "[^:]+"), ply, cmd)
		if err then
			handleError(ply, cmd, err)
			return
		end
	end
	for i = 1, #maestro.commands[cmd].args do
		local arg = maestro.commands[cmd].args[i]
		local desc = string.match(arg, "[^:]+$")
		if not args[i] and not string.find(desc, "optional") and not string.find(desc, "multiple") then
			handleError(ply, cmd, "Missing required argument \"" .. arg .. "\", aborting.")
			return
		end
	end
	local ret = hook.Call("maestro_command", nil, ply, cmd, args)
	if ret then
		if type(ret) == "string" then
			handleError(ply, cmd, ret)
		end
		return
	end
	local err, msg = maestro.commands[cmd].callback(ply, unpack(args))
	if err then
		handleError(ply, cmd, msg)
	elseif msg then
		local t = string.Explode("%%[%d%%]", msg, true)
		local ret = {ply or "(Console)", " "}
		local i = 1
		local max = 1
		for m in string.gmatch(msg, "%%%d") do --tally up
			local num = tonumber(m:sub(2, 2))
			max = math.max(max, num)
		end
		max = max + 1
		for m in string.gmatch(msg, "%%[%d%%]") do
			local num = tonumber(m:sub(2, 2))
			table.insert(ret, Color(255, 255, 255))
			table.insert(ret, t[i])
			if num then --normal argument
				local a = args[num]
				handleMultiple(a, ret, cmd, num)
			else --it's a vararg
				table.insert(ret, maestro.orange)
				table.insert(ret, "[")
				for i = max, #args do
					local a = args[i]
					table.insert(ret, Color(255, 255, 255))
					if i ~= max and i == #args then
						if i - max > 2 then
							table.insert(ret, ", and ")
						else
							table.insert(ret, " and ")
						end
					elseif i ~= max then
						table.insert(ret, ", ")
					end
					handleMultiple(a, ret, cmd, num)
				end
				table.insert(ret, maestro.orange)
				table.insert(ret, "]")
			end
			i = i + 1
		end
		if #t[#t] ~= 0 then
			table.insert(ret, Color(255, 255, 255))
			table.insert(ret, t[#t])
		end

		if silent then
			local ranks = {}
			for name, tab in pairs(maestro.rankgettable()) do
				local cr = tab.canrank
				local rs = maestro.targetrank(cr, maestro.userrank(ply))
				if rs[maestro.userrank(ply)] then
					ranks[name] = true
				end
			end
			local plys = {}
			for _, ply in pairs(player.GetAll()) do
				if ranks[maestro.userrank(ply)] then
					plys[#plys + 1] = ply
				end
			end
			maestro.chat(plys, Color(64, 64, 64), "silent ", Color(255, 255, 255), unpack(ret))
		else
			maestro.chat(nil, unpack(ret))
		end
	end
end

net.Receive("maestro_cmd", function(len, ply)
	local num = net.ReadUInt(8)
	local cmd = string.lower(net.ReadString())
	if maestro.commands[cmd] then
		if maestro.rankget(maestro.userrank(ply)).perms[cmd] then
			local args = {}
			for i = 1, num - 1 do
				args[i] = net.ReadString()
			end
			local silent = net.ReadBool()
			maestro.runcmd(silent, cmd, args, ply)
		else
			maestro.chat(ply, maestro.orange,  cmd .. ": Insufficient permissions!")
		end
	else
		maestro.chat(ply, maestro.orange, "Unrecognized command: " .. cmd)
	end
end)

function maestro.command(cmd, args, callback)
	for k, arg in pairs(args) do
		args[k] = string.gsub(arg, "%s", "_")
	end
	maestro.commands[cmd] = {args = args, callback = callback}
end

concommand.Add("ms", function(ply, cmd, args, str)
	local cmd = args[1]
	table.remove(args, 1)
	maestro.runcmd(false, cmd, args)
end)
concommand.Add("mss", function(ply, cmd, args, str)
	local cmd = args[1]
	table.remove(args, 1)
	maestro.runcmd(true, cmd, args)
end)

maestro.hook("PlayerSay", "maestro_command", function(ply, txt, team)
	if txt:sub(1, 1) == "!" then
		txt = txt:sub(2)
		local args = maestro.split(txt)
		local cmd = args[1]
		if not cmd then
			return
		end
		table.remove(args, 1)
		cmd = string.lower(cmd)
		if maestro.commands[cmd] then
			if maestro.rankget(maestro.userrank(ply)).perms[cmd] then
				maestro.runcmd(team, cmd, args, ply)
			else
				maestro.chat(ply, maestro.orange, cmd, ": Insufficient permissions!")
			end
			return ""
		end
	else
		maestro.log("log_" .. os.date("%y-%m-%d"), os.date("[%H:%M] ") .. ply:Nick() .. "(" .. ply:SteamID() .. "): " .. txt)
	end
end)
