-- Monitor management

local m = {elems = {}}

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

-- module stuff
return { m }
