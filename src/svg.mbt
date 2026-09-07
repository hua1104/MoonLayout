///|
/// Renders a layout as a self-contained SVG suitable for demos or embedding.
pub fn render_svg(graph : Graph, config : LayoutConfig) -> String {
  let mut output = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
    config.width.to_string() +
    " " +
    config.height.to_string() +
    "\" role=\"img\">\n"
  output = output + "<rect width=\"100%\" height=\"100%\" fill=\"#101820\"/>\n"
  for edge in graph.edges {
    if edge.source >= 0 &&
      edge.target >= 0 &&
      edge.source < graph.nodes.length() &&
      edge.target < graph.nodes.length() {
      let source = graph.nodes[edge.source]
      let target = graph.nodes[edge.target]
      output = output +
        "<line x1=\"" +
        source.x.to_string() +
        "\" y1=\"" +
        source.y.to_string() +
        "\" x2=\"" +
        target.x.to_string() +
        "\" y2=\"" +
        target.y.to_string() +
        "\" stroke=\"#58c4dd\" stroke-width=\"2\" opacity=\".72\"/>\n"
    }
  }
  for node in graph.nodes {
    output = output +
      "<g><circle cx=\"" +
      node.x.to_string() +
      "\" cy=\"" +
      node.y.to_string() +
      "\" r=\"22\" fill=\"#f3a847\" stroke=\"#fff3d6\" stroke-width=\"3\"/>" +
      "<text x=\"" +
      node.x.to_string() +
      "\" y=\"" +
      (node.y + 5).to_string() +
      "\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"14\" fill=\"#101820\">" +
      escape_xml(node.id) +
      "</text></g>\n"
  }
  output + "</svg>\n"
}

///|
fn escape_xml(input : String) -> String {
  input
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
}
