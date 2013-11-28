-- configuration variables
local branchLength = 50 -- depth of the branches
local startDepth = 20   -- depth of the first level
local branchesPerLevel = 10 -- how many branches per level
local branchSpacing = 4 -- spacing between branches
local levelSpacing = 4  -- spacing between levels
local statusMonitorId = 22 -- id of the status monitor
local controlMonitorId = 25 -- id of the control monitor
local numRetries = 20       -- number of retires before crying for help
local maxValuableDepth = 12 -- maximum recursion depth when following valuables

-- state variables
local branchNum = 0
local level = 0
local curPos = {0, 0, 0}
local curDir = {1, 1}
local branchStart = {0, 0, 0}
local dropPoint = {0, 0, 0}
local overDropPoint = {0, 0, 2}
local startPoint = {2, 0, 0}
local state = "start"

function epsilonCompare(x, y)
  return x + 0.1 > y and x - 0.1 < y;
end

function refuelFromInventory()
  if turtle.getItemCount(1) < 1 then
    print("completely out of cole")
    return false
  end
  for i=6,15 do
    turtle.select(i)
    if turtle.compareTo(1) then
      if turtle.transferTo(1, math.min(turtle.getItemSpace(1), turtle.getItemCount(i))) then
        turtle.select(1)
        return true
      else
        print("failed to transfer fuel")
        return false
      end
    end
  end
  turtle.select(1)
  return false
end

local fuelLow = false
function checkFuel()
  if fuelLow then
    return
  end
  if turtle.getItemCount(1) > 2 or refuelFromInventory() then
    if turtle.getFuelLevel() < 4 then
      turtle.select(1)
      while not turtle.refuel(1) do
        report("Help! Need Fuel! state: "..state)
        os.sleep(60)
      end
    end
  else
    local returnToPos = tableCopy(curPos)
    local returnToDir = tableCopy(curDir)
    turtle.select(1)
    turtle.refuel()
    fuelLow = true
    moveTo(branchStart, {"z", "y", "x"})
    moveTo(startPoint, {"x", "y", "z"})
    while not turtle.refuel(1) do
      print("Need Fuel! state: "..state)
      os.sleep(5)
    end
    fuelLow = false
    moveTo(branchStart, {"z", "y", "x"})
    moveTo(returnToPos, {"x", "y", "z"})
    rotateTo(returnToDir)
  end
end

function tableCopy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function forward()
  checkFuel()
  local retry = 0
  curPos[curDir[1]] = curPos[curDir[1]] + curDir[2]
  savePosition()
  while not turtle.forward() do
    curPos[curDir[1]] = curPos[curDir[1]] - curDir[2]
    savePosition()
    if turtle.detect() then
      if not turtle.dig() then
        hitBedrock()
      end
    else
      retry = retry + 1
      if retry > numRetries then
        report("HELP! failed to move forward. branch:"..branchNum.." level: "..level)
        os.sleep(60)
        retry = 0
      else
        os.sleep(1)
      end
    end
    curPos[curDir[1]] = curPos[curDir[1]] + curDir[2]
    savePosition()
  end
end

function back()
  checkFuel()
  local retry = 0
  curPos[curDir[1]] = curPos[curDir[1]] - curDir[2]
  savePosition()
  while not turtle.back() do
    curPos[curDir[1]] = curPos[curDir[1]] + curDir[2]
    savePosition()
    turnRight()
    turnRight()
    if turtle.detect() then
      if not turtle.dig() then
        hitBedrock()
      end
    else
      retry = retry + 1
      if retry > numRetries then
        report("HELP! failed to move back. branch:"..branchNum.." level: "..level)
        os.sleep(60)
        retry = 0
      else
        os.sleep(1)
      end
    end
    turnLeft()
    turnLeft()
    curPos[curDir[1]] = curPos[curDir[1]] - curDir[2]
    savePosition()
  end
end

function hitBedrock()
  if state ~= "gotoLevel" then
    moveTo(branchStart, {"z", "y", "x"})
  end
  moveTo(startPoint, {"x", "y", "z"})
  moveTo(overDropPoint, {"z", "x", "y"})
  moveTo(dropPoint, {"x", "y", "z"})
  rotateTo({1, 1})
  error("hit bedrock. branch:"..branchNum.." level: "..level)
end

function returnHome()
  report("returning home")
  rednet.send(controlMonitorId, "returning home")
  if state ~= "gotoLevel" then
    moveTo(branchStart, {"z", "y", "x"})
  end
  moveTo(startPoint, {"x", "y", "z"})
  moveTo(overDropPoint, {"z", "x", "y"})
  moveTo(dropPoint, {"x", "y", "z"})
  rotateTo({1, 1})

  --try to refuel before dropping coal
  refuelFromInventory()
  
  -- drop stuff
  putValuablesInChest()
  error("waiting for manual reboot")  
end

function down()
  checkFuel()
  local retry = 0
  curPos[3] = curPos[3] - 1
  savePosition()
  while not turtle.down() do
    curPos[3] = curPos[3] + 1
    savePosition()
    if turtle.detectDown() then
      if not turtle.digDown() then
        hitBedrock()
      end
    else
      retry = retry + 1
      if retry > numRetries then
        report("HELP! failed to move down. branch:"..branchNum.." level: "..level)
        os.sleep(60)
        retry = 0
      else
        os.sleep(1)
      end
    end
    curPos[3] = curPos[3] - 1
    savePosition()
  end
end

function up()
  checkFuel()
  local retry = 0
  curPos[3] = curPos[3] + 1
  savePosition()
  while not turtle.up() do
    curPos[3] = curPos[3] - 1
    savePosition()
    if turtle.detectUp() then
      turtle.digUp()
    else
      retry = retry + 1
      if retry > numRetries then
        report("HELP! failed to move up. branch:"..branchNum.." level: "..level)
        os.sleep(60)
        retry = 0
      else
        os.sleep(1)
      end
    end
    curPos[3] = curPos[3] + 1
    savePosition()
  end
end

function turnLeft()
  checkFuel()
  if epsilonCompare(curDir[1], 1) then
    curDir[1] = 2
    curDir[2] = -curDir[2]
  else
    curDir[1] = 1
  end
  saveDirection()
  while not turtle.turnLeft() do
  end
  sleep(0)
end

function turnRight()
  checkFuel()
  if epsilonCompare(curDir[1], 1) then
    curDir[1] = 2
  else
    curDir[1] = 1
    curDir[2] = -curDir[2]
  end
  saveDirection()
  while not turtle.turnRight() do    
  end
  sleep(0)
end

function digDown()
  if turtle.detectDown() then
    if not turtle.digDown() then
      hitBedrock()
    end
  end
end

function digUp()
  if turtle.detectUp() then
    turtle.digUp()
  end
end

function dig()
  if turtle.detect() then
    if not turtle.dig() then
      hitBedrock()
    end
  end
end

function placeTorch()
  if turtle.getItemCount(16) < 2 then
    deliverValuables()
  end
  turtle.select(16)
  back()
  turtle.placeDown()
  forward()
  turtle.select(1)
end

function computeBranchStart()
  branchStart = { startPoint[1], 
                  startPoint[2] + (branchNum * branchSpacing) - (math.floor(branchesPerLevel / 2) * branchSpacing), 
                  -startDepth - (level * levelSpacing) }
end

function findNextBranch()
  if branchNum > branchesPerLevel then
    level = level + 1
    branchNum = 0
  end
  computeBranchStart()
  branchNum = branchNum + 1
end

function moveHelper(axis, index, loc, twoHigh)
  if loc[index] - curPos[index] ~= 0 then
    local dist = loc[index] - curPos[index]
    -- check that we look in any x direction
    if curDir[1] ~= index then
      turnRight()
    end
    -- check that we look in the correct x direction
    if curDir[2] > 0 and dist < 0 or curDir[2] < 0 and dist > 0 then
      turnRight()
      turnRight()
    end
    -- move the requested amount
    if dist < 0 then
      dist = -dist
    end
    while dist > 0 do
      dig()
      forward()
      if twoHigh then
        digUp()
      end
      dist = dist - 1
    end
    if curPos[index] ~= loc[index] then
      report("ERROR move to "..axis.." "..loc[index].." but ended up in "..curPos[index])
      error("should move to "..axis.." "..loc[index].." but ended up in "..curPos[index])
      return false
    end
  end
  return true
end

function moveTo(loc, order)
  print("moving to "..loc[1].." "..loc[2].." "..loc[3])
  for i=1,3 do
    if order[i] == "x" then
      if not moveHelper("x", 1, loc) then
        return false
      end
    elseif order[i] == "y" then
      if not moveHelper("y", 2, loc) then
        return false
      end
    elseif order[i] == "y2" then
      if not moveHelper("y", 2, loc, true) then
        return false
      end    
    elseif order[i] == "z" then
      if loc[3] - curPos[3] ~= 0 then
        local dist = loc[3] - curPos[3]
        if dist > 0 then
          while dist > 0 do
            digUp()
            up()
            dist = dist - 1
          end
        else
          while dist < 0 do
            digDown()
            down()
            dist = dist + 1
          end
        end
        if curPos[3] ~= loc[3] then
          report("ERROR should move to z " ..loc[3].." but ended up at "..curPos[3])
          error("should move to z " ..loc[3].." but ended up at "..curPos[3])
          return false
        end
      end
    else
      error("Unkown axis "..order[i])
      return false
    end
  end
  return true
end

function rotateTo(dir)
  local diff1 = curDir[1] - dir[1]
  local diff2 = curDir[2] - dir[2]
  while not epsilonCompare(curDir[1], dir[1]) 
     or not epsilonCompare(curDir[2], dir[2]) do
    turnRight()
  end
end

-- depth of recursion
local valuableDepth = 0

function isValuableInFront()
  if valuableDepth > maxValuableDepth then
    return false
  end
  if not turtle.detect() then
    return false
  end
  for i=2,5 do
    turtle.select(i)
    if turtle.compare() then
      turtle.select(1)
      return false
    end
  end
  turtle.select(1)
  return true
end

function isValuableDown()
  if valuableDepth > maxValuableDepth then
    return false
  end
  if not turtle.detectDown() then
    return false
  end
  for i=2,5 do
    turtle.select(i)
    if turtle.compareDown() then
      return false
    end
  end
  return true
end

function isValuableUp()
  if valuableDepth > maxValuableDepth then
    return false
  end
  if not turtle.detectUp() then
    return false
  end
  for i=2,5 do
    turtle.select(i)
    if turtle.compareUp() then
      turtle.select(1)
      return false
    end
  end
  turtle.select(1)
  return true
end

function mineValuableUp()
  if isValuableUp() then
    valuableDepth = valuableDepth + 1
    local returnToPos = tableCopy(curPos)
    local returnToDir = tableCopy(curDir)
    digUp()
    if isFull(1) then
      deliverValuables()
    end
    if valuableDepth < maxValuableDepth then
      up()
      mineValuableUp()
      for i=1,4 do
        mineValuable()
        turnLeft()
      end
    end
    moveTo(returnToPos, {"z", "y", "x"})
    rotateTo(returnToDir)
    valuableDepth = valuableDepth - 1
  end
end

function mineValuableDown()
  if isValuableDown() then
    valuableDepth = valuableDepth + 1
    local returnToPos = tableCopy(curPos)
    local returnToDir = tableCopy(curDir)
    digDown()
    if isFull(1) then
      deliverValuables()
    end
    if valuableDepth < maxValuableDepth then
      down()
      mineValuableDown()
      for i=1,4 do
        mineValuable()
        turnLeft()
      end
    end
    moveTo(returnToPos, {"z", "y", "x"})
    rotateTo(returnToDir)
    valuableDepth = valuableDepth - 1
  end
end

function mineValuableVert()
  mineValuableUp()
  mineValuableDown()
end

function mineValuable()
  if isValuableInFront() then
    valuableDepth = valuableDepth + 1
    print("found valuable")
    local returnToPos = tableCopy(curPos)
    local returnToDir = tableCopy(curDir)
    dig()
    if isFull(1) then
      deliverValuables()
    end
    mineValuableVert()
    if valuableDepth < maxValuableDepth then
      forward()
      for i=1,4 do
        mineValuable()
        turnLeft()
      end
    end
    moveTo(returnToPos, {"z", "y", "x"})
    rotateTo(returnToDir)
    valuableDepth = valuableDepth - 1
  end
end

function checkMinerals()
  turnLeft()
  mineValuable()
  turnRight()
  turnRight()
  mineValuable()
  turnLeft()
end

function dropCrap()
  for i=6,15 do
    turtle.select(i)
    for j=2,5 do
      if turtle.compareTo(j) then
        turtle.drop()
      end
    end
  end
  if isFull(2) then
    deliverValuables()
  end
  turtle.select(1)
end

function checkForReturnRequest()
  while true do
    local id, msg = rednet.receive(1)
	if not id then
	  break
	end
	if id == controlMonitorId and msg == "return home" then
	  returnHome()
	  break
	end
  end
end

function mine(dist)
  if curDir[1] ~= 1 then
    turnRight()
  end
  if curDir[2] < 0 then
    turnRight()
    turnRight()
  end
  local i=0
  local torchDist=3
  while dist > 0 do
    mineValuableDown()
    dig()
    forward()
    mineValuableDown()
    checkMinerals()
    digUp()
    up()
    checkMinerals()
    digUp()
    up()
    mineValuableUp()
    checkMinerals()
    if torchDist > 3 then
      placeTorch()
      torchDist = 0
    else
      torchDist = torchDist + 1
    end
    dig()
    forward()
    mineValuableUp()
    checkMinerals()
    if i > 2 then
      i = 0
      dropCrap()
	  checkForReturnRequest()
	  local into = math.abs(curPos[1] - branchStart[1])
	  report(into.." blocks into brach "..branchNum.." on level "..level)
    else
      i = i + 1
    end
    digDown()
    down()
    checkMinerals()
    digDown()
    down()
    checkMinerals()
    dist = dist - 2
  end
end

function isFull(remainingSlots)
  local empty = 0
  for i=6,15 do
    if turtle.getItemCount(i) < 1 then
      empty = empty + 1
    end
  end
  return empty < remainingSlots
end

function fillTorches()
  if turtle.getItemCount(16) < 64 then
    turnLeft()
    turtle.select(16)
    while turtle.getItemCount(16) < 64 do
      local oldCount = turtle.getItemCount(16)
      while not turtle.suck() do
        report("torch chest is empty")
        os.sleep(60)
      end
      if not (turtle.getItemCount(16) > oldCount) then
        error("failed to pick up a torch")
      end
    end
    for i=6,15 do
      turtle.select(i)
      if turtle.compareTo(16) then
        turtle.drop()
      end
    end
    turnRight()
  end
  turtle.select(1)
end

function putValuablesInChest()
  for i=2,5 do
    turtle.select(i)
    turtle.drop(turtle.getItemCount(i) - 1)
  end
  for i=6,15 do
    turtle.select(i)
    turtle.drop()
  end
end

function deliverValuables()
  local returnToPos = tableCopy(curPos)
  local returnToDir = tableCopy(curDir)
  print("delivering valuables")
  report("returning valuables")
  moveTo(branchStart, {"z", "y", "x"})
  moveTo(startPoint, {"x", "y", "z"})
  moveTo(overDropPoint, {"z", "x", "y"})
  moveTo(dropPoint, {"x", "y", "z"}) 
  rotateTo({1, 1})
  
  -- save our current state to disk
  turnRight()
  saveToDisk()
  turnLeft()

  --try to refuel before dropping coal
  refuelFromInventory()
  
  -- drop stuff
  putValuablesInChest()
  
  -- grab torches
  fillTorches()
  
  print("returning to work")
  report("returning to work")
  moveTo(overDropPoint, {"z", "y", "x"})
  moveTo(startPoint, {"x", "y", "z"})
  moveTo(branchStart, {"z", "y", "x"})
  moveTo(returnToPos, {"x", "y", "z"})
  rotateTo(returnToDir)
end

function getName()
  return os.computerLabel() or ("miner"..os.getComputerID())
end

function saveToPath(path)
  local f = fs.open(path, "w")
  f.write(getName()); f.write("\n")
  f.write(level); f.write("\n")
  f.write(branchNum); f.write("\n") 
  f.write(branchSpacing); f.write("\n")
  f.write(levelSpacing); f.write("\n")
  f.write(startDepth); f.write("\n")
  f.write(branchLength); f.write("\n")
  f.write(branchesPerLevel); f.write("\n")
  f.close()
end

function saveToDisk()
  if disk.isPresent("front") and disk.hasData("front") then
    local path = disk.getMountPath("front")
    if path then
      path = "/"..path.."/mineData"
      saveToPath(path)
    end
  end
end

function loadFromPath(path)
  local f = fs.open(path, "r")     
  if f then
    local name = f.readLine()
    local inLevel = f.readLine()
    local inBranchNum = f.readLine()
    local inBranchSpacing = f.readLine()
    local inLevelSpacing = f.readLine()
    local inStartDepth = f.readLine()
    local inBranchLength = f.readLine()
    local inBranchesPerLevel = f.readLine()
    f.close()
    if name and inLevel and inBranchNum and inBranchSpacing and inLevelSpacing and
       inStartDepth and inBranchLength and inBranchesPerLevel 
    then
      os.setComputerLabel(name)
      level = tonumber(inLevel)
      branchNum = tonumber(inBranchNum)
      branchSpacing = tonumber(inBranchSpacing)
      levelSpacing = tonumber(inLevelSpacing)
      startDepth = tonumber(inStartDepth)
      branchLength = tonumber(inBranchLength)
      branchesPerLevel = tonumber(inBranchesPerLevel)
      print("loaded name = "..name)
      print("loaded level = "..level)
      print("loaded branchNum = "..branchNum)
      print("loaded branchSpacing = "..branchSpacing)
      print("loaded levelSpacing = "..levelSpacing)
      print("loaded startDepth = "..startDepth)
      print("loaded branchLength = "..branchLength)
      print("loaded branchesPerLevel = "..branchesPerLevel)
      return true
    end
  end    
  return false
end

function loadFromDisk()
  if disk.isPresent("front") and disk.hasData("front") then
    local mpath = disk.getMountPath("front")
    if mpath then
      local path = "/"..mpath.."/mineData"
      if fs.exists("mineData") then
        loadFromPath("mineData")
      else
        loadFromPath(path)
      end
      
      if fs.exists("/"..mpath.."/startup") then
        if fs.exists("startup") then
          fs.delete("startup")
        end
        fs.copy("/"..mpath.."/startup", "startup")
      end
      
      return true      
    end
  end
  return false
end

function report(msg)
  local x, y, z = gps.locate()
  local pos = ""
  if x and y and z then
    pos = "("..x..", "..y..", "..z..")"
  end
  rednet.send(statusMonitorId, getName()..pos..": "..msg)
end

function savePosition()
  local f = fs.open("minePos", "w")
  f.write(curPos[1].."\n"..curPos[2].."\n"..curPos[3].."\n")
  --print("pos = "..curPos[1].." "..curPos[2].." "..curPos[3])
  f.close()
end

function saveDirection()
  local f = fs.open("mineDir", "w")
  --print("dir = "..curDir[1].." "..curDir[2])
  f.write(curDir[1].."\n"..curDir[2].."\n")
  f.close()
end

function setState(newState)
  state = newState
  local f = fs.open("mineState", "w")
  f.write(state.."\n")
  f.close()
end

function restoreState()
  if fs.exists("minePos") and fs.exists("mineDir") and fs.exists("mineState") then
    local oldPos = false
    local oldDir = false
    local oldState = false
    
    -- read position
    local f = fs.open("minePos", "r")
    if f then
      local posX = f.readLine()
      if posX then posX = tonumber(posX) end
      local posY = f.readLine()
      if posY then posY = tonumber(posY) end
      local posZ = f.readLine()
      if posZ then posZ = tonumber(posZ) end
    
      if posX and posY and posZ then
        oldPos = {posX, posY, posZ}
      end
      f.close()
    end
    
    -- read direction
    f = fs.open("mineDir", "r")
    if f then
      local dir1 = f.readLine()
      if dir1 then dir1 = tonumber(dir1) end
      local dir2 = f.readLine()
      if dir2 then dir2 = tonumber(dir2) end
      
      if dir1 and dir2 then
        oldDir = {dir1, dir2}
      end
      f.close()
    end
    
    -- read state
    f = fs.open("mineState", "r")
    if f then
      oldState = f.readLine()
      f.close()
    end
    
    if oldPos and oldDir and oldState and loadFromPath("mineData") then
      
      curPos = oldPos
      curDir = oldDir
      state = oldState
      print("restored pos = "..curPos[1].." "..curPos[2].." "..curPos[3])
      print("restored dir = "..curDir[1].." "..curDir[2])
      print("restored state = "..state)
      return true
    end
    
  end
  return false
end

function work()
  while state ~= "error" do
    print("entering state "..state)
    if state == "start" then
      checkFuel()
      setState("gotoStart")
    elseif state == "gotoStart" then
      moveTo(overDropPoint, {"z", "y", "x"})
      moveTo(startPoint, {"x", "y", "z"})
      findNextBranch()
      setState("gotoLevel")
    elseif state == "gotoLevel" then
      moveTo(branchStart, {"z","y2","x"})
      setState("mineBranch")
    elseif state == "mineBranch" then
      report("start mining branch "..branchNum.." on level "..level)
      saveToPath("mineData")
      mine(branchLength)
      moveTo(branchStart, {"z", "y", "x"})
      findNextBranch()
      setState("gotoLevel")
    else
	  error("unkown state "..state)
	end
  end
  print("end at "..curPos[1].." "..curPos[2].." "..curPos[3])
end

rednet.open("right")
print("ver 0.1.1")

function boot()
  if loadFromDisk() then
    turtle.turnLeft()
    fillTorches()
  elseif restoreState() then
    turtle.turnRight()
    if disk.isPresent("front") then
      turtle.turnLeft()
      error("waiting for manual reboot")
    end
    turtle.turnLeft()
    --error("done")
    if state == "gotoStart" or curPos[3] > -2 then
      error("need manual restart")
    end
    report("continuing from restored data")
    branchNum = branchNum - 1
    computeBranchStart()
    branchNum = branchNum + 1
    checkFuel()
    dropCrap()
    if state == "mineBranch" then
      moveTo(branchStart, {"z", "y", "x"})
    end
  else
    error("HELP! I'm lost")
  end
  
  work()
end
  
local status, err = pcall(boot)
if not status then
  if string.find(err, "waiting for manual reboot") then
    print(err)
  else
    while true do
      report("Lua ERROR: "..(err or "unkown error"))
      print("Lua ERROR: "..(err or "unkown error"))
      os.sleep(120)
    end
  end
end