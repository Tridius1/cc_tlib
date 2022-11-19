--Movement

local function go_fwd(x)
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


local function rect(x, y)
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


local function empty()
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


local function emptyUp()
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


local function emptyDown()
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

-- return module
local modTable = {
	go = go_fwd,
	rect = rect,
	empty = empty,
	emptyUp = emptyUp,
	emptyDown = emptyDown
}
return modTable