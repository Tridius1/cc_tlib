-- [gps]

--GPS and pathfinding
local tgps = {pos = {x = nil, y = nil, z = nil}, facing = nil}
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
		
return { tgps }