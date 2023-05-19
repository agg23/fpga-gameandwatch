use std::{
    fs,
    path::{Path, PathBuf},
};

pub fn encode(background_bytes: &[u8], mask_bytes: &[u8], asset_dir: &Path) -> PathBuf {
    let background_iter = background_bytes.into_iter();
    let mask_iter = mask_bytes.into_iter();

    let mut count = 0;

    let image_block = background_iter
        .zip(mask_iter)
        .filter(|_| {
            let prev_count = count;
            if count < 3 {
                count += 1;
            } else {
                count = 0;
            }
            prev_count != 3
        })
        // Background is low byte
        .flat_map(|(background_byte, mask_byte)| [*background_byte, *mask_byte])
        .collect::<Vec<u8>>();

    let debug_path = asset_dir.join(format!("dump.bin"));

    fs::write(&debug_path, image_block).unwrap();

    debug_path
}
