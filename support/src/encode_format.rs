use std::{
    fs,
    path::{Path, PathBuf},
};

use bitvec::{
    field::BitField,
    prelude::{bitvec, Msb0},
};

use crate::{HEIGHT, WIDTH};

pub fn encode(
    background_bytes: &[u8],
    mask_bytes: &[u8],
    pixels_to_mask_id: &[Option<u16>],
    asset_dir: &Path,
) -> PathBuf {
    let background_iter = background_bytes.into_iter();
    let mask_iter = mask_bytes.into_iter();

    let mut count = 0;

    let image_block = background_iter
        .zip(mask_iter)
        .filter(|_| {
            let prev_count = count;
            // Drop every 4th (alpha) byte
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

    let mask_block = build_mask_map(pixels_to_mask_id);

    let debug_path = asset_dir.join(format!("dump2.bin"));

    fs::write(&debug_path, mask_block).unwrap();

    debug_path
}

const BYTES_PER_ENTRY: usize = 5;
const AVERAGE_ENTRIES_PER_ROW: usize = 26;
const TOTAL_BYTE_LENGTH: usize = BYTES_PER_ENTRY * AVERAGE_ENTRIES_PER_ROW * HEIGHT;

fn build_mask_map(pixels_to_mask_id: &[Option<u16>]) -> Vec<u8> {
    // 5 bytes per entry
    let mut output: Vec<u8> = vec![0; TOTAL_BYTE_LENGTH];
    let mut byte_index = 0;

    for y in 0..HEIGHT {
        let mut current_id: Option<u16> = None;
        let mut start_x: usize = 0;
        let mut length: usize = 0;

        for x in 0..WIDTH {
            if let Some(id) = pixels_to_mask_id[y * WIDTH + x] {
                // Has id
                if current_id.is_none() {
                    // Begin entry
                    current_id = Some(id);
                    start_x = x;
                    length = 1;
                } else {
                    // Increment current entry
                    length += 1;
                }
            } else {
                // No id
                if let Some(id) = current_id {
                    // End entry
                    current_id = None;

                    output[byte_index..byte_index + BYTES_PER_ENTRY]
                        .clone_from_slice(&entry_to_bytes(id, length, start_x, y));

                    byte_index += BYTES_PER_ENTRY;
                }
            }
        }

        if let Some(id) = current_id {
            output[byte_index..byte_index + BYTES_PER_ENTRY]
                .clone_from_slice(&entry_to_bytes(id, length, start_x, y));

            byte_index += BYTES_PER_ENTRY;
        }

        if byte_index > TOTAL_BYTE_LENGTH {
            println!(
                "More entries ({}) than allowed ({TOTAL_BYTE_LENGTH})",
                byte_index
            );
        }
    }

    output
}

// fn entry_to_bytes(id: u16, length: usize, start_x: usize) -> Vec<u8> {
//     let mut data: Vec<u8> = vec![];

//     // line 10: [id 12bit][x 10bit][length 10bit]...next
//     // id: 12 bits
//     data.push((id >> 4) as u8);

//     // x: 10 bits - 4 bits id, 4 bits x
//     data.push(((id << 4) | (start_x as u16 >> 6)) as u8);

//     // length: 10 bits - 6 bits x, 2 bits length
//     data.push(((start_x << 2) | (length >> 8)) as u8);
//     // - 8 bits length
//     data.push((length >> 2) as u8);

//     data
// }

fn entry_to_bytes(id: u16, length: usize, start_x: usize, y: usize) -> Vec<u8> {
    let mut data = bitvec![u8, Msb0; 0; 5*8];
    // let data = bits![u8, Msb0; 5 * 8];

    data[0..10].store::<u16>(id);
    data[10..20].store::<u16>(start_x as u16);
    data[20..30].store::<u16>(y as u16);
    data[30..40].store::<u16>(length as u16);

    data.into()
}
