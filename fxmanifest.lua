fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'ex_vehlock'
description 'Modified ESX Vehicle Lock'
version '2.0.0'
author 'wibowo#7184'

files {
	"html/sounds/*.ogg",
    "html/main.html"
}

shared_scripts {
	"@es_extended/imports.lua",
	"@ox_lib/init.lua",
	"config.lua",
	"shared.lua",
}

server_script {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}

client_scripts {
	'client/*.lua'
}

dependencies {
	'es_extended',
	'oxmysql',
	'ox_lib',
	-- 'ox_target'-- optional
}

ui_page "html/main.html"