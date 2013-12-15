#ifndef _NOTIFICATIONS_H
#define _NOTIFICATIONS_H

#import <Foundation/Foundation.h>

#include <node.h>
#include <v8.h>
using namespace v8;
using namespace node;

class Notification : public ObjectWrap {
	public:
		static void Init(Handle<Object> exports);
	
	private:
		explicit Notification(char *a, char *b, char *c);
		~Notification();

		static Handle<Value> New(const Arguments &args);
		static Handle<Value> Show(const Arguments &args);
		static Handle<Value> Remove(const Arguments &args);
		static Handle<Value> HasDelivered(const Arguments &args);
		static Handle<Value> On(const Arguments &args);
		
		static Persistent<Function> constructor;

		char *title;
		char *subtitle;
		char *info;
		bool delivered;
};

#endif
