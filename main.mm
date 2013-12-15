#include <node.h>
#include <v8.h>
#include <objc/runtime.h>

#include "notifications.h"

using namespace v8;

static IMP __NodeNotificationsIdentifierOriginal = NULL;
static NSString *identifier = nil;
static NSString *__NodeNotificationsIdentifierOverride(NSBundle *self, SEL _cmd) {
	if (self == [NSBundle mainBundle]) return identifier;
	return __NodeNotificationsIdentifierOriginal(self, _cmd);
}

static Persistent<Function> ModuleCtor;

Handle<Value> InitializeBundle(const Arguments &args) {
	HandleScope scope;
	
	if (args.IsConstructCall()) {
		Class $NSBundle = objc_getClass("NSBundle");
		if (!$NSBundle) { ThrowException(Exception::Error(String::New("Did not link to Foundation.framework"))); }
		
		if (![[$NSBundle mainBundle] bundleIdentifier]) {
			if (args.Length() == 0) identifier = @"com.apple.Finder";
			else {
				Local<Value> bundleId = args[0]; // what on error?
				if (bundleId->IsString()) {
					identifier = [NSString stringWithUTF8String:*(String::AsciiValue(bundleId->ToString()))];
				}
			}

			Method identifierOrig = class_getInstanceMethod($NSBundle, @selector(bundleIdentifier));
			__NodeNotificationsIdentifierOriginal = method_getImplementation(identifierOrig);
			method_setImplementation(identifierOrig, (IMP)__NodeNotificationsIdentifierOverride);
		}

		Notification::Init(args.This());
		return scope.Close(args.This());
	}

	const int argc = 1;
	Local<Value> argv[argc] = { args[0] };
	return scope.Close(ModuleCtor->NewInstance(argc, argv));
}

void ModuleInit(Handle<Object> exports, Handle<Object> module) {
	HandleScope scope;
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(InitializeBundle);
	tpl->SetClassName(String::NewSymbol("nodenotifications"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);

	ModuleCtor = Persistent<Function>::New(tpl->GetFunction());
	module->Set(String::NewSymbol("exports"), ModuleCtor);	
}

NODE_MODULE(nodenotifications, ModuleInit);
