--init.lua
local ok,e = pcall(dofile,"config.lua")
if not ok then
  print(e)
  return
end
print(ssid)
print(password)
print(apikey)
print("Setting up WIFI...")
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid,password)
wifi.sta.connect()
tmr.alarm(1, 1000, 1, function() 
  print("in function")
  if wifi.sta.getip() == nil then 
    print("IP unavaiable, Waiting...") 
  else 
    tmr.stop(1)
    print("Config done, IP is "..wifi.sta.getip())
  end 
end)
