var util = require("util"),
    Notifications = require("./build/Release/nodenotifications");

util.inherits(Notifications, process.EventEmitter);

exports = module.exports = Notifications;
