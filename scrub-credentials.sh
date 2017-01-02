#!/bin/bash

sed 's/wifi\.sta\.config.*/wifi\.sta\.config("essid","password")/' wifi.lua > wifi.lua.template
sed 's/wifi\.sta\.config.*/wifi\.sta\.config("essid","password")/' init.lua > init.lua.template
sed 's/  apikey = "[0-9a-zA-Z]*"/  apikey = "yourapikey"/' ds1820.lua > ds1820.lua.template
