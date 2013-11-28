-- usage:
-- Download as "startup" onto a computer and run once with
-- startup <x> <y> <z>
-- with x, y, z beeing the correct world coordinates of the computer

local gpsPos = false
local tArgs = { ... }

local modem = peripheral.wrap("right")
if not modem.isOpen(gps.CHANNEL_GPS) then
  modem.open(gps.CHANNEL_GPS)
  print("opened gps channel")
else
  print("gps channel already open")
end

if fs.exists("gpsPos") then
  local f = fs.open("gpsPos", "r")
  gpsPos = f.readLine()
  f.close()
elseif #tArgs < 3 then
  error("need position <x> <y> <z> as arguments on first use")
else
  local x = tonumber(tArgs[1])
  local y = tonumber(tArgs[2])
  local z = tonumber(tArgs[3])
  if x == nil or y == nil or z == nil then
    error("need position <x> <y> <z> as arguments on first use")
  end
  gpsPos = textutils.serialize({x,y,z})
  local f = fs.open("gpsPos", "w")
  f.write(gpsPos)
  f.close()
end

if gpsPos then
  print("gps host up and running on position "..gpsPos)
  while true do
    local e, p1, p2, p3, p4, p5 = os.pullEvent()
	if e == "modem_message" then
	  local side, channel, replyChannel, msg, distance = p1, p2, p3, p4, p5
	  if channel == gps.CHANNEL_GPS and msg == "PING" then
	    modem.transmit( replyChannel, gps.CHANNEL_GPS, gpsPos)
	    print("served request from "..replyChannel)
	  end
	end
  end
end