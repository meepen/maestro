maestro.command("strip", {"player:target", "boolean:state(optional)"}, function(caller, targets, state)
	if #targets == 0 then
		return true, "Query matched no players."
	end
	for _, ply in pairs(targets) do
		if state == nil then
			if ply.maestro_strip then
				ply:StripWeapons()
				local tab = ply.maestro_strip
				ply.maestro_strip = false
				for i = 1, #tab do
					ply:Give(tab[i])
				end
			else
				local weps = ply:GetWeapons()
				for i = 1, #weps do
					weps[i] = weps[i]:GetClass()
				end
				ply.maestro_strip = weps
				ply:StripWeapons()
			end
		elseif state then
			if not ply.maestro_strip then
				local weps = ply:GetWeapons()
				for i = 1, #weps do
					weps[i] = weps[i]:GetClass()
				end
				ply.maestro_strip = weps
				ply:StripWeapons()
			end
		else
			if ply.maestro_strip then
				ply:StripWeapons()
				local tab = ply.maesto_strip
				ply.maestro_strip = false
				for i = 1, #tab do
					ply:Give(tab[i])
				end
			end
		end
	end
	if state == nil then
		return false, "toggled weapon strip on %1"
	elseif state then
		return false, "stripped weapons from %1"
	else
		return false, "gave weapons back to %2"
	end
end)

hook.Add("PlayerDeath", "maestro_strip", function(v)
	if v.maestro_strip then
		v.maestro_strip = false
	end
end)

hook.Add("PlayerCanPickupWeapon", "maestro_strip", function(v)
	if v.maestro_strip then
		return false
	end
end)