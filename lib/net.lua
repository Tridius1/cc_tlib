-- [net]
-- Networking

local defaultChannel = 100
local net = {recieved = {}}

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

-- messages

local message = {init = false}

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




return {
	net = net,
	message = message
}