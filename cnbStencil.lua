local component = require('component')
local shell = require('shell')
local event = require('event')
local holo = component.hologram

if not holo then
  print('Error: Hologram projector not found.')
  os.exit(1)
end

local args, options = shell.parse(...)
if #args < 1 then
  print('Usage: cnbStencil [-p|--preview] <model file>')
  os.exit(0)
end
local previewMode = options.preview or options.p or false
local file, reason = io.open(args[1], 'r')
if not file then
  print('Error opening model: ' .. reason)
  os.exit(1)
end
local fileContents = file:read('*a')
file:close()
local model = {math=math, table=table}
local modelFunc, reason = load(fileContents, nil, nil, model)
if not modelFunc then
  print('Error parsing model: ' .. reason)
  os.exit(1)
end
local res, reason = pcall(modelFunc)
if not res then
  print('Error executing model: ' .. reason)
  os.exit(1)
end

local blockBounds = model.blockBounds or {0,0, 0,0, 0,0}
local origin = model.origin or {7.5, 7.5, 7.5}
local numMaterials = model.numMaterials or 1
local drawMode = model.drawMode or 'EDGE_THICK'
local isInShape = model.isInShape
if not isInShape then
  print('Error: isInShape missing from model.')
  os.exit(1)
end
local getMaterial = model.getMaterial or function() return 1 end
function getPreviewColor(mat)
  return mat % (numMaterials % 3 == 0 and 3 or
      numMaterials % 2 == 0 and 2 or 3) + 1
end

function isOnEdge(x, y, z)
  return not (isInShape(x - 1, y, z) and
      isInShape(x + 1, y, z) and
      isInShape(x, y - 1, z) and
      isInShape(x, y + 1, z) and
      isInShape(x, y, z - 1) and
      isInShape(x, y, z + 1))
end
function isOnEdgeThick(x, y, z)
  for dx = -1, 1 do
    for dy = -1, 1 do
      for dz = -1, 1 do
        if not isInShape(x + dx, y + dy, z + dz) then return true end
      end
    end
  end
  return false
end
local bitDeterminer
if drawMode == 'SOLID' then
  bitDeterminer = function(x, y, z)
    return isInShape(x, y, z)
  end
elseif drawMode == 'INVERSE' then
  bitDeterminer = function(x, y, z)
    return not isInShape(x, y, z)
  end
elseif drawMode == 'EDGE' then
  bitDeterminer = function(x, y, z)
    return isInShape(x, y, z) and isOnEdge(x, y, z)
  end
elseif drawMode == 'EDGE_THICK' then
  bitDeterminer = function(x, y, z)
    return isInShape(x, y, z) and isOnEdgeThick(x, y, z)
  end
else exit('Unknown draw mode \'' .. drawMode .. '\'') end
function holoSet(x, y, z, val)
  val = val or 1
  --print('in', x, y, z)
  --print('out', (15 - x) + 17, y + 9, z + 17)
  holo.set((15 - x) + 17, y + 9, z + 17, val)
end

event.pull('key_up') -- from entering command
for iBlockY = blockBounds[3], blockBounds[4] do
for iBlockX = blockBounds[1], blockBounds[2] do
for iBlockZ = blockBounds[5], blockBounds[6] do
  if previewMode then
    holo.clear()
    print('Rendering block (' ..
        iBlockX .. '/' .. blockBounds[2] .. ', ' ..
        iBlockY .. '/' .. blockBounds[4] .. ', ' ..
        iBlockZ .. '/' .. blockBounds[6] .. ')')
  end
  for iBitZ = 15, 0, -1 do
    local z = iBlockZ * 16 + iBitZ - origin[3]
    local slice = {}
    for iBitX = 0, 15 do
    for iBitY = 0, 15 do
      local x = iBlockX * 16 + iBitX - origin[1]
      local y = iBlockY * 16 + iBitY - origin[2]
      if bitDeterminer(x, y, z) then
        local mat = getMaterial(x, y, z)
        if not slice[mat] then slice[mat] = {} end
        if not slice[mat][iBitX] then slice[mat][iBitX] = {} end
        slice[mat][iBitX][iBitY] = true
      end
    end end
    for mat, xs in pairs(slice) do
      if not previewMode then
        holo.clear()
        print('Rendering block (' ..
            iBlockX .. '/' .. blockBounds[2] .. ', ' ..
            iBlockY .. '/' .. blockBounds[4] .. ', ' ..
            iBlockZ .. '/' .. blockBounds[6] .. ') slice ' ..
            iBitZ .. ' material ' .. mat .. '/' .. numMaterials)
      end
      local setCount = 0
      for iBitX, ys in pairs(xs) do
      for iBitY, _ in pairs(ys) do
          holoSet(iBitX, iBitY, iBitZ, previewMode and getPreviewColor(mat) or 1)
        setCount = setCount + 1
      end end
      if setCount > 0 and not previewMode then
        print(setCount .. ' voxels rendered')
        event.pull('key_up')
      end
    end
  end
  if previewMode then
    event.pull('key_up')
  else
    os.sleep(0)
  end
end end end
