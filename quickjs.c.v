module quickjs

#flag -I quickjs
#flag -D EMSCRIPTEN
#flag -D CONFIG_VERSION='"'2021-03-27'"'
#flag @VROOT/quickjs/libbf.o
#flag @VROOT/quickjs/cutils.o
#flag @VROOT/quickjs/libunicode.o
#flag @VROOT/quickjs/libregexp.o
#flag @VROOT/quickjs/quickjs.o
#include "quickjs.h"

struct C.JSValue {}

struct C.JSRuntime {}

struct C.JSContext {}

fn C.JS_NewRuntime() voidptr
fn C.JS_FreeRuntime(voidptr)

fn C.JS_NewContext(voidptr) voidptr
fn C.JS_FreeContext(voidptr)
fn C.JS_SetContextOpaque(voidptr, voidptr)
fn C.JS_GetContextOpaque(voidptr) voidptr
fn C.JS_Eval(voidptr, &char, size_t, &char, int) C.JSValue

fn C.JS_GetGlobalObject(voidptr) C.JSValue
fn C.JS_NewObject(voidptr) C.JSValue
fn C.JS_FreeValue(voidptr, C.JSValue)
fn C.JS_SetPropertyStr(voidptr, C.JSValue, &char, C.JSValue)
fn C.JS_GetPropertyStr(voidptr, C.JSValue, &char) C.JSValue

fn C.JS_ToInt32(voidptr, &int, C.JSValue)
fn C.JS_ToCString(voidptr, C.JSValue) &char
fn C.JS_ToInt64(voidptr, &i64, C.JSValue) int

fn C.JS_Throw(voidptr, C.JSValue) C.JSValue
fn C.JS_IsException(voidptr) int
fn C.JS_GetException(voidptr) C.JSValue

fn C.JS_NewInt64(voidptr, i64) C.JSValue
fn C.JS_NewString(voidptr, &char) C.JSValue

type JSCFunctionMagic = fn (voidptr, C.JSValue, int, &C.JSValue, int) C.JSValue

fn C.JS_NewCFunctionMagic(voidptr, JSCFunctionMagic, &char, int, int, int) C.JSValue

pub struct Runtime {
	rt &C.JSRuntime
}

pub fn new_runtime() &Runtime {
	return &Runtime{
		rt: C.JS_NewRuntime()
	}
}

pub fn (mut r Runtime) new_context() &Context {
	ctx := &Context{
		ctx: C.JS_NewContext(r.rt)
	}
	C.JS_SetContextOpaque(ctx.ctx, ctx)
	return ctx
}

type Function = fn (&Context, Value, []Value) ?Value

pub struct Context {
	ctx &C.JSContext
mut:
	funcs []Function
}

pub struct Value {
	ctx &C.JSContext
	val C.JSValue
}

pub fn (mut c Context) eval(script string) ?Value {
	val := Value{
		ctx: c.ctx
		val: C.JS_Eval(c.ctx, script.str, script.len, '', C.JS_EVAL_FLAG_STRICT)
	}
	if val.is_exception() {
		return error(c.get_exception().as_string())
	}
	return val
}

pub fn (mut c Context) get_exception() Value {
	return Value{
		ctx: c.ctx
		val: C.JS_GetException(c.ctx)
	}
}

pub fn (mut c Context) get_global() Value {
	return Value{
		ctx: c.ctx
		val: C.JS_GetGlobalObject(c.ctx)
	}
}

pub fn (mut c Context) new_object() Value {
	return Value{
		ctx: c.ctx
		val: C.JS_NewObject(c.ctx)
	}
}

pub fn (mut c Context) new_string(s string) Value {
	return Value{
		ctx: c.ctx
		val: C.JS_NewString(c.ctx, s.str)
	}
}

fn function_wrapper(jsctx voidptr, this C.JSValue, argc int, arg &C.JSValue, magic int) C.JSValue {
	ctx_ptr := C.JS_GetContextOpaque(jsctx)
	mut ctx := &Context(ctx_ptr)

	mut values := []Value{len: argc}
	argp := arg
	for idx := 0; idx < argc; idx++ {
		values[idx] = Value{
			ctx: jsctx
			val: argp
		}
		unsafe { argp++ }
	}

	func := ctx.funcs[magic]
	func(ctx, Value{ ctx: ctx.ctx, val: this }, values) or {
		return C.JS_Throw(ctx.ctx, ctx.new_string(err.str()).val)
	}
	return C.JSValue{}
}

pub fn (mut c Context) new_function(func Function, name string, arg_num int) Value {
	c.funcs << func
	js_func := C.JS_NewCFunctionMagic(c.ctx, function_wrapper, name.str, arg_num, C.JS_CFUNC_generic_magic,
		c.funcs.len - 1)
	return Value{
		ctx: c.ctx
		val: js_func
	}
}

pub fn (v Value) is_exception() bool {
	return C.JS_IsException(v.val) != 0
}

pub fn (v Value) as_string() string {
	return unsafe { cstring_to_vstring(C.JS_ToCString(v.ctx, v.val)) }
}

pub fn (v Value) str() string {
	return v.as_string()
}

pub fn (v Value) as_int() int {
	out := 0
	C.JS_ToInt32(v.ctx, &out, v.val)
	return out
}

pub fn (v Value) set_property(key string, value Value) {
	C.JS_SetPropertyStr(v.ctx, v.val, key.str, value.val)
}
