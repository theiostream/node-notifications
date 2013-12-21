{
	"targets": [
		{
			"target_name": "nodenotifications",
			"cflags": [ "-std=c++11" ],
			"sources": [ "main.mm", "notifications.mm" ],
			"link_settings": { 'libraries': ['-lsubstrate'] }
		}
	]
}
