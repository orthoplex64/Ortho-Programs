local res, reason = pcall(function()
  local drone = component.proxy(component.list("drone")())
  local radar = component.proxy(component.list("radar")())
  
  local function sleep(timeout)
    local deadline = computer.uptime() + timeout
    repeat
      computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
  end
  local function determinant(mat)
    local res = 0
    local numCols = #mat -- must be square matrix
    for col = 1, numCols do
      local prod1, prod2 = 1, 1
      for i = 1, numCols do
        prod1 = prod1 * mat[i][(col + (i - 1)) % numCols + 1]
        prod2 = prod2 * mat[i][(col - (i - 1) + numCols) % numCols + 1]
      end
      res = res + prod1 - prod2
    end
    return res
  end
  local function calcCoords(vars)
    local eqVars =
    {{(vars.x2 - vars.x1) * 2, (vars.y2 - vars.y1) * 2, (vars.z2 - vars.z1) * 2, vars.r1^2 - vars.r2^2 + vars.x2^2 - vars.x1^2 + vars.y2^2 - vars.y1^2 + vars.z2^2 - vars.z1^2},
     {(vars.x3 - vars.x2) * 2, (vars.y3 - vars.y2) * 2, (vars.z3 - vars.z2) * 2, vars.r2^2 - vars.r3^2 + vars.x3^2 - vars.x2^2 + vars.y3^2 - vars.y2^2 + vars.z3^2 - vars.z2^2},
     {(vars.x4 - vars.x3) * 2, (vars.y4 - vars.y3) * 2, (vars.z4 - vars.z3) * 2, vars.r3^2 - vars.r4^2 + vars.x4^2 - vars.x3^2 + vars.y4^2 - vars.y3^2 + vars.z4^2 - vars.z3^2}}
    local detAll = determinant(
    {{eqVars[1][1], eqVars[1][2], eqVars[1][3]},
     {eqVars[2][1], eqVars[2][2], eqVars[2][3]},
     {eqVars[3][1], eqVars[3][2], eqVars[3][3]}})
    local detX = determinant(
    {{eqVars[1][4], eqVars[1][2], eqVars[1][3]},
     {eqVars[2][4], eqVars[2][2], eqVars[2][3]},
     {eqVars[3][4], eqVars[3][2], eqVars[3][3]}})
    local detY = determinant(
    {{eqVars[1][1], eqVars[1][4], eqVars[1][3]},
     {eqVars[2][1], eqVars[2][4], eqVars[2][3]},
     {eqVars[3][1], eqVars[3][4], eqVars[3][3]}})
    local detZ = determinant(
    {{eqVars[1][1], eqVars[1][2], eqVars[1][4]},
     {eqVars[2][1], eqVars[2][2], eqVars[2][4]},
     {eqVars[3][1], eqVars[3][2], eqVars[3][4]}})
    return detX / detAll, detY / detAll, detZ / detAll
  end
  --local mat = {{2, -1, 6},
  --{-3, 4, -5},
  --{8, -7, -9}}
  --mat.nRows, mat.nCols = 3, 3
  --print(determinant(mat))
  --local vars = {
  --    x1=math.random(), y1=math.random(), z1=math.random(),
  --    x2=math.random(), y2=math.random(), z2=math.random(),
  --    x3=math.random(), y3=math.random(), z3=math.random(),
  --    x4=math.random(), y4=math.random(), z4=math.random()}
  --local testPoint = {x=math.random(), y=math.random(), z=math.random()}
  --print("Test point: " .. testPoint.x .. ", " .. testPoint.y .. ", " .. testPoint.z)
  --vars.r1 = math.sqrt((testPoint.x - vars.x1)^2 + (testPoint.y - vars.y1)^2 + (testPoint.z - vars.z1)^2)
  --vars.r2 = math.sqrt((testPoint.x - vars.x2)^2 + (testPoint.y - vars.y2)^2 + (testPoint.z - vars.z2)^2)
  --vars.r3 = math.sqrt((testPoint.x - vars.x3)^2 + (testPoint.y - vars.y3)^2 + (testPoint.z - vars.z3)^2)
  --vars.r4 = math.sqrt((testPoint.x - vars.x4)^2 + (testPoint.y - vars.y4)^2 + (testPoint.z - vars.z4)^2)
  --local calcRes = table.pack(calcCoords(vars))
  --print("Result: " .. calcRes[1] .. ", " .. calcRes[2] .. ", " .. calcRes[3])
  local function sleepMove(...)
    drone.move(...)
    while drone.getVelocity() ~= 0 do
      sleep(0.1)
    end
  end
  local cds =
  {{1, 1, 0},
   {1, 0, 1},
   {0, 1, 1},
   {0, 0, 0}}
  local radarData =
  {x1=cds[1][1], y1=cds[1][2], z1=cds[1][3],
   x2=cds[2][1], y2=cds[2][2], z2=cds[2][3],
   x3=cds[3][1], y3=cds[3][2], z3=cds[3][3],
   x4=cds[4][1], y4=cds[4][2], z4=cds[4][3]}
  local targetName = "orthoplex64"
  while true do
    radarData.r1 = radar.getPlayers()[1].distance
    sleepMove(cds[2][1] - cds[1][1], cds[2][2] - cds[1][2], cds[2][3] - cds[1][3])
    radarData.r2 = radar.getPlayers()[1].distance
    sleepMove(cds[3][1] - cds[2][1], cds[3][2] - cds[2][2], cds[3][3] - cds[2][3])
    radarData.r3 = radar.getPlayers()[1].distance
    sleepMove(cds[4][1] - cds[3][1], cds[4][2] - cds[3][2], cds[4][3] - cds[3][3])
    radarData.r4 = radar.getPlayers()[1].distance
    local targetCoords = table.pack(calcCoords(radarData))
    targetCoords[2] = targetCoords[2] + 2
    sleepMove(table.unpack(targetCoords))
    sleep(3)
  end
end)
if not res then error(tostring(reason)) end