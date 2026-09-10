///|
/// Renders a snapshot and highlights every audit finding in a self-contained SVG.
pub fn render_audit_svg(
  snapshot : LayoutSnapshot,
  report : AuditReport,
) -> String {
  let mut output = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
    snapshot.width.to_string() +
    " " +
    snapshot.height.to_string() +
    "\" role=\"img\">\n"
  output = output + "<title>MoonLayout Audit report</title>\n"
  output = output + "<desc>" + escape_xml(report_summary(report)) + "</desc>\n"
  output = output +
    "<defs><marker id=\"arrow-ok\" markerWidth=\"8\" markerHeight=\"8\" refX=\"7\" refY=\"4\" orient=\"auto\"><path d=\"M0,0 L8,4 L0,8 z\" fill=\"#58c4dd\"/></marker><marker id=\"arrow-error\" markerWidth=\"8\" markerHeight=\"8\" refX=\"7\" refY=\"4\" orient=\"auto\"><path d=\"M0,0 L8,4 L0,8 z\" fill=\"#ff6b6b\"/></marker></defs>\n"
  output = output + "<rect width=\"100%\" height=\"100%\" fill=\"#101820\"/>\n"
  for edge in snapshot.edges {
    match edge_points_for_svg(snapshot, edge) {
      Some((source, target)) => {
        let problem = edge_has_violation(report, edge_key_for_svg(edge))
        let color = if problem { "#ff6b6b" } else { "#58c4dd" }
        let marker = if problem { "arrow-error" } else { "arrow-ok" }
        output = output +
          "<line x1=\"" +
          source.x.to_string() +
          "\" y1=\"" +
          source.y.to_string() +
          "\" x2=\"" +
          target.x.to_string() +
          "\" y2=\"" +
          target.y.to_string() +
          "\" stroke=\"" +
          color +
          "\" stroke-width=\"2\" opacity=\".82\" marker-end=\"url(#" +
          marker +
          ")\"/>\n"
      }
      None => ()
    }
  }
  for node in snapshot.nodes {
    let x = node_left_for_svg(node)
    let y = node_top_for_svg(node)
    let color = if node_has_violation(report, node.id) {
      "#ff6b6b"
    } else {
      "#f3a847"
    }
    output = output +
      "<g><rect x=\"" +
      x.to_string() +
      "\" y=\"" +
      y.to_string() +
      "\" width=\"" +
      node.width.to_string() +
      "\" height=\"" +
      node.height.to_string() +
      "\" rx=\"8\" fill=\"" +
      color +
      "\" stroke=\"#fff3d6\" stroke-width=\"2\"/>" +
      "<text x=\"" +
      node.x.to_string() +
      "\" y=\"" +
      (node.y + 5).to_string() +
      "\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\" fill=\"#101820\">" +
      escape_xml(node.id) +
      "</text></g>\n"
  }
  output = output +
    "<text x=\"16\" y=\"" +
    (snapshot.height - 16).to_string() +
    "\" font-family=\"monospace\" font-size=\"13\" fill=\"#fff3d6\">" +
    escape_xml(report_summary(report)) +
    "</text>\n"
  output + "</svg>\n"
}

///|
fn report_summary(report : AuditReport) -> String {
  "status=" +
  (if report.passed { "PASS" } else { "FAIL" }) +
  " overlaps=" +
  report.overlap_pairs.to_string() +
  " crossings=" +
  report.edge_crossings.to_string() +
  " out_of_bounds=" +
  report.out_of_bounds.to_string()
}

///|
fn edge_points_for_svg(
  snapshot : LayoutSnapshot,
  edge : Edge,
) -> (PositionedNode, PositionedNode)? {
  match
    (
      find_node_for_svg(snapshot.nodes, edge.source),
      find_node_for_svg(snapshot.nodes, edge.target),
    ) {
    (Some(source), Some(target)) => Some((source, target))
    _ => None
  }
}

///|
fn find_node_for_svg(
  nodes : Array[PositionedNode],
  id : String,
) -> PositionedNode? {
  for node in nodes {
    if node.id == id {
      return Some(node)
    }
  }
  None
}

///|
fn edge_key_for_svg(edge : Edge) -> String {
  edge.source + "->" + edge.target
}

///|
fn edge_has_violation(report : AuditReport, key : String) -> Bool {
  for violation in report.violations {
    if violation.kind == "edge_crossing" &&
      (violation.first == key || violation.second == key) {
      return true
    }
  }
  false
}

///|
fn node_has_violation(report : AuditReport, id : String) -> Bool {
  for violation in report.violations {
    if violation.first == id || violation.second == id {
      return true
    }
  }
  false
}

///|
fn node_left_for_svg(node : PositionedNode) -> Int {
  node.x - node.width / 2
}

///|
fn node_top_for_svg(node : PositionedNode) -> Int {
  node.y - node.height / 2
}

///|
fn escape_xml(input : String) -> String {
  input
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
}
