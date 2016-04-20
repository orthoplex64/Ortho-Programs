local res, reason = pcall(function()
  local modem = component.proxy(component.list("modem")())
  local function tableSize(theTable)
    local res = 0
    for _ in pairs(theTable) do res = res + 1 end
    return res
  end
  local function customTostring(tableCache, indent, args)
    local res = ""
    for i = 1, args.n do
      local argType = type(args[i])
      if argType == "table" then
        tableCache[tostring(args[i])] = true
        local numPairs = tableSize(args[i])
        res = res .. "{"
        local currentPair = 1
        for k, v in pairs(args[i]) do
          res = res .. k .. " = "
          if type(v) == "table" then
            if tableCache[tostring(v)] then
              res = res .. "*"
            else
              res = res .. customTostring(tableCache, indent + 2, table.pack(v))
              tableCache[tostring(v)] = true
            end
          else
            res = res .. customTostring(tableCache, indent + 2, table.pack(v))
          end
          if currentPair < numPairs then res = res .. ",\n" .. (" "):rep(indent + 2) end
          currentPair = currentPair + 1
        end
        res = res .. "}"
      elseif argType == "function" then
        res = res .. "function"
      elseif argType == "string" then
        res = res .. ("%q"):format(args[i])
      else
        res = res .. tostring(args[i])
      end
      if i < args.n then res = res .. ", " end
    end
    return res
  end
  modem.open(6464)
  while true do
    local signalName, _, senderAddr, _, senderDistance, input = computer.pullSignal()
    if signalName == "modem_message" then
      local loadRes, loadReason = load(input)
      if loadRes then
        local inputRes
        local pcallRes, pcallReason = pcall(function() inputRes = table.pack(loadRes()) end)
        if pcallRes then
          output = customTostring({}, 0, inputRes)
        else
          output = tostring(pcallReason)
        end
      else
        output = tostring(loadReason)
      end
      if modem.setStrength then modem.setStrength(senderDistance + 1) end
      modem.send(senderAddr, 6465, output)
    end
  end
end)
if not res then error(tostring(reason)) end