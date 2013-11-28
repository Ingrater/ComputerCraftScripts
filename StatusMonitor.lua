-- number of lines to print from the log file
local numLinesFromLog = 10
-- list of ids to forward messages to
local forwardTo = { 0 } 

function forward(msg)
  for i=1,#forwardTo do
    rednet.send(forwardTo[i], msg)
  end
end

rednet.open("right")
print("listening...")

if fs.exists("log") then
  local f = fs.open("log", "r")
  local lines = {}
  local line = false
  
  local i = 1
  local wrap = false
  while true do
    local line = f.readLine()
	if not line
	  break
	end
    lines[i] = line
	i = i + 1
	if i > numLinesFromLog + 1 then
	  i = 0
	  wrap = true
	end
  end  
  
  local num = numLinesFromLog
  if not wrap then
    num = i-1
    i = 1
  end
	 
  
  for j=1,num do
    print(lines[i])
	forward(lines[i])
	i = i + 1
	if i > numLinesFromLog + 1 then
	  i = 0
	  wrap = true
	end
  end
  f.close()
end

while true do
  local id, msg = rednet.recieve()
  local flog = fs.open("log", "a")
  local output = id.."> "..(msg or "nil");
  flog.writeLine(output);
  flog.close()
  print(output)
  forward(output)
end
