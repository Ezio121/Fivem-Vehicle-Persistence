fx_version 'cerulean'
game 'gta5'

author 'BadassFalcon'
description 'Vehicle Saving and Respawning Script'
version '1.0.0'

dependency 'mysql-async'

client_scripts {
    'client.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua', 
    'server.lua',
}
