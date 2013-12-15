#include <node.h>
#include <v8.h>
#include "notifications.h"

using namespace v8;

void Init(Handle<Object> exports) {
	Notification::Init(exports);
}

NODE_MODULE(nodenotifications, Init);
