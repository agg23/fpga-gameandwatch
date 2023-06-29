use std::{fs::File, path::Path};

use colored::Colorize;
use zip::ZipArchive;

///
/// Extract artwork and ROM assets
///
pub fn get_assets(
    platform_name: &str,
    owning_rom_name: &Option<String>,
    mame_path: &Path,
    temp_dir: &Path,
) -> Result<(), String> {
    let artwork_path = mame_path
        .join("artwork/foo")
        .with_file_name(platform_name)
        .with_extension("zip");

    let roms_path = mame_path
        .join("roms/foo")
        .with_file_name(platform_name)
        .with_extension("zip");

    let mut has_parent = false;

    if let Some(owning_rom_name) = owning_rom_name {
        let owning_roms_path = mame_path
            .join("roms/foo")
            .with_file_name(owning_rom_name)
            .with_extension("zip");

        if let Err(message) = extract_path(&owning_roms_path, &temp_dir, "parent ROM") {
            return Err(format!(
                "Device is dependent on parent ROM {}\n{message}",
                owning_rom_name.cyan()
            ));
        }

        has_parent = true;
    }

    extract_path(&artwork_path, &temp_dir, "artwork")?;
    match extract_path(&roms_path, &temp_dir, "ROM") {
        Ok(_) => Ok(()),
        Err(err) => {
            // If we found a parent, we don't require a ROM for this title
            if has_parent {
                Ok(())
            } else {
                Err(err)
            }
        }
    }
}

fn extract_path(file_path: &Path, outdir: &Path, data_type: &str) -> Result<(), String> {
    guard!(let Ok(zip_file) = File::open(file_path) else {
        let name = if let Some(name) = file_path.file_name() {
            format!(" ({name:?})")
        } else {
            "".to_string()
        };

        return Err(format!("Could not open expected {data_type} file{name} at {file_path:?}"));
    });

    guard!(let Ok(mut archive) = ZipArchive::new(zip_file) else {
        return Err(format!("Could not open zip at {file_path:?}"));
    });

    if archive.extract(outdir).is_err() {
        return Err(format!("Could not extract zip at {file_path:?}"));
    }

    Ok(())
}
