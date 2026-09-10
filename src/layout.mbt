///|
/// A positioned node from a layout snapshot.
pub(all) struct PositionedNode {
  id : String
  x : Int
  y : Int
  width : Int
  height : Int
}

///|
/// A directed edge between two node identifiers.
pub(all) struct Edge {
  source : String
  target : String
}

///|
/// A layout snapshot produced by any graph layout engine.
pub(all) struct LayoutSnapshot {
  width : Int
  height : Int
  nodes : Array[PositionedNode]
  edges : Array[Edge]
}

///|
/// Thresholds used by the deterministic audit.
pub(all) struct AuditConfig {
  max_overlaps : Int
  max_crossings : Int
  max_out_of_bounds : Int
  min_edge_length : Int
  max_edge_length : Int
}

///|
pub fn default_audit_config() -> AuditConfig {
  {
    max_overlaps: 0,
    max_crossings: 0,
    max_out_of_bounds: 0,
    min_edge_length: 0,
    max_edge_length: 0,
  }
}

///|
/// A single machine-readable quality finding.
pub(all) struct Violation {
  kind : String
  first : String
  second : String
  detail : String
}

///|
/// The complete result of auditing a snapshot.
pub(all) struct AuditReport {
  nodes : Int
  edges : Int
  overlap_pairs : Int
  duplicate_positions : Int
  out_of_bounds : Int
  edge_crossings : Int
  invalid_edge_endpoints : Int
  min_edge_length : Int
  max_edge_length : Int
  average_edge_length : Int
  passed : Bool
  fingerprint : String
  violations : Array[Violation]
}

///|
pub fn make_snapshot(
  width : Int,
  height : Int,
  nodes : Array[PositionedNode],
  edges : Array[Edge],
) -> LayoutSnapshot {
  { width, height, nodes, edges }
}

///|
/// Audits a snapshot without changing it. All computations are integer based
/// so a report is reproducible on every supported MoonBit target.
pub fn audit_snapshot(
  snapshot : LayoutSnapshot,
  config : AuditConfig,
) -> AuditReport {
  let mut overlap_pairs = 0
  let mut duplicate_positions = 0
  let mut out_of_bounds = 0
  let mut edge_crossings = 0
  let mut invalid_edge_endpoints = 0
  let mut min_edge_length = 0
  let mut max_edge_length = 0
  let mut total_edge_length = 0
  let mut measured_edges = 0
  let violations : Array[Violation] = []

  for index, node in snapshot.nodes {
    if node_left(node) < 0 ||
      node_top(node) < 0 ||
      node_right(node) > snapshot.width ||
      node_bottom(node) > snapshot.height {
      out_of_bounds = out_of_bounds + 1
      violations.push({
        kind: "out_of_bounds",
        first: node.id,
        second: "",
        detail: "node rectangle is outside the canvas",
      })
    }
    let mut other = index + 1
    while other < snapshot.nodes.length() {
      let other_node = snapshot.nodes[other]
      if node.x == other_node.x && node.y == other_node.y {
        duplicate_positions = duplicate_positions + 1
        violations.push({
          kind: "duplicate_position",
          first: node.id,
          second: other_node.id,
          detail: "nodes have identical center coordinates",
        })
      }
      if rectangles_overlap(node, other_node) {
        overlap_pairs = overlap_pairs + 1
        violations.push({
          kind: "node_overlap",
          first: node.id,
          second: other_node.id,
          detail: "node rectangles overlap",
        })
      }
      other = other + 1
    }
  }

  for index, edge in snapshot.edges {
    match edge_points(snapshot, edge) {
      Some((source, target)) =>
        if source.id != target.id {
          let length = manhattan_distance(source, target)
          if measured_edges == 0 || length < min_edge_length {
            min_edge_length = length
          }
          if length > max_edge_length {
            max_edge_length = length
          }
          total_edge_length = total_edge_length + length
          measured_edges = measured_edges + 1
        }
      None => {
        invalid_edge_endpoints = invalid_edge_endpoints + 1
        violations.push({
          kind: "unknown_edge_endpoint",
          first: edge.source,
          second: edge.target,
          detail: "edge endpoint is not present in the snapshot",
        })
      }
    }
    let mut other = index + 1
    while other < snapshot.edges.length() {
      let other_edge = snapshot.edges[other]
      if edges_can_cross(edge, other_edge) {
        match (edge_points(snapshot, edge), edge_points(snapshot, other_edge)) {
          (Some((a, b)), Some((c, d))) =>
            if segments_cross(a, b, c, d) {
              edge_crossings = edge_crossings + 1
              violations.push({
                kind: "edge_crossing",
                first: edge_key(edge),
                second: edge_key(other_edge),
                detail: "edge segments cross away from shared endpoints",
              })
            }
          _ => ()
        }
      }
      other = other + 1
    }
  }

  if config.min_edge_length > 0 &&
    measured_edges > 0 &&
    min_edge_length < config.min_edge_length {
    violations.push({
      kind: "edge_too_short",
      first: "",
      second: "",
      detail: "at least one edge is shorter than the configured minimum",
    })
  }
  if config.max_edge_length > 0 && max_edge_length > config.max_edge_length {
    violations.push({
      kind: "edge_too_long",
      first: "",
      second: "",
      detail: "at least one edge is longer than the configured maximum",
    })
  }

  let average_edge_length = if measured_edges == 0 {
    0
  } else {
    total_edge_length / measured_edges
  }
  let passed = overlap_pairs <= config.max_overlaps &&
    edge_crossings <= config.max_crossings &&
    out_of_bounds <= config.max_out_of_bounds &&
    invalid_edge_endpoints == 0 &&
    (
      config.min_edge_length == 0 ||
      measured_edges == 0 ||
      min_edge_length >= config.min_edge_length
    ) &&
    (config.max_edge_length == 0 || max_edge_length <= config.max_edge_length)
  {
    nodes: snapshot.nodes.length(),
    edges: snapshot.edges.length(),
    overlap_pairs,
    duplicate_positions,
    out_of_bounds,
    edge_crossings,
    invalid_edge_endpoints,
    min_edge_length,
    max_edge_length,
    average_edge_length,
    passed,
    fingerprint: snapshot_fingerprint(snapshot),
    violations,
  }
}

///|
/// Parses the line-oriented `.snapshot` format used by the CLI.
pub fn parse_snapshot(input : String) -> Result[LayoutSnapshot, String] {
  let mut width : Int? = None
  let mut height : Int? = None
  let mut canvas_seen = false
  let nodes : Array[PositionedNode] = []
  let edges : Array[Edge] = []
  let edge_lines : Array[Int] = []
  for line_number, raw in input.split("\n") {
    let line = raw.trim().to_owned()
    if line == "" || line.has_prefix("#") {
      continue
    }
    let words = split_words(line)
    if words.length() == 0 {
      continue
    }
    match words[0] {
      "canvas" => {
        if canvas_seen {
          return Err(line_error(line_number + 1, "duplicate canvas record"))
        }
        if words.length() != 3 {
          return Err(
            line_error(line_number + 1, "canvas expects width and height"),
          )
        }
        match (parse_signed_int(words[1]), parse_signed_int(words[2])) {
          (Some(w), Some(h)) => {
            if w <= 0 || h <= 0 {
              return Err(
                line_error(
                  line_number + 1,
                  "canvas dimensions must be positive",
                ),
              )
            }
            width = Some(w)
            height = Some(h)
            canvas_seen = true
          }
          _ =>
            return Err(
              line_error(line_number + 1, "canvas dimensions must be integers"),
            )
        }
      }
      "node" => {
        if words.length() != 6 {
          return Err(
            line_error(line_number + 1, "node expects id x y width height"),
          )
        }
        if find_node(nodes, words[1]) is Some(_) {
          return Err(
            line_error(line_number + 1, "duplicate node id: " + words[1]),
          )
        }
        match
          (
            parse_signed_int(words[2]),
            parse_signed_int(words[3]),
            parse_signed_int(words[4]),
            parse_signed_int(words[5]),
          ) {
          (Some(x), Some(y), Some(node_width), Some(node_height)) => {
            if node_width <= 0 || node_height <= 0 {
              return Err(
                line_error(line_number + 1, "node dimensions must be positive"),
              )
            }
            nodes.push({
              id: words[1],
              x,
              y,
              width: node_width,
              height: node_height,
            })
          }
          _ =>
            return Err(
              line_error(
                line_number + 1,
                "node coordinates and dimensions must be integers",
              ),
            )
        }
      }
      "edge" => {
        if words.length() != 3 {
          return Err(
            line_error(line_number + 1, "edge expects source and target"),
          )
        }
        edges.push({ source: words[1], target: words[2] })
        edge_lines.push(line_number + 1)
      }
      _ =>
        return Err(line_error(line_number + 1, "unknown record: " + words[0]))
    }
  }
  match (width, height) {
    (Some(w), Some(h)) => {
      for index, edge in edges {
        if find_node(nodes, edge.source) is None {
          return Err(
            line_error(
              edge_lines[index],
              "edge references unknown node: " + edge.source,
            ),
          )
        }
        if find_node(nodes, edge.target) is None {
          return Err(
            line_error(
              edge_lines[index],
              "edge references unknown node: " + edge.target,
            ),
          )
        }
      }
      Ok({ width: w, height: h, nodes, edges })
    }
    _ => Err("snapshot must define one canvas record")
  }
}

///|
pub fn report_to_text(report : AuditReport) -> String {
  let mut output = "moonlayout-audit\n"
  output = output + "nodes: " + report.nodes.to_string() + "\n"
  output = output + "edges: " + report.edges.to_string() + "\n"
  output = output + "overlaps: " + report.overlap_pairs.to_string() + "\n"
  output = output +
    "duplicate_positions: " +
    report.duplicate_positions.to_string() +
    "\n"
  output = output + "out_of_bounds: " + report.out_of_bounds.to_string() + "\n"
  output = output +
    "edge_crossings: " +
    report.edge_crossings.to_string() +
    "\n"
  output = output +
    "invalid_edge_endpoints: " +
    report.invalid_edge_endpoints.to_string() +
    "\n"
  output = output +
    "edge_length_min: " +
    report.min_edge_length.to_string() +
    "\n"
  output = output +
    "edge_length_max: " +
    report.max_edge_length.to_string() +
    "\n"
  output = output +
    "edge_length_average: " +
    report.average_edge_length.to_string() +
    "\n"
  output = output + "fingerprint: " + report.fingerprint + "\n"
  output + "status: " + (if report.passed { "PASS" } else { "FAIL" }) + "\n"
}

///|
pub fn report_to_json(report : AuditReport) -> String {
  let mut output = "{\n"
  output = output + "  \"nodes\": " + report.nodes.to_string() + ",\n"
  output = output + "  \"edges\": " + report.edges.to_string() + ",\n"
  output = output +
    "  \"overlap_pairs\": " +
    report.overlap_pairs.to_string() +
    ",\n"
  output = output +
    "  \"duplicate_positions\": " +
    report.duplicate_positions.to_string() +
    ",\n"
  output = output +
    "  \"out_of_bounds\": " +
    report.out_of_bounds.to_string() +
    ",\n"
  output = output +
    "  \"edge_crossings\": " +
    report.edge_crossings.to_string() +
    ",\n"
  output = output +
    "  \"invalid_edge_endpoints\": " +
    report.invalid_edge_endpoints.to_string() +
    ",\n"
  output = output +
    "  \"min_edge_length\": " +
    report.min_edge_length.to_string() +
    ",\n"
  output = output +
    "  \"max_edge_length\": " +
    report.max_edge_length.to_string() +
    ",\n"
  output = output +
    "  \"average_edge_length\": " +
    report.average_edge_length.to_string() +
    ",\n"
  output = output +
    "  \"passed\": " +
    (if report.passed { "true" } else { "false" }) +
    ",\n"
  output = output +
    "  \"fingerprint\": \"" +
    escape_json(report.fingerprint) +
    "\",\n"
  output = output + "  \"violations\": ["
  for index, violation in report.violations {
    if index > 0 {
      output = output + ","
    }
    output = output +
      "\n    {\"kind\":\"" +
      escape_json(violation.kind) +
      "\",\"first\":\"" +
      escape_json(violation.first) +
      "\",\"second\":\"" +
      escape_json(violation.second) +
      "\",\"detail\":\"" +
      escape_json(violation.detail) +
      "\"}"
  }
  output + "\n  ]\n}\n"
}

///|
fn edge_points(
  snapshot : LayoutSnapshot,
  edge : Edge,
) -> (PositionedNode, PositionedNode)? {
  match
    (
      find_node(snapshot.nodes, edge.source),
      find_node(snapshot.nodes, edge.target),
    ) {
    (Some(source), Some(target)) => Some((source, target))
    _ => None
  }
}

///|
fn edges_can_cross(left : Edge, right : Edge) -> Bool {
  left.source != right.source &&
  left.source != right.target &&
  left.target != right.source &&
  left.target != right.target
}

///|
fn segments_cross(
  a : PositionedNode,
  b : PositionedNode,
  c : PositionedNode,
  d : PositionedNode,
) -> Bool {
  let ab_c = orientation(a, b, c)
  let ab_d = orientation(a, b, d)
  let cd_a = orientation(c, d, a)
  let cd_b = orientation(c, d, b)
  let strict_cross = ((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
    ((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0))
  strict_cross ||
  (ab_c == 0 && on_segment(a, b, c)) ||
  (ab_d == 0 && on_segment(a, b, d)) ||
  (cd_a == 0 && on_segment(c, d, a)) ||
  (cd_b == 0 && on_segment(c, d, b))
}

///|
fn orientation(
  a : PositionedNode,
  b : PositionedNode,
  c : PositionedNode,
) -> Int {
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
}

///|
fn on_segment(
  a : PositionedNode,
  b : PositionedNode,
  point : PositionedNode,
) -> Bool {
  point.x >= min_int(a.x, b.x) &&
  point.x <= max_int(a.x, b.x) &&
  point.y >= min_int(a.y, b.y) &&
  point.y <= max_int(a.y, b.y)
}

///|
fn min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn rectangles_overlap(a : PositionedNode, b : PositionedNode) -> Bool {
  node_left(a) < node_right(b) &&
  node_right(a) > node_left(b) &&
  node_top(a) < node_bottom(b) &&
  node_bottom(a) > node_top(b)
}

///|
fn node_left(node : PositionedNode) -> Int {
  node.x - node.width / 2
}

///|
fn node_right(node : PositionedNode) -> Int {
  node.x + node.width / 2
}

///|
fn node_top(node : PositionedNode) -> Int {
  node.y - node.height / 2
}

///|
fn node_bottom(node : PositionedNode) -> Int {
  node.y + node.height / 2
}

///|
fn manhattan_distance(a : PositionedNode, b : PositionedNode) -> Int {
  abs_int(a.x - b.x) + abs_int(a.y - b.y)
}

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn find_node(nodes : Array[PositionedNode], id : String) -> PositionedNode? {
  for node in nodes {
    if node.id == id {
      return Some(node)
    }
  }
  None
}

///|
fn edge_key(edge : Edge) -> String {
  edge.source + "->" + edge.target
}

///|
fn split_words(line : String) -> Array[String] {
  let words : Array[String] = []
  for raw in line.split(" ") {
    let word = raw.trim().to_owned()
    if word != "" {
      words.push(word)
    }
  }
  words
}

///|
fn parse_signed_int(value : String) -> Int? {
  if value == "" {
    return None
  }
  let mut start = 0
  let mut sign = 1
  if value[0] == '-' {
    sign = -1
    start = 1
  } else if value[0] == '+' {
    start = 1
  }
  if start >= value.length() {
    return None
  }
  let mut result = 0
  for index, ch in value {
    if index >= start {
      if ch >= '0' && ch <= '9' {
        result = result * 10 + ch.to_int() - '0'.to_int()
      } else {
        return None
      }
    }
  }
  Some(result * sign)
}

///|
fn line_error(line : Int, message : String) -> String {
  "line " + line.to_string() + ": " + message
}

///|
fn snapshot_fingerprint(snapshot : LayoutSnapshot) -> String {
  let mut canonical = snapshot.width.to_string() +
    "x" +
    snapshot.height.to_string()
  for node in snapshot.nodes {
    canonical = canonical +
      "|n:" +
      node.id +
      ":" +
      node.x.to_string() +
      ":" +
      node.y.to_string() +
      ":" +
      node.width.to_string() +
      ":" +
      node.height.to_string()
  }
  for edge in snapshot.edges {
    canonical = canonical + "|e:" + edge.source + "->" + edge.target
  }
  let mut hash = 216613626
  for ch in canonical {
    hash = (hash ^ ch.to_int()) * 16777619
  }
  hash.to_string()
}

///|
fn escape_json(input : String) -> String {
  input
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new="\\n")
  .replace_all(old="\r", new="\\r")
}
