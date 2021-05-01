module main

import os
import quickjs

fn js_eval_file(mut ctx quickjs.Context, this quickjs.Value, args []quickjs.Value) ?quickjs.Value {
	return ctx.eval(os.read_file(args[0].as_string())?.str())
}

fn js_getcwd(mut ctx quickjs.Context, this quickjs.Value, args []quickjs.Value) ?quickjs.Value {
	return ctx.new_string(os.getwd())
}

fn js_is_readable(mut ctx quickjs.Context, this quickjs.Value, args []quickjs.Value) ?quickjs.Value {
	return ctx.new_bool(os.is_readable(args[0].as_string()))
}

fn js_log_debug(mut ctx quickjs.Context, this quickjs.Value, args []quickjs.Value) ?quickjs.Value {
	println(args[0].as_string())
	return quickjs.undefined
}

fn main() {
	mut ctx := quickjs.new_runtime().new_context()
	ctx.get_global().set_property('eval_file', ctx.new_function(js_eval_file, 'eval_file', 1))
	ctx.get_global().set_property('getcwd', ctx.new_function(js_getcwd, 'getcwd', 0))
	ctx.get_global().set_property('is_readable_file', ctx.new_function(js_is_readable, 'is_readable_file', 1))
	ctx.get_global().set_property('log_debug', ctx.new_function(js_log_debug, 'log_debug', 1))
	ctx.get_global().set_property('ENV', ctx.new_object_from_map(os.environ()))
	ctx.get_global().set_property('CMDLINE', ctx.new_array_from_array(["gcc"]))
	println(ctx.eval("eval_file('airi_base.js')")?)
	println(ctx.eval("get_cmd_list()")?.as_array())
	println(ctx.eval("get_cmdline()")?.as_array())
}
