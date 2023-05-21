use std::{
    collections::HashSet,
    path::{Path, PathBuf},
};

use image::{imageops::FilterType, DynamicImage, ImageBuffer, Rgba};
use resvg::tiny_skia::{BlendMode, Color, Pixmap, PixmapPaint};
use tiny_skia_path::Transform;

use crate::{
    encode_format::encode,
    layout::{BlendType, Bounds, Element, Screen, View, ViewElement},
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
    let mut view_bounds: Option<Bounds> = None;
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
                view_bounds = Some(bounds.to_xy());
            }
            ViewElement::Element(element) => elements.push(element),
            ViewElement::Screen(screen) => screens.push(screen),
        }
    }

    let view_bounds = if let Some(view_bounds) = view_bounds {
        view_bounds
    } else {
        // Calculate actual bounds
        let mut min_x: Option<i32> = None;
        let mut min_y: Option<i32> = None;
        let mut max_width = 0;
        let mut max_height = 0;

        for bounds in elements
            .iter()
            .map(|e| e.bounds.to_xy())
            .chain(screens.iter().map(|s| s.bounds.to_xy()))
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

    // Keep track of the set of pixels that make up each screen
    let mut pixels_to_mask_id: Vec<Option<u16>> = vec![None; WIDTH * HEIGHT];

    let mut background_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();
    let mut mask_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

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
                    "dust" => {
                        // Ignore these features
                        println!("Ignoring element by name {}", element.ref_name);
                        continue;
                    }
                    value => {
                        if value.starts_with("fix") || value.starts_with("gradient") {
                            println!("Ignoring element by name {}", element.ref_name);
                            continue;
                        }
                    }
                }

                let file_path = asset_dir
                    .join("foo")
                    .with_file_name(format!("{}.png", element.ref_name));

                // A bug in either tiny_skia or image prevents transparency from working correctly when imported
                // through image, so we import in tiny_skia and convert
                guard!(let Ok(image) = Pixmap::load_png(&file_path) else {
                    println!("Ignoring element asset {} which was not at {file_path:?}", element.ref_name);
                    continue;
                });

                let image = ImageBuffer::<Rgba<u8>, Vec<u8>>::from_vec(
                    image.width(),
                    image.height(),
                    image.take(),
                )
                .expect("Could not convert image data");

                let dimensions = ImageDimensions::new(
                    &view_bounds,
                    &element.bounds.to_xy(),
                    ratio,
                    x_offset,
                    y_offset,
                );

                let image = DynamicImage::ImageRgba8(image).resize_exact(
                    dimensions.width,
                    dimensions.height,
                    FilterType::CatmullRom,
                );

                // Dimensions might change by a pixel as part of resizing
                let image_width = image.width();
                let image_height = image.height();

                guard!(let Some(image_map) = Pixmap::from_vec(
                    image.into_bytes(),
                    tiny_skia_path::IntSize::from_wh(image_width, image_height).unwrap(),
                ) else {
                    return Err(format!("Could not convert PNG into Pixmap"));
                });

                let mut aligned_image_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

                // This is inefficient, but I don't want to calculate the bounds changes
                aligned_image_pixmap.draw_pixmap(
                    dimensions.x,
                    dimensions.y,
                    image_map.as_ref(),
                    &PixmapPaint::default(),
                    Transform::identity(),
                    None,
                );

                // We have to go pixel by pixel and check if they're in the mask
                let pixels = aligned_image_pixmap.pixels();
                for i in 0..WIDTH * HEIGHT {
                    let pixel = pixels[i];
                    if pixel.alpha() == 0 {
                        continue;
                    }

                    if pixels_to_mask_id[i].is_some() {
                        // A mask pixel is at this location
                        mask_pixmap.pixels_mut()[i] = pixel;

                        // Also write through to the background
                        background_pixmap.pixels_mut()[i] = pixel;
                    } else {
                        // No mask pixel, write to background
                        background_pixmap.pixels_mut()[i] = pixel;
                    }
                }
            }
            ViewElement::Screen(screen) => {
                let file_path = asset_dir.join("foo").with_file_name(screen_filename(
                    screen.index as usize,
                    platform_name,
                    platform,
                ));

                let bounds = screen.bounds.to_xy();

                let dimensions =
                    ImageDimensions::new(&view_bounds, &bounds, ratio, x_offset, y_offset);

                // TODO: We don't really have a way to scale SVGs that won't result in a quality loss
                // so that isn't handled here
                let rendered_svg = build_svg(&file_path, &dimensions);

                // Draw actual LCD pixels
                mask_pixmap.draw_pixmap(
                    // This image is already aligned
                    0,
                    0,
                    rendered_svg.pixmap.as_ref(),
                    &PixmapPaint::default(),
                    Transform::identity(),
                    None,
                );

                // Combine this screen into the global pixel ID map
                // If both have IDs, latest wins
                for i in 0..WIDTH * HEIGHT {
                    if let Some(new_svg_id) = rendered_svg.pixel_pos_to_id[i] {
                        // Use this, replacing any existing pixel
                        pixels_to_mask_id[i] = Some(new_svg_id);
                    }
                }
            }
            ViewElement::Bounds(_) => {}
        }
    }

    let mut debug_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

    debug_pixmap.draw_pixmap(
        0,
        0,
        background_pixmap.as_ref(),
        &PixmapPaint::default(),
        Transform::identity(),
        None,
    );

    debug_pixmap.draw_pixmap(
        0,
        0,
        mask_pixmap.as_ref(),
        &PixmapPaint::default(),
        Transform::identity(),
        None,
    );

    let mut output_mask = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

    output_mask.fill(Color::from_rgba8(255, 255, 255, 255));

    output_mask.draw_pixmap(
        0,
        0,
        mask_pixmap.as_ref(),
        &PixmapPaint::default(),
        Transform::identity(),
        None,
    );

    let debug_path = asset_dir.join(format!("{platform_name}.png"));
    let debug_background_path = asset_dir.join(format!("{platform_name}_background.png"));
    let debug_mask_path = asset_dir.join(format!("{platform_name}_mask.png"));

    debug_pixmap.save_png(&debug_path).unwrap();
    background_pixmap.save_png(&debug_background_path).unwrap();
    output_mask.save_png(&debug_mask_path).unwrap();

    Ok(encode(
        background_pixmap.data(),
        output_mask.data(),
        pixels_to_mask_id.as_slice(),
        asset_dir,
    ))

    // Ok(debug_path)
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

fn blend_to_pixmap_paint(blend: &Option<BlendType>) -> PixmapPaint {
    let mut paint = PixmapPaint::default();

    // paint.blend_mode = BlendMode::Overlay;

    if let Some(blend) = blend {
        match blend {
            BlendType::Add => paint.blend_mode = BlendMode::Plus,
            BlendType::Alpha => {
                // TODO: Unimplemented
            }
            BlendType::Multiply => paint.blend_mode = BlendMode::Multiply,
        }
    }

    paint
}

#[derive(Clone)]
pub struct ImageDimensions {
    pub x: i32,
    pub y: i32,
    pub width: u32,
    pub height: u32,
}

impl ImageDimensions {
    fn new(
        view_bounds: &Bounds,
        bounds: &Bounds,
        ratio: f32,
        x_offset: i32,
        y_offset: i32,
    ) -> Self {
        let x = ((bounds.x as i32 - view_bounds.x as i32) as f32 * ratio).round() as i32;
        let y = ((bounds.y as i32 - view_bounds.y as i32) as f32 * ratio).round() as i32;
        let width = (bounds.width as f32 * ratio) as u32;
        let height = (bounds.height as f32 * ratio) as u32;

        if x < 0 {
            println!("Unexpected X: {x} is less than 0");
        }

        if y < 0 {
            println!("Unexpected Y: {y} is less than 0");
        }

        ImageDimensions {
            x: x + x_offset,
            y: y + y_offset,
            width,
            height,
        }
    }
}
