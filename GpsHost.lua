-- usage:
-- Download as "startup" onto a computer and run once with
-- startup <x> <y> <z>
-- with x, y, z beeing the correct world coordinates of the computer

local gpsPos = false
local tArgs = { ... }

rednet.open("right")

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
    sender,message,distance = rednet.receive()
	if message == "PING" then
	  rednet.send(sender, gpsPos)
	  print("served request from "..sender)
	end
  end
end