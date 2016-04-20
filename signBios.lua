local res, reason = pcall(function()
  local sign = component.proxy(component.list("sign")())
  local redstone = component.proxy(component.list("redstone")())
  local function tableSize(theTable)
    local res = 0
    for _ in pairs(theTable) do res = res + 1 end
    return res
  end
  local function customTostring(tableCache, args)
    local res = ""
    for i = 1, args.n do
      if res:len() >= 60 then break end
      local argType = type(args[i])
      if argType == "table" then
        tableCache[tostring(args[i])] = true
        local numPairs = tableSize(args[i])
        res = res .. "{"
        local currentPair = 1
        for k, v in pairs(args[i]) do
          res = res .. k .. "="
          if type(v) == "table" then
            if tableCache[tostring(v)] then
              res = res .. "*"
            else
              res = res .. customTostring(tableCache, table.pack(v))
              tableCache[tostring(v)] = true
            end
          else
            res = res .. customTostring(tableCache, table.pack(v))
          end
          if currentPair < numPairs then res = res .. "," end
          currentPair = currentPair + 1
        end
        res = res .. "}"
      elseif argType == "function" then
        res = res .. "func"
      else
        res = res .. tostring(args[i])
      end
      if i < args.n then res = res .. "," end
    end
    return res
  end
  while true do
    local signalName, _, redstoneSide = computer.pullSignal()
    if signalName == "redstone_changed" and redstone.getInput(redstoneSide) > 0 then
      local input = sign.getValue() or ""
      input = input:gsub("\n", "")
      if input:len() >= 1 and input:sub(1, 1) == "=" then
        input = "return " .. input:sub(2, -1)
      end
      local output
      local loadRes, loadReason = load(input)
      if loadRes then
        local inputRes
        local pcallRes, pcallReason = pcall(function() inputRes = table.pack(loadRes()) end)
        if pcallRes then
          output = customTostring({}, inputRes)
        else
          output = tostring(pcallReason)
        end
      else
        output = tostring(loadReason)
      end
      output = output:gsub("(" .. ("[^\n]"):rep(15) .. ")", "%1\n")
      sign.setValue(output)
    end
  end
end)
if not res then error(tostring(reason)) end