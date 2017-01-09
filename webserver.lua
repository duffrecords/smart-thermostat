-----------------------
--                   --
--  httpserver2.lua  --
--                   --
-----------------------

-- 1:set variables and initial GPIO states
led1 = 0
heatsetpoint = 25
gpio.mode(led1,gpio.OUTPUT)
gpio.write(led1,gpio.LOW)

-- 2:check whether server is already started
if srv~=nil then
  srv:close()
end

-- 3:create webserver
srv = net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive",function(cn,request)
    local buf = ""

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

    -- 6:the webpage
    buf = buf.."Demo server"
    buf = buf.."Led 1 Turn on "
    buf = buf.."Turn off"
    buf = buf.."Led 2 Turn on "
    buf = buf.."Turn off"

    -- 7:the actions
    if (_GET.pin=="L1On") then
      gpio.write(led1,gpio.HIGH)
    elseif (_GET.pin=="L1Off") then
      gpio.write(led1,gpio.LOW)
    elseif (type(_GET.heatsetpoint)=="string") then
      heatsetpoint = tonumber(_GET.heatsetpoint)
    end

    -- 8:send the data and close the connection
    cn:send(buf)
    cn:close()
    collectgarbage()
  end)
end)
