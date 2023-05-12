#[macro_use]
extern crate guard;

use std::{
    collections::{HashMap, HashSet},
    fs,
};

use resvg::{
    tiny_skia,
    usvg::{self, NodeExt, TreeParsing},
};

use svg::{self, node::element::tag::Type};

static WIDTH: u32 = 720;
static HEIGHT: u32 = WIDTH;

fn parse_title(title: &str) -> Option<u8> {
    let mut sections = title.split(".");

    guard!(let Ok(segment) = sections.next()?.parse::<u8>() else {
        println!("Could not parse segment from title {title}");
        return None;
    });

    if segment > 2 {
        println!("Segment {segment} in {title} was out of bounds");
        return None;
    }

    guard!(let Ok(column) = sections.next()?.parse::<u8>() else {
        println!("Could not parse column from title {title}");
        return None;
    });

    if column > 15 {
        println!("Column {column} in {title} was out of bounds");
        return None;
    }

    guard!(let Ok(row_h) = sections.next()?.parse::<u8>() else {
        println!("Could not parse row_h from title {title}");
        return None;
    });

    if row_h > 4 {
        println!("Row {row_h} in {title} was out of bounds");
        return None;
    }

    assert_eq!(sections.next(), None, "Title contained too many groups");

    return Some((segment << 6) | (column << 2) | row_h);
}

// Returns false if a node should be detached. Otherwise, sets the color to the title byte
fn keep_and_mutate_usvg_node(node: &usvg::Node, svg_id_to_title: &HashMap<String, u8>) -> bool {
    match &mut *node.borrow_mut() {
        usvg::NodeKind::Path(ref mut path) => {
            // Check if we care about this path
            if path.id.is_empty() {
                println!("No id");
                return false;
            }

            guard!(let Some(title) = svg_id_to_title.get(&path.id) else {
                println!("No title");
                return false;
            });

            let paint = usvg::Paint::Color(usvg::Color {
                red: *title,
                green: *title,
                blue: *title,
            });

            // Encode the title byte into the color
            if let Some(fill) = &mut path.fill {
                fill.paint = paint.clone();
            }

            if let Some(stroke) = &mut path.stroke {
                stroke.paint = paint;
            }
        }
        _ => {}
    }

    return true;
}

fn main() {
    let svg_path = "assets/gnw_dkong2_top.svg";

    let mut content = String::new();

    let mut svg_id_to_title: HashMap<String, u8> = HashMap::new();
    let mut path_to_title: HashMap<String, u8> = HashMap::new();

    #[derive(PartialEq, Debug)]
    struct ActiveGroup {
        id: Option<String>,
        title: Option<u8>,
        paths: HashSet<String>,
    }

    #[derive(PartialEq, Debug)]
    struct ActivePath {
        id: Option<String>,
        title: Option<u8>,
    }

    let mut group_stack: Vec<ActiveGroup> = vec![];
    // let mut active_group: Option<ActiveGroup> = None;
    let mut active_path: Option<ActivePath> = None;
    let mut inside_title = false;

    for event in svg::open(svg_path, &mut content).unwrap() {
        // These match values are in order they should be encountered, not logical order
        match event {
            svg::parser::Event::Tag("g", Type::Start, attributes) => {
                group_stack.push(ActiveGroup {
                    id: attributes.get("id").map(|v| v.clone().into()),
                    title: None,
                    paths: HashSet::new(),
                });
            }
            svg::parser::Event::Tag("path", Type::Start, attributes) => {
                assert_eq!(active_path, None, "SVG contains invalid nested paths");

                let id: Option<String> = attributes.get("id").map(|v| v.clone().into());

                active_path = Some(ActivePath { id, title: None });
            }
            svg::parser::Event::Tag("title", Type::Start, _) => {
                assert_eq!(inside_title, false, "SVG contains invalid nested titles");

                inside_title = true;
            }
            svg::parser::Event::Text(value) => {
                if !inside_title {
                    // Random text, ignore
                    continue;
                }

                if let Some(ActivePath { ref mut title, .. }) = active_path {
                    *title = parse_title(value);
                } else if let Some(ActiveGroup { title, id, .. }) = group_stack.last_mut() {
                    // Set group title
                    *title = parse_title(value);
                }
            }
            svg::parser::Event::Tag("title", Type::End, _) => {
                assert_eq!(inside_title, true, "SVG contains an invalid end title tag");

                inside_title = false;
            }
            svg::parser::Event::Tag("path", tag_type, attributes) => {
                if tag_type == Type::Empty {
                    let path = ActivePath {
                        id: attributes.get("id").map(|v| v.clone().into()),
                        title: None,
                    };

                    active_path = Some(path);
                }

                guard!(let Some(path) = &active_path else {
                    panic!("SVG contains an invalid unterminated path");
                });

                guard!(let Some(id) = &path.id else {
                    // If this path didn't have an id, we don't care about it
                    continue;
                });

                if let Some(ActiveGroup { paths, .. }) = group_stack.last_mut() {
                    // Mark this path as being a part of the group
                    paths.insert(id.clone());
                }

                if let Some(title) = path.title {
                    // This path is complete, add it to map
                    svg_id_to_title.insert(id.clone(), title);
                }

                active_path = None;
            }
            svg::parser::Event::Tag("g", Type::End, _) => {
                guard!(let Some(group) = group_stack.last() else {
                    panic!("SVG contains an invalid end group tag");
                });

                if let Some(title) = group.title {
                    // Group set a title
                    for p in &group.paths {
                        if !svg_id_to_title.contains_key(p) {
                            // Path title overrides group title, so make sure to skip if already set
                            svg_id_to_title.insert(p.clone(), title);
                        }
                    }
                }

                group_stack.pop();
                // println!("Popped group")
            }
            _ => {}
        }
    }

    // println!("{svg_id_to_title:?}");

    let svg_data = fs::read(svg_path).unwrap();

    let mut tree = usvg::Tree::from_data(&svg_data, &usvg::Options::default()).unwrap();

    let viewbox = tree.view_box;

    for node in tree.root.descendants() {
        if !keep_and_mutate_usvg_node(&node, &svg_id_to_title) {
            // Drop node
            // TODO: Handle this
            println!("Would have dropped node {}", node.id());
            // node.detach();
        }
    }

    let mut pixmap = tiny_skia::Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();
    resvg::render(
        &tree,
        resvg::FitTo::Width(WIDTH as u32),
        tiny_skia::Transform::default(),
        pixmap.as_mut(),
    )
    .unwrap();

    let png = pixmap.encode_png().unwrap();

    fs::write("output.png", png).unwrap();
}
