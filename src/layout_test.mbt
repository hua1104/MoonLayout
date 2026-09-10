///|
test "snapshot parser accepts comments and rejects malformed records" {
  let input =
    #|# pipeline
    #|canvas 900 600
    #|node A 100 100 40 40
    #|node B 300 100 40 40
    #|edge A B
  match parse_snapshot(input) {
    Ok(snapshot) => {
      inspect(snapshot.nodes.length(), content="2")
      inspect(snapshot.edges.length(), content="1")
    }
    Err(_) => inspect(false, content="true")
  }
  match parse_snapshot("canvas 100 100\nnode A 1 1 10 10\nedge A Missing") {
    Ok(_) => inspect(false, content="true")
    Err(message) =>
      inspect(message.find("unknown node") is Some(_), content="true")
  }
}

///|
test "audit detects overlap and duplicate positions" {
  let snapshot = make_snapshot(
    400,
    300,
    [
      { id: "A", x: 100, y: 100, width: 80, height: 80 },
      { id: "B", x: 100, y: 100, width: 80, height: 80 },
    ],
    [],
  )
  let report = audit_snapshot(snapshot, default_audit_config())
  inspect(report.passed, content="false")
  inspect(report.overlap_pairs, content="1")
  inspect(report.duplicate_positions, content="1")
}

///|
test "audit detects bounds and crossing edges" {
  let snapshot = make_snapshot(
    400,
    300,
    [
      { id: "A", x: 50, y: 50, width: 20, height: 20 },
      { id: "B", x: 350, y: 250, width: 20, height: 20 },
      { id: "C", x: 350, y: 50, width: 20, height: 20 },
      { id: "D", x: 50, y: 250, width: 20, height: 20 },
      { id: "Outside", x: 0, y: 0, width: 40, height: 40 },
    ],
    [{ source: "A", target: "B" }, { source: "C", target: "D" }],
  )
  let report = audit_snapshot(snapshot, default_audit_config())
  inspect(report.passed, content="false")
  inspect(report.edge_crossings, content="1")
  inspect(report.out_of_bounds, content="1")
}

///|
test "audit rejects unknown edge endpoints in programmatic snapshots" {
  let snapshot = make_snapshot(
    300,
    200,
    [{ id: "A", x: 80, y: 100, width: 20, height: 20 }],
    [{ source: "A", target: "Missing" }],
  )
  let report = audit_snapshot(snapshot, default_audit_config())
  inspect(report.passed, content="false")
  inspect(report.invalid_edge_endpoints, content="1")
}

///|
test "report and fingerprint are deterministic" {
  let input =
    #|canvas 500 300
    #|node A 100 150 40 40
    #|node B 300 150 40 40
    #|edge A B
  let first = match parse_snapshot(input) {
    Ok(snapshot) =>
      report_to_json(audit_snapshot(snapshot, default_audit_config()))
    Err(_) => ""
  }
  let second = match parse_snapshot(input) {
    Ok(snapshot) =>
      report_to_json(audit_snapshot(snapshot, default_audit_config()))
    Err(_) => ""
  }
  inspect(first == second, content="true")
  inspect(first.find("\"passed\": true") is Some(_), content="true")
}

///|
test "audit SVG contains arrows and accessible summary" {
  let snapshot = make_snapshot(
    400,
    300,
    [
      { id: "A", x: 100, y: 150, width: 40, height: 40 },
      { id: "B", x: 300, y: 150, width: 40, height: 40 },
    ],
    [{ source: "A", target: "B" }],
  )
  let report = audit_snapshot(snapshot, default_audit_config())
  let svg = render_audit_svg(snapshot, report)
  inspect(svg.find("marker-end") is Some(_), content="true")
  inspect(svg.find("<title>") is Some(_), content="true")
  inspect(svg.find("status=PASS") is Some(_), content="true")
}
