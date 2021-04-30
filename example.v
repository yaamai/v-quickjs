module main
import quickjs

fn wrapfn(ctx &quickjs.Context, this quickjs.Value, args []quickjs.Value) quickjs.Value {
    println("wrap ${args}")
    return quickjs.Value{ctx: 0}
}

fn main() {
        mut rt := quickjs.new_runtime()
        mut ctx := rt.new_context()
        obj := ctx.new_object()
        func := ctx.new_function(wrapfn, "log", 2)
        ctx.get_global().set_property("console", obj)
        obj.set_property("log", func)

        println(ctx.eval("1+2")?.as_int())
        println(ctx.eval("console.log('aaaaaa', 1, 2)")?.as_int())
}

