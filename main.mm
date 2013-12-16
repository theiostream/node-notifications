#include <node.h>
#include <v8.h>
#include <objc/runtime.h>

#include "notifications.h"

using namespace v8;

/* Hooks {{{ */
static IMP __NodeNotificationsNotificationCenterOriginal = NULL;
static BOOL isInvokingNotificationCenter = NO;
static NSUserNotificationCenter *__NodeNotificationsNotificationCenterOverride(Class self, SEL _cmd) {
	isInvokingNotificationCenter = YES;
	NSUserNotificationCenter *center = __NodeNotificationsNotificationCenterOriginal(self, _cmd);
	isInvokingNotificationCenter = NO;

	return center;
}

static IMP __NodeNotificationsIdentifierOriginal = NULL;
static NSString *identifier = nil;
static NSString *__NodeNotificationsIdentifierOverride(NSBundle *self, SEL _cmd) {
	if (self == [NSBundle mainBundle] && isInvokingNotificationCenter) return identifier;
	return __NodeNotificationsIdentifierOriginal(self, _cmd);
}

static void PerformHooks() {
	Method ncOrig = class_getClassMethod($NSUserNotificationCenter, @selector(defaultUserNotificationCenter));
	__NodeNotificationsNotificationCenterOriginal = method_getImplementation(ncOrig);
	method_setImplementation(ncOrig, (IMP)__NodeNotificationsNotificationCenterOverride);

	Method identifierOrig = class_getInstanceMethod($NSBundle, @selector(bundleIdentifier));
	__NodeNotificationsIdentifierOriginal = method_getImplementation(identifierOrig);
	method_setImplementation(identifierOrig, (IMP)__NodeNotificationsIdentifierOverride);

}
/* }}} */

static Persistent<Function> ModuleCtor;
Handle<Value> InitializeBundle(const Arguments &args) {
	HandleScope scope;
	
	if (args.IsConstructCall()) {
		@autoreleasepool {
			Class $NSBundle = objc_getClass("NSBundle");
			Class $NSUserNotificationCenter = objc_getClass("NSUserNotificationCenter");
			if (!$NSBundle || !$NSUserNotificationCenter) {
				ThrowException(Exception::Error(String::New("Did not link to Foundation.framework")));
				return Undefined();
			}
			
			if (![[$NSBundle mainBundle] bundleIdentifier]) {
				if (args.Length() < 1) identifier = @"com.apple.Finder";
				else {
					Local<Value> bundleId = args[0];
					if (bundleId->IsString()) {
						char *identifier_ = *(String::AsciiValue(bundleId->ToString()));
						if (identifier_ == NULL || *identifier_ == '\0')
							identifier = @"com.apple.Finder";

						if (identifier != nil) [identifier release];
						identifier = [[NSString alloc] initWithUTF8String:identifier_];
					}
				}
			}
		}
		
		Notification::AddToExports(args.This());
		return scope.Close(args.This());
	}

	const int argc = 1;
	Local<Value> argv[argc] = { args[0] };
	return scope.Close(ModuleCtor->NewInstance(argc, argv));
}


void ModuleInit(Handle<Object> exports, Handle<Object> module) {
	PerformHooks();
	
	HandleScope scope;
	
	Notification::Init();
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(InitializeBundle);
	tpl->SetClassName(String::NewSymbol("nodenotifications"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);

	ModuleCtor = Persistent<Function>::New(tpl->GetFunction());
	module->Set(String::NewSymbol("exports"), ModuleCtor);
}

NODE_MODULE(nodenotifications, ModuleInit);
