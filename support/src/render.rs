use std::{
    collections::HashSet,
    path::{Path, PathBuf},
};

use image::imageops::FilterType;
use resvg::tiny_skia::{Pixmap, PixmapPaint};
use tiny_skia_path::Transform;

use crate::{
    layout::{Bounds, Element, Screen, View, ViewElement},
    manifest::{self, PresetDefinition},
    svg_manage::build_svg,
    HEIGHT, WIDTH,
};

pub fn render(
    platform_name: &str,
    layout: &View,
    platform: &PresetDefinition,
    asset_dir: &Path,
) -> Result<PathBuf, String> {
    let mut view_bounds: Option<&Bounds> = None;
    let mut elements: Vec<&Element> = vec![];
    let mut screens: Vec<&Screen> = vec![];

    for item in &layout.items {
        match item {
            ViewElement::Bounds(bounds) => {
                if view_bounds.is_some() {
                    return Err(format!(
                        "View {} in {platform_name} has multiple bounds. Skipping",
                        layout.name
                    ));
                }
                view_bounds = Some(bounds);
            }
            ViewElement::Element(element) => elements.push(element),
            ViewElement::Screen(screen) => screens.push(screen),
        }
    }

    let view_bounds = if let Some(view_bounds) = view_bounds {
        view_bounds.clone()
    } else {
        // Calculate actual bounds
        let mut min_x: Option<i32> = None;
        let mut min_y: Option<i32> = None;
        let mut max_width = 0;
        let mut max_height = 0;

        for bounds in elements
            .iter()
            .map(|e| &e.bounds)
            .chain(screens.iter().map(|s| &s.bounds))
        {
            if let Some(inner_min_x) = min_x {
                if inner_min_x > bounds.x {
                    min_x = Some(bounds.x);
                }
            }

            if let Some(inner_min_y) = min_y {
                if inner_min_y > bounds.y {
                    min_y = Some(bounds.y);
                }
            }

            if bounds.width + bounds.x > max_width {
                max_width = bounds.width + bounds.x;
            }

            if bounds.height + bounds.y > max_height {
                max_height = bounds.height + bounds.y;
            }
        }

        Bounds {
            x: min_x.map_or(0, |x| x),
            y: min_y.map_or(0, |y| y),
            width: max_width,
            height: max_height,
        }
    };

    let x_ratio = WIDTH as f32 / view_bounds.width as f32;
    let y_ratio = HEIGHT as f32 / view_bounds.height as f32;

    let (ratio, x_scale) = if x_ratio < y_ratio {
        // Scaling based on X
        (x_ratio, true)
    } else {
        (y_ratio, false)
    };

    let (x_offset, y_offset) = if !x_scale {
        let scaled_width = view_bounds.width as f32 * ratio;
        ((WIDTH as i32 - scaled_width.round() as i32) / 2, 0)
    } else {
        let scaled_height = view_bounds.height as f32 * ratio;
        (0, (HEIGHT as i32 - scaled_height.round() as i32) / 2)
    };

    // Keep track of which refs have already been added to the image, as most layouts contain multiple duplicates
    let mut already_applied_refs = HashSet::<&String>::new();

    let mut pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

    // We currently ignore offsetting by X/Y at the parent view, so the child positions are subtracted
    // from the parent's offset
    for item in &layout.items {
        match item {
            ViewElement::Element(element) => {
                if already_applied_refs.contains(&element.ref_name) {
                    continue;
                }

                already_applied_refs.insert(&element.ref_name);

                match element.ref_name.to_lowercase().as_str() {
                    "dust" | "fix-top" | "fix-bottom" => {
                        // Ignore these features
                        println!("Ignoring element by name {}", element.ref_name);
                        continue;
                    }
                    _ => {}
                }

                let file_path = asset_dir
                    .join("foo")
                    .with_file_name(format!("{}.png", element.ref_name));

                guard!(let Ok(image) = image::open(&file_path) else {
                    return Err(format!("Could not load element asset at {file_path:?}"));
                });

                let dimensions = ImageDimensions::new(
                    &view_bounds,
                    &element.bounds,
                    ratio,
                    image.width() as f32,
                    image.height() as f32,
                );

                let image =
                    image.resize(dimensions.width, dimensions.height, FilterType::CatmullRom);

                // Dimensions might change by a pixel as part of resizing
                let image_width = image.width();
                let image_height = image.height();

                guard!(let Some(image_map) = Pixmap::from_vec(
                    image.into_bytes(),
                    tiny_skia_path::IntSize::from_wh(image_width, image_height).unwrap(),
                ) else {
                    return Err(format!("Could not convert PNG into Pixmap"));
                });

                pixmap.draw_pixmap(
                    dimensions.x + x_offset,
                    dimensions.y + y_offset,
                    image_map.as_ref(),
                    &PixmapPaint::default(),
                    Transform::identity(),
                    None,
                );
            }
            ViewElement::Screen(screen) => {
                let file_path = asset_dir.join("foo").with_file_name(screen_filename(
                    screen.index as usize,
                    platform_name,
                    platform,
                ));

                let width: f32 = screen.bounds.width as f32 * ratio;
                let height = screen.bounds.height as f32 * ratio;

                let dimensions = ImageDimensions::new(
                    &view_bounds,
                    &screen.bounds,
                    ratio,
                    // We don't care about image dimensions for SVG
                    width,
                    height,
                );

                let svg_map = build_svg(&file_path, width as u32, height as u32);

                pixmap.draw_pixmap(
                    dimensions.x + x_offset,
                    dimensions.y + y_offset,
                    svg_map.as_ref(),
                    &PixmapPaint::default(),
                    Transform::identity(),
                    None,
                );
            }
            ViewElement::Bounds(_) => {}
        }
    }

    let debug_path = asset_dir.join(format!("{platform_name}.png"));

    pixmap.save_png(&debug_path).unwrap();

    Ok(debug_path)
}

fn screen_filename(index: usize, platform_name: &str, platform: &PresetDefinition) -> String {
    let suffix = match platform.screen {
        manifest::Screen::Single { .. } => "",
        manifest::Screen::DualVertical { .. } => {
            if index == 0 {
                "_top"
            } else {
                "_bottom"
            }
        }
        manifest::Screen::DualHorizontal { .. } => {
            if index == 0 {
                "_left"
            } else {
                "_right"
            }
        }
    };

    format!("{platform_name}{suffix}.svg")
}

struct ImageDimensions {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
}

impl ImageDimensions {
    fn new(
        view_bounds: &Bounds,
        bounds: &Bounds,
        ratio: f32,
        image_width: f32,
        image_height: f32,
    ) -> Self {
        let x = ((bounds.x as i32 - view_bounds.x as i32) as f32 * ratio).round() as i32;
        let y = ((bounds.y as i32 - view_bounds.y as i32) as f32 * ratio).round() as i32;
        let width = bounds.width as f32 * ratio;
        let height = bounds.height as f32 * ratio;

        if x < 0 {
            println!("Unexpected X: {x} is less than 0");
        }

        if y < 0 {
            println!("Unexpected Y: {y} is less than 0");
        }

        // Use this ratio to rescale the _actual_ size of the image asset so that it maintains proportions,
        // but sets the max dimension to match the bounds
        let image_ratio_x = width / image_width;
        let image_ratio_y = height / image_height;

        let image_ratio = if image_ratio_x < image_ratio_y {
            image_ratio_x
        } else {
            image_ratio_y
        };

        let image_width = (image_ratio * image_width) as u32;
        let image_height = (image_ratio * image_height) as u32;

        ImageDimensions {
            x,
            y,
            width: image_width,
            height: image_height,
        }
    }
}
