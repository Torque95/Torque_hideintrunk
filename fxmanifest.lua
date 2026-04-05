fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx_trunkhide'
author 'Torque'
description 'Qbox trunk hide using ox_lib + ox_target'
version '1.0.0'

shared_scripts {
  '@ox_lib/init.lua',
  'shared/config.lua',
}

client_scripts {
  'client/main.lua',
}

server_scripts {
  'server/main.lua',
}

dependencies {
  'ox_lib',
  'ox_target',
  'qbx_core',
}
