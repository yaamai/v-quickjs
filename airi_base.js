// ENV(object), CMDLINE(array): passed by airi
ENV = ENV
CMDLINE = CMDLINE

// alias command base
let BASE = {}
function _get_base() {
    return BASE
}

// command name to definition map
let CMDS = {}

// alias conversion defaults
let DEFS = {}
DEFS.ary = {pre: _get_base, suffix: []}
DEFS.obj = {b: _get_base, p: [], s: [], a: CMDLINE}

// remove undefined and flatten arrays
function flatten(input) {
    let stack = input.slice()
    let result = []

    while (stack.length) {
        let next = stack.pop()

        if (next === undefined) {
            continue
        }

        if (next instanceof Function) {
            next = next()
        }

        if (Array.isArray(next)) {
            stack = stack.concat(next)

            continue
        }

        result.push(next)
    }

    return result.reverse()
}

function get_cmdname() {
    let command_name = CMDLINE[0]
    if (command_name.startsWith('./')) {
        command_name = command_name.slice(2);
    }

    if (command_name.includes('/')) {
        let pos = command_name.lastIndexOf('/')
        command_name = command_name.slice(pos+1)
    }
    // if call alias with full-path,
    // CMDLINE[0] need relative in container
    CMDLINE[0] = command_name

    return command_name
}

function _get_cmdline_array(cmdname) {
    return flatten([DEFS.ary.pre, CMDS[cmdname], DEFS.ary.suffix, CMDLINE])
}

function _get_cmdline_obj(cmdname) {
    obj = CMDS[cmdname]

    base = obj.b
    if (base === undefined) {
        base = DEFS.obj.b
    }
    prefix = obj.p
    if (prefix === undefined) {
        prefix = DEFS.obj.p
    }
    suffix = obj.s
    if (suffix === undefined) {
        suffix = DEFS.obj.s
    }
    args = obj.a
    if (args === undefined) {
        args = DEFS.obj.a
    }
    image = obj.i

    return flatten([base, prefix, image, suffix, args])
}

function _get_cmdline() {
    let cmdname = get_cmdname()
    if (CMDS[cmdname] === undefined) {
        return undefined
    }

    if (CMDS[cmdname].constructor === Object) {
        return _get_cmdline_obj(cmdname)
    } else {
        return _get_cmdline_array(cmdname)
    }
}

let get_cmdline = _get_cmdline

// called from C program to get command list
function get_cmd_list() {
    return Object.keys(CMDS)
}

function load_configs() {
  let cwd = getcwd() + '/'
  let suffix = 'airi.js'
  let home_suffix = '.config'
  let result = []

  for (var i = 0; i < 4; i++) {
    let pos = cwd.lastIndexOf('/')
    if (pos == -1) break
    let parent_cwd = cwd.slice(0, pos)
    result.push(parent_cwd+'/'+suffix)
    cwd = parent_cwd
  }

  if (ENV.AIRI_CONF) {
    result.push(ENV.AIRI_CONF)
  }

  if (ENV.HOME) {
  	result.push(ENV.HOME+'/'+home_suffix+'/'+suffix)
  }
  result.reverse()

  let configs = result.filter(function(e) { return is_readable_file(e) })
  configs.map(function(e) {
    log_debug('Evaluating ' + e)
    eval_file(e)
  })
}
load_configs()

log_debug('Config loaded');
true
