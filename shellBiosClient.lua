local component = require("component")
local event = require("event")
local term = require("term")

local prompt = "> "
local function modemListener(_, _, senderAddr, portReceivedOn, senderDistance, data)
  if portReceivedOn ~= 6465 then return end
  term.clearLine()
  term.write("From " .. senderAddr:sub(1, 4) .. ":\n")
  term.write(data .. "\n", true)
  term.write(prompt)
end
event.listen("modem_message", modemListener)
component.modem.open(6465)
term.write("Now listening on port 6465.\n")
if component.modem.setStrength then component.modem.setStrength(20) end
local termHistory = {}
while true do
  term.write(prompt)
  local input = term.read(termHistory)
  while #termHistory > 100 do
    table.remove(termHistory, 1)
  end
  if input == nil then break end
  input = input:gsub("^%s+", ""):gsub("%s+$", "")
  if input:len() >= 1 then
    if input:sub(1, 1) == "=" then
      input = "return " .. input:sub(2, -1)
    elseif input:sub(1, 1) == "/" then
      local args = {n=0}
      for str in input:sub(2, -1):gmatch("(%S+)") do
        table.insert(args, str)
        args.n = args.n + 1
      end
      if args[1] == "sendfile" then
        local file, message = io.open(input:match("sendfile%s+(.*)") or "")
        if file then
          input = file:read("*a")
          file:close()
        else
          term.write(message .. "\n", true)
          input = nil
        end
      end
    end
  end
  if input and input:len() > 0 then
    component.modem.broadcast(6464, input)
  end
end
component.modem.close(6465)
event.ignore("modem_message", modemListener)
term.write("No longer listening on port 6465.\n")