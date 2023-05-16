use clap::ValueEnum;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PlatformSpecification {
    pub device: PresetDefinition,
    pub port_map: PlatformPortMapping,
}

/* Preset Definition */

#[derive(Debug, Deserialize)]
pub struct PresetDefinition {
    pub cpu: CPUType,
    pub screen: Screen,
}

#[derive(PartialEq, Clone, Debug, Deserialize, ValueEnum)]
#[serde(rename_all = "lowercase")]
pub enum CPUType {
    SM5a,
    KB1013VK12,
    SM510,
    SM511,
    SM512,
    SM530,
    #[serde(rename = "sm510_tiger")]
    SM510Tiger,
    #[serde(rename = "sm511_tiger1bit")]
    SM511Tiger1Bit,
    #[serde(rename = "sm511_tiger2bit")]
    SM511Tiger2Bit,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[serde(tag = "type")]
pub enum Screen {
    Single { width: f32, height: f32 },
    DualVertical { top: Size, bottom: Size },
    DualHorizontal { left: Size, right: Size },
}

#[derive(Debug, Deserialize)]
pub struct Size {
    pub width: f32,
    pub height: f32,
}

/* Input Mapping */

#[derive(Debug, Deserialize)]
pub struct PlatformPortMapping {
    pub ports: Vec<Port>,
    pub include: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
#[serde(tag = "type")]
pub enum Port {
    S {
        index: usize,
        bitmap: [Option<NamedAction>; 4],
    },
    ACL {
        bit: Option<NamedAction>,
    },
    B {
        bit: Option<NamedAction>,
    },
    BA {
        bit: Option<NamedAction>,
    },
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NamedAction {
    pub action: Action,
    pub active_low: bool,
    pub name: Option<String>,
}

#[derive(PartialEq, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Action {
    JoyUp,
    JoyDown,
    JoyLeft,
    JoyRight,
    LeftJoyUp,
    LeftJoyDown,
    LeftJoyLeft,
    LeftJoyRight,
    RightJoyUp,
    RightJoyDown,
    RightJoyLeft,
    RightJoyRight,
    Button1,
    Button2,
    Button3,
    Button4,
    Button5,
    Button6,
    Button7,
    Button8,
    Select,
    Start1,
    Start2,
    Service1,
    Service2,
    VolumeDown,
    PowerOn,
    PowerOff,
    Keypad,
    Custom,
    Unused,
}
