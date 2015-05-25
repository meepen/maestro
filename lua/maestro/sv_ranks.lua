local ranks = {}
local newfile
util.AddNetworkString("maestro_ranks")
maestro.load("ranks", function(rs, nf)
	ranks, newfile = rs, nf
end)
for rank, tab in pairs(ranks) do
	if tab.inherits and tab.inherits ~= rank then
		setmetatable(tab.perms, {__index = ranks[tab.inherits].perms})
	end
end
function maestro.saveranks()
	maestro.save("ranks", ranks)
	maestro.broadcastranks()
end



function maestro.rankadd(name, inherits, perms)
	perms = perms or {}
	local r = {perms = perms, inherits = inherits, cantarget = "<#" .. name, canrank = "!>#" .. name, flags = {}}
	ranks[name] = r
	if inherits then 
		maestro.ranksetinherits(name, inherits)
	else
		maestro.saveranks()
	end
end
function maestro.rankremove(name)
	for _, v in pairs(player.GetAll()) do
		if maestro.userrank(v) == name then
			maestro.userrank(v, ranks[name].inherits)
		end
	end
	for rank, tab in pairs(ranks) do
		if tab.inherits == name then
			maestro.ranksetinherits(rank, ranks[name].inherits)
		end
	end
	ranks[name] = nil
	maestro.saveranks()
end
function maestro.rankget(name)
	return ranks[name]
end
function maestro.ranksetperms(name, perms)
	local r = maestro.rankget(name)
	r.perms = perms
	maestro.ranksetinherits(name, r.inherits)
end
function maestro.rankaddperms(name, perms)
	local r = ranks[name]
	local p = r.perms
	local newperms = {}
	newperms = table.Copy(p)
	for perm in pairs(perms) do
		newperms[perm] = true
	end
	r.perms = newperms
	maestro.ranksetinherits(name, r.inherits)
end
function maestro.rankremoveperms(name, perms)
	local r = ranks[name]
	local p = r.perms
	local newperms = {}
	newperms = table.Copy(p)
	for perm in pairs(perms) do
		newperms[perm] = false
	end
	r.perms = newperms
	maestro.ranksetinherits(name, r.inherits)
end
function maestro.rankresetperms(name)
	ranks[name].perms = {}
	maestro.ranksetinherits(name, ranks[name].inherits)
end
function maestro.getranktable()
	return ranks
end
function maestro.ranksetinherits(name, inherits, all)
	local r = ranks[name]
	r.inherits = inherits
	if name ~= inherits then
		setmetatable(r.perms, {__index = ranks[inherits].perms})
	end
	if not all then
		for rank, tab in pairs(ranks) do
			maestro.ranksetinherits(rank, tab.inherits, true)
		end
		maestro.saveranks()
	end
end
function maestro.rankflag(rank, name, bool)
	if ranks[rank] then
		ranks[rank].flags[name] = bool
	end
	maestro.saveranks()
end
function maestro.rankgetcantarget(name, str)
	return ranks[name].cantarget
end
function maestro.ranksetcantarget(name, str)
	ranks[name].cantarget = str
	maestro.saveranks()
end
function maestro.rankresetcantarget(name)
	ranks[name].cantarget = "<#" .. name
	maestro.saveranks()
end
function maestro.rankgetpermcantarget(name, perm)
	return ranks[name].perms[perm]
end
function maestro.ranksetpermcantarget(name, perm, str)
	ranks[name].perms[perm] = str
end
function maestro.rankresetpermcantarget(name, perm)
	ranks[name].perms[perm] = true
end
function maestro.rankgetcanrank(name, str)
	return ranks[name].canrank
end
function maestro.ranksetcanrank(name, str)
	ranks[name].canrank = str
	maestro.saveranks()
end
function maestro.rankresetcanrank(name)
	ranks[name].canrank = "!>#" .. name
	maestro.saveranks()
end
function maestro.rankrename(name, to)
	ranks[to] = ranks[name]
	for _, v in pairs(player.GetAll()) do
		if maestro.userrank(v) == name then
			maestro.userrank(v, to)
		end
	end
	for rank, tab in pairs(ranks) do
		if tab.inherits == name then
			maestro.ranksetinherits(rank, to)
		end
	end
	ranks[name] = nil
	maestro.saveranks()
end
function maestro.RESETRANKS()
	ranks = {}
	maestro.rankadd("user", "user", {help = true, who = true})
end


function maestro.sendranks(ply)
	net.Start("maestro_ranks")
		net.WriteTable(ranks)
	net.Send(ply)
end
function maestro.broadcastranks()
	for _, v in pairs(player.GetAll()) do
		maestro.sendranks(v)
	end
end

if newfile then
	maestro.rankadd("user", "user", {help = true, who = true})
end