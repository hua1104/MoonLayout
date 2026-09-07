///|
/// A graph node with integer coordinates for deterministic, portable layouts.
pub(all) struct Node {
  id : String
  x : Int
  y : Int
}

///|
/// An edge stores indexes into `Graph.nodes`.
pub(all) struct Edge {
  source : Int
  target : Int
}

///|
pub(all) struct Graph {
  nodes : Array[Node]
  edges : Array[Edge]
}

///|
pub(all) struct LayoutConfig {
  width : Int
  height : Int
  iterations : Int
  link_distance : Int
  repulsion : Int
  gravity : Int
  damping : Int
}

///|
pub fn default_layout_config() -> LayoutConfig {
  {
    width: 900,
    height: 600,
    iterations: 180,
    link_distance: 130,
    repulsion: 3600,
    gravity: 3,
    damping: 78,
  }
}

///|
/// Returns a bounded configuration suitable for every supported target.
/// Keeping this normalization in the library protects callers that do not use
/// the CLI and prevents accidental runaway simulations.
pub fn normalize_layout_config(config : LayoutConfig) -> LayoutConfig {
  {
    width: clamp(config.width, 100, 4096),
    height: clamp(config.height, 100, 4096),
    iterations: clamp(config.iterations, 0, 5000),
    link_distance: if config.link_distance < 1 {
      1
    } else {
      config.link_distance
    },
    repulsion: if config.repulsion < 0 {
      0
    } else {
      config.repulsion
    },
    gravity: if config.gravity < 0 {
      0
    } else {
      config.gravity
    },
    damping: clamp(config.damping, 0, 100),
  }
}

///|
/// Builds a graph and places nodes on a stable grid before simulation.
pub fn make_graph(ids : Array[String], edges : Array[Edge]) -> Graph {
  let nodes : Array[Node] = []
  for index, id in ids {
    // A repeating 3x3 lattice avoids the common all-nodes-on-one-line case
    // while remaining deterministic and independent of a random source.
    let column = index % 3
    let row = index * 2 % 3
    nodes.push({ id, x: 150 + column * 300, y: 120 + row * 180 })
  }
  { nodes, edges }
}

///|
/// Runs a deterministic integer force simulation. No random seed or wall
/// clock is involved, so the same graph always produces the same coordinates.
pub fn layout(graph : Graph, config : LayoutConfig) -> Graph {
  let config = normalize_layout_config(config)
  let nodes : Array[Node] = []
  for node in graph.nodes {
    nodes.push(node)
  }
  let mut step = 0
  let total = if config.iterations < 0 { 0 } else { config.iterations }
  while step < total {
    let dx : Array[Int] = []
    let dy : Array[Int] = []
    for _ in nodes {
      dx.push(0)
      dy.push(0)
    }
    apply_repulsion(nodes, dx, dy, config.repulsion)
    apply_links(nodes, graph.edges, dx, dy, config.link_distance)
    apply_gravity(nodes, dx, dy, config, config.width, config.height)
    for index, node in nodes {
      let next_x = node.x + dx[index] * config.damping / 100
      let next_y = node.y + dy[index] * config.damping / 100
      nodes[index] = {
        ..node,
        x: clamp(next_x, 24, config.width - 24),
        y: clamp(next_y, 24, config.height - 24),
      }
    }
    step = step + 1
  }
  { nodes, edges: graph.edges }
}

///|
fn apply_repulsion(
  nodes : Array[Node],
  dx : Array[Int],
  dy : Array[Int],
  strength : Int,
) -> Unit {
  let mut left = 0
  while left < nodes.length() {
    let mut right = left + 1
    while right < nodes.length() {
      let x_delta = nodes[left].x - nodes[right].x
      let y_delta = nodes[left].y - nodes[right].y
      let distance = abs_int(x_delta) + abs_int(y_delta) + 1
      let force = strength / (distance * distance / 80 + 1)
      let x_push = signed_unit(x_delta) * force
      let y_push = signed_unit(y_delta) * force
      dx[left] = dx[left] + x_push
      dy[left] = dy[left] + y_push
      dx[right] = dx[right] - x_push
      dy[right] = dy[right] - y_push
      right = right + 1
    }
    left = left + 1
  }
}

///|
fn apply_links(
  nodes : Array[Node],
  edges : Array[Edge],
  dx : Array[Int],
  dy : Array[Int],
  desired : Int,
) -> Unit {
  for edge in edges {
    if edge.source < 0 ||
      edge.target < 0 ||
      edge.source >= nodes.length() ||
      edge.target >= nodes.length() {
      continue
    }
    let x_delta = nodes[edge.target].x - nodes[edge.source].x
    let y_delta = nodes[edge.target].y - nodes[edge.source].y
    let distance = abs_int(x_delta) + abs_int(y_delta) + 1
    let stretch = distance - desired
    let x_pull = signed_unit(x_delta) * stretch / 8
    let y_pull = signed_unit(y_delta) * stretch / 8
    dx[edge.source] = dx[edge.source] + x_pull
    dy[edge.source] = dy[edge.source] + y_pull
    dx[edge.target] = dx[edge.target] - x_pull
    dy[edge.target] = dy[edge.target] - y_pull
  }
}

///|
fn apply_gravity(
  nodes : Array[Node],
  dx : Array[Int],
  dy : Array[Int],
  config : LayoutConfig,
  width : Int,
  height : Int,
) -> Unit {
  let center_x = width / 2
  let center_y = height / 2
  for index, node in nodes {
    dx[index] = dx[index] + (center_x - node.x) * config.gravity / 100
    dy[index] = dy[index] + (center_y - node.y) * config.gravity / 100
  }
}

///|
fn signed_unit(value : Int) -> Int {
  if value < 0 {
    -1
  } else if value > 0 {
    1
  } else {
    0
  }
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
fn clamp(value : Int, low : Int, high : Int) -> Int {
  if high < low {
    low
  } else if value < low {
    low
  } else if value > high {
    high
  } else {
    value
  }
}

///|
/// Parses `A-B,B-C` into a graph, adding isolated names when needed.
pub fn parse_edge_list(input : String) -> Graph {
  let ids : Array[String] = []
  let edges : Array[Edge] = []
  for raw in input.split(",") {
    let token = raw.trim().to_owned()
    match token.find("-") {
      Some(at) => {
        let left = token[:at].trim().to_owned()
        let right = token[at + 1:].trim().to_owned()
        if left != "" && right != "" {
          let source = ensure_id(ids, left)
          let target = ensure_id(ids, right)
          edges.push({ source, target })
        }
      }
      None => if token != "" { ensure_id(ids, token) |> ignore }
    }
  }
  make_graph(ids, edges)
}

///|
fn ensure_id(ids : Array[String], id : String) -> Int {
  for index, value in ids {
    if value == id {
      return index
    }
  }
  ids.push(id)
  ids.length() - 1
}
