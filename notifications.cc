#include "notifications.h"

Persistent<Function> Notification::constructor;

Notification::Notification(Persistent<Object> options_) :
	options(options_)
{}

Notification::~Notification() {
	//constructor.Dispose();
	options.Dispose();
}

void Notification::Init(Handle<Object> exports) {
	HandleScope scope;
	
	Local<FunctionTemplate> tpl = FunctionTemplate::New(New);
	tpl->SetClassName(String::NewSymbol("Notification"));
	tpl->InstanceTemplate()->SetInternalFieldCount(1);
	
	tpl->PrototypeTemplate()->Set(String::NewSymbol("show"), FunctionTemplate::New(Show)->GetFunction());
	tpl->PrototypeTemplate()->Set(String::NewSymbol("remove"), FunctionTemplate::New(Remove)->GetFunction());
	tpl->PrototypeTemplate()->Set(String::NewSymbol("hasDelivered"), FunctionTemplate::New(HasDelivered)->GetFunction());
	tpl->PrototypeTemplate()->Set(String::NewSymbol("on"), FunctionTemplate::New(On)->GetFunction());

	constructor = Persistent<Function>::New(tpl->GetFunction());
	exports->Set(String::NewSymbol("Notification"), constructor);

	scope.Close(Undefined());
}

Handle<Value> Notification::New(const Arguments &arguments) {
	HandleScope scope;

	if (args.IsConstructCall()) {
		Notification *notification = new Notification(args[0]);
		notification->Wrap(args.This());

		return args.This();
	}

	const int argc = 1;
	Local<Value> argv[argc] = { args[0] };
	return scope.Close(constructor->NewInstance(argc, argv));
}

Handle<Value> Notification::NewInstance(const Arguments &args) {
	HandleScope scope;

	const unsigned argc = 1;
	Handle<Value> argv[argc] = { args[0] };
	Local<Object> instance = constructor->NewInstance(argc, argv);

	return scope.Close(instance);
}

Handle<Value> Notification::Show(const Arguments &args) {
	
}

Handle<Value> Notification::Remove(const Arguments &args) {
	
}

Handle<Value> Notification::HasDelivered(const Arguments &args) {
	
}

Handle<Value> Notification::On(const Arguments &args) {
	
}
