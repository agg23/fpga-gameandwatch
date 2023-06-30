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
    #[serde(rename = "$value")]
    pub items: Vec<NameElementChildren>,
}

#[derive(PartialEq, Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum NameElementChildren {
    Image(Image),
    Rect(Rect),
}

#[derive(PartialEq, Debug, Deserialize)]
pub struct Image {}

#[derive(PartialEq, Debug, Deserialize)]
pub struct Rect {}

#[derive(Clone, Debug, Deserialize)]
pub struct View {
    pub name: String,
    // element: Vec<RefElement>,
    // pub screen: Vec<Screen>,
    #[serde(rename = "$value")]
    pub items: Vec<ViewElement>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ViewElement {
    Bounds(CompleteBounds),
    #[serde(alias = "bezel")]
    Element(Element),
    Overlay(Element),
    Screen(Screen),
}

#[derive(Clone, Debug, Deserialize)]
pub struct XYBounds {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

#[derive(Clone, Debug, Deserialize)]
pub struct CompleteBounds {
    // Standard XY
    pub x: Option<i32>,
    pub y: Option<i32>,
    pub width: Option<i32>,
    pub height: Option<i32>,

    // Center
    pub xc: Option<i32>,
    pub yc: Option<i32>,

    // LeftRight
    pub left: Option<i32>,
    pub right: Option<i32>,
    pub top: Option<i32>,
    pub bottom: Option<i32>,
}

#[derive(Clone, Debug)]
pub struct Bounds {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

// This is written in such garbage form because serde_xml_rs doesn't support untagged enums, so I can't get it to
// properly build enums with the different Bounds variants
impl CompleteBounds {
    pub fn to_xy(&self) -> Bounds {
        if let (Some(x), Some(y), Some(width), Some(height)) =
            (self.x, self.y, self.width, self.height)
        {
            // XY
            Bounds {
                x,
                y,
                width,
                height,
            }
        } else if let (Some(xc), Some(yc), Some(width), Some(height)) =
            (self.xc, self.yc, self.width, self.height)
        {
            // Center
            Bounds {
                x: xc - width,
                y: yc - height,
                width: width,
                height: height,
            }
        } else if let (Some(left), Some(right), Some(top), Some(bottom)) =
            (self.left, self.right, self.top, self.bottom)
        {
            Bounds {
                x: left,
                y: top,
                width: right - left,
                height: bottom - top,
            }
        } else {
            panic!("Bounds appear to have an invalid format {self:?}");
        }
    }
}

#[derive(Clone, Debug, Deserialize)]
pub struct Element {
    #[serde(rename = "ref")]
    #[serde(alias = "element")]
    pub ref_name: String,
    pub bounds: CompleteBounds,
    pub blend: Option<BlendType>,
}

#[derive(Clone, PartialEq, Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum BlendType {
    Add,
    Alpha,
    Multiply,
}

#[derive(Clone, Debug, Deserialize)]
pub struct Screen {
    pub index: i32,
    pub bounds: CompleteBounds,
    pub blend: Option<BlendType>,
}

pub fn parse_layout(
    temp_dir: &Path,
    specified_layout: Option<&String>,
) -> Result<(MameLayout, View), String> {
    let layout_path = temp_dir.join("default.lay");
    let layout_file = match fs::read(&layout_path) {
        Ok(layout_file) => layout_file,
        Err(_) => {
            return Err(format!(
                "Could not find default.lay file at path {layout_path:?}"
            ))
        }
    };

    // let output: MameLayout = match serde_xml_rs::from_reader(layout_file.as_slice()) {
    //     Ok(output) => output,
    //     Err(err) => {
    //         return Err(format!("Could not parse layout: \"{err}\""))},
    // };
    let output: MameLayout = serde_xml_rs::from_reader(layout_file.as_slice()).unwrap();

    let mut map = HashMap::<String, View>::new();

    for view in output.view.iter() {
        map.insert(view.name.to_lowercase(), view.clone());
    }

    if let Some(specified_layout) = specified_layout {
        if let Some(view) = map.remove(&specified_layout.trim().to_lowercase()) {
            return Ok((output, view));
        } else {
            return Err(format!("Could not find view named \"{specified_layout}\""));
        }
    }

    guard!(let Some(view) = select_view(&mut map) else {
        return Err("Could not find suitable view".to_string());
    });

    Ok((output, view))
}

fn select_view<'a>(views: &mut HashMap<String, View>) -> Option<View> {
    // Constructed this way to give ordered priority to each view name we want
    let desired_names = vec![
        "backgrounds only (no frame)",
        "background only (no frame)",
        "backgrounds only (no shadow)",
        "background only (no shadow)",
        "backgrounds only",
        "background only",
        "background",
        "handheld layout",
        "external layout",
        "screen focus",
        "unit only",
    ];

    for name in desired_names {
        if let Some(view) = views.remove(name) {
            return Some(view);
        }
    }

    None
}
