#ifndef _NOTIFICATIONS_H
#define _NOTIFICATIONS_H

#include <node.h>
#include <v8.h>
using namespace v8;

class Notification : public node::ObjectWrap {
	public:
		static void Init(Handle<Object> exports);
	
	private:
		explicit Notification(Handle<Object> options);
		~Notification();

		static Handle<Value> New(const Arguments &args);
		static Handle<Value> Show(const Arguments &args);
		static Handle<Value> Remove(const Arguments &args);
		static Handle<Value> HasDelivered(const Arguments &args);
		static Handle<Value> On(const Arguments &args);
		
		static Persistent<Function> constructor;
		Persistent<Object> options;
}

#endif
