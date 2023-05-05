fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'ex_vehlock'
description 'Modified ESX Vehicle Lock'
version '1.0.0'
author 'wibowo#7184'

files {
	"html/sounds/*.ogg",
    "html/main.html"
}

shared_scripts {
	"@es_extended/imports.lua",
	"@es_extended/locale.lua",
	"@ox_lib/init.lua",
	'locales/*.lua',
	'config.lua',
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
}

ui_page "html/main.html"