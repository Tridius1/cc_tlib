--Timestamps



local function datetime()
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


local function timestamp(value)
	return timestampObj:newDatetime(value)
end





-- load er up
modTable = {
	timestamp = timestamp,
	timestampObj = timestampObj,
	realizeTimestamp = realizeTimestamp,
	datetime = datetime
}

return modTable
