#include "notifications.h"
#include <map>

@interface _NodeNotificationsDelegateBridge : NSObject <NSUserNotificationCenterDelegate> {
	std::map<NSUserNotification *, Persistent<Object> > *handleMap;
}
+ (id)sharedInstance;
- (void)mapHandle:(Handle<Object>)handle toUserNotification:(NSUserNotification *)userNotification;
- (void)unmapHandleToUserNotification:(NSUserNotification *)userNotification;
@end

static _NodeNotificationsDelegateBridge *_sharedInstance = nil;
@implementation _NodeNotificationsDelegateBridge
+ (id)sharedInstance {
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		if (_sharedInstance == nil)
			_sharedInstance = [[[self class] alloc] init];
	});

	return _sharedInstance;
}

- (id)init {
	if ((self = [super init])) {
		handleMap = new std::map<NSUserNotification *, Persistent<Object> >;
	}

	return self;
}

- (void)dealloc {
	delete handleMap;
	[super dealloc];
}

- (void)mapHandle:(Handle<Object>)handle toUserNotification:(NSUserNotification *)userNotification {
	handleMap->insert(std::pair<NSUserNotification *, Persistent<Object> >(userNotification, Persistent<Object>::New(handle)));
}

- (void)unmapHandleToUserNotification:(NSUserNotification *)userNotification {
	handleMap->at(userNotification).Dispose();
	handleMap->erase(userNotification);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)userNotification {
	HandleScope scope;
	
	Local<Value> argv[1] = {
		String::New("delivery")
	};
	MakeCallback(handleMap->at(userNotification), "emit", 1, argv);
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)userNotification {
	HandleScope scope;

	Local<Value> argv[1] = {
		String::New("permitDisplay")
	};
	
	Handle<Value> shouldDisplay = MakeCallback(handleMap->at(userNotification), "emit", 1, argv);
	Local<v8::Boolean> ret = shouldDisplay->ToBoolean();

	return ret->Value();
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)userNotification {
	NSUserNotificationActivationType type = [userNotification activationType];
	unsigned int argc;
	Local<Value> argv[2];

	if (type == NSUserNotificationActivationTypeNone) {
		argc = 1;
		argv[0] = String::New("ignore");
	}
	else {
		argc = 2;
		argv[0] = String::New("activate");
		argv[1] = type == NSUserNotificationActivationTypeContentsClicked ? String::New("content") : String::New("button");
	}

	MakeCallback(handleMap->at(userNotification), "emit", argc, argv);
}
@end

Persistent<Function> Notification::constructor;

Notification::Notification(NSString *title, NSString *subtitle, NSString *info) {
	@autoreleasepool {
		userNotification = [[NSUserNotification alloc] init];
		[userNotification setTitle:title];
		[userNotification setSubtitle:subtitle];
		[userNotification setInformativeText:info];
	}
}

Notification::~Notification() {
	@autoreleasepool {
		[[_NodeNotificationsDelegateBridge sharedInstance] unmapHandleToUserNotification:userNotification];
		[userNotification release];
	}
}

void Notification::Init() {
	HandleScope scope;
	
	@autoreleasepool {
		[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:[_NodeNotificationsDelegateBridge sharedInstance]];
	}

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
		@autoreleasepool {
			NSString *title=nil, *subtitle=nil, *info=nil;

			if (!args[0]->IsObject()) {
				ThrowException(Exception::TypeError(String::New("Should pass object to constructor.")));
				return Undefined();
			}
			Local<Object> obj = args[0]->ToObject();
			
			Local<Value> title_ = obj->Get(String::New("title"));
			if (title_->IsString()) title = [[NSString alloc] initWithUTF8String:*(String::AsciiValue(title_->ToString()))];
			Local<Value> subtitle_ = obj->Get(String::New("subtitle"));
			if (subtitle_->IsString()) subtitle = [[NSString alloc] initWithUTF8String:*(String::AsciiValue(subtitle_->ToString()))];
			Local<Value> info_ = obj->Get(String::New("info"));
			if (info_->IsString()) info = [[NSString alloc] initWithUTF8String:*(String::AsciiValue(info_->ToString()))];	
			
			Notification *notification = new Notification(title, subtitle, info);
			[[_NodeNotificationsDelegateBridge sharedInstance] mapHandle:args.This() toUserNotification:notification->userNotification];
			notification->Wrap(args.This());

			if (title != nil) [title release];
			if (subtitle != nil) [subtitle release];
			if (info != nil) [info release];

			return scope.Close(args.This());
		}
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
