use std::{fs::File, path::Path};

use zip::ZipArchive;

///
/// Extract artwork and ROM assets
///
pub fn get_assets(platform_name: &str, mame_path: &Path, temp_dir: &Path) {
    let artwork_path = mame_path
        .join("artwork/foo")
        .with_file_name(platform_name)
        .with_extension("zip");

    let roms_path = mame_path
        .join("roms/foo")
        .with_file_name(platform_name)
        .with_extension("zip");

    extract_path(&artwork_path, &temp_dir);
    extract_path(&roms_path, &temp_dir);
}

fn extract_path(file_path: &Path, outdir: &Path) {
    let zip_file = File::open(file_path).expect("Could not open expected artwork file");

    let mut archive = ZipArchive::new(zip_file).expect("Could not open zip");
    archive.extract(outdir).expect("Could not extract zip");
}
