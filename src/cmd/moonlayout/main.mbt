///|
/// MoonLayout Audit CLI: verify graph layout snapshots in CI or documentation builds.
struct Options {
  input : String
  report : String
  svg : String
  max_overlaps : Int
  max_crossings : Int
  max_out_of_bounds : Int
  min_edge_length : Int
  max_edge_length : Int
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
  if options.input != "" && !file_exists(options.input) {
    print_error("input file does not exist: " + options.input)
    exit_with(2)
  }
  let source = if options.input == "" {
    default_snapshot()
  } else {
    read_text_file(options.input)
  }
  match @core.parse_snapshot(source) {
    Err(message) => {
      print_error(message)
      exit_with(2)
    }
    Ok(snapshot) => {
      let report = @core.audit_snapshot(snapshot, {
        max_overlaps: options.max_overlaps,
        max_crossings: options.max_crossings,
        max_out_of_bounds: options.max_out_of_bounds,
        min_edge_length: options.min_edge_length,
        max_edge_length: options.max_edge_length,
      })
      write_text_file(options.report, @core.report_to_json(report))
      write_text_file(options.svg, @core.render_audit_svg(snapshot, report))
      println(@core.report_to_text(report))
      println("wrote " + options.report)
      println("wrote " + options.svg)
      if report.passed {
        exit_with(0)
      } else {
        exit_with(1)
      }
    }
  }
}

///|
fn parse_args(args : Array[String]) -> Options {
  let errors : Array[String] = []
  let mut input = ""
  let mut report = "audit-report.json"
  let mut svg = "audit.svg"
  let mut max_overlaps = 0
  let mut max_crossings = 0
  let mut max_out_of_bounds = 0
  let mut min_edge_length = 0
  let mut max_edge_length = 0
  let mut index = 0
  while index < args.length() {
    let arg = args[index]
    if arg == "--help" || arg == "-h" {
      print_help()
      exit_with(0)
    } else if arg == "--version" {
      println("moonlayout-audit 0.2.0")
      exit_with(0)
    } else if arg == "--input" {
      match next_value(args, index) {
        Some(value) => {
          input = value
          index = index + 2
        }
        None => {
          errors.push("missing value for --input")
          index = index + 1
        }
      }
    } else if arg == "--report" {
      match next_value(args, index) {
        Some(value) => {
          report = value
          index = index + 2
        }
        None => {
          errors.push("missing value for --report")
          index = index + 1
        }
      }
    } else if arg == "--svg" {
      match next_value(args, index) {
        Some(value) => {
          svg = value
          index = index + 2
        }
        None => {
          errors.push("missing value for --svg")
          index = index + 1
        }
      }
    } else if arg == "--max-overlaps" {
      match next_nonnegative_int(args, index) {
        Some(value) => {
          max_overlaps = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --max-overlaps")
          index = index + 2
        }
      }
    } else if arg == "--max-crossings" {
      match next_nonnegative_int(args, index) {
        Some(value) => {
          max_crossings = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --max-crossings")
          index = index + 2
        }
      }
    } else if arg == "--max-out-of-bounds" {
      match next_nonnegative_int(args, index) {
        Some(value) => {
          max_out_of_bounds = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --max-out-of-bounds")
          index = index + 2
        }
      }
    } else if arg == "--min-edge-length" {
      match next_nonnegative_int(args, index) {
        Some(value) => {
          min_edge_length = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --min-edge-length")
          index = index + 2
        }
      }
    } else if arg == "--max-edge-length" {
      match next_nonnegative_int(args, index) {
        Some(value) => {
          max_edge_length = value
          index = index + 2
        }
        None => {
          errors.push("invalid value for --max-edge-length")
          index = index + 2
        }
      }
    } else {
      errors.push("unknown option: " + arg)
      index = index + 1
    }
  }
  {
    input,
    report,
    svg,
    max_overlaps,
    max_crossings,
    max_out_of_bounds,
    min_edge_length,
    max_edge_length,
    errors,
  }
}

///|
fn next_value(args : Array[String], index : Int) -> String? {
  if index + 1 < args.length() {
    let value = args[index + 1]
    if value.has_prefix("--") || value == "-h" {
      None
    } else {
      Some(value)
    }
  } else {
    None
  }
}

///|
fn next_nonnegative_int(args : Array[String], index : Int) -> Int? {
  match next_value(args, index) {
    Some(value) => parse_nonnegative_int(value)
    None => None
  }
}

///|
fn parse_nonnegative_int(value : String) -> Int? {
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
  println("moonlayout-audit 0.2.0")
  println(
    "Verify deterministic graph layout snapshots for CI and documentation.",
  )
  println("Usage: moon run src/cmd/moonlayout -- [options]")
  println("  --version                 print the CLI version")
  println(
    "  --input <file>            .snapshot input (default: built-in demo)",
  )
  println(
    "  --report <file>           JSON report (default: audit-report.json)",
  )
  println("  --svg <file>              annotated SVG (default: audit.svg)")
  println("  --max-overlaps <n>        allowed overlapping pairs (default: 0)")
  println("  --max-crossings <n>       allowed edge crossings (default: 0)")
  println(
    "  --max-out-of-bounds <n>   allowed out-of-bounds nodes (default: 0)",
  )
  println(
    "  --min-edge-length <n>     minimum Manhattan edge length (default: 0)",
  )
  println(
    "  --max-edge-length <n>     maximum Manhattan edge length (default: unlimited)",
  )
}

///|
fn default_snapshot() -> String {
  (
    #|canvas 900 600
    #|node Client 120 260 44 44
    #|node API 360 260 44 44
    #|node DB 600 180 44 44
    #|node Queue 600 340 44 44
    #|edge Client API
    #|edge API DB
    #|edge API Queue
  )
}

///|
extern "js" fn cli_args() -> FixedArray[String] =
  #| function() { return process.argv.slice(2); }

///|
extern "js" fn read_text_file(path : String) -> String =
  #| function(path) {
  #|   const fs = require("fs");
  #|   try { return fs.readFileSync(path, "utf8"); }
  #|   catch (_) { return ""; }
  #| }

///|
extern "js" fn file_exists(path : String) -> Bool =
  #| function(path) {
  #|   const fs = require("fs");
  #|   try { return fs.statSync(path).isFile(); }
  #|   catch (_) { return false; }
  #| }

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
  #| function(message) { process.stderr.write("moonlayout-audit: " + message + "\n"); }

///|
extern "js" fn exit_with(code : Int) -> Unit =
  #| function(code) { process.exit(code); }
