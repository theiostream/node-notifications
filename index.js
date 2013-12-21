// Thanks to github.com/bnoordhuis/node-event-emitter
// ISC-Licensed.
function inherits(target, source) {
  for (var k in source.prototype)
    target.prototype[k] = source.prototype[k];
}

Notifications = require("./build/Release/nodenotifications")
events = require('events')

inherits(Notifications.NotificationCtor, events.EventEmitter)
delete Notifications.NotificationCtor;

exports = module.exports = Notifications;
