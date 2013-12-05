local statusMonitorId = 22 -- id of the status monitor
local firstTree = {3, -6, 2}
local dropOverPoint = {0, 0, 3}
local dropPoint = {0, 0, 0}
local treesPerRow = 5
local numTrees = 30
local maxValuableDepth = 15
local waitAmount = 400

-- state variables
local curPos = {0, 0, 0}
local curDir = {1, 1}
local state = "start"
local numRetries = 20

function epsilonCompare(x, y)
  return x + 0.1 > y and x - 0.1 < y;
end

function tableCopy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function refuelFromInventory()
  if turtle.getItemCount(1) < 1 then
    print("completely out of fuel")
    return false
  end
  for i=3,16 do
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

function checkFuel()
  if fuelLow then
    return
  end
  if turtle.getFuelLevel() < 1 then
    if turtle.getItemCount(1) < 2 then
      refuelFromInventory()
      if turtle.getItemCount(1) < 2 then
        while turtle.getItemCount(1) < 2 do
          report("Help! Need Fuel! state: "..state)
          os.sleep(60)
        end
      end	  
	end
	turtle.select(1)
	turtle.refuel(1)
  end
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

function sign(x)
  if x < 0 then
    return -1
  end
  return 1
end

function moveHelper(axis, index, loc, twoHigh)
  if loc[index] - curPos[index] ~= 0 then
    local dist = loc[index] - curPos[index]
    
    -- look into the correct direction
    rotateTo({index, sign(dist)})
    
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
  local dirCopy = tableCopy(curDir)
  local curIndex = curDir[1] + curDir[2]
  local newIndex = dir[1] + dir[2]
  
  if epsilonCompare(curDir[1], dir[1]) and epsilonCompare(curDir[2], dir[2]) == false then
    -- turn 180 degrees
    turnLeft()
    turnLeft()
  elseif epsilonCompare(newIndex, 0) and epsilonCompare(curIndex, 3) then
    turnRight()
  elseif epsilonCompare(newIndex, 3) and epsilonCompare(curIndex, 0) then
    turnLeft()
  elseif newIndex > curIndex then
    turnRight()
  elseif newIndex < curIndex then
    turnLeft()
  end
  if epsilonCompare(curDir[1], dir[1]) == false or epsilonCompare(curDir[2], dir[2]) == false then
    error("should rotate to {"..dir[1]..", "..dir[2].."} from {"..dirCopy[1]..", "..dirCopy[2].."} ended up in {"..curDir[1]..","..curDir[2].."}");
  end
end

-- depth of recursion
local valuableDepth = 0

function findWoodStack()
  refuelFromInventory()
  turtle.select(1)
  for i=3,16 do
    if turtle.getItemCount(i) > 0 then
	  if turtle.compareTo(i) and turtle.getItemCount(i) < 32 then
	    return i
	  end
	end
  end
  -- no existing stack, find a empty one
  while turlte.getItemCount(1) < 3 then
    report("HELP! need fuel")
	os.sleep(120)
  end
  for i=3,16 do
    if turtle.getItemCount(i) < 1 then
	  turtle.transferTo(i, 1)
	  return i
	end
  end
  error("failed to find woodstack")
end

function isValuableInFront(woodStack)
  if valuableDepth > maxValuableDepth then
    return false
  end
  if not turtle.detect() then
    return false
  end
  turtle.select(woodStack)
  local oldCount = turtle.getItemCount(woodStack)
  turtle.dig()
  local newCount = turtle.getItemCount(woodStack)
  return newCount > oldCount
end

function isValuableUp(woodStack)
  if valuableDepth > maxValuableDepth then
    return false
  end
  if not turtle.detectUp() then
    return false
  end
  turtle.select(woodStack)
  local oldCount = turtle.getItemCount(woodStack)
  turtle.digUp()
  local newCount = turtle.getItemCount(woodStack)
  return newCount > oldCount  
end

function mineValuableUp(woodStack)
  if isValuableUp(woodStack) == true then
    valuableDepth = valuableDepth + 1
    local returnToPos = tableCopy(curPos)
    local returnToDir = tableCopy(curDir)
    if valuableDepth < maxValuableDepth then
      up()
      mineValuableUp(woodStack)
      for i=1,4 do
        mineValuable(woodStack)
        turnLeft()
      end
    end
    moveTo(returnToPos, {"z", "y", "x"})
    rotateTo(returnToDir)
    valuableDepth = valuableDepth - 1
  end
end

function mineValuable(woodStack)
  if isValuableInFront(woodStack) == true then
    valuableDepth = valuableDepth + 1
    print("found valuable")
    local returnToPos = tableCopy(curPos)
    local returnToDir = tableCopy(curDir)
    mineValuableUp(woodStack)
    if valuableDepth < maxValuableDepth then
      forward()
      for i=1,4 do
        mineValuable(woodStack)
        turnLeft()
      end
    end
    moveTo(returnToPos, {"z", "y", "x"})
    rotateTo(returnToDir)
    valuableDepth = valuableDepth - 1
  end
end

function getName()
  return os.computerLabel() or ("miner"..os.getComputerID())
end

function report(msg)
  local x, y, z = gps.locate()
  local pos = ""
  if x and y and z then
    pos = "("..x..", "..y..", "..z..")"
  end
  rednet.send(statusMonitorId, getName()..pos..": "..msg)
  print(msg)
end

function savePosition()
  --[[local f = fs.open("forstPos", "w")
  f.write(curPos[1].."\n"..curPos[2].."\n"..curPos[3].."\n")
  --print("pos = "..curPos[1].." "..curPos[2].." "..curPos[3])
  f.close()--]]
end

function saveDirection()
  --[[local f = fs.open("forstDir", "w")
  --print("dir = "..curDir[1].." "..curDir[2])
  f.write(curDir[1].."\n"..curDir[2].."\n")
  f.close()--]]
end

function setState(newState)
  state = newState
  --[[local f = fs.open("forstState", "w")
  f.write(state.."\n")
  f.close()--]]
end

function restoreState()
  if fs.exists("forstPos") and fs.exists("forstDir") and fs.exists("forstState") then
    local oldPos = false
    local oldDir = false
    local oldState = false
    
    -- read position
    local f = fs.open("forstPos", "r")
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
    f = fs.open("forstDir", "r")
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
    f = fs.open("forstState", "r")
    if f then
      oldState = f.readLine()
      f.close()
    end
    
    if oldPos and oldDir and oldState then
      
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

function treePos(num)
  local i = num - 1
  return { firstTree[1] + math.floor(i / treesPerRow) * 3, 
           firstTree[2] + math.fmod(i, treesPerRow) * 3,
		   firstTree[3]}
end

function zigZag(i)
  i = i - 1 -- deal with lua arrays starting at index 1
  local column = math.floor(i / treesPerRow)
  local row = math.fmod(i, treesPerRow)
  local isOddColumn = math.fmod(column, 2)
  if isOddColumn > 0 then
    i = column * treesPerRow + (treesPerRow - (row + 1))
  end
  
  i = i + 1
  return i
end

function checkTree(i)
  moveTo(treePos(i), {"x", "y", "z"})
  rotateTo({1, 1})
  if not turtle.detect() then
	  -- empty block
	  turtle.select(1)
	  forward()
	  up()
	  turtle.select(2)
	  turtle.placeDown()
  elseif turtle.select(1) and turtle.compare() == true then
	  -- a tree block
	  forward()
	  local woodStack = findWoodStack()
	  mineValuableUp(woodStack)
	  up()
  else
    up()
  end
end

function checkTrees()
  local lastDst = false
  for i=1,numTrees do
    local treeIndex = zigZag(i)
    local curDst = treePos(treeIndex)
	if lastDst and lastDst[1] ~= curDst[1] then
	  -- avoid chopping down a tree when switching rows
	  rotateTo({2, 1})
	  forward()
	end
	lastDst = curDst
	checkTree(treeIndex)
  end
end

function checkTreesBackwards()
  local lastDst = false
  for i=numTrees,1,-1 do
    local treeIndex = zigZag(i)
    local curDst = treePos(treeIndex)
	if lastDst and lastDst[1] ~= curDst[1] then
	  -- avoid chopping down a tree when switching rows
	  rotateTo({2, 1})
	  forward()
	end
	lastDst = curDst
	checkTree(treeIndex)
  end
end

function refillSaplings()
  if turtle.getItemCount(2) < numTrees * 2 then
    turtle.select(2)
	  while turtle.getItemCount(2) < 64 do
	    local oldCount = turtle.getItemCount(2)
	    turtle.suck()
	    if turtle.getItemCount(2) <= oldCount then
	      report("no more saplings in chest")
		  os.sleep(60)
	    end
	  end
  end
end

function work()
  while true do
    if state == "start" then
      refillSaplings()
      moveTo(dropOverPoint, {"z", "y", "x"})
      setState("check")
    elseif state == "check" then
      checkTrees()
      rotateTo({1, 1})
      back()
      setState("wait1")
    elseif state == "wait1" then
      os.sleep(waitAmount)
      setState("checkBackwards")
    elseif state == "checkBackwards" then
      checkTreesBackwards()
      rotateTo({1, 1})
      back()
      setState("deliver")
    elseif state == "wait2" then
      os.sleep(waitAmount)
      setState("check")
    elseif state == "deliver" then
      moveTo(dropOverPoint, {"z", "y", "x"})
      moveTo(dropPoint, {"x", "y", "z"})
      rotateTo({1, 1})
      turnLeft()
      refuelFromInventory()
      for i=4,16 do
        turtle.select(i)
        if turtle.getItemCount(2) < 64 and turtle.compareTo(2) then
          turtle.transferTo(2, math.min(turtle.getItemSpace(2), turtle.getItemCount(i)))
        end
        turtle.drop()
      end
      turnRight()
      refillSaplings()
      moveTo(dropOverPoint, {"z", "y", "x"})
      setState("wait2")
    else
      error("Unkown state "..state)
    end
  end
end

function upABit()
  for i=1,6 do
    up()
  end
end

function boot()
   if restoreState() then
     if state == "check" then
       upABit()
       moveTo(treePos(1), {"x", "y", "z"})
     elseif state == "checkBackwards" then
       upABit()
       moveTo(treePos(numTrees), {"x", "y", "z"})   
     elseif state == "deliver" then
       upABit()     
     end
   end
   
   work()
end

rednet.open("right")
print("ver 0.1.0")

local status, err = pcall(boot)
if not status then
  if string.find(err, "waiting for manual reboot") or string.find("Terminated") then
    print(err)
  else
    while true do
      report("Lua ERROR: "..(err or "unkown error"))
      print("Lua ERROR: "..(err or "unkown error"))
      os.sleep(120)
    end
  end
end