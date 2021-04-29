module main

#flag -I quickjs
#flag -D EMSCRIPTEN
#flag -D CONFIG_VERSION="2021-03-27"
#flag @VROOT/quickjs/libbf.o
#flag @VROOT/quickjs/cutils.o
#flag @VROOT/quickjs/libunicode.o
#flag @VROOT/quickjs/libregexp.o
#flag @VROOT/quickjs/quickjs.o
#include "quickjs.h"
fn C.JS_NewRuntime() voidptr
fn C.JS_FreeRuntime(voidptr)
fn C.JS_NewContext(voidptr) voidptr
fn C.JS_FreeContext(voidptr)
fn C.JS_Eval(voidptr, charptr, size_t, charptr, int) C.JSValue
fn C.JS_ToInt32(voidptr, &int, C.JSValue)

fn C.JS_GetGlobalObject(voidptr) C.JSValue
fn C.JS_NewObject(voidptr) C.JSValue
fn C.JS_SetPropertyStr(voidptr, C.JSValue, charptr, C.JSValue)

type QuickJsFn = fn (voidptr, C.JSValue, int, &C.JSValue) C.JSValue
fn C.JS_NewCFunction(voidptr, QuickJsFn, charptr, int) C.JSValue
fn C.JS_NewObject(voidptr) C.JSValue
fn C.JS_FreeValue(voidptr, C.JSValue)

fn C.JS_IsException(voidptr) int
fn C.JS_GetException(voidptr) C.JSValue
fn C.JS_ToCString(voidptr, C.JSValue) &char

struct C.JSValue {}
struct C.JSRuntime {}
struct C.JSContext {}


struct Runtime {
        rt &C.JSRuntime
}

fn new_runtime() Runtime {
        return Runtime {rt: C.JS_NewRuntime()}
}

fn (mut r Runtime) new_context() Context {
        return Context {ctx: C.JS_NewContext(r.rt)}
}

struct Context {
        ctx &C.JSContext
}

struct Value {
        ctx &C.JSContext
        val C.JSValue
}

fn (mut c Context) eval(script string) ?Value {
        val := Value{ctx: c.ctx, val: C.JS_Eval(c.ctx, script.str, script.len, "", C.JS_EVAL_FLAG_STRICT)}
        if val.is_exception() {
                return error(c.get_exception().as_string())
        }
        return val
}

fn (mut c Context) get_exception() Value {
        return Value{ctx: c.ctx, val: C.JS_GetException(c.ctx)}
}

fn (mut c Context) get_global() Value {
        return Value{ctx: c.ctx, val: C.JS_GetGlobalObject(c.ctx)}
}

fn (mut c Context) new_object() Value {
        return Value{ctx: c.ctx, val: C.JS_NewObject(c.ctx)}
}

fn (mut c Context) new_function(func QuickJsFn, name string, arg_num int) Value {
        return Value{ctx: c.ctx, val: C.JS_NewCFunction(c.ctx, func, name.str, arg_num)}
}

fn (v Value) is_exception() bool {
        return C.JS_IsException(v.val) != 0
}

fn (v Value) as_string() string {
        return unsafe{cstring_to_vstring(C.JS_ToCString(v.ctx, v.val))}
}

fn (v Value) as_int() int {
        out := 0
        C.JS_ToInt32(v.ctx, &out, v.val)
        return out
}

fn (v Value) set_property(key string, value Value) {
        C.JS_SetPropertyStr(v.ctx, v.val, key.str, value.val)
}


fn test(ctx voidptr, this C.JSValue, argc int, arg &C.JSValue) C.JSValue {
        arg_str := unsafe{
                cstring_to_vstring(C.JS_ToCString(ctx, arg++))
        }
        println(arg_str)

        arg_str2 := unsafe{
                cstring_to_vstring(C.JS_ToCString(ctx, arg++))
        }
        println(arg_str2)
        return C.JSValue{}
}

fn test_eval() {
        rt := C.JS_NewRuntime()
        ctx := C.JS_NewContext(rt)
        val := C.JS_Eval(ctx, "1+2", 3, "...", C.JS_EVAL_FLAG_STRICT)
        out := 0
        C.JS_ToInt32(ctx, &out, val)
        println(out)
}

fn test_c_callback() {
        rt := C.JS_NewRuntime()
        ctx := C.JS_NewContext(rt)

        global := C.JS_GetGlobalObject(ctx)
        console := C.JS_NewObject(ctx)
        C.JS_SetPropertyStr(ctx, global, "console", console)
        C.JS_SetPropertyStr(ctx, console, "log", C.JS_NewCFunction(ctx, test, "log", 2))
        C.JS_FreeValue(ctx, global)

        script := 'console.log("aaa", "bbb")'
        ret := C.JS_Eval(ctx, script.str, script.len, "...", C.JS_EVAL_FLAG_STRICT)
        if C.JS_IsException(ret) != 0 {
                exc := C.JS_GetException(ctx)
                exc_str := unsafe{cstring_to_vstring(C.JS_ToCString(ctx, exc))}
                println(exc_str)
        }

        out := 0
        C.JS_ToInt32(ctx, &out, ret)
        println(out)
}

fn main() {
        mut rt := new_runtime()
        mut ctx := rt.new_context()

        println(ctx.eval("1+2")?.as_int())
}

