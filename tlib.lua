--Tristan Swanson
--General purpose CC Tweaked API
--Last updated: 10/29/2021

-- Internal


local libTable = {}
-- Installed?
old_v = false
if not (fs.exists("lib")) then
	fs.makeDir("lib")
	print("Installing...")
	old_v = true
end
if not (fs.exists("lib/manifest.json")) then
	print("Installing...")
	old_v = true
else
	--load er up
	local mfile = fs.open("lib/manifest.json", "r")
	libTable = textutils.unserializeJSON(mfile.readAll())
	mfile.close()
end

function update()
	term.clear()
	term.setCursorPos(0, 0)
	print("Updating tlib")

	-- Main File
	local download = {name = "tlib.lua", url = "https://raw.githubusercontent.com/Tridius1/cc_tlib/main/tlib.lua"}

	local request = http.get(download.url)
	local data = request.readAll()

	if fs.exists(download.name) then
		fs.delete(download.name)
	end
	local file = fs.open(download.name, "w")
	file.write(data)
	file.close()

	-- Manifest
	if not (fs.exists("lib")) then
		fs.makeDir("lib")
	end
	download = {name = "manifest.json", url = "https://raw.githubusercontent.com/Tridius1/cc_tlib/main/lib/manifest.json"}
	request, e = http.get(download.url)
	if (request == nil) then
		print("http get failed: manifest")
		error(e)
	end

	libTable = textutils.unserializeJSON(request.readAll())
	-- library files
	for k,v in pairs(libTable) do
		print("Downloading "..k.." module to "..v)
		download = {name = v, url = "https://raw.githubusercontent.com/Tridius1/cc_tlib/main/"..v}
		request, e = http.get(download.url)
		if (request == nil) then
			print("http get failed: "..k)
			error(e)
		end
		data = request.readAll()
		if fs.exists(download.name) then
			fs.delete(download.name)
		end
		file = fs.open(download.name, "w")
		file.write(data)
		file.close()
	end

	print("Done")
end


-- Load up all modules
local function loadModules(lib)
	modules = {}
	for k,v in pairs(lib) do
		for n,f in pairs(require("lib."..k)) do
			modules[n] = f
		end
	end
	return modules
end

if (arg[1] == "u" or arg[1] == "update") then
	update()
elseif (old_v) then
	update()
end

local success, modules = pcall(loadModules, libTable)
if success then
	return modules
else
	print("Error loading tlib libraries, update required")
	return
end