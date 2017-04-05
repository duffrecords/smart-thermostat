-- Measure temperature and post data to thingspeak.com
-- 2014 OK1CDJ
--- Tem sensor DS18B20 is conntected to GPIO0
--- 2015.01.21 sza2 temperature value concatenation bug correction

panic = false
relaypin = 0
pin = 1
ow.setup(pin)

counter=0
lasttemp=-999
home=false

function bxor(a,b)
   local r = 0
   for i = 0, 31 do
      if ( a % 2 + b % 2 == 1 ) then
         r = r + 2^i
      end
      a = a / 2
      b = b / 2
   end
   return r
end

--- Get temperature from DS18B20
function getTemp()
      addr = ow.reset_search(pin)
      repeat
        tmr.wdclr()

      if (addr ~= nil) then
        crc = ow.crc8(string.sub(addr,1,7))
        if (crc == addr:byte(8)) then
          if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
                ow.reset(pin)
                ow.select(pin, addr)
                ow.write(pin, 0x44, 1)
                tmr.delay(1000000)
                present = ow.reset(pin)
                ow.select(pin, addr)
                ow.write(pin,0xBE, 1)
                data = nil
                data = string.char(ow.read(pin))
                for i = 1, 8 do
                  data = data .. string.char(ow.read(pin))
                end
                crc = ow.crc8(string.sub(data,1,8))
                if (crc == data:byte(9)) then
                   t = (data:byte(1) + data:byte(2) * 256)
         if (t > 32768) then
                    t = (bxor(t, 0xffff)) + 1
                    t = (-1) * t
                   end
         t = t * 625
                   lasttemp = t
         print("Last temp: " .. lasttemp)
                end
                tmr.wdclr()
          end
        end
      end
      addr = ow.search(pin)
      until(addr == nil)
end

--- Get temp and send data to thingspeak.com
function sendData()
  print("about to run getTemp")
  getTemp()
  t1 = lasttemp / 10000
  t2 = (lasttemp >= 0 and lasttemp % 10000) or (10000 - lasttemp % 10000)
  print("Temp:"..t1 .. "."..string.format("%01d", t2).." C\n")
  -- print("Sending data to apilio.com")
  -- url = "https://apilio.herokuapp.com/string_variables/thermostat_temperature/set_value/with_key/" .. apikey .. "?value=" .. t1 .. "." .. string.format("%04d", t2)
  full_temp = t1 .. "." .. string.format("%01d", t2)
  metrics_db_body = "temperatures,location=living-tstat temp=" .. full_temp
  print(metrics_db_url)
  print(metrics_db_headers)
  print(metrics_db_body)
  http.post(metrics_db_url,
    metrics_db_headers,
    metrics_db_body,
    function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        print(code, data)
      end
    end)

  --- operate the relay that controls the thermostat
  gpio.mode(0,gpio.OUTPUT)
  if (t1 < heatsetpoint) then
    if (home) then
      gpio.write(0,gpio.HIGH)
      metrics_db_body = "devices,device=living-tstat status=1"
    end
  else
    gpio.write(0,gpio.LOW)
    metrics_db_body = "devices,device=living-tstat status=0"
  end

  --- send metrics
  http.post(metrics_db_url,
    metrics_db_headers,
    metrics_db_body,
    function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        print(code, data)
      end
    end)
end

-- send data every X ms to thing speak
-- tmr.alarm(0, 60000, 1, function() sendData() end )
tstat_timer = tmr.create()
tstat_timer:alarm(60000, tmr.ALARM_AUTO, function(cb_timer)
  if panic == false then
    sendData()
  else
    print("Received panic command. Stopping heater control sequence.")
    cb_timer:unregister()
    print("Shutting off heater.")
    gpio.mode(relaypin,gpio.OUTPUT)
    gpio.write(relaypin,gpio.LOW)
  end
end)
