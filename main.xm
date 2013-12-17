#include <node.h>
#include <v8.h>
#include <objc/runtime.h>

#include "notifications.h"

using namespace v8;

/* Hooks {{{ */
%config(generator=internal)

static BOOL isInvokingNotificationCenter = NO;
static NSString *identifier = nil;

%hook NSUserNotificationCenter
+ (NSUserNotificationCenter *)defaultUserNotificationCenter {
	isInvokingNotificationCenter = YES;
	NSUserNotificationCenter *ret = %orig;
	isInvokingNotificationCenter = NO;

	return ret;
}
%end

%hook NSBundle
- (NSString *)bundleIdentifier {
	if (self == [NSBundle mainBundle] && isInvokingNotificationCenter) return identifier;
	return %orig;
}
%end

static void PerformHooks() {
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		%init();
	});
}
/* }}} */

static BOOL identifierIsAllocated = NO;
static Persistent<Function> ModuleCtor;
Handle<Value> InitializeBundle(const Arguments &args) {
	HandleScope scope;
	
	if (args.IsConstructCall()) {
		@autoreleasepool {
			if (identifierIsAllocated) {
				[identifier release];
				identifierIsAllocated = NO;
			}

			if (args.Length() < 1) identifier = @"com.apple.Finder";
			else {
				Local<Value> bundleId = args[0];
				if (bundleId->IsString()) {
					char *identifier_ = *(String::AsciiValue(bundleId->ToString()));
					if (identifier_ == NULL || *identifier_ == '\0')
						identifier = @"com.apple.Finder";
					else {
						identifierIsAllocated = YES;
						identifier_ = strdup(identifier_);
						identifier = [[NSString alloc] initWithUTF8String:identifier_];
						free(identifier_);
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
