# Fivem-Vehicle-Persistence
A very simple Vehicle Persistence script that saves the vehicle and location you are in when you press the "L" key and when you reconnect to the server it will respawn you into that vehicle in that location, keeping the vehicles health, fuel, heading etc the same.

It works with all frameworks.

Dependency: mysql-async



Usage:
Add it to the reosurces folder and then put ensure Fivem-Vehicle-Persistence in the server beflow the mysql-async

1.Press L to save a vehicle in your database
  Each player can only save one vehicle this way. 
  As long as a vehicle is saved, when a player reconnects they spawn in that vehicle, persisting all the vehicle data

2.Press [ to delete the vehicle from the database so that the auto spawn doesn't happen

Note: Keys can be configured at the top of the client.lua 

For any issues contact me @Discord(badassfalcon)
