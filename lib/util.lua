-- [util]

-- Utility Functions


local function formatNum(rawRF)
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


local function getPeri(pType)
	for _, side in ipairs(peripheral.getNames()) do
		if peripheral.getType(side) == pType then
			return peripheral.wrap(side)
		end
	end
	return false
end

local function leadZero(numStr, len)
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

local function printTable(table)
	doPrintTable(table, 0)
	print("")
end



modtable = {
	formatNum = formatNum,
	getPeri = getPeri,
	leadZero = leadZero,
	printTable = printTable
}

return modtable