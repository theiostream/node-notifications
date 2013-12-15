#include "notifications.h"

Persistent<Function> Notification::constructor;

Notification::Notification(char *title_, char *subtitle_, char *info_) :
	title(title_ != NULL ? strdup(title_) : NULL),
	subtitle(subtitle_ != NULL ? strdup(subtitle_) : NULL),
	info(info_ != NULL ? strdup(info_) : NULL)
{}

Notification::~Notification() {
	//constructor.Dispose();

	if (title != NULL) free(title);
	if (subtitle != NULL) free(subtitle);
	if (info != NULL) free(info);
}

void Notification::Init(Handle<Object> exports) {
	HandleScope scope;
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(New);
	tpl->SetClassName(String::NewSymbol("Notification"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);
	
	NODE_SET_PROTOTYPE_METHOD(tpl, "show", Show);
	NODE_SET_PROTOTYPE_METHOD(tpl, "remove", Remove);
	NODE_SET_PROTOTYPE_METHOD(tpl, "hasDelivered", HasDelivered);
	
	constructor = Persistent<Function>::New(tpl->GetFunction());
	exports->Set(String::NewSymbol("Notification"), constructor);
}

Handle<Value> Notification::New(const Arguments &args) {
	HandleScope scope;

	if (args.IsConstructCall()) {
		char *title=(char*)"", *subtitle=(char*)"", *info=(char*)"";
		
		if (!args[0]->IsObject()) {
			ThrowException(Exception::TypeError(String::New("Should pass object to constructor.")));
			return scope.Close(Undefined());
		}
		Local<Object> obj = args[0]->ToObject();

		Local<Value> title_ = obj->Get(String::New("title"));
		if (title_->IsString()) title = strdup(*(String::AsciiValue(title_->ToString())));
		Local<Value> subtitle_ = obj->Get(String::New("subtitle"));
		if (subtitle_->IsString()) subtitle = strdup(*(String::AsciiValue(subtitle_->ToString())));
		Local<Value> info_ = obj->Get(String::New("info"));
		if (info_->IsString()) info = strdup(*(String::AsciiValue(info_->ToString())));
		
		fprintf(stderr, "stderr teststrings %s %s %s\n", title, subtitle, info);

		Notification *notification = new Notification(title, subtitle, info);
		notification->Wrap(args.This());

		if (strlen(title) > 0) free(title);
		if (strlen(subtitle) > 0) free(subtitle);
		if (strlen(info) > 0) free(info);

		return args.This();
	}

	const int argc = 1;
	Local<Value> argv[argc] = { args[0] };
	return scope.Close(constructor->NewInstance(argc, argv));
}

Handle<Value> Notification::Show(const Arguments &args) {
	HandleScope scope;
	
	Notification *notification = ObjectWrap::Unwrap<Notification>(args.This());
	NSUserNotification *userNotification = [[NSUserNotification alloc] init];
	[userNotification setTitle:[NSString stringWithUTF8String:notification->title]];
	[userNotification setSubtitle:[NSString stringWithUTF8String:notification->subtitle]];
	[userNotification setInformativeText:[NSString stringWithUTF8String:notification->info]];

	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
	fprintf(stderr, "what is default? %p\n", [NSUserNotificationCenter defaultUserNotificationCenter]);

	return Undefined();
}

Handle<Value> Notification::Remove(const Arguments &args) {
	return Undefined();
}

Handle<Value> Notification::HasDelivered(const Arguments &args) {
	return Undefined();
}
