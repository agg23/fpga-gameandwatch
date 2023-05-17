use std::{fs::File, path::Path};

use zip::ZipArchive;

///
/// Extract artwork and ROM assets
///
pub fn get_assets(platform_name: &str, mame_path: &Path, temp_dir: &Path) -> Result<(), String> {
    let artwork_path = mame_path
        .join("artwork/foo")
        .with_file_name(platform_name)
        .with_extension("zip");

    let roms_path = mame_path
        .join("roms/foo")
        .with_file_name(platform_name)
        .with_extension("zip");

    extract_path(&artwork_path, &temp_dir, "artwork")?;
    extract_path(&roms_path, &temp_dir, "ROM")?;

    Ok(())
}

fn extract_path(file_path: &Path, outdir: &Path, data_type: &str) -> Result<(), String> {
    guard!(let Ok(zip_file) = File::open(file_path) else {
        return Err(format!("Could not open expected {data_type} file at {file_path:?}"));
    });

    guard!(let Ok(mut archive) = ZipArchive::new(zip_file) else {
        return Err(format!("Could not open zip at {file_path:?}"));
    });

    if archive.extract(outdir).is_err() {
        return Err(format!("Could not extract zip at {file_path:?}"));
    }

    Ok(())
}
