-- prints images as 3D prints

local component = require("component")
local os = require("os")
local printer = component.printer3d

local function HSBtoRGB(hue, sat, bright)
  local r, g, b = 0, 0, 0
  local fl = math.floor
  if sat == 0 then
    local rgb = fl(bright * 255 + 0.5)
    return rgb, rgb, rgb
  end
  local f1 = (hue - fl(hue)) * 6
  local f2 = f1 - fl(f1)
  local f3 = bright * (1 - sat)
  local f4 = bright * (1 - sat * f2)
  local f5 = bright * (1 - sat * (1 - f2))
  if fl(f1) == 0 then
    return fl(bright * 255 + 0.5), fl(f5 * 255 + 0.5), fl(f3 * 255 + 0.5)
  elseif fl(f1) == 1 then
    return fl(f4 * 255 + 0.5), fl(bright * 255 + 0.5), fl(f3 * 255 + 0.5)
  elseif fl(f1) == 2 then
    return fl(f3 * 255 + 0.5), fl(bright * 255 + 0.5), fl(f5 * 255 + 0.5)
  elseif fl(f1) == 3 then
    return fl(f3 * 255 + 0.5), fl(f4 * 255 + 0.5), fl(bright * 255 + 0.5)
  elseif fl(f1) == 4 then
    return fl(f5 * 255 + 0.5), fl(f3 * 255 + 0.5), fl(bright * 255 + 0.5)
  elseif fl(f1) == 5 then
    return fl(bright * 255 + 0.5), fl(f3 * 255 + 0.5), fl(f4 * 255 + 0.5)
  else error("shouldn't be here") end
end

local tileSize = 4
local pixelSize = math.floor(16 / tileSize)
local function getDimensions() return 8 * tileSize, 6 * tileSize end
local imageName = "Shop Ceiling"
local function getColor(x, y)
  local w, h = getDimensions()
  local r, g, b = HSBtoRGB((math.atan2(h/2-y, x-w/2) + math.pi) / (2*math.pi) + math.sqrt((x-w/2)^2+(y-h/2)^2)/10, 1, 1)
  return bit32.bor(bit32.lshift(r, 16), bit32.lshift(g, 8), bit32.lshift(b, 0))
end
-- subX and subY range from 0 to (tileSize - 1), inclusive
local function get3DCoords(subX, subY)
  -- covers for bottom of ceiling
  return subX * pixelSize, 15, subY * pixelSize, subX * pixelSize + pixelSize, 16, subY * pixelSize + pixelSize
end

local width, height = getDimensions()
-- iterate through height first to line up in the output chest
for itiley = 0, math.ceil(height / tileSize) - 1 do
  for itilex = 0, math.ceil(width / tileSize) - 1 do
    printer.reset()
    printer.setLabel(imageName .. " (" .. itilex .. ", " .. itiley .. ")")
    for isubx = 0, tileSize - 1 do
      for isuby = 0, tileSize - 1 do
        local x1, y1, z1, x2, y2, z2 = get3DCoords(isubx, isuby)
        printer.addShape(x1, y1, z1, x2, y2, z2, "opencomputers:White", getColor(itilex * tileSize + isubx, itiley * tileSize + isuby))
      end
    end
    printer.commit()
    os.sleep(0.5)
    while printer.status() == "busy" do
      os.sleep(0.05)
    end
  end
end
printer.reset()
