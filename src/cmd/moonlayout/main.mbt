///|
/// MoonLayout CLI: generate a deterministic SVG graph demo.
struct Options {
  edges : String
  out : String
  width : Int
  height : Int
  iterations : Int
  errors : Array[String]
}

///|
fn main {
  let options = parse_args(Array::from_fixed_array(cli_args()))
  if options.errors.length() > 0 {
    for error in options.errors {
      print_error(error)
    }
    print_help()
    exit_with(2)
  }
  if options.width < 100 || options.height < 100 {
    print_error("canvas dimensions must be at least 100 pixels")
    exit_with(2)
  }
  if options.iterations > 5000 {
    print_error("iterations must be at most 5000")
    exit_with(2)
  }
  let config = @core.normalize_layout_config({
    ..@core.default_layout_config(),
    width: options.width,
    height: options.height,
    iterations: options.iterations,
  })
  let graph = @core.layout(@core.parse_edge_list(options.edges), config)
  let svg = @core.render_svg(graph, config)
  write_text_file(options.out, svg)
  println("moonlayout 0.1.0")
  println(
    "laid out " +
    graph.nodes.length().to_string() +
    " nodes and " +
    graph.edges.length().to_string() +
    " edges",
  )
  println("wrote " + options.out)
}

///|
fn parse_args(args : Array[String]) -> Options {
  let errors : Array[String] = []
  let mut edges = "Moon-AI,AI-Data,Data-Web,Web-Moon,Data-Moon"
  let mut out = "moonlayout.svg"
  let mut width = 900
  let mut height = 600
  let mut iterations = 180
  let mut index = 0
  while index < args.length() {
    let arg = args[index]
    if arg == "--help" || arg == "-h" {
      print_help()
      exit_with(0)
    } else if arg == "--edges" {
      match next_value(args, index) {
        Some(value) => {
          edges = value
          index = index + 2
        }
        None => {
          errors.push("missing value for --edges")
          index = index + 1
        }
      }
    } else if arg == "--out" {
      match next_value(args, index) {
        Some(value) => {
          out = value
          index = index + 2
        }
        None => {
          errors.push("missing value for --out")
          index = index + 1
        }
      }
    } else if arg == "--width" {
      match next_int(args, index) {
        Some(value) => {
          width = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --width")
          index = index + 2
        }
      }
    } else if arg == "--height" {
      match next_int(args, index) {
        Some(value) => {
          height = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --height")
          index = index + 2
        }
      }
    } else if arg == "--iterations" {
      match next_int(args, index) {
        Some(value) => {
          iterations = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --iterations")
          index = index + 2
        }
      }
    } else {
      errors.push("unknown option: " + arg)
      index = index + 1
    }
  }
  { edges, out, width, height, iterations, errors }
}

///|
fn next_value(args : Array[String], index : Int) -> String? {
  if index + 1 < args.length() {
    Some(args[index + 1])
  } else {
    None
  }
}

///|
fn next_int(args : Array[String], index : Int) -> Int? {
  match next_value(args, index) {
    Some(value) => parse_int(value)
    None => None
  }
}

///|
fn parse_int(value : String) -> Int? {
  if value == "" {
    return None
  }
  let mut result = 0
  for ch in value {
    if ch >= '0' && ch <= '9' {
      result = result * 10 + ch.to_int() - '0'.to_int()
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn print_help() -> Unit {
  println("moonlayout 0.1.0")
  println("Deterministic graph auto-layout engine with SVG output.")
  println("Usage: moon run src/cmd/moonlayout -- [options]")
  println("  --edges A-B,B-C     edge list (default: built-in demo)")
  println("  --out <file>        SVG output path (default: moonlayout.svg)")
  println("  --width <pixels>    canvas width (default: 900)")
  println("  --height <pixels>   canvas height (default: 600)")
  println("  --iterations <n>    simulation steps (default: 180)")
}

///|
extern "js" fn cli_args() -> FixedArray[String] =
  #| function() { return process.argv.slice(2); }

///|
extern "js" fn write_text_file(path : String, content : String) -> Unit =
  #| function(path, content) {
  #|   const fs = require("fs");
  #|   const nodePath = require("path");
  #|   const target = nodePath.resolve(process.cwd(), path);
  #|   fs.mkdirSync(nodePath.dirname(target), { recursive: true });
  #|   fs.writeFileSync(target, content, "utf8");
  #| }

///|
extern "js" fn print_error(message : String) -> Unit =
  #| function(message) { process.stderr.write("moonlayout: " + message + "\n"); }

///|
extern "js" fn exit_with(code : Int) -> Unit =
  #| function(code) { process.exit(code); }
