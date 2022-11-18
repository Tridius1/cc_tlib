--Tristan Swanson
--General purpose CC Tweaked API
--Last updated: 10/29/2021

-- Internal

-- Load subjects - dont?
--[[
local time = require("lib/time.lua")
local uuid = require("lib/uuid.lua")
local move = require("lib/move.lua")
local monitor = require("lib/monitor.lua")
local gps = require("lib/gps.lua")
]]

local libTable = {
	time = "lib/time.lua",
	uuid = "lib/uuid.lua",
	move = "lib/move.lua",
	monitor = "lib/monitor.lua",
	gps = "lib/gps.lua"
}
-- Create 
old_v = false
if not (fs.exists("lib")) then
	fs.makeDir("lib")
	print("Installing...")
	old_v = true
end
if not (fs.exists("lib/manifest.json")) then
	m = fs.open("lib/manifest.json", "w")
	m.write(textutils.serialiseJSON(libTable))
	m.close()
	old_v = true
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
	request = http.get(download.url)
	libTable = textutils.unserializeJSON(request.readAll())
	-- library files
	for k,v in pairs(libTable) do
		print("Downloading "..k.." module to "..v)
		download = {name = v, url = "https://raw.githubusercontent.com/Tridius1/cc_tlib/main/"..v}
		request = http.get(download.url)
		data = request.readAll()
		if fs.exists(download.name) then
			fs.delete(download.name)
		end
		file = fs.open(download.name, "w")
		file.write(data)
		file.close()
	end

	print("Done, a restart is recomended")
end

function formatNum(rawRF)
	local names = {
		"Thousand",
		"Million",
		"Billion",
		"Trillion",
		"Quadrillion"
	}

	local digits = math.floor(math.log10(rawRF)) -- actually # digits - 1
	local index = math.floor(digits / 3)
	local fOut = math.floor(rawRF / 10^(digits - 3)) -- 2 significant figures
	fOut = fOut/100 .. " " .. names[index]
	return fOut
end


function getPeri(pType)
	for _, side in ipairs(peripheral.getNames()) do
		if peripheral.getType(side) == pType then
			return peripheral.wrap(side)
		end
	end
	return false
end

function leadZero(numStr, len)
	numStr = tostring(numStr)
	while string.len(numStr) < len do
		numStr = '0' .. numStr
	end
	return numStr
end


local function doPrintTable(table, indent)
	if (indent == nil or indent < 0) then
		error("doPrintTable: Bad indentation value")
	end
	--Reccursive function
	if type(table) == "table" then
		-- Reccursive case
		term.write("{")
		print("")
		indent = indent + 1
		for k, v in pairs(table) do
			for i = 1, indent, 1 do
				term.write("    ")
			end
			term.write(k .." = ")
			doPrintTable(v, indent)
			print("")
		end
		for i = 2, indent, 1 do
			term.write("    ")
		end
		term.write("}")
	else
		-- Base case
		term.write(table)
	end
end

function printTable(table)
	doPrintTable(table, 0)
	print("")
end





-- messages

message = {init = false}

function message:new(chIn, chOut, rtext, dist)
	dist = dist or -1 -- distance optional
	newMsg = {channel = chIn, replyChannel = chOut, content = rtext, distance = distance}
	newMsg.init = true
	newMsg.id = uuid()
	setmetatable(newMsg, {__index = message})
	if type(newMsg.content) == "string" then
		newMsg.isText = true
	else
		newMsg.isText = false
	end
	return newMsg
end

function message:reply(payload, replyChannel)
	local rc = replyChannel or self.channel
	if not self.init then
		error("Reply: Not a valid message")
	end
	net:send(self.replyChannel, payload, rc)
end

-- Networking

local defaultChannel = 100
net = {recieved = {}}

function net:init(channel)
	channel = channel or defaultChannel
	self.modem = getPeri("modem")
	if not self.modem.isWireless() then
		print("Wireless modem required for networking")
		self.ready = false
		return false
	end
	self.ready = true
	return true
end

function net:send(channel, payload, replyChannel)
	replyChannel = replyChannel or channel
	if not self.ready then
		return false
	end
	self.modem.transmit(channel, replyChannel, payload)
end

function net:listen(channel)
	if channel ~= nil then
		self.modem.open(channel)
	end
	print("Listening")
	local event, side, channel, replyChannel, content, distance = os.pullEvent("modem_message")
	local recieved =  message:new(channel, replyChannel, content, distance)
	table.insert(self.recieved, recieved)
	return recieved
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


if (old_v) then
	update()
end

if (arg[1] == "u" or arg[1] == "update") then
	update()
end

local success, modules = pcall(loadModules(libTable))
if success then
	return modules
else
	print("Error loading tlib libraries, updating")
	update()
	return
end