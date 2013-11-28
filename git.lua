--usage git <filename> <destination>
--latest pastebin id: TcZAmnL4

local tArgs = { ... }

function work()
  if #tArgs ~= 2 then
    print("git <filename> <destination>")
  else
    local h = http.get("https://raw.github.com/Ingrater/ComputerCraftScripts/master/"..tArgs[1])
	if not h then
	  print("file '"..tArgs[1].." does not exist in git repository")
	  return
	end
    local contents = h.readAll()
    if fs.exists(tArgs[2]) then
      print("The file '"..tArgs[2].."' does already exist, overwrite?")
      local answer = read()
	  while answer ~= "no" and answer ~= "yes" do
	    print("please enter 'yes' or 'no'")
	    answer = read()
	  end
	  if answer == "no" then
	    return
	  end
    end
    local f = fs.open(tArgs[2], "w")
	f.write(contents)
	f.close()
	print("downloaded "..tArgs[1].." to "..tArgs[2])
  end
end

work()