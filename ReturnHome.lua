-- usage: ReturnHome <name>

--list of mining turtles as <name> = <id>
local turtles = {
  sklave1 = 23,
  sklave3 = 25,
  sklave4 = 32
}

local tArgs = { ... }

rednet.open("right")

if #tArgs ~= 1 then
  print("usage: ReturnHome <name>")
else
  local name = tArgs[1]
  if turtles[name] then
    local retry = true
    while retry do
	  print("sending request")
      rednet.send(turtles[name], "return home")
	  print("waiting for response...")
	  local id, msg = rednet.recieve(10)
	  while id do
	    if id == turtles[name] and string.find(msg, "returning home") then
		  print("turtle is returing: "..(msg or "nil"))
		  retry = false
		  break
		else
		  print("recieved message: "..(msg or "nil"))
		end
		id, msg = rednet.receive(10)
	  end
	end
  else
    print("There is no known turtle with the name '"..name.."'")
	print("To add new turtles you have to edit the script")
  end
end