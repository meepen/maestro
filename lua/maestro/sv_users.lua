maestro.users = {}
maestro.load("users", function(val)
	maestro.users = val
end)

function maestro.userrank(id, rank)
	if rank then
		local ply
		if type(id) == "Player" then
			ply = id
			id = id:SteamID()
		else
			ply = player.GetBySteamID()
		end
		if not id then
			return
		end
		local prevrank = maestro.userrank(id)
		if IsValid(ply) then
			if maestro.rankget(rank) and not maestro.rankget(rank).anonymous then
				ply:SetNWString("rank", rank)
			else
				ply:SetNWString("rank", "user")
			end
		end
		maestro.users[id] = maestro.users[id] or {}
		maestro.users[id].rank = rank
		if rank == "user" then
			maestro.users[id] = nil
		end
		if IsValid(ply) then
			CAMI.SignalUserGroupChanged(ply, prevrank, rank, "maestro")
		end
		maestro.save("users", maestro.users)
	else
		if type(id) == "Player" then
			id = id:SteamID()
		end
		if not maestro.users[id] then
			return "user"
		end
		if maestro.rankget(maestro.users[id].rank) ~= "user" then
			return maestro.users[id].rank
		end
		return "user"
	end
end

function maestro.RESETUSERS()
	for _, ply in pairs(player.GetAll()) do
		maestro.userrank(ply, "user")
	end
	maestro.users = {}
	maestro.save("users", maestro.users)
end

maestro.hook("CAMI.PlayerUsergroupChanged", "cami", function(ply, prevrank, rank, source)
	if source == "maestro" then return end
	maestro.userrank(ply, rank)
end)
