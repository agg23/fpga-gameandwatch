#[macro_use]
extern crate guard;

use std::{collections::HashMap, env::temp_dir, fs, path::Path};

use assets::get_assets;
use layout::parse_layout;
use manifest::PlatformSpecification;
use svg_manage::build_svg;

use crate::manifest::CPUType;

mod assets;
mod layout;
mod manifest;
mod render;
mod svg_manage;

static WIDTH: usize = 720;
static HEIGHT: usize = WIDTH;

fn main() {
    // let svg_path = "assets/gnw_dkong2_top.svg";

    let temp_dir = temp_dir().join("gnw");
    let mame_path = Path::new("/Users/adam/Downloads/Mame 252/");

    let platform_name = "gnw_dkong2";

    let manifest_file = fs::read("extraction/output.json").unwrap();

    let manifest: HashMap<String, PlatformSpecification> =
        serde_json::from_slice(manifest_file.as_slice()).unwrap();

    guard!(let Some(platform) = manifest.get(platform_name) else {
        println!("Could not find platform {platform_name} in manifest");
        return;
    });

    guard!(let Ok(layout) = parse_layout() else {
        println!("Could not parse layout");
        return;
    });

    get_assets(platform_name, mame_path, &temp_dir);

    render::render(platform_name, &layout, &platform.device, &temp_dir);

    // parse_layout();

    // let manifest = fs::read("extraction/output.json").unwrap();

    // let output: HashMap<String, PlatformSpecification> =
    //     serde_json::from_slice(manifest.as_slice()).unwrap();

    // // println!("{output:?}");

    // println!("Selecting only SM510 systems");

    // output
    //     .iter()
    //     .filter(|(_, p)| p.device.cpu == CPUType::SM510)
    //     .for_each(|(s, _)| println!("{s}"));

    // let png = build_svg(svg_path);

    // fs::write("output.png", png).unwrap();
}
