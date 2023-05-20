use std::{
    collections::{HashMap, HashSet},
    fs,
    path::Path,
};

use resvg::{
    tiny_skia::{self, Pixmap, PixmapPaint, PremultipliedColorU8},
    usvg::{self, Color, NormalizedF64, ShapeRendering, TreeParsing},
    FitTo,
};

use svg::{self, node::element::tag::Type};
use tiny_skia_path::Transform;

use crate::{render::ImageDimensions, HEIGHT, WIDTH};

pub struct RenderedSVG {
    pub pixmap: Pixmap,
    pub pixel_pos_to_id: Vec<Option<u16>>,
}

pub fn build_svg(svg_path: &Path, dimensions: &ImageDimensions) -> RenderedSVG {
    // Actual SVG ID (so `path123`) to title field (the segment ID)
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
    // let mut active_group: Option<ActiveGroup> = None;
    let mut active_path: Option<ActivePath> = None;
    let mut inside_title = false;

    let svg_contents = fs::read_to_string(svg_path).expect("Could not open SVG");

    for event in svg::read(&svg_contents).unwrap() {
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
            }
            _ => {}
        }
    }

    let tree = usvg::Tree::from_str(&svg_contents, &usvg::Options::default()).unwrap();
    let mut svg_title_to_color = HashMap::<u16, Color>::new();

    // Clear unnecessary nodes
    for node in tree.root.descendants() {
        if !keep_usvg_node(&node, &svg_id_to_title) {
            node.detach();
        }
    }

    // Set path colors
    for node in tree.root.descendants() {
        mutate_usvg_node(&node, &svg_id_to_title, &mut svg_title_to_color);
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

    mask_pixmap.save_png("outputtest.png");

    let mut pixel_pos_to_id: Vec<Option<u16>> = vec![None; WIDTH * HEIGHT];

    let pixels = mask_pixmap.pixels_mut();

    for i in 0..WIDTH * HEIGHT {
        let pixel = pixels[i];
        if pixel.alpha() == 0 {
            // Skip this pixel
            continue;
        }

        // // Check neighbors
        // let compare = |x: Option<PremultipliedColorU8>| {
        //     if let Some(x) = x {
        //         x.green() == pixel.green() && x.blue() == pixel.blue()
        //     } else {
        //         false
        //     }
        // };

        // let left = if i > 0 {
        //     Some(pixels[i - 1].clone())
        // } else {
        //     None
        // };

        // let right = if i < WIDTH * HEIGHT - 1 {
        //     Some(pixels[i + 1].clone())
        // } else {
        //     None
        // };

        // let top = if i >= WIDTH {
        //     Some(pixels[i - WIDTH].clone())
        // } else {
        //     None
        // };

        // let bottom = if i + WIDTH < WIDTH * HEIGHT {
        //     Some(pixels[i + WIDTH].clone())
        // } else {
        //     None
        // };

        // let directions = [left, right, top, bottom];
        // let mut matching_neighbor = false;
        // let mut direction_colors: Vec<PremultipliedColorU8> = vec![];

        // for direction in directions {
        //     if compare(direction) {
        //         matching_neighbor = true;
        //     }

        //     if let Some(color) = direction {
        //         if color.alpha() != 0 {
        //             // Rendered pixel
        //             direction_colors.push(color);
        //         }
        //     }
        // }

        // if !matching_neighbor {
        //     if direction_colors.len() < 1 {
        //         let id = (pixel.green() as u16) << 8 | pixel.blue() as u16;

        //         println!(
        //             "Isolated color with ID {} at index {i}. Dropping from mask",
        //             build_title(id)
        //         );

        //         continue;
        //     } else {
        //         // Switch to sibling color to one with highest alpha
        //         println!("Switching with sibling at index {i}");
        //         let mut max_alpha_color = direction_colors[0];
        //         for color in direction_colors {
        //             if color.alpha() > max_alpha_color.alpha() {
        //                 max_alpha_color = color;
        //             }
        //         }
        //         pixels[i] = max_alpha_color;
        //     }
        // }

        let id = (pixel.green() as u16) << 8 | pixel.blue() as u16;

        // Copy id to a pixel indexed array
        pixel_pos_to_id[i] = Some(id);

        if let Some(color) = svg_title_to_color.get(&id) {
            pixels[i] =
                PremultipliedColorU8::from_rgba(color.red, color.green, color.blue, 255).unwrap();
        } else {
            let title = build_title(id);
            println!("{} {}", pixel.blue(), pixel.green());
            println!(
                "Could not find color for pixel at index {i} using title {title}. Setting to black"
            );
            pixels[i] = PremultipliedColorU8::from_rgba(0, 0, 0, 255).unwrap();
        }
    }

    RenderedSVG {
        pixmap: mask_pixmap,
        pixel_pos_to_id,
    }
}

fn build_title(id: u16) -> String {
    let h = id & 0x3;
    let column = (id >> 2) & 0xF;
    let segments = (id >> 6) & 0xF;

    format!("{segments}.{column}.{h}")
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

/// Sets the node color to contain the title byte and stores this color by id
fn mutate_usvg_node(
    node: &usvg::Node,
    svg_id_to_title: &HashMap<String, u16>,
    svg_title_to_color: &mut HashMap<u16, Color>,
) {
    match &mut *node.borrow_mut() {
        usvg::NodeKind::Path(ref mut path) => {
            // Check if we care about this path
            guard!(let Some(title) = svg_id_to_title.get(&path.id) else {
                return;
            });

            // Disable antialiasing, which will change colors
            path.rendering_mode = ShapeRendering::CrispEdges;

            let paint = usvg::Paint::Color(usvg::Color {
                red: 0,
                green: (((title >> 8) & 0xFF) as u8),
                blue: (title & 0xFF) as u8,
            });

            // Encode the title byte into the color
            if let Some(fill) = &mut path.fill {
                // Save existing fill to use in the output images
                let color = match &fill.paint {
                    usvg::Paint::Color(color) => {
                        // Normalize alpha
                        let alpha = fill.opacity.get();
                        let red_float = (color.red as f64) * alpha;
                        let green_float = (color.green as f64) * alpha;
                        let blue_float = (color.blue as f64) * alpha;

                        Color {
                            red: red_float.round() as u8,
                            green: green_float.round() as u8,
                            blue: blue_float.round() as u8,
                        }
                    }
                    value => {
                        println!("Unexpected color {value:?}. Using black");
                        Color {
                            red: 255,
                            green: 255,
                            blue: 255,
                        }
                    }
                };
                svg_title_to_color.insert(*title, color);

                fill.paint = paint.clone();
                fill.opacity = NormalizedF64::new(1.0).unwrap();
            }
        }
        _ => {}
    }
}
