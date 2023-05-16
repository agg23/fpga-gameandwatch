#[macro_use]
extern crate guard;

use std::{collections::HashMap, env::temp_dir, fs, path::PathBuf};

use clap::{Parser, Subcommand};

use colored::Colorize;

use assets::get_assets;
use layout::parse_layout;
use manifest::PlatformSpecification;

use crate::manifest::CPUType;

mod assets;
mod layout;
mod manifest;
mod render;
mod svg_manage;

static WIDTH: usize = 720;
static HEIGHT: usize = WIDTH;

#[derive(Subcommand, Clone, Debug)]
enum FilterArg {
    /// Match a particular game
    Specific { name: String },
    /// Match the games that use a particular CPU
    CPU { name: CPUType },
    /// All game types specified in the manifest.json
    All,
}

#[derive(Parser, Debug)]
struct Args {
    #[command(subcommand)]
    filter: FilterArg,

    #[arg(short = 'o', long)]
    /// Only the games located in your MAME directory
    only_owned: bool,

    #[arg(short = 'm', long)]
    /// The path to your MAME directory containing your games
    mame_path: PathBuf,

    #[arg(short = 'a', long, default_value = "manifest.json")]
    manifest_path: PathBuf,
}

fn main() {
    let args = Args::parse();

    let temp_dir = temp_dir().join("gnw");

    let manifest_file = fs::read(args.manifest_path).expect("Could not find manifest file");

    let manifest: HashMap<String, PlatformSpecification> =
        serde_json::from_slice(manifest_file.as_slice()).expect("Could not parse manifest file");

    let platforms: Option<Vec<(String, &PlatformSpecification)>> = match args.filter {
        FilterArg::Specific { name } => {
            let trimmed_name = name.trim().to_string();

            if let Some(entry) = manifest.get(&trimmed_name) {
                Some(vec![(trimmed_name, entry)])
            } else {
                None
            }
        }
        FilterArg::CPU { name } => {
            let result = manifest
                .iter()
                .filter(|(_, p)| p.device.cpu == name)
                .map(|(n, p)| (n.clone(), p))
                .collect::<Vec<(String, &PlatformSpecification)>>();

            if result.len() > 0 {
                Some(result)
            } else {
                None
            }
        }
        FilterArg::All => Some(manifest.iter().map(|(n, p)| (n.clone(), p)).collect()),
    };

    guard!(let Some(mut platforms) = platforms else {
        println!("No manifest listings for selected devices found");
        return;
    });

    platforms.sort_by(|(a, _), (b, _)| a.partial_cmp(b).unwrap());

    let mut success_count = 0;
    let mut skip_count = 0;
    let mut fail_count = 0;
    let platform_count = platforms.len();

    let mut fail = |name: String, message: String| {
        println!("{message}");
        println!("Skipping device {name}\n");

        fail_count += 1;
    };

    for (name, platform) in platforms {
        let temp_dir = temp_dir.join(name.clone());

        println!("-------------------------");
        println!("Processing device {}\n", name.green());

        if let Err(err) = get_assets(&name, &args.mame_path, &temp_dir) {
            if !args.only_owned {
                // Only fail if we're not looking for only owned games
                fail(name, err);
            } else {
                println!("Skipping device {name}: Not installed\n");
                skip_count += 1;
            }
            continue;
        }

        let layout = match parse_layout(&temp_dir) {
            Ok(layout) => layout,
            Err(err) => {
                fail(name, err);
                continue;
            }
        };

        let path = match render::render(&name, &layout, &platform.device, &temp_dir) {
            Ok(path) => path,
            Err(err) => {
                fail(name, err);
                return;
            }
        };

        println!("Successfully created device {} at {path:?}\n", name.green());
        success_count += 1;
    }

    println!("-------------------------");
    println!(
        "Total: {platform_count}, Success: {success_count}, Fail: {fail_count}, Skip: {skip_count}",
    );

    // guard!(let Some(platform) = manifest.get(platform_name) else {
    //     println!("Could not find platform {platform_name} in manifest");
    //     return;
    // });

    // guard!(let Ok(layout) = parse_layout() else {
    //     println!("Could not parse layout");
    //     return;
    // });

    // get_assets(platform_name, mame_path, &temp_dir);

    // render::render(platform_name, &layout, &platform.device, &temp_dir);

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
