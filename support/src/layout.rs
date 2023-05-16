use std::{collections::HashMap, fs, path::Path};

use serde::Deserialize;

use serde_xml_rs;

#[derive(Debug, Deserialize)]
pub struct MameLayout {
    pub element: Vec<NameElement>,
    pub view: Vec<View>,
}

#[derive(Debug, Deserialize)]
pub struct NameElement {
    pub name: String,
}

#[derive(Debug, Deserialize)]
pub struct View {
    pub name: String,
    // element: Vec<RefElement>,
    // pub screen: Vec<Screen>,
    #[serde(rename = "$value")]
    pub items: Vec<ViewElement>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ViewElement {
    Bounds(Bounds),
    Element(Element),
    Screen(Screen),
}

#[derive(Clone, Debug, Deserialize)]
pub struct Bounds {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

#[derive(Debug, Deserialize)]
pub struct Element {
    #[serde(rename = "ref")]
    pub ref_name: String,
    pub bounds: Bounds,
}

#[derive(Debug, Deserialize)]
pub struct Screen {
    pub index: i32,
    pub bounds: Bounds,
}

pub fn parse_layout(temp_dir: &Path) -> Result<View, String> {
    let layout_path = temp_dir.join("default.lay");
    let layout_file = fs::read(layout_path).unwrap();

    let output: MameLayout = serde_xml_rs::from_reader(layout_file.as_slice()).unwrap();

    let mut map = HashMap::<String, View>::new();

    for view in output.view {
        map.insert(view.name.to_lowercase(), view);
    }

    guard!(let Some(view) = select_view(&mut map) else {
        return Err("Could not find suitable view".to_string());
    });

    Ok(view)
}

fn select_view(views: &mut HashMap<String, View>) -> Option<View> {
    if let Some(view) = views.remove("backgrounds only (no shadow)") {
        Some(view)
    } else if let Some(view) = views.remove("backgrounds only (no shadow)") {
        Some(view)
    } else {
        None
    }
}
