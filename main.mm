#line 1 "main.xm"
#include <node.h>
#include <v8.h>
#include <objc/runtime.h>

#include "notifications.h"

using namespace v8;




static BOOL isInvokingNotificationCenter = NO;
static NSString *identifier = nil;

#include <objc/message.h>
@class NSBundle; @class NSUserNotificationCenter; 
static Class _logos_supermetaclass$_ungrouped$NSUserNotificationCenter; static NSUserNotificationCenter * (*_logos_meta_orig$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter)(Class, SEL);static Class _logos_superclass$_ungrouped$NSBundle; static NSString * (*_logos_orig$_ungrouped$NSBundle$bundleIdentifier)(NSBundle*, SEL);

#line 15 "main.xm"

static NSUserNotificationCenter * _logos_meta_super$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter(Class self, SEL _cmd) {return ((NSUserNotificationCenter * (*)(Class, SEL))class_getMethodImplementation(_logos_supermetaclass$_ungrouped$NSUserNotificationCenter, @selector(defaultUserNotificationCenter)))(self, _cmd);}static NSUserNotificationCenter * _logos_meta_method$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter(Class self, SEL _cmd) {
	isInvokingNotificationCenter = YES;
	NSUserNotificationCenter *ret = _logos_meta_orig$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter(self, _cmd);
	isInvokingNotificationCenter = NO;

	return ret;
}



static NSString * _logos_super$_ungrouped$NSBundle$bundleIdentifier(NSBundle* self, SEL _cmd) {return ((NSString * (*)(NSBundle*, SEL))class_getMethodImplementation(_logos_superclass$_ungrouped$NSBundle, @selector(bundleIdentifier)))(self, _cmd);}static NSString * _logos_method$_ungrouped$NSBundle$bundleIdentifier(NSBundle* self, SEL _cmd) {
	if (self == [NSBundle mainBundle] && isInvokingNotificationCenter) return identifier;
	return _logos_orig$_ungrouped$NSBundle$bundleIdentifier(self, _cmd);
}


static void PerformHooks() {
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		{Class _logos_class$_ungrouped$NSUserNotificationCenter = objc_getClass("NSUserNotificationCenter"); Class _logos_metaclass$_ungrouped$NSUserNotificationCenter = object_getClass(_logos_class$_ungrouped$NSUserNotificationCenter); _logos_supermetaclass$_ungrouped$NSUserNotificationCenter = class_getSuperclass(_logos_metaclass$_ungrouped$NSUserNotificationCenter); { Class _class = _logos_metaclass$_ungrouped$NSUserNotificationCenter;Method _method = class_getInstanceMethod(_class, @selector(defaultUserNotificationCenter));if (_method) {_logos_meta_orig$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter = _logos_meta_super$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter;if (!class_addMethod(_class, @selector(defaultUserNotificationCenter), (IMP)&_logos_meta_method$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter, method_getTypeEncoding(_method))) {_logos_meta_orig$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter = (NSUserNotificationCenter * (*)(Class, SEL))method_getImplementation(_method);_logos_meta_orig$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter = (NSUserNotificationCenter * (*)(Class, SEL))method_setImplementation(_method, (IMP)&_logos_meta_method$_ungrouped$NSUserNotificationCenter$defaultUserNotificationCenter);}}}Class _logos_class$_ungrouped$NSBundle = objc_getClass("NSBundle"); _logos_superclass$_ungrouped$NSBundle = class_getSuperclass(_logos_class$_ungrouped$NSBundle); { Class _class = _logos_class$_ungrouped$NSBundle;Method _method = class_getInstanceMethod(_class, @selector(bundleIdentifier));if (_method) {_logos_orig$_ungrouped$NSBundle$bundleIdentifier = _logos_super$_ungrouped$NSBundle$bundleIdentifier;if (!class_addMethod(_class, @selector(bundleIdentifier), (IMP)&_logos_method$_ungrouped$NSBundle$bundleIdentifier, method_getTypeEncoding(_method))) {_logos_orig$_ungrouped$NSBundle$bundleIdentifier = (NSString * (*)(NSBundle*, SEL))method_getImplementation(_method);_logos_orig$_ungrouped$NSBundle$bundleIdentifier = (NSString * (*)(NSBundle*, SEL))method_setImplementation(_method, (IMP)&_logos_method$_ungrouped$NSBundle$bundleIdentifier);}}}}
	});
}


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
	module->Set(String::NewSymbol("NotificationCtor"), Notification::constructor);
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(InitializeBundle);
	tpl->SetClassName(String::NewSymbol("nodenotifications"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);

	ModuleCtor = Persistent<Function>::New(tpl->GetFunction());
	module->Set(String::NewSymbol("exports"), ModuleCtor);
}

NODE_MODULE(nodenotifications, ModuleInit);
