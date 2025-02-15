maestro.command("ban", {"player:target", "time", "reason"}, function(caller, targets, time, reason)
	if not targets or #targets == 0 then
		return true, "Query matched no players."
	elseif #targets > 1 then
		return true, "Query matched more than 1 player."
	end
	local ply = targets[1]
	maestro.ban(ply, time, reason)
	return false, "banned %1 for %2 (%3)"
end, [[
Bans the player for the specified time and reason.]])
maestro.command("banid", {"steamid", "time", "reason"}, function(caller, id, time, reason)
	print(id, time, reason)
	maestro.ban(id, time, reason)
	return false, "banned %1 for %2 (%3)"
end, [[
Bans the SteamID for the specified time and reason.
Any currently connected players with this SteamID will be kicked.]])
maestro.command("unban", {"id", "reason:optional"}, function(caller, id, reason)
	maestro.unban(id, reason)
	if reason then
		return false, "unbanned %1 (%2)"
	end
	return false, "unbanned %1"
end)

if SERVER then
	util.AddNetworkString("maestro_banlog")
end
maestro.command("banlog", {"player:target"}, function(caller, targets)
	if not targets or #targets == 0 then
		return true, "Query matched no players."
	elseif #targets > 1 then
		return true, "Query matched more than 1 player."
	end
	local id = targets[1]:SteamID()
	if caller then
		net.Start("maestro_banlog")
			net.WriteEntity(targets[1])
			net.WriteString(targets[1]:SteamID())
			for json in maestro.read("banlog", true) do
				local item = util.JSONToTable(json)
				if item.id == id then
					net.WriteString(" ")
					net.WriteBool(item.type == "ban")
					net.WriteString(item.reason)
					if item.type == "ban" then
						net.WriteUInt(math.floor(item.length), 32)
						net.WriteUInt(item.prevbans + 1, 16)
						net.WriteBool(item.perma)
					end
				end
			end
		net.Send(caller)
	else
		MsgC(Color(255, 255, 255), "Banlog for ", targets[1]:Nick() .. " ", "(", id, "):\n")
		for json in maestro.read("banlog", true) do
			local item = util.JSONToTable(json)
			if item.id == id then
				local ban = item.type == "ban"
				local reason = item.reason or "no reason"
				local date = item.date
				if ban then
					local length = math.floor(item.length)
					local num = item.prevbans + 1
					local perma = item.perma
					MsgC(maestro.orange, "\t", os.date("%x - ", date), "Ban #", num, ": ", Color(255, 255, 255), reason, maestro.orange, " Length: ", Color(255, 255, 255), perma and "permenant" or maestro.time(length), "\n")
				else
					MsgC(maestro.blue, "\t", os.date("%x - ", date), "Unban: ", Color(255, 255, 255), reason, "\n")
				end
			end
		end
	end
end, [[
Displays a history of bans and unbans for the specified player.]])
maestro.command("banlogid", {"id"}, function(caller, id)
	if caller then
		net.Start("maestro_banlog")
			net.WriteEntity()
			net.WriteString(id)
			for json in maestro.read("banlog", true) do
				local item = util.JSONToTable(json)
				if item.id == id then
					net.WriteString(" ")
					net.WriteBool(item.type == "ban")
					net.WriteString(item.reason or "no reason")
					net.WriteUInt(item.date, 32)
					if item.type == "ban" then
						net.WriteUInt(math.floor(item.length), 32)
						net.WriteUInt(item.prevbans + 1, 16)
						net.WriteBool(item.perma)
					end
				end
			end
		net.Send(caller)
	else
		MsgC(Color(255, 255, 255), "Banlog for (", id, "):\n")
		for json in maestro.read("banlog", true) do
			local item = util.JSONToTable(json)
			if item.id == id then
				local ban = item.type == "ban"
				local reason = item.reason or "no reason"
				local date = item.date
				if ban then
					local length = math.floor(item.length)
					local num = item.prevbans + 1
					local perma = item.perma
					MsgC(maestro.orange, "\t", os.date("%x - ", date), "Ban #", num, ": ", Color(255, 255, 255), reason, maestro.orange, " Length: ", Color(255, 255, 255), perma and "permenant" or maestro.time(length), "\n")
				else
					MsgC(maestro.blue, "\t", os.date("%x - ", date), "Unban: ", Color(255, 255, 255), reason, "\n")
				end
			end
		end
	end
end, [[
Displays a history of bans and unbans for the specified SteamID.]])
if CLIENT then
	net.Receive("maestro_banlog", function()
		local ply = net.ReadEntity()
		local id = net.ReadString()
		local nick = ""
		if ply:IsPlayer() then
			nick = ply:Nick() .. " "
		end
		MsgC(Color(255, 255, 255), "Banlog for ", nick, "(", id, "):\n")
		while true do
			local validate = net.ReadString()
			if validate == "" then return end
			local ban = net.ReadBool()
			local reason = net.ReadString()
			local date = net.ReadUInt(32)
			if ban then
				local length = net.ReadUInt(32)
				local num = net.ReadUInt(16)
				local perma = net.ReadBool()
				MsgC(maestro.orange, "\t", os.date("%x - ", date), "Ban #", num, ": ", Color(255, 255, 255), reason, maestro.orange, " Length: ", Color(255, 255, 255), perma and "permenant" or maestro.time(length), "\n")
			else
				MsgC(maestro.blue, "\t", os.date("%x - ", date), "Unban: ", Color(255, 255, 255), reason, "\n")
			end
		end
	end)
end
