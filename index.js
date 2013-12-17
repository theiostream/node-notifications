var util = require("util"),
Notifications = require("./build/Release/nodenotifications");

util.inherits(Notifications.NotificationCtor, process.EventEmitter);
delete Notifications.NotificationCtor

exports = module.exports = Notifications;
