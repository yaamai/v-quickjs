module main

import os
import quickjs

fn js_eval_file(mut ctx quickjs.Context, this quickjs.Value, args []quickjs.Value) ?quickjs.Value {
	return ctx.eval(os.read_file(args[0].as_string())?.str())
}

fn wrapfn(ctx &quickjs.Context, this quickjs.Value, args []quickjs.Value) ?quickjs.Value {
	println('wrap $args')
	return quickjs.Value{
		ctx: 0
	}
}

fn main() {
	mut ctx := quickjs.new_runtime().new_context()
	ctx.get_global().set_property('eval_file', ctx.new_function(js_eval_file, 'eval_file', 1))
	println(ctx.eval("eval_file('test.js')") ?)
}
