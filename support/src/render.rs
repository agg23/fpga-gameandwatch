use std::{collections::HashSet, path::Path};

use image::{imageops::FilterType, DynamicImage, ImageBuffer, Rgba};
use resvg::tiny_skia::{Pixmap, PixmapPaint, PremultipliedColorU8};
use tiny_skia_path::Transform;

use crate::{
    layout::{
        BlendType, Bounds, Element, MameLayout, NameElementChildren, Screen, View, ViewElement,
    },
    manifest::{self, PlatformSpecification, PresetDefinition},
    svg_manage::build_svg,
    HEIGHT, WIDTH,
};

pub struct RenderedData {
    pub background_bytes: Pixmap,
    pub mask_bytes: Pixmap,
    pub pixels_to_mask_id: Vec<Option<u16>>,
}

pub fn render(
    platform_name: &str,
    layout: &View,
    layout_manifest: &MameLayout,
    platform: &PlatformSpecification,
    asset_dir: &Path,
    debug: bool,
) -> Result<RenderedData, String> {
    let mut view_bounds: Option<Bounds> = None;
    let mut elements: Vec<&Element> = vec![];
    let mut screens: Vec<&Screen> = vec![];

    let mut filtered_items: Vec<&ViewElement> = vec![];

    // Keep track of which refs have already been added to the image, as most layouts contain multiple duplicates
    let mut already_applied_refs: HashSet<&String> = HashSet::<&String>::new();

    // Prefilter all items
    for item in &layout.items {
        match item {
            ViewElement::Bounds(bounds) => {
                // Filter out
                if view_bounds.is_some() {
                    return Err(format!(
                        "View {} in {platform_name} has multiple bounds. Skipping",
                        layout.name
                    ));
                }
                view_bounds = Some(bounds.to_xy());
            }
            ViewElement::Element(element) | ViewElement::Overlay(element) => {
                if already_applied_refs.contains(&element.ref_name) {
                    continue;
                }

                already_applied_refs.insert(&element.ref_name);

                match element.ref_name.to_lowercase().as_str() {
                    "dust" | "bubbles" | "unit" | "backdrop" => {
                        // Ignore these features
                        println!("Ignoring element by name {}", element.ref_name);
                        continue;
                    }
                    value => {
                        // if value.starts_with("fix") || value.starts_with("gradient") {
                        if value.starts_with("gradient") {
                            println!("Ignoring element by name {}", element.ref_name);
                            continue;
                        }
                    }
                }

                filtered_items.push(item);
                elements.push(element);
            }
            ViewElement::Screen(screen) => {
                filtered_items.push(item);
                screens.push(screen);
            }
        }
    }

    // Calculate actual bounds
    let mut min_x: Option<i32> = None;
    let mut min_y: Option<i32> = None;
    let mut max_width = 0;
    let mut max_height = 0;
    let mut max_common_x: Option<i32> = None;
    let mut max_common_y: Option<i32> = None;

    // Calculate max bounds
    // Only Element nodes are used, as Screen's should not drive the overall picture size (they sometimes overrun it)
    for bounds in elements.iter().map(|e| e.bounds.to_xy()) {
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

        if let Some(common_x) = max_common_x {
            if common_x > bounds.x {
                // Shorten max common
                max_common_x = Some(bounds.x);
            }
        } else {
            // Set first value
            max_common_x = Some(bounds.x);
        }

        if let Some(common_y) = max_common_y {
            if common_y > bounds.y {
                // Shorten max common
                max_common_y = Some(bounds.y);
            }
        } else {
            // Set first value
            max_common_y = Some(bounds.y);
        }
    }

    let max_common_x = max_common_x.map_or(0, |x| x.max(0));
    let max_common_y = max_common_y.map_or(0, |y| y.max(0));

    let view_bounds = Bounds {
        x: (min_x.map_or(0, |x| x) - max_common_x).max(0),
        y: (min_y.map_or(0, |y| y) - max_common_y).max(0),
        width: max_width - max_common_x,
        height: max_height - max_common_y,
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

    // Keep track of the set of pixels that make up each screen
    let mut pixels_to_mask_id: Vec<Option<u16>> = vec![None; WIDTH * HEIGHT];

    let mut background_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();
    let mut mask_pixmap = Pixmap::new(WIDTH as u32, HEIGHT as u32).unwrap();

    // We currently ignore offsetting by X/Y at the parent view, so the child positions are subtracted
    // from the parent's offset
    for item in &filtered_items {
        match item {
            ViewElement::Element(element) | ViewElement::Overlay(element) => {
                if layout_manifest
                    .element
                    .iter()
                    .find(|e| {
                        e.name == element.ref_name
                            && e.items
                                .iter()
                                .find(|p| {
                                    if let NameElementChildren::Image(_) = **p {
                                        true
                                    } else {
                                        false
                                    }
                                })
                                .is_some()
                    })
                    .is_none()
                {
                    // There is no defined element with this name OR the defined element does not have image data
                    // Skip
                    continue;
                }

                let file_path = asset_dir
                    .join("foo")
                    .with_file_name(format!("{}.png", element.ref_name));

                // A bug in either tiny_skia or image prevents transparency from working correctly when imported
                // through image, so we import in tiny_skia and convert
                guard!(let Ok(image) = Pixmap::load_png(&file_path) else {
                    return Err(format!("Missing element asset \"{}\" which was not at {file_path:?}", element.ref_name));
                });

                let image = ImageBuffer::<Rgba<u8>, Vec<u8>>::from_vec(
                    image.width(),
                    image.height(),
                    image.take(),
                )
                .expect("Could not convert image data");

                let element_bounds = element.bounds.to_xy();

                let x = if element_bounds.x >= 0 {
                    // Only normalize to 0 if we started out positive
                    (element_bounds.x - max_common_x).max(0)
                } else {
                    element_bounds.x - max_common_x
                };

                let y = if element_bounds.y >= 0 {
                    // Only normalize to 0 if we started out positive
                    (element_bounds.y - max_common_y).max(0)
                } else {
                    element_bounds.y - max_common_y
                };

                let element_bounds = Bounds {
                    x,
                    y,
                    width: element_bounds.width,
                    height: element_bounds.height,
                };

                let dimensions =
                    ImageDimensions::new(&view_bounds, &element_bounds, ratio, x_offset, y_offset);

                let image: DynamicImage = DynamicImage::ImageRgba8(image).resize_exact(
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

                let blend = if let ViewElement::Overlay(_) = item {
                    Some(&BlendType::Multiply)
                } else {
                    element.blend.as_ref()
                };

                let blend_func = match blend {
                    Some(BlendType::Add) | Some(BlendType::Alpha) | None => alpha_blend_colors,
                    Some(BlendType::Multiply) => multiply_blend_colors,
                };

                let white_pixel = PremultipliedColorU8::from_rgba(255, 255, 255, 255).unwrap();

                // We have to go pixel by pixel and check if they're in the mask
                let pixels = aligned_image_pixmap.pixels();
                let mask_pixels = mask_pixmap.pixels_mut();
                let background_pixels = background_pixmap.pixels_mut();
                for i in 0..WIDTH * HEIGHT {
                    let pixel = pixels[i];
                    if pixel.alpha() == 0 {
                        continue;
                    }

                    let background_pixel = if blend == Some(&BlendType::Multiply)
                        && background_pixels[i].alpha() == 0
                    {
                        // Value was never set, mulitply would fail
                        white_pixel
                    } else {
                        background_pixels[i]
                    };

                    if pixels_to_mask_id[i].is_some() {
                        // A mask pixel is at this location
                        mask_pixels[i] = blend_func(mask_pixels[i], pixel);

                        // Also write through to the background
                        background_pixels[i] = blend_func(background_pixel, pixel);
                    } else {
                        // No mask pixel, write to background
                        background_pixels[i] = blend_func(background_pixel, pixel);
                    }
                }
            }
            ViewElement::Screen(screen) => {
                let file_path = asset_dir.join("foo").with_file_name(screen_filename(
                    screen.index as usize,
                    platform_name,
                    &platform.device,
                ));

                let alternate_file_path = platform.rom.rom_owner.as_ref().and_then(|parent| {
                    Some(asset_dir.join("foo").with_file_name(screen_filename(
                        screen.index as usize,
                        &parent,
                        &platform.device,
                    )))
                });

                let bounds = screen.bounds.to_xy();

                let x = if bounds.x >= 0 {
                    // Only normalize to 0 if we started out positive
                    (bounds.x - max_common_x).max(0)
                } else {
                    bounds.x - max_common_x
                };

                let y = if bounds.y >= 0 {
                    // Only normalize to 0 if we started out positive
                    (bounds.y - max_common_y).max(0)
                } else {
                    bounds.y - max_common_y
                };

                let bounds = Bounds {
                    x,
                    y,
                    width: bounds.width,
                    height: bounds.height,
                };

                let dimensions =
                    ImageDimensions::new(&view_bounds, &bounds, ratio, x_offset, y_offset);

                // TODO: We don't really have a way to scale SVGs that won't result in a quality loss
                // so that isn't handled here
                let rendered_svg = build_svg(&file_path, &alternate_file_path, &dimensions)?;

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

    let mut output_mask = background_pixmap.clone();

    // Draw mask over top of background, so transparency can blend to the correct colors
    output_mask.draw_pixmap(
        0,
        0,
        mask_pixmap.as_ref(),
        &PixmapPaint::default(),
        Transform::identity(),
        None,
    );

    if debug {
        let debug_path = asset_dir.join(format!("{platform_name}.png"));
        let debug_background_path = asset_dir.join(format!("{platform_name}_background.png"));
        let debug_mask_path = asset_dir.join(format!("{platform_name}_mask.png"));

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

        debug_pixmap.save_png(&debug_path).unwrap();
        background_pixmap.save_png(&debug_background_path).unwrap();
        output_mask.save_png(&debug_mask_path).unwrap();
    }

    Ok(RenderedData {
        background_bytes: background_pixmap,
        mask_bytes: output_mask,
        pixels_to_mask_id: pixels_to_mask_id,
    })
}

fn alpha_blend_colors(
    background: PremultipliedColorU8,
    foreground: PremultipliedColorU8,
) -> PremultipliedColorU8 {
    let combine_values = |foreground: u8, background: u8, foreground_alpha: f32| -> u8 {
        let foreground = foreground as f32;
        let background = background as f32;

        let output = (foreground / 255.0) + (background / 255.0) * (1.0 - foreground_alpha);

        (output * 255.0).round() as u8
    };

    let foreground_alpha = foreground.alpha() as f32 / 255.0;

    let red = combine_values(foreground.red(), background.red(), foreground_alpha);
    let green = combine_values(foreground.green(), background.green(), foreground_alpha);
    let blue = combine_values(foreground.blue(), background.blue(), foreground_alpha);
    let alpha = combine_values(foreground.alpha(), background.alpha(), foreground_alpha);

    PremultipliedColorU8::from_rgba(red, green, blue, red.max(green).max(blue).max(alpha))
        .expect("Could not convert alpha blend color")
}

fn multiply_blend_colors(
    background: PremultipliedColorU8,
    foreground: PremultipliedColorU8,
) -> PremultipliedColorU8 {
    let combine_values = |foreground: u8, background: u8| -> u8 {
        let foreground = foreground as f32;
        let background = background as f32;

        let output = (foreground / 255.0) * (background / 255.0);

        let output = output.min(1.0);

        (output * 255.0).round() as u8
    };

    let red = combine_values(foreground.red(), background.red());
    let green = combine_values(foreground.green(), background.green());
    let blue = combine_values(foreground.blue(), background.blue());
    let alpha = combine_values(foreground.alpha(), background.alpha());

    PremultipliedColorU8::from_rgba(red, green, blue, red.max(green).max(blue).max(alpha))
        .expect("Could not convert multiply blend color")
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

#[derive(Clone, Debug)]
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

        // if x < 0 {
        //     println!("Unexpected X: {x} is less than 0");
        // }

        // if y < 0 {
        //     println!("Unexpected Y: {y} is less than 0");
        // }

        ImageDimensions {
            x: x + x_offset,
            y: y + y_offset,
            width,
            height,
        }
    }
}
