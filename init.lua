-- FAILSAFE: turn off the relay by default in case something goes wrong
relaypin = 0
gpio.mode(relaypin,gpio.OUTPUT)
gpio.write(relaypin,gpio.LOW)
panic = true

-- load credentials, 'ssid' and 'password' declared and initialize in there
dofile("config.lua")

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        -- dofile("application.lua")
        dofile("webserver.lua")
        dofile("ds18b20.lua")
    end
end

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid, password)
-- wifi.sta.connect() not necessary because config() uses auto-connect=true by default
tmr.create():alarm(1000, tmr.ALARM_AUTO, function(cb_timer)
    if wifi.sta.getip() == nil then
        print("Waiting for IP address...")
    else
        cb_timer:unregister()
        print("WiFi connection established, IP address: " .. wifi.sta.getip())
        print("You have 3 seconds to abort")
        print("Waiting...")
        tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
    end
end)
