const global = {
  check_for_updates_on_startup: true,
  show_in_menu_bar: true,
  show_profile_name_in_menu_bar: false,
};
const parameters = {
  "basic.simultaneous_threshold_milliseconds": 50,
  "basic.to_delayed_action_delay_milliseconds": 500,
  "basic.to_if_alone_timeout_milliseconds": 1000,
  "basic.to_if_held_down_threshold_milliseconds": 500,
  "mouse_motion_to_scroll.speed": 100,
};
const caps_lock_toggler = {
  description: "caps_lock as nav_mode toggle",
  manipulators: [
    {
      from: {
        key_code: "caps_lock",
        modifiers: { optional: ["any"] },
      },
      to: [
        {
          set_variable: {
            name: "nav_mode",
            value: 1,
          },
        },
      ],
      to_after_key_up: [
        {
          set_variable: {
            name: "nav_mode",
            value: 0,
          },
        },
      ],
      to_if_alone: [
        {
          key_code: "escape",
        },
      ],
      type: "basic",
    },
  ],
};
const nav_mappings = [
  // text nav
  {
    from: {
      key_code: "i",
      modifiers: {
        optional: ["shift"],
      },
    },
    to: { key_code: "up_arrow" },
  },
  {
    from: {
      key_code: "k",
      modifiers: {
        optional: ["shift"],
      },
    },
    to: { key_code: "down_arrow" },
  },
  {
    from: {
      key_code: "j",
      modifiers: {
        optional: ["shift"],
      },
    },
    to: { key_code: "left_arrow" },
  },
  {
    from: {
      key_code: "l",
      modifiers: {
        optional: ["shift"],
      },
    },
    to: { key_code: "right_arrow" },
  },
  {
    from: {
      key_code: "h",
      modifiers: {
        optional: ["shift"],
      },
    },
    to: {
      key_code: "left_arrow",
      modifiers: ["left_command"],
    },
  },
  {
    from: {
      key_code: "semicolon",
      modifiers: {
        optional: ["shift"],
      },
    },
    to: {
      key_code: "right_arrow",
      modifiers: ["left_command"],
    },
  },
  // text nav holding command
  {
    from: {
      key_code: "i",
      modifiers: {
        mandatory: ["option"],
        optional: ["any"],
      },
    },
    to: {
      key_code: "page_up",
    },
  },
  {
    from: {
      key_code: "k",
      modifiers: {
        mandatory: ["option"],
        optional: ["any"],
      },
    },
    to: {
      key_code: "page_down",
    },
  },
  {
    from: {
      key_code: "j",
      modifiers: {
        mandatory: ["option"],
        optional: ["any"],
      },
    },
    to: {
      key_code: "home",
    },
  },
  {
    from: {
      key_code: "l",
      modifiers: {
        mandatory: ["option"],
        optional: ["any"],
      },
    },
    to: {
      key_code: "end",
    },
  },
  {
    from: {
      key_code: "h",
      modifiers: {
        mandatory: ["option"],
        optional: ["any"],
      },
    },
    to: {
      key_code: "home",
    },
  },
  {
    from: {
      key_code: "semicolon",
      modifiers: {
        mandatory: ["option"],
        optional: ["any"],
      },
    },
    to: {
      key_code: "end",
    },
  },
  // tab nav
  {
    from: {
      key_code: "u",
      modifiers: {
        optional: ["command"],
      },
    },
    to: {
      key_code: "tab",
      modifiers: ["left_control", "left_shift"],
    },
  },
  {
    from: {
      key_code: "o",
      modifiers: {
        optional: ["command"],
      },
    },
    to: {
      key_code: "tab",
      modifiers: ["left_control"],
    },
  },
  // editor group nav
  {
    from: {
      key_code: "u",
      modifiers: {
        mandatory: ["option"],
      },
    },
    to: {
      key_code: "f13",
      modifiers: ["left_control"],
    },
  },
  {
    from: {
      key_code: "o",
      modifiers: {
        mandatory: ["option"],
      },
    },
    to: {
      key_code: "f13",
      modifiers: ["left_control", "left_shift"],
    },
  },
  // spaces nav
  {
    from: { key_code: "d" },
    to: {
      key_code: "left_arrow",
      modifiers: ["left_control"],
    },
  },
  {
    from: { key_code: "f" },
    to: {
      key_code: "right_arrow",
      modifiers: ["left_control"],
    },
  },
  // window nav
  {
    from: { key_code: "s" },
    to: {
      shell_command:
        'echo "tell application \\"System Events\\" to key code 50 using command down" | osascript',
    },
  },
  {
    from: { key_code: "w" },
    to: {
      key_code: "q",
      modifiers: ["left_option"],
    },
  },
];
const nav_mode = {
  description: "nav_mode",
  manipulators: nav_mappings.map((item) => ({
    ...item,
    conditions: [
      {
        name: "nav_mode",
        type: "variable_if",
        value: 1,
      },
    ],
    type: "basic",
  })),
};
const fn_function_keys = [
  {
    from: {
      key_code: "f1",
    },
    to: {
      consumer_key_code: "display_brightness_decrement",
    },
  },
  {
    from: {
      key_code: "f2",
    },
    to: {
      consumer_key_code: "display_brightness_increment",
    },
  },
  {
    from: {
      key_code: "f3",
    },
    to: {
      key_code: "mission_control",
    },
  },
  {
    from: {
      key_code: "f4",
    },
    to: {
      key_code: "launchpad",
    },
  },
  {
    from: {
      key_code: "f5",
    },
    to: {
      key_code: "illumination_decrement",
    },
  },
  {
    from: {
      key_code: "f6",
    },
    to: {
      key_code: "illumination_increment",
    },
  },
  {
    from: {
      key_code: "f7",
    },
    to: {
      consumer_key_code: "rewind",
    },
  },
  {
    from: {
      key_code: "f8",
    },
    to: {
      consumer_key_code: "play_or_pause",
    },
  },
  {
    from: {
      key_code: "f9",
    },
    to: {
      consumer_key_code: "fast_forward",
    },
  },
  {
    from: {
      key_code: "f10",
    },
    to: {
      consumer_key_code: "mute",
    },
  },
  {
    from: {
      key_code: "f11",
    },
    to: {
      consumer_key_code: "volume_decrement",
    },
  },
  {
    from: {
      key_code: "f12",
    },
    to: {
      consumer_key_code: "volume_increment",
    },
  },
];
const profiles = [
  {
    complex_modifications: {
      parameters,
      rules: [caps_lock_toggler, nav_mode],
    },
    devices: [],
    // fn_function_keys,
    name: "Default profile",
    parameters: {
      delay_milliseconds_before_open_device: 1000,
    },
    selected: true,
    simple_modifications: [],
    virtual_hid_keyboard: {
      country_code: 0,
      mouse_key_xy_scale: 100,
    },
  },
];
const config = {
  global,
  profiles,
};

export default config;
