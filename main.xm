#include <node.h>
#include <v8.h>
#include <uv.h>

#include <Block.h>
#include <objc/runtime.h>
#import <dispatch/dispatch.h>
#import <substrate.h>

#include "notifications.h"

using namespace v8;

static BOOL isInvokingNotificationCenter = NO;
static BOOL identifierHasAlloc = NO;
static NSString *identifier = nil;

static OSSpinLock spinLock = OS_SPINLOCK_INIT;
static uv_async_t *watcher;

/* Hooks {{{ */
%config(generator=internal)

%hook NSUserNotificationCenter
+ (NSUserNotificationCenter *)defaultUserNotificationCenter {
	isInvokingNotificationCenter = YES;
	NSUserNotificationCenter *ret = %orig;
	isInvokingNotificationCenter = NO;

	// Why not?
	if (identifierHasAlloc) {
		[identifier release];
		identifierHasAlloc = NO;
	}

	return ret;
}
%end

%hook NSBundle
- (NSString *)bundleIdentifier {
	if (self == [NSBundle mainBundle] && isInvokingNotificationCenter) return identifier;
	return %orig;
}
%end

MSHook(void, dispatch_sync, dispatch_queue_t queue, void(^block)()) {
	if (queue == dispatch_get_main_queue()) {
		watcher->data = Block_copy(block);
		uv_async_send(watcher);
		
		// There should be a better solution for this.
		// TODO: Explore more locking options.
		// (Also, what'd happen if Lock(); Lock(); ... Unlock(); Would this be called or would we wait until the 'queue' was over?
		while (!OSSpinLockTry(&spinLock));
	}
	else
		_dispatch_sync(queue, block);
}
MSHook(void, dispatch_async, dispatch_queue_t queue, void (^block)()) {
	if (queue == dispatch_get_main_queue()) {
		watcher->data = Block_copy(block);
		uv_async_send(watcher);
	}
	else
		_dispatch_async(queue, block);
}

static void dispatchCallback(uv_async_t *handle, int status) {
	OSSpinLockLock(&spinLock);
	
	((void(^)())handle->data)();
	Block_release(handle->data);
	
	OSSpinLockUnlock(&spinLock);
}

static void PerformHooks() {
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		MSHookFunction(NULL, "_dispatch_sync", MSHake(dispatch_sync));
		MSHookFunction(NULL, "_dispatch_async", MSHake(dispatch_async));
		%init();
	});
}
/* }}} */

static BOOL bridgeInitd = NO;
static Persistent<Function> ModuleCtor;
Handle<Value> InitializeBundle(const Arguments &args) {
	HandleScope scope;
	
	if (args.IsConstructCall()) {
		@autoreleasepool {
			if (!bridgeInitd) {
				if (args.Length() < 1) identifier = @"com.apple.Finder";
				else {
					Local<Value> bundleId = args[0];
					if (bundleId->IsString()) {
						char *identifier_ = *(String::AsciiValue(bundleId->ToString()));
						if (identifier_ == NULL || *identifier_ == '\0')
							identifier = @"com.apple.Finder";
						else {
							identifier_ = strdup(identifier_);
							identifier = [[NSString alloc] initWithUTF8String:identifier_];
							free(identifier_);
							identifierHasAlloc = YES;
						}
					}
				}

				Notification::InitBridge();
				bridgeInitd = YES;
			}

			else fprintf(stderr, "[osx-notifications] Warning: Re-initializing the Notifications object will not change the bundle identifier for the notifications posted. For that, restart the node process.\n");
		}
		
		Notification::AddToExportsInstance(args.This());
		return scope.Close(args.This());
	}

	const int argc = 1;
	Local<Value> argv[argc] = { args[0] };
	return scope.Close(ModuleCtor->NewInstance(argc, argv));
}

Handle<Value> GetThread(const Arguments &args) {
	HandleScope scope;
	return scope.Close(String::New(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)));
}

void ModuleInit(Handle<Object> exports, Handle<Object> module) {
	watcher = new uv_async_t; // we never close you.
	uv_async_init(uv_default_loop(), watcher, dispatchCallback);
	PerformHooks();
	
	HandleScope scope;
	Notification::Init();
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(InitializeBundle);
	tpl->SetClassName(String::NewSymbol("nodenotifications"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);

	ModuleCtor = Persistent<Function>::New(tpl->GetFunction());
	ModuleCtor->Set(String::NewSymbol("getthread"), FunctionTemplate::New(GetThread)->GetFunction());
	ModuleCtor->Set(String::NewSymbol("NotificationCtor"), Notification::constructor);
	module->Set(String::NewSymbol("exports"), ModuleCtor);
}

NODE_MODULE(nodenotifications, ModuleInit);
