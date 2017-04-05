-----------------------
--                   --
--  httpserver2.lua  --
--                   --
-----------------------

-- 1:set variables and initial GPIO states
relaypin = 0
heatsetpoint = 25
t1 = 25
t2 = 0
gpio.mode(relaypin,gpio.OUTPUT)
gpio.write(relaypin,gpio.LOW)

-- 2:check whether server is already started
if srv~=nil then
  srv:close()
end

-- 3:create webserver
srv = net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive",function(cn,request)
    local buf = ""
    local apibuf = ""

    -- 4:extra path and variables
    local _,_,method,path,vars = string.find(request,"([A-Z]+) (.+)?(.+) HTTP")
    if(method==nil) then
      _, _, method, path = string.find(request,"([A-Z]+) (.+) HTTP")
    end

    -- 5:extract the variables passed in the url
    local _GET = {}
    if (vars~=nil) then
      for k,v in string.gmatch(vars,"(%w+)=(%w+)&*") do
        _GET[k] = v
      end
    end

    -- 7:the actions
    if (_GET.pin=="L1On") then
      gpio.write(relaypin,gpio.HIGH)
    elseif (_GET.pin=="L1Off") then
      gpio.write(relaypin,gpio.LOW)
    elseif (type(_GET.heatsetpoint)=="string") then
      heatsetpoint = tonumber(_GET.heatsetpoint)
    elseif (_GET.adjust=="up") then
      if (heatsetpoint < 30) then
        heatsetpoint = heatsetpoint + 1
      end
    elseif (_GET.adjust=="down") then
      if (heatsetpoint > 20) then
        heatsetpoint = heatsetpoint - 1
      end
    elseif (_GET.home=="true") then
      home = true
    elseif (_GET.home=="false") then
      home = false
    elseif (_GET.status=="relay") then
      apibuf = apibuf..tostring(gpio.read(relaypin))
    elseif (_GET.status=="heatsetpoint") then
      apibuf = apibuf..tostring(heatsetpoint)
    elseif (_GET.status=="home") then
      apibuf = apibuf..tostring(home)
    else
      buf = ""
    end

    -- 6:the webpage
    buf = buf.."<h1> ESP8266 Smart Thermostat</h1>";
    if (gpio.read(relaypin)==0) then
      buf = buf.."<p>Contact Closure: <a href=\"?pin=L1On\"><button>ON</button></a>&nbsp;<a href=\"?pin=L1Off\"><button style=\"color:#0099ff\">OFF</button></a></p>";
    else
      buf = buf.."<p>Contact Closure: <a href=\"?pin=L1On\"><button style=\"color:#0099ff\">ON</button></a>&nbsp;<a href=\"?pin=L1Off\"><button>OFF</button></a></p>";
    end
    buf = buf.."<p>Heater Setpoint: "..tostring(heatsetpoint).."&nbsp;<a href=\"?adjust=down\"><button>&#9660;</button></a>&nbsp;<a href=\"?adjust=up\"><button>&#9650;</button></a></p>";
    buf = buf.."<p>Current Temperature: "..tostring(t1).."."..string.format("%01d", t2).."&deg; C</p>";
    if (home) then
      mode = 'Home'
    else
      mode = 'Away'
    end
    buf = buf.."<p>Heating Mode: "..mode.."</p>";

    -- 8:send the data and close the connection
    if (apibuf=="") then
      cn:send(buf)
    else
      cn:send(apibuf)
    end
    cn:close()
    collectgarbage()
  end)
end)
