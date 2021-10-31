--Tristan Swanson
--General purpose CC Tweaked API
--Last updated: 10/29/2021

-- Internal

function update()
	term.clear()
	term.setCursorPos(0, 0)
	print("Updating tlib")

	download = {name = "tlib.lua", url = "https://raw.githubusercontent.com/Tridius1/cc_tlib/main/tlib.lua"}

	request = http.get("https://raw.githubusercontent.com/Tridius1/cc_tlib/main/tlib.lua")
	data = request.readAll()

	if fs.exists(download.name) then
		fs.delete(download.name)
	end
	file = fs.open(download.name, "w")
	file.write(data)
	file.close()
	print("Done, a restart is recomended")
end

function formatRF(rawRF)
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

function datetime()
	-- returns time table for now
	local time = os.epoch("utc") / 1000 --Seconds not milliseconds
	local utc_time_table = os.date("!*t", time)
	local offset = 21600 -- MST is -6 from UTC
	if utc_time_table.isdst then
		offset = 25200 -- MDT is -7 from UTC
	end
	local time_table = os.date("!*t", time - offset) --mnt time is -6 from UTC
	return time_table
end

--Timestamps

local timestampObj = {t = "prototype", val = nil}
local timestampMeta = {
	__index = timestampObj,
	__call = function (t_obj)
		return t_obj.val
	end
}

function timestampObj:newDatetime(ts)
	local value = ts or os.epoch("utc")
	local newTimestamp = {t = "datetime", val = value}
	setmetatable(newTimestamp, timestampMeta)
	return newTimestamp
end

function timestampObj:newDelta(msec)
	if msec == nil then
		error("timestampObj:newDelta: Parameter cannot be nil")
	end
	local newTimestamp = {t = "delta", val = msec}
	setmetatable(newTimestamp, timestampMeta)
	return newTimestamp
end

function timestampObj:realize(timeObj)
	if timeObj.t == "datetime" then
		return self:newDatetime(timeObj.val)
	elseif timeObj.t == "delta" then
		return self:newDelta(timeObj.val)
	else
		error("timestampObj:realize: Passed object not of known timestamp type")
	end
end

function realizeTimestamp(timeObj)
	return timestampObj:realize(timeObj)
end

function timestampObj:timeTable()
	if not (self.t == "datetime") then
		error("timestampObj:timeTable: Argument must be timestamp of type datetime")
	end
	local stampInSec = self.val / 1000
	local utc_time_table = os.date("!*t", stampInSec)
	local offset = 21600 -- MST is -6 from UTC
	if utc_time_table.isdst then
		offset = 25200 -- MDT is -7 from UTC
	end
	local time_table = os.date("!*t", stampInSec - offset) --mnt time is -6 from UTC
	return time_table
end

function timestampObj:formatDatetime(dtFormat)
	-- @h = hour, @m = minute, @s = second, @d = day of month, @D = day of year, @M = month, @y = year [yy], @Y = year [yyyy], @l = is daylight savings##
	if not (self.t == "datetime") then
		error("timestampObj:formatDatetime: Argument must be timestamp of datetime type")
	end

	--default
	if dtFormat == nil then
		dtFormat = "@M/@d/@Y @h:@m:@s"
	end

	local time_table = self:timeTable()
	local dtStr = dtFormat:gsub("@h", time_table.hour)
	dtStr = dtStr:gsub("@m", time_table.min)
	dtStr = dtStr:gsub("@s", time_table.sec)
	dtStr = dtStr:gsub("@d", time_table.day)
	dtStr = dtStr:gsub("@D", time_table.yday)
	dtStr = dtStr:gsub("@M", time_table.month)
	dtStr = dtStr:gsub("@y", string.sub(time_table.year, 3))
	dtStr = dtStr:gsub("@Y", time_table.year)
	dtStr = dtStr:gsub("@l", time_table.isdst)
	return dtStr
end

function timestampObj:deltaTable()
	local time_table = {}
	local time = self.val -- milliseconds
	if time < 0 then -- negative check
		time_table.neg = true
		time = time * (-1)
	else
		time_table.neg = false
	end
	time_table.msec = time % 1000
	time = (time - time_table.msec) / 1000 -- clean seconds
	time_table.sec = time % 60
	time = (time - time_table.sec) / 60 -- clean minutes
	time_table.min = time % 60
	time = (time - time_table.min) / 60 -- clean hours
	time_table.hour = time % 24
	time = (time - time_table.hour) / 24 -- clean days
	time_table.day = time % 365
	time = (time - time_table.day) / 363 -- clean years
	time_table.year = time
	
	return time_table
end

function timestampObj:formatDelta(dFormat)
	-- @h = hour, @m = minute, @s = second, @d = day of month, @D = day of year, @M = month, @y = year [yy], @Y = year [yyyy], @l = is daylight savings##
	if not (self.t == "delta") then
		error("timestampObj:formatDelta: Argument must be timestamp of delta type")
	end
	local time_table = self:deltaTable()

	--default
	if dFormat == nil then
		if time_table.sec == 0 then
			dFormat = "@c milliseconds"
		else
			dFormat = "@s seconds"
			if time_table.min > 0 then
				dFormat = "@m minutes, " .. dFormat
				if time_table.hour > 0 then
					dFormat = "@h hours, " .. dFormat
					if time_table.day > 0 then
						dFormat = "@h days, " .. dFormat
					end
				end
			end
		end
		if time_table.neg then
			dFormat = "negative " .. dFormat
		end
	end

	local dtStr = dFormat:gsub("@h", time_table.hour)
	dtStr = dtStr:gsub("@m", time_table.min)
	dtStr = dtStr:gsub("@s", time_table.sec)
	dtStr = dtStr:gsub("@c", time_table.msec)
	dtStr = dtStr:gsub("@d", time_table.day)
	dtStr = dtStr:gsub("@D", time_table.yday)
	dtStr = dtStr:gsub("@M", time_table.month)
	dtStr = dtStr:gsub("@y", string.sub(time_table.year, 3))
	dtStr = dtStr:gsub("@Y", time_table.year)
	return dtStr

end

function timestampObj:format(template)
	if self.t == "datetime" then
		return self:formatDatetime(template)
	elseif self.t == "delta" then
		return self:formatDelta(template)
	else
		error("timestampObj:format: Invalid timestamp")
	end
end

function timestampObj:age()
	if self.t == "delta" then
		return self -- detla is age
	elseif self.t == "datetime" then
		-- quick maths
		return (timestamp() - self)
	else
		error("timestampObj:age: Timestamp of type '" .. self.t .. "' has no defined age")
	end
end

function timestampMeta.__sub(oldtime, newtime)
	--must be sent a timestamp or int
	if type(newtime) == "number" then
		-- assume number is in seconds
		newtime = oldtime:newDelta(newtime * 1000)
	end
	if oldtime.t == "datetime" then
		-- datetime minus
		if newtime.t == "datetime" then
			-- datetime - datetime = delta
			return oldtime:newDelta(oldtime() - newtime())
		end
		if newtime.t == "delta" then
			-- datetime - delta = datetime
			return oldtime:newDatetime(oldtime() - newtime())
		end
	end
	if oldtime.t == delta then
		-- delta minus
		if newtime.t == "datetime" then
			-- delta - datetime = [invalid]
			error("timestampObj:difference: A delta - datetime expression is undefined")
		end
		if newtime.t == "delta" then
			-- delta - delta = delta
			return oldtime:newDelta(oldtime() - newtime())
		end
	end
	print("timestampObj:difference: Invalid object passed")
end

function timestampMeta.__add(oldtime, newtime)
	--must be sent a timestamp or int
	if type(newtime) == "number" then
		-- assume number is in seconds
		newtime = oldtime:newDelta(newtime * 1000)
	end
	if oldtime.t == "datetime" then
		-- datetime plus
		if newtime.t == "datetime" then
			-- datetime + datetime = [invalid]
			error("timestampMeta.__add: A datetime + datetime expression is undefined")
		end
		if newtime.t == "delta" then
			-- datetime + delta = datetime
			return oldtime:newDatetime(oldtime() + newtime())
		end
	end
	if oldtime.t == delta then
		-- delta plus
		if newtime.t == "datetime" then
			-- delta + datetime = datetime
			return oldtime:newDatetime(oldtime() + newtime())
		end
		if newtime.t == "delta" then
			-- delta + delta = delta
			return oldtime:newDelta(oldtime() + newtime())
		end
	end
	print("timestampMeta.__add: Invalid object passed")
end


function timestamp(value)
	return timestampObj:newDatetime(value)
end

local seedSalt = ((os.epoch("utc") / 1000 ) % 1087) + 857 -- Make sure each seed is different from the last, and that each init has a different first seedSalt
function uuid()
	math.randomseed(os.epoch("utc") + seedSalt)
	-- computer id - game age in seconds - random - authcheck
	local new_id = "i-ttttt-xxxxxxx-cccc"
	new_id =string.gsub(new_id, "i", os.computerID())
	new_id =string.gsub(new_id, "ttttt", function(c) return leadZero(math.floor((os.epoch("utc") / 1000) % 100000), 5) end)
	new_id =string.gsub(new_id, "x", function(c) return math.random(9) end)
	local cksum = 1
	for digit in new_id:gmatch("%d") do
		cksum = (cksum + (digit * cksum) % 537067) -- 537067 is just a nice high prime
	end
	cksum = cksum % 10000 -- four digits max
	new_id =string.gsub(new_id, "cccc", leadZero(cksum, 4))

	seedSalt = (cksum * cksum) % 1291 -- new seedsalt based on this run, keep it smallish
	return new_id
end
	
function verifyUuid(uuid)
	local data = uuid:match("^%d+.%d+.%d+")
	local hash = uuid:match("(%d+)$")
	local cksum = 1
	for digit in data:gmatch("%d") do
		cksum = (cksum + (digit * cksum) % 537067) -- 537067 is just a nice high prime
	end
	cksum = cksum % 10000 -- four digits max
	return tonumber(hash) == tonumber(cksum)
end

function uuidAge(uuid)
	local age = tonumber(uuid:match("%d%d%d%d%d"))
	age = math.floor((os.epoch("utc") / 1000) % 100000) - age
	return age
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



--Movement

function go_fwd(x)
	for i = 1, x, 1 do
		local trys = 0
		while not turtle.forward() do
			if not turtle.dig() then
				if not turtle.attack() then
					if turtle.getFuelLevel() == 0 then
						error("Out of fuel")
					else
						if trys < 25 then
							trys = trys + 1
							print("go_fwd() try " .. trys .. " failed")
						else
							error("go_fwd() failed for unknown reason")
						end
					end
				end
			end
		end
	end
end


function rect(x, y)
	-- x if forward, y is right
	-- -x is backwards, -y is left
	

	if x < 0 then
		turtle.turnRight()
		turtle.turnRight()
		x = 0 - x
	end

	local right = true
	if y < 0 then
		right = false
		y = 0 - y
	end

	for i = 1, x, 1 do
		-- x loop
		if right then
			turtle.turnRight()
		else
			turtle.turnLeft()
		end

		-- y "loop"
		go_fwd(y - 1)

		if (right) then
			turtle.turnLeft()
		else
			turtle.turnRight()
		end

		right = not right

		if not (i == x) then
			go_fwd(1)
		end
	end
end


function empty()
	local success = true
	for i = 1, 16, 1 do
		turtle.select(i)
		if not turtle.drop() then
			success = false
		end
	end
	turtle.select(1)
	return success
end


function emptyUp()
	local success = true
	for i = 1, 16, 1 do
		turtle.select(i)
		if not turtle.dropUp() then
			success = false
		end
	end
	turtle.select(1)
	return success
end


function emptyDown()
	local success = true
	for i = 1, 16, 1 do
		turtle.select(i)
		if not turtle.dropDown() then
			success = false
		end
	end
	turtle.select(1)
	return success
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



-- Monitor management

m = {elems = {}}


function m:newMonitor(side, index)
	local monitorObj = {id = uuid()}
	monitorObj.p = peripheral.wrap(side)
	monitorObj.width, monitorObj.height = monitorObj.p.getSize()
	monitorObj.isColor = monitorObj.p.isColor()
	self.elems[id] = monitorObj
end


function m:init(count)
	count = count or 1
	local pAll = peripheral.getNames()
	local mNum = 1
	for i, p in ipairs(pAll) do
		if mNum <= count then
			if peripheral.getType(p) == "monitor" then
				local id = "m".. mNum
				self[id] = peripheral.wrap(p)
				mNum = mNum + 1
			end
		else
			break
		end
	end
end



m.bar = {}
function m.bar:new(x, y, h, l, mon)
	local newbar = {}
	setmetatable(newbar, self)
	self.__index = self
	newbar.id = uuid()
	newbar.enabled = true
	newbar.border = colors.white
	newbar.fill = colors.green
	newbar.bezzle = 1
	newbar.mon = mon or "m1"
	newbar.x = x
	newbar.y = y
	newbar.h = h
	newbar.l = l
	newbar.draw = function (self)
		paintutils.drawBox(self.x, self.y, self.x + self. l, self.y + self.h, self.border)
		paintutils.drawFilledBox(self.x + self.bezzle, self.y + self.bezzle, self.x + self. l - self.bezzle, self.y + self.h - self.bezzle, self.fill)
	end
	return newbar
end





--GPS and pathfinding
tgps = {pos = {x = nil, y = nil, z = nil}, facing = nil}
tgps.rotations = {
	{val = 0, name = "North", delta = {x = 0, z = -1}},
	{val = 1, name = "East", delta = {x = 1, z = 0}},
	{val = 2, name = "South", delta = {x = 0, z = 1}},
	{val = 3, name = "West", delta = {x = -1, z = 0}}
}

function tgps:pReady()
	if (self.pos.x == nil or self.pos.y == nil or self.pos.z == nil) then
		return false
	else
		return true
	end
end

function tgps:fReady()
	if (self.facing == nil) then
		return false
	else
		return true
	end
end

function tgps:ready()
	return self:pReady() and self:fReady()
end

function tgps:findPos()
	self.pos.x, self.pos.y, self.pos.z = gps.locate()
end

function tgps:cpPos(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = v
	end
	return out
end

function tgps:posDiff(pTbl)
	self:findPos()
	local diffs = {}
	diffs.x = self.pos.x - pTbl.x
	diffs.y = self.pos.y - pTbl.y
	diffs.z = self.pos.z - pTbl.z
	return diffs
end

function tgps:validateDelta(delta)
	if (delta.x > 1 or delta.x < -1) then
		return false, "Bad x value: "..delta.x.."  "
	end
	if (delta.y ~= nil and delta.y ~= 0) then
		return false, "Bad y value: "..delta.y.."  "
	end

	if (delta.z > 1 or delta.z < -1) then
		return false, "Bad z value: "..delta.z.."  "
	end
	return true
end

function tgps:deltaToRot(delta)
	for i, rotation in ipairs(self.rotations) do
		if (delta.x == rotation.delta.x and delta.y == rotation.delta.y) then
			return rotation
		end
	end
	return nil
end


function tgps:findDir(goBack)
	goBack = goBack or false

	if not self:pReady() then
		self:findPos()
	end

	local oldPos = self:cpPos(self.pos)

	local moved = false
	for i = 1, 4, 1 do
		--for each direction
		if turtle.forward() then
			moved = true
			break
		end
		turtle.turnRight()
	end
	
	print(moved)
	if not moved then
		error("Cannot move")
	end

	--assume we moved
	local delta = self:posDiff(oldPos)
	delta.y = nil
	local valid, e = self:validateDelta(delta)
	if not valid then
		error("Delta failed verification: "..e)
	end
	--success
	if goBack then
		turtle.back()
		self:findPos()
	end
	self.facing = self:deltaToRot(delta)
end

function tgps:cardinal(dir)
	if dir == nil then
		if self.facing == nil then
			return "Unknown"
		end
		return self.facing.name
	end
	for i, rotation in ipairs(self.rotations) do
		if rotation.val == dir then
			return rotation.name
		end
	end
	return "Invalid rotation"
end

function tgps:invertDelta(delta)
	out = {}
	for k, v in pairs(delta) do
		out[k] = 0 - v
	end
	return out
end

function tgps:thisWay(movement)
	-- Is this rotation the way we want to go?
	local x = movement.x * self.facing.delta.x
	local z = movement.z * self.facing.delta.z
	if (x > 0) then
		return x
	elseif (z > 0) then
		return z
	else
		return 0
	end
end

function tgps:right()
	for i, rot in ipairs(self.rotations) do
		if (rot.val == (self.facing.val + 1) % 4 ) then
			turtle.turnRight()
			self.facing = rot
			return true
		end
	end
end

function tgps:left()
	for i, rot in ipairs(self.rotations) do
		if (rot.val == (self.facing.val - 1) % 4 ) then
			turtle.turnRight()
			self.facing = rot
			return true
		end
	end
end

function tgps:init()
	self:findPos()
	self:findDir(true)
end

function tgps:simpleGo(ix, iy, iz)
	self:init()
	local move = self:invertDelta(self:posDiff({x=ix, y=iy, z=iz}))
	while (self.pos.x ~= ix or self.pos.y ~= iy or self.pos.z ~= iz) do
		local d = self:thisWay(move)
		print(">> "..d)
		go_fwd(d)
		self:right()
		self:findPos()
	end
end
		
