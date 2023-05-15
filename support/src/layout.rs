use std::fs;

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
    pub x: usize,
    pub y: usize,
    pub width: usize,
    pub height: usize,
}

#[derive(Debug, Deserialize)]
pub struct Element {
    #[serde(rename = "ref")]
    pub ref_name: String,
    pub bounds: Bounds,
}

#[derive(Debug, Deserialize)]
pub struct Screen {
    pub index: usize,
    pub bounds: Bounds,
}

pub fn parse_layout() -> Result<View, String> {
    let layout_file = fs::read("assets/default.lay").unwrap();

    let output: MameLayout = serde_xml_rs::from_reader(layout_file.as_slice()).unwrap();

    guard!(let Some(background_only) = output.view.into_iter().filter(|v| v.name.to_lowercase().starts_with("backgrounds only")).next() else {
        return Err("Could not find view settings".to_string());
    });

    return Ok(background_only);
}
