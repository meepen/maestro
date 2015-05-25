local protocol = "plaintext" --Set the database protocol here. Availible options: plaintext, sqlite, mysql
local credentials = { --Only used for tmysql4.
	hostname = "localhost",
	username = "root",
	password = "root",
	database = "maestro",
	port = 3306,
}


if protocol == "plaintext" then
	if not file.Exists("maestro", "DATA") then
		file.CreateDir("maestro")
	end

	function maestro.load(name, func)
		local newfile = false
		if not file.Exists("maestro/" .. name .. ".txt", "DATA") then
			file.Write("maestro/" .. name .. ".txt", "")
			newfile = true
		end
		func(util.JSONToTable(file.Read("maestro/" .. name .. ".txt")) or {}, newfile)
	end

	function maestro.save(name, tab)
		file.Write("maestro/" .. name .. ".txt", util.TableToJSON(tab))
	end

	function maestro.log(name, item)
		if type(item) == "table" then item = util.TableToJSON(item) end
		if not file.Exists("maestro/" .. name .. ".txt", "DATA") then
			file.Write("maestro/" .. name .. ".txt", "")
		end
		file.Append("maestro/" .. name .. ".txt", item .. "\n")
	end

	function maestro.read(name, iterator)
		local ret = {}
		if iterator then
			return string.gmatch(file.Read("maestro/" .. name .. ".txt"), "[^\n]+")
		end
		
		for w in string.gmatch(file.Read("maestro/" .. name .. ".txt"), "[^\n]+") do
			ret[#ret + 1] = w
		end
		return ret
	end
elseif protocol == "sqlite" or protocol == "mysql" then
	include("mysqlite.lua")
	MySQLite.initialize{
		EnableMySQL = (protocol == "mysql"),
		Host = credentials.hostname,
		Username = credentials.username,
		Password = credentials.password,
		Database_name = credentials.database,
		Database_port = credentials.port,
	}
	hook.Add("DatabaseInitialized", "maestro_createtables", function()
		MySQLite.query([[
			CREATE TABLE IF NOT EXISTS maestro_users(
				steamID VARCHAR(50) NOT NULL PRIMARY KEY,
				rank VARCHAR(50)
			)
		]])
		MySQLite.query([[
			CREATE TABLE IF NOT EXISTS maestro_ranks(
				name VARCHAR(50) NOT NULL PRIMARY KEY,
				inherits VARCHAR(50),
				cantarget VARCHAR(50),
				canrank VARCHAR(50)
			)
		]])
		MySQLite.query([[
			CREATE TABLE IF NOT EXISTS maestro_rankperms(
				id INTEGER,
				rank VARCHAR(50),
				perm VARCHAR(50),
				val BOOLEAN
			)
		]])
		MySQLite.query([[
			CREATE TABLE IF NOT EXISTS maestro_rankflags(
				id INTEGER,
				rank VARCHAR(50),
				flag VARCHAR(50),
				val BOOLEAN
			)
		]])
	end)
	
	function maestro.load(name, func)
		MySQLite.query([[
			SELECT * FROM maestro_]] .. name .. [[
		]], func)
	end
else
	timer.Simple(20, function()
		error("Maestro database protocol not valid! Make sure it's set EXACTLY as shown at the top of lua/autorun/maestro.lua. EVERYTHING WILL BREAK UNTIL THIS GETS FIXED.")
	end)
	error("Maestro database protocol not valid! Make sure it's set EXACTLY as shown at the top of lua/autorun/maestro.lua. EVERYTHING WILL BREAK UNTIL THIS GETS FIXED.")
end