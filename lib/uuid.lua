
-- Universal Unique ID ; snowflakes

local seedSalt = ((os.epoch("utc") / 1000 ) % 1087) + 857 -- Make sure each seed is different from the last, and that each init has a different first seedSalt
local function uuid()
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
	
local function verifyUuid(uuid)
	local data = uuid:match("^%d+.%d+.%d+")
	local hash = uuid:match("(%d+)$")
	local cksum = 1
	for digit in data:gmatch("%d") do
		cksum = (cksum + (digit * cksum) % 537067) -- 537067 is just a nice high prime
	end
	cksum = cksum % 10000 -- four digits max
	return tonumber(hash) == tonumber(cksum)
end

local function uuidAge(uuid)
	local age = tonumber(uuid:match("%d%d%d%d%d"))
	age = math.floor((os.epoch("utc") / 1000) % 100000) - age
	return age
end

modTable = {
	seedSalt = seedSalt,
	uuid = uuid,
	verifyUuid = verifyUuid,
	uuidAge = uuidAge
}
return modTable