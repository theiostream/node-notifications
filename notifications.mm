#include "notifications.h"

Persistent<Function> Notification::constructor; // leak?

Notification::Notification(NSString *title, NSString *subtitle, NSString *info) {
	@autoreleasepool {
		userNotification = [[NSUserNotification alloc] init];
		[userNotification setTitle:title];
		[userNotification setSubtitle:subtitle];
		[userNotification setInformativeText:info];
	}
}

Notification::~Notification() {
	[userNotification release];
}

void Notification::Init() {
	HandleScope scope;
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(New);
	tpl->SetClassName(String::NewSymbol("Notification"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);
	
	NODE_SET_PROTOTYPE_METHOD(tpl, "show", Show);
	NODE_SET_PROTOTYPE_METHOD(tpl, "remove", Remove);
	NODE_SET_PROTOTYPE_METHOD(tpl, "hasDelivered", HasDelivered);
	
	constructor = Persistent<Function>::New(tpl->GetFunction());
}

void Notification::AddToExports(Handle<Object> exports) {
	HandleScope scope;
	exports->Set(String::NewSymbol("Notification"), constructor);
}

Handle<Value> Notification::New(const Arguments &args) {
	HandleScope scope;

	if (args.IsConstructCall()) {
		NSString *title=nil, *subtitle=nil, *info=nil;

		if (!args[0]->IsObject()) {
			ThrowException(Exception::TypeError(String::New("Should pass object to constructor.")));
			return Undefined();
		}
		Local<Object> obj = args[0]->ToObject();
		
		@autoreleasepool {
			Local<Value> title_ = obj->Get(String::New("title"));
			if (title_->IsString()) title = [[NSString alloc] initWithUTF8String:*(String::AsciiValue(title_->ToString()))];
			Local<Value> subtitle_ = obj->Get(String::New("subtitle"));
			if (subtitle_->IsString()) subtitle = [[NSString alloc] initWithUTF8String:*(String::AsciiValue(subtitle_->ToString()))];
			Local<Value> info_ = obj->Get(String::New("info"));
			if (info_->IsString()) info = [[NSString alloc] initWithUTF8String:*(String::AsciiValue(info_->ToString()))];
		}
		
		Notification *notification = new Notification(title, subtitle, info);
		notification->Wrap(args.This());

		if (title != nil) [title release];
		if (subtitle != nil) [subtitle release];
		if (info != nil) [info release];

		return scope.Close(args.This());
	}

	const int argc = 1;
	Local<Value> argv[argc] = { args[0] };
	return scope.Close(constructor->NewInstance(argc, argv));
}

Handle<Value> Notification::Show(const Arguments &args) {
	HandleScope scope;
	
	Notification *notification = ObjectWrap::Unwrap<Notification>(args.This());
	@autoreleasepool {
		[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification->userNotification];
	}
	
	return Undefined();
}

Handle<Value> Notification::Remove(const Arguments &args) {
	HandleScope scope;

	Notification *notification = ObjectWrap::Unwrap<Notification>(args.This());
	@autoreleasepool {
		[[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification->userNotification];
	}
	
	return Undefined();
}

Handle<Value> Notification::HasDelivered(const Arguments &args) {
	HandleScope scope;
	
	Handle<Value> ret;
	@autoreleasepool {
		Notification *notification = ObjectWrap::Unwrap<Notification>(args.This());
		NSArray *deliveredNotifications = [[NSUserNotificationCenter defaultUserNotificationCenter] deliveredNotifications];
		ret = v8::Boolean::New((bool)[deliveredNotifications containsObject:notification->userNotification]);
	}

	return ret;
}
