///|
test "edge list is deterministic and includes isolated nodes" {
  let graph = parse_edge_list("A-B,B-C,solo")
  inspect(graph.nodes.length(), content="4")
  inspect(graph.edges.length(), content="2")
  let config = { ..default_layout_config(), iterations: 30 }
  let first = layout(graph, config)
  let second = layout(graph, config)
  inspect(first.nodes[0].x == second.nodes[0].x, content="true")
  inspect(first.nodes[0].y == second.nodes[0].y, content="true")
}

///|
test "svg contains escaped nodes and edges" {
  let graph = layout(parse_edge_list("A-&-B"), {
    ..default_layout_config(),
    iterations: 1,
  })
  let svg = render_svg(graph, default_layout_config())
  inspect(svg.find("<line") is Some(_), content="true")
  inspect(svg.find("A") is Some(_), content="true")
}

///|
test "layout keeps nodes inside the configured canvas" {
  let config = {
    ..default_layout_config(),
    width: 320,
    height: 240,
    iterations: 60,
  }
  let result = layout(parse_edge_list("A-B,B-C,C-D,D-A"), config)
  let mut valid = true
  for node in result.nodes {
    if node.x < 24 ||
      node.x > config.width - 24 ||
      node.y < 24 ||
      node.y > config.height - 24 {
      valid = false
    }
  }
  inspect(valid, content="true")
}

///|
test "invalid edge indexes are ignored by the simulation" {
  let graph = make_graph(["A", "B"], [{ source: 0, target: 9 }])
  let result = layout(graph, { ..default_layout_config(), iterations: 2 })
  inspect(result.nodes.length(), content="2")
  inspect(
    render_svg(result, default_layout_config()).find("<line") is Some(_),
    content="false",
  )
}

///|
test "configuration normalization bounds unsafe values" {
  let config = normalize_layout_config({
    width: 20,
    height: 0,
    iterations: 9000,
    link_distance: -4,
    repulsion: -1,
    gravity: -2,
    damping: 140,
  })
  inspect(config.width, content="100")
  inspect(config.height, content="100")
  inspect(config.iterations, content="5000")
  inspect(config.link_distance, content="1")
  inspect(config.repulsion, content="0")
  inspect(config.gravity, content="0")
  inspect(config.damping, content="100")
}

///|
test "parser trims whitespace and deduplicates node names" {
  let graph = parse_edge_list(" A - B, B-C, A-B ")
  inspect(graph.nodes.length(), content="3")
  inspect(graph.edges.length(), content="3")
  inspect(graph.nodes[0].id, content="A")
  inspect(graph.nodes[1].id, content="B")
}

///|
test "empty graph renders a valid SVG" {
  let graph = layout(parse_edge_list(""), default_layout_config())
  let svg = render_svg(graph, default_layout_config())
  inspect(graph.nodes.length(), content="0")
  inspect(svg.find("<svg") is Some(_), content="true")
  inspect(svg.find("<line") is Some(_), content="false")
}
