local computer = require("computer")
local os = require("os")
local component = require("component")
local robot = require("robot")
local sides = require("sides")

--local radius = 15
--radius = radius + 1
--local radiusSqr = radius * radius
local radiusSqr = 1
local radiusX = 3
local radiusY = 5
local radiusZ = 7
radiusX = radiusX + 1
radiusY = radiusY + 1
radiusZ = radiusZ + 1
local isInShape = function(x, y, z)
  return x^2/radiusX^2 + y^2/radiusY^2 + z^2/radiusZ^2 < radiusSqr
end
local verticalDirection = "up"
local bounds = {}
bounds.minX = -radiusX
bounds.minY = -radiusY
bounds.minZ = -radiusZ
bounds.maxX = radiusX
bounds.maxY = radiusY
bounds.maxZ = radiusZ
--local glassSlots = {5,6,7,8,9,10,11,12,13,14,15,16}
local glassSlots = {}
for i=5, robot.inventorySize() do
  glassSlots[#glassSlots + 1] = i
end
local glassChestSlot = 3
local glassReferenceSlot = 4
local cellSlot = 1
--local converterSlot = 2
local chargerSlot = 2

-- assumes angel upgrade, inventory controller upgrade, ...

if component.isAvailable("navigation") then
  local navdir = component.navigation.getFacing()
  if navdir == sides.north then
    reldir = "F"
  elseif navdir == sides.south then
    reldir = "B"
  elseif navdir == sides.west then
    reldir = "L"
  elseif navdir == sides.east then
    reldir = "R"
  end
else
  print("navigation component not available. assuming North-facing")
  reldir = "F"
end
relloc = {x=0, y=0, z=0}

local customForward = function()
  if not robot.forward() then return false end
  if reldir == "F" then
    relloc.z = relloc.z - 1
  elseif reldir == "B" then
    relloc.z = relloc.z + 1
  elseif reldir == "L" then
    relloc.x = relloc.x - 1
  elseif reldir == "R" then
    relloc.x = relloc.x + 1
  end
  return true
end
local forceForward = function()
  while not customForward() do robot.swing() os.sleep(0.1) end
end

local customBack = function()
  if not robot.back() then return false end
  if reldir == "F" then
    relloc.z = relloc.z + 1
  elseif reldir == "B" then
    relloc.z = relloc.z - 1
  elseif reldir == "L" then
    relloc.x = relloc.x + 1
  elseif reldir == "R" then
    relloc.x = relloc.x - 1
  end
  return true
end
local forceBack = function()
  while not customBack() do os.sleep(0.1) end
end

local customUp = function()
  if not robot.up() then return false end
  relloc.y = relloc.y + 1
  return true
end
local forceUp = function()
  while not customUp() do robot.swingUp() os.sleep(0.1) end
end

local customDown = function()
  if not robot.down() then return false end
  relloc.y = relloc.y - 1
  return true
end
local forceDown = function()
  while not customDown() do robot.swingDown() os.sleep(0.1) end
end

local customTurnLeft = function()
  if not robot.turnLeft() then return false end
  if reldir == "F" then
    reldir = "L"
  elseif reldir == "L" then
    reldir = "B"
  elseif reldir == "B" then
    reldir = "R"
  elseif reldir == "R" then
    reldir = "F"
  end
  return true
end
local forceLeft = function()
  while not customTurnLeft() do os.sleep(0.1) end
end

local customTurnRight = function()
  if not robot.turnRight() then return false end
  if reldir == "F" then
    reldir = "R"
  elseif reldir == "R" then
    reldir = "B"
  elseif reldir == "B" then
    reldir = "L"
  elseif reldir == "L" then
    reldir = "F"
  end
  return true
end
local forceRight = function()
  while not customTurnRight() do os.sleep(0.1) end
end

local forceFace = function(dir)
  if dir == reldir then return end
  if reldir == "F" and dir == "B" or
      reldir == "B" and dir == "F" or
      reldir == "L" and dir == "R" or
      reldir == "R" and dir == "L" then
    for i=1,2 do forceRight() end
    return
  end
  if reldir == "F" and dir == "L" or
      reldir == "L" and dir == "B" or
      reldir == "B" and dir == "R" or
      reldir == "R" and dir == "F" then
    forceLeft()
    return
  end
  if reldir == "F" and dir == "R" or
      reldir == "R" and dir == "B" or
      reldir == "B" and dir == "L" or
      reldir == "L" and dir == "F" then
    forceRight()
    return
  end
end
local forceMove = function(loc)
  while relloc.y < loc.y do forceUp() end
  while relloc.y > loc.y do forceDown() end
  if relloc.x < loc.x then
    forceFace("R")
    --print("forceMove R")
    while relloc.x < loc.x do forceForward() end
  elseif relloc.x > loc.x then
    forceFace("L")
    --print("forceMove L")
    while relloc.x > loc.x do forceForward() end
  end
  if relloc.z < loc.z then
    forceFace("B")
    --print("forceMove B")
    while relloc.z < loc.z do forceForward() end
  elseif relloc.z > loc.z then
    forceFace("F")
    --print("forceMove F")
    while relloc.z > loc.z do forceForward() end
  end
end

local forcePlace = function()
  if robot.compare() then return end
  while not robot.place() do robot.swing() os.sleep(0.1) end
end
local forcePlaceUp = function()
  if robot.compareUp() then return end
  while not robot.placeUp() do robot.swingUp() os.sleep(0.1) end
end
local forcePlaceDown = function()
  if robot.compareDown() then return end
  while not robot.placeDown() do robot.swingDown() os.sleep(0.1) end
end

local selectGlass = function()
  for k,v in ipairs(glassSlots) do
    if robot.count(v) > 0 then
      robot.select(v)
      if robot.compareTo(glassReferenceSlot) then
        return
      else
        robot.drop()
      end
    end
  end
  robot.select(glassChestSlot)
  if verticalDirection == "up" then
    forcePlaceUp()
    for k,v in ipairs(glassSlots) do
      robot.select(v)
      robot.drop()
      while not robot.suckUp() do os.sleep(0.1) end
    end
    robot.select(glassChestSlot)
    robot.swingUp()
  elseif verticalDirection == "down" then
    forcePlaceDown()
    for k,v in ipairs(glassSlots) do
      robot.select(v)
      robot.drop()
      while not robot.suckDown() do os.sleep(0.1) end
    end
    robot.select(glassChestSlot)
    robot.swingDown()
  end
  -- swingUp/Down() only starts swinging; it could end after selecting the glass slot (it seems)
  os.sleep(5)
  robot.select(glassSlots[1])
end

local isOnEdge = function(x, y, z)
  return not (isInShape(x - 1, y, z) and
      isInShape(x + 1, y, z) and
      isInShape(x, y - 1, z) and
      isInShape(x, y + 1, z) and
      isInShape(x, y, z - 1) and
      isInShape(x, y, z + 1))
end
local isOnEdgeThick = function(x, y, z)
  for dx=-1,1 do
    for dy=-1,1 do
      for dz=-1,1 do
        if not isInShape(x + dx, y + dy, z + dz) then return true end
      end
    end
  end
  return false
end

local checkCharge = function()
  if computer.energy() / computer.maxEnergy() > 0.1 then
    return
  end
  if verticalDirection == "up" then
    forceUp()
    robot.select(cellSlot)
    forcePlaceDown()
    forceUp()
    robot.select(chargerSlot)
    forcePlaceDown()
    component.redstone.setOutput(sides.down, 15)
    while computer.energy() / computer.maxEnergy() < 0.9 do os.sleep(1) end
    component.redstone.setOutput(sides.down, 0)
    robot.select(chargerSlot)
    robot.drop()
    robot.swingDown()
    forceDown()
    robot.select(cellSlot)
    robot.drop()
    robot.swingDown()
    forceDown()
  elseif verticalDirection == "down" then
    forceDown()
    robot.select(cellSlot)
    forcePlaceUp()
    forceDown()
    robot.select(chargerSlot)
    forcePlaceUp()
    component.redstone.setOutput(sides.up, 15)
    while computer.energy() / computer.maxEnergy() < 0.9 do os.sleep(1) end
    component.redstone.setOutput(sides.up, 0)
    robot.select(chargerSlot)
    robot.drop()
    robot.swingUp()
    forceUp()
    robot.select(cellSlot)
    robot.drop()
    robot.swingUp()
    forceUp()
  end
end

local removeFromList = function(list, element)
  local size = #list
  local i = 1
  while i <= size do
    if list[i] == element then
      table.remove(list, i)
      size = size - 1
    else
      i = i + 1
    end
  end
end
local shallowAndNaiveListCopy = function(list)
  local res = {}
  for i=1,#list do
    res[i] = list[i]
  end
  return res
end
-- taxicab geometry, plus 1 when turning is necessary
local robotDistance = function(pos1, pos2)
  local res = math.abs(pos2.x - pos1.x) + math.abs(pos2.z - pos1.z)
  if (pos2.x ~= pos1.x) and (pos2.z ~= pos1.z) then
    res = res + 1
  end
  return res
end

local relativeSorting = {}
relativeSorting.center = {x=0, z=0}
relativeSorting.angleComparator = function(a, b)
  local angleDiff = math.atan2(a.z - relativeSorting.center.z, a.x - relativeSorting.center.x) -
      math.atan2(b.z - relativeSorting.center.z, b.x - relativeSorting.center.x)
  if angleDiff == 0 then
    -- if they're the same angle, the furthest one from the center takes priority
    return not relativeSorting.robotDistanceComparator(a, b)
  end
  return angleDiff < 0
end
relativeSorting.robotDistanceComparator = function(a, b)
  return (a.x - relativeSorting.center.x) ^ 2 + (a.z - relativeSorting.center.z) ^ 2 <
      (b.x - relativeSorting.center.x) ^ 2 + (b.z - relativeSorting.center.z) ^ 2
end
-- relativeSorting.findFirst = function(list, comparator)
--
-- end
local sortByAngle = function(layer)
  -- turtle goes in a circle, least angle to greatest angle
  relativeSorting.center.x = 0
  relativeSorting.center.z = 0
  table.sort(layer, relativeSorting.angleComparator)
  return layer
end
local sortByNN = function(layer)
  local res = {}
  if #layer == 0 then return res end
  local remaining = shallowAndNaiveListCopy(layer)
  relativeSorting.center.x = relloc.x
  relativeSorting.center.z = relloc.z
  table.sort(remaining, relativeSorting.robotDistanceComparator)
  -- the first block we visit should be the one closest to the robot
  res[#res + 1] = remaining[1]
  table.remove(remaining, 1)
  while #remaining > 0 do
    local last = res[#res]
    local shortestDist = -1
    for k,v in pairs(remaining) do
      local dist = robotDistance(last, v)
      if (dist < shortestDist) or (shortestDist < 0) then
        shortestDist = dist
      end
    end
    local closestBlocks = {}
    for k,v in pairs(remaining) do
      if robotDistance(last, v) == shortestDist then
        closestBlocks[#closestBlocks + 1] = v
      end
    end
    relativeSorting.center.x = last.x
    relativeSorting.center.z = last.z
    table.sort(closestBlocks, relativeSorting.angleComparator)
    res[#res + 1] = closestBlocks[1]
    removeFromList(remaining, closestBlocks[1])
  end
  return res
end

local tempLoc = {}
local iyIterationVals = {}
if verticalDirection == "up" then
  iyIterationVals.initial = bounds.minY
  iyIterationVals.final = bounds.maxY
  iyIterationVals.increment = 1
elseif verticalDirection == "down" then
  iyIterationVals.initial = bounds.maxY
  iyIterationVals.final = bounds.minY
  iyIterationVals.increment = -1
end
for iy=iyIterationVals.initial, iyIterationVals.final, iyIterationVals.increment do
  local layer = {}
  for ix=bounds.minX, bounds.maxX do
    for iz=bounds.minZ, bounds.maxZ do
      if isInShape(ix, iy, iz) and isOnEdge(ix, iy, iz) then
        layer[#layer + 1] = {x=ix, z=iz}
      end
    end
  end
  --layer = sortByAngle(layer)
  layer = sortByNN(layer)

  for i,loc in ipairs(layer) do
    --forceMove({x=loc.x, y=iy+1, z=loc.z})
    tempLoc.x = loc.x
    if verticalDirection == "up" then
      tempLoc.y = iy + 1
    elseif verticalDirection == "down" then
      tempLoc.y = iy - 1
    end
    tempLoc.z = loc.z
    forceMove(tempLoc)
    selectGlass()
    if verticalDirection == "up" then
      forcePlaceDown()
    elseif verticalDirection == "down" then
      forcePlaceUp()
    end
    layer[i] = nil
    checkCharge()
    --collectgarbage()
  end
end
