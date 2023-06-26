use std::{
    collections::{HashMap, HashSet},
    fs,
    path::Path,
};

use resvg::{
    tiny_skia::{self, Pixmap, PixmapPaint, PremultipliedColorU8},
    usvg::{self, NodeKind, Tree, TreeParsing},
    FitTo,
};

use rctree;
use svg::{self, node::element::tag::Type};
use tiny_skia_path::Transform;

use crate::{render::ImageDimensions, HEIGHT, WIDTH};

pub struct RenderedSVG {
    pub pixmap: Pixmap,
    pub pixel_pos_to_id: Vec<Option<u16>>,
}

pub fn build_svg(svg_path: &Path, dimensions: &ImageDimensions) -> RenderedSVG {
    // Actual SVG ID (so `path123`) to title field (the segment ID)
    let contents = fs::read_to_string(svg_path).expect("Could not open SVG");
    let svg_id_to_title = correlate_id_to_title(&contents);

    let tree = usvg::Tree::from_str(&contents, &usvg::Options::default()).unwrap();

    // Clear unnecessary nodes
    for node in tree.root.descendants() {
        if !keep_usvg_node(&node, &svg_id_to_title) {
            node.detach();
        }
    }

    pub type Node = rctree::Node<NodeKind>;

    let mut title_trees: Vec<(Node, u16)> = vec![];

    // Build sets of subtrees and ids
    for node in tree.root.descendants() {
        let element = node.borrow();

        match *element {
            usvg::NodeKind::Path(ref path) => {
                // Check if we care about this path
                guard!(let Some(title) = svg_id_to_title.get(&path.id) else {
                    continue;
                });

                let mut owning_tree = Node::new(element.clone());
                let mut next_parent = node.parent();

                while let Some(parent) = next_parent {
                    let new_parent = Node::new(parent.borrow().clone());
                    new_parent.append(owning_tree);
                    owning_tree = new_parent;

                    next_parent = parent.parent();
                }

                title_trees.push((owning_tree, *title));
            }
            _ => {}
        }
    }

    let mut id_mask_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

    let mut pixel_pos_to_id: Vec<Option<u16>> = vec![None; WIDTH * HEIGHT];

    // Extract pixel to ID mapping
    for (title_tree, id) in title_trees {
        let tree = Tree {
            size: tree.size,
            view_box: tree.view_box,
            root: title_tree,
        };

        let mut render_pixmap = Pixmap::new(dimensions.width, dimensions.height).unwrap();

        resvg::render(
            &tree,
            FitTo::Size(dimensions.width, dimensions.height),
            tiny_skia::Transform::default(),
            render_pixmap.as_mut(),
        )
        .expect("Could not render SVG to bitmap");

        // This is very wasteful and exists just to transform the coordinates, but I'm lazy
        id_mask_pixmap.draw_pixmap(
            dimensions.x,
            dimensions.y,
            render_pixmap.as_ref(),
            &PixmapPaint::default(),
            Transform::identity(),
            None,
        );

        let pixels = id_mask_pixmap.pixels_mut();

        for i in 0..WIDTH * HEIGHT {
            let pixel = pixels[i];
            if pixel.alpha() == 0 {
                // Skip this pixel
                continue;
            }

            // Copy id to a pixel indexed array
            pixel_pos_to_id[i] = Some(id);

            // Zero out this pixel for next render
            pixels[i] = PremultipliedColorU8::from_rgba(0, 0, 0, 0).unwrap();
        }
    }

    // This scales proportionally, which is not always what MAME does (gnw_cgrab)
    let mut render_pixmap = Pixmap::new(dimensions.width, dimensions.height).unwrap();
    resvg::render(
        &tree,
        FitTo::Size(dimensions.width, dimensions.height),
        tiny_skia::Transform::default(),
        render_pixmap.as_mut(),
    )
    .expect("Could not render SVG to bitmap");

    // This is inefficient, but it transforms the coordinates for us
    let mut mask_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();
    mask_pixmap.draw_pixmap(
        dimensions.x,
        dimensions.y,
        render_pixmap.as_ref(),
        &PixmapPaint::default(),
        Transform::identity(),
        None,
    );

    RenderedSVG {
        pixmap: mask_pixmap,
        pixel_pos_to_id,
    }
}

fn parse_title(title: &str) -> Option<u16> {
    let mut sections = title.split(".");

    guard!(let Ok(segment) = sections.next()?.parse::<u8>() else {
        println!("Could not parse segment from title {title}");
        return None;
    });

    if segment > 15 {
        println!("Segment {segment} in {title} was out of bounds");
        return None;
    }

    let segment = segment as u16;

    guard!(let Ok(column) = sections.next()?.parse::<u8>() else {
        println!("Could not parse column from title {title}");
        return None;
    });

    if column > 15 {
        println!("Column {column} in {title} was out of bounds");
        return None;
    }

    let column = column as u16;

    guard!(let Ok(row_h) = sections.next()?.parse::<u8>() else {
        println!("Could not parse row_h from title {title}");
        return None;
    });

    if row_h > 4 {
        println!("Row {row_h} in {title} was out of bounds");
        return None;
    }

    let row_h = row_h as u16;

    assert_eq!(sections.next(), None, "Title contained too many groups");

    return Some((segment << 6) | (column << 2) | row_h);
}

fn correlate_id_to_title(contents: &String) -> HashMap<String, u16> {
    let mut svg_id_to_title: HashMap<String, u16> = HashMap::new();

    #[derive(PartialEq, Debug)]
    struct ActiveGroup {
        id: Option<String>,
        title: Option<u16>,
        paths: HashSet<String>,
    }

    #[derive(PartialEq, Debug)]
    struct ActivePath {
        id: Option<String>,
        title: Option<u16>,
    }

    let mut group_stack: Vec<ActiveGroup> = vec![];
    let mut active_path: Option<ActivePath> = None;
    let mut inside_title = false;

    for event in svg::read(contents).unwrap() {
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
                } else if let Some(ActiveGroup { title, .. }) = group_stack.last_mut() {
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

                if let Some(ancestor_or_self) = group_stack.iter().rev().find(|g| g.title.is_some())
                {
                    // Title is guaranteed by the above check
                    let title = ancestor_or_self.title.unwrap();
                    // Group set a title
                    for p in &group.paths {
                        if !svg_id_to_title.contains_key(p) {
                            // Path title overrides group title, so make sure to skip if already set
                            svg_id_to_title.insert(p.clone(), title);
                        }
                    }
                }

                group_stack.pop();
            }
            _ => {}
        }
    }

    svg_id_to_title
}

fn keep_usvg_node(node: &usvg::Node, svg_id_to_title: &HashMap<String, u16>) -> bool {
    match *node.borrow() {
        usvg::NodeKind::Path(ref path) => {
            if path.id.is_empty() {
                return false;
            }

            if !svg_id_to_title.contains_key(&path.id) {
                return false;
            }
        }
        _ => {}
    }

    return true;
}
