maestro.ranks = {}
net.Receive("maestro_ranks", function()
	local ranks = net.ReadTable()
	for rank, r in pairs(ranks) do
		setmetatable(r.perms, {__index = function(tab, key)
			if rank == "root" then return true end
			if tab ~= maestro.ranks[r.inherits].perms then
				return maestro.ranks[r.inherits].perms[key]
			end
		end})
		setmetatable(r.flags, {__index = function(tab, key)
			if tab ~= maestro.ranks[r.inherits].flags then
				return maestro.ranks[r.inherits].flags[key]
			end
		end})
	end
	maestro.ranks = ranks
	for k, v in pairs(ranks) do
		if CAMI.GetUsergroup(k) then continue end

		CAMI.RegisterUsergroup({
			Name = k,
			Inherits = v.inherits,
		}, "maestro")
	end
	for k, v in pairs(CAMI.GetUsergroups()) do
		if ranks[k] then continue end
		CAMI.UnregisterUsergroup(k, "maestro")
	end
end)

function maestro.rankget(name)
	return maestro.ranks[name] or {flags = {}, perms = {}}
end
function maestro.rankgetcantarget(name, str)
	return maestro.ranks[name].cantarget
end
function maestro.rankgetpermcantarget(name, perm)
	return maestro.ranks[name].perms[perm]
end
function maestro.rankgettable()
	return maestro.ranks
end
