// unused - just for reference
const global = {
  ask_for_confirmation_before_quitting: true,
  check_for_updates_on_startup: true,
  show_in_menu_bar: true,
  show_profile_name_in_menu_bar: false,
  unsafe_ui: false,
};

// unused -just for reference
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
      from: { key_code: "caps_lock", modifiers: { optional: ["any"] } },
      to: [{ set_variable: { name: "nav_mode", value: 1 } }],
      to_after_key_up: [{ set_variable: { name: "nav_mode", value: 0 } }],
      to_if_alone: [{ key_code: "escape" }],
      type: "basic",
    },
  ],
};

const app_bundle_identifiers_with_command_shift_w_to_close_window = [
  "com\\.googlecode\\.iterm2",
  "com\\.microsoft\\.VSCode",
  "com\\.google\\.Chrome",
  "com\\.apple\\.finder",
];

const nav_mappings = [
  { from: { key_code: "quote" }, to: { key_code: "return_or_enter" } },
  // text nav
  {
    from: { key_code: "i", modifiers: { optional: ["shift"] } },
    to: { key_code: "up_arrow" },
  },
  {
    from: { key_code: "k", modifiers: { optional: ["shift"] } },
    to: { key_code: "down_arrow" },
  },
  {
    from: { key_code: "j", modifiers: { optional: ["shift"] } },
    to: { key_code: "left_arrow" },
  },
  {
    from: { key_code: "l", modifiers: { optional: ["shift"] } },
    to: { key_code: "right_arrow" },
  },
  {
    from: { key_code: "h", modifiers: { optional: ["shift"] } },
    to: { key_code: "left_arrow", modifiers: ["left_option"] },
  },
  {
    from: { key_code: "semicolon", modifiers: { optional: ["shift"] } },
    to: { key_code: "right_arrow", modifiers: ["left_option"] },
  },
  // text nav holding command
  {
    from: {
      key_code: "i",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "page_up" },
  },
  {
    from: {
      key_code: "k",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "page_down" },
  },
  {
    from: {
      key_code: "j",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "left_arrow", modifiers: ["left_command"] },
  },
  {
    from: {
      key_code: "l",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "right_arrow", modifiers: ["left_command"] },
  },
  {
    from: {
      key_code: "h",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "left_arrow", modifiers: ["left_command"] },
  },
  {
    from: {
      key_code: "semicolon",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "right_arrow", modifiers: ["left_command"] },
  },
  // tab nav
  {
    type: "basic",
    conditions: [
      {
        type: "frontmost_application_unless",
        bundle_identifiers: ["com\\.quip\\.Desktop"],
      },
    ],
    from: { key_code: "u", modifiers: { optional: ["option"] } },
    to: { key_code: "tab", modifiers: ["left_control", "left_shift"] },
  },
  {
    type: "basic",
    conditions: [
      {
        type: "frontmost_application_unless",
        bundle_identifiers: ["com\\.quip\\.Desktop"],
      },
    ],
    from: { key_code: "o", modifiers: { optional: ["option"] } },
    to: { key_code: "tab", modifiers: ["left_control"] },
  },
  {
    type: "basic",
    conditions: [
      {
        type: "frontmost_application_if",
        bundle_identifiers: ["com\\.quip\\.Desktop"],
      },
    ],
    from: { key_code: "u", modifiers: { optional: ["option"] } },
    to: { key_code: "left_arrow", modifiers: ["left_option", "left_command"] },
  },
  {
    type: "basic",
    conditions: [
      {
        type: "frontmost_application_if",
        bundle_identifiers: ["com\\.quip\\.Desktop"],
      },
    ],
    from: { key_code: "o", modifiers: { optional: ["option"] } },
    to: { key_code: "right_arrow", modifiers: ["left_option", "left_command"] },
  },
  // vscode nav
  // vscode change tab groups left/right
  {
    from: { key_code: "u", modifiers: { mandatory: ["command"] } },
    to: { key_code: "f13", modifiers: ["left_control"] },
  },
  {
    from: { key_code: "o", modifiers: { mandatory: ["command"] } },
    to: { key_code: "f13", modifiers: ["left_control", "left_shift"] },
  },
  // vscode search results nav up/down
  {
    from: { key_code: "open_bracket" },
    to: {
      key_code: "open_bracket",
      modifiers: ["left_control", "left_command", "left_option"],
    },
  },
  {
    from: { key_code: "close_bracket" },
    to: {
      key_code: "close_bracket",
      modifiers: ["left_control", "left_command", "left_option"],
    },
  },
  // hop through vscode search results
  {
    from: { key_code: "m", modifiers: { mandatory: ["command"] } },
    to: {
      key_code: "open_bracket",
      modifiers: ["left_control", "left_command", "left_option"],
    },
  },
  {
    from: { key_code: "period", modifiers: { mandatory: ["command"] } },
    to: {
      key_code: "close_bracket",
      modifiers: ["left_control", "left_command", "left_option"],
    },
  },

  // spaces nav
  {
    from: { key_code: "d" },
    to: { key_code: "left_arrow", modifiers: ["left_control"] },
  },
  {
    from: { key_code: "f" },
    to: { key_code: "right_arrow", modifiers: ["left_control"] },
  },
  {
    from: { key_code: "g" },
    to: {
      key_code: "f17",
      modifiers: ["left_option", "left_shift", "left_command"],
    },
  },
  {
    from: {
      key_code: "d",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: {
      key_code: "f16",
      modifiers: ["left_option", "left_shift", "left_command"],
    },
  },
  {
    from: {
      key_code: "f",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "f16", modifiers: ["left_option", "left_command"] },
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
    from: { key_code: "a" },
    to: {
      shell_command:
        'echo "tell application \\"System Events\\" to key code 48 using command down" | osascript',
    },
  },
  {
    from: { key_code: "e" },
    to: { key_code: "f16", modifiers: ["left_shift"] },
  },
  { from: { key_code: "r" }, to: { key_code: "f16" } },
  {
    from: {
      key_code: "e",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "f16", modifiers: ["left_command", "left_shift"] },
  },
  {
    from: {
      key_code: "r",
      modifiers: { mandatory: ["command"], optional: ["any"] },
    },
    to: { key_code: "f16", modifiers: ["left_command"] },
  },
  {
    conditions: [
      {
        type: "frontmost_application_if",
        bundle_identifiers:
          app_bundle_identifiers_with_command_shift_w_to_close_window,
      },
    ],
    from: { key_code: "w" },
    to: { key_code: "w", modifiers: ["left_command", "left_shift"] },
  },
  {
    conditions: [
      {
        type: "frontmost_application_unless",
        bundle_identifiers:
          app_bundle_identifiers_with_command_shift_w_to_close_window,
      },
    ],
    from: { key_code: "w" },
    to: { key_code: "w", modifiers: ["left_command"] },
  },
  {
    from: { key_code: "spacebar" },
    to: {
      key_code: "equal_sign",
      modifiers: ["left_command", "left_shift", "left_control"],
    },
  },
  // forward/back
  {
    conditions: [
      {
        type: "frontmost_application_unless",
        bundle_identifiers: ["net.whatsapp.WhatsApp"],
      },
    ],
    from: { key_code: "m" },
    to: { key_code: "open_bracket", modifiers: ["left_command"] },
  },
  {
    conditions: [
      {
        type: "frontmost_application_unless",
        bundle_identifiers: ["net.whatsapp.WhatsApp"],
      },
    ],
    from: { key_code: "period" },
    to: { key_code: "close_bracket", modifiers: ["left_command"] },
  },
  // forward/back for whatsapp
  {
    conditions: [
      {
        type: "frontmost_application_if",
        bundle_identifiers: ["net.whatsapp.WhatsApp"],
      },
    ],
    from: { key_code: "m" },
    to: {
      key_code: "open_bracket",
      modifiers: ["left_command", "left_shift"],
    },
  },
  {
    conditions: [
      {
        type: "frontmost_application_if",
        bundle_identifiers: ["net.whatsapp.WhatsApp"],
      },
    ],
    from: { key_code: "period" },
    to: {
      key_code: "close_bracket",
      modifiers: ["left_command", "left_shift"],
    },
  },

  // delete/backspace
  {
    from: { key_code: "delete_or_backspace" },
    to: { key_code: "delete_forward" },
  },
];

const nav_mode_rule = {
  description: "nav_mode",
  manipulators: nav_mappings.map((item) => ({
    ...item,
    conditions: (item.conditions || []).concat([
      { name: "nav_mode", type: "variable_if", value: 1 },
    ]),
    type: "basic",
  })),
};

// TODO: fix this so shift + press cmd, alt + press cmd, etc does nothing
const command_for_alfred = {
  description: "tap command to open alfred",
  manipulators: [
    {
      type: "basic",
      from: { key_code: "left_command", modifiers: { optional: ["any"] } },
      to: [{ key_code: "left_command", lazy: true }],
      to_if_alone: [{ key_code: "spacebar", modifiers: ["left_option"] }],
    },
  ],
};

const option_for_notifications = {
  description: "tap option to open notification panel",
  manipulators: [
    {
      type: "basic",
      from: { key_code: "left_option", modifiers: { optional: ["any"] } },
      to: [{ key_code: "left_option", lazy: true }],
      to_if_alone: [
        {
          key_code: "f8",
          modifiers: ["left_option", "left_control", "left_command"],
        },
      ],
    },
  ],
};

const misc_shortcuts = {
  description: "miscellaneous shortcuts",
  manipulators: [
    {
      type: "basic",
      conditions: [
        {
          type: "frontmost_application_if",
          bundle_identifiers: ["com\\.apple\\.finder"],
        },
      ],
      from: { key_code: "w", modifiers: { mandatory: ["left_command"] } },
      to: { key_code: "w", modifiers: ["left_command", "left_shift"] },
    },
    {
      type: "basic",
      from: { key_code: "f11", modifiers: { mandatory: ["left_command"] } },
      to: { shell_command: "~/code/ddcctl/ddcctl.sh down" },
    },
    {
      type: "basic",
      from: { key_code: "f12", modifiers: { mandatory: ["left_command"] } },
      to: { shell_command: "~/code/ddcctl/ddcctl.sh up" },
    },
    {
      type: "basic",
      from: { key_code: "h", modifiers: { mandatory: ["left_command"] } },
      to: { key_code: "f", modifiers: ["left_command", "left_option"] },
    },
    {
      type: "basic",
      from: { key_code: "f17" },
      to: {
        key_code: "volume_decrement",
        modifiers: ["left_shift", "left_option"],
      },
    },
    {
      type: "basic",
      from: { key_code: "f18" },
      to: {
        key_code: "volume_increment",
        modifiers: ["left_shift", "left_option"],
      },
    },
    {
      type: "basic",
      from: { key_code: "f17", modifiers: { mandatory: ["left_shift"] } },
      to: { key_code: "volume_decrement" },
    },
    {
      type: "basic",
      from: { key_code: "f18", modifiers: { mandatory: ["left_shift"] } },
      to: { key_code: "volume_increment" },
    },
    {
      type: "basic",
      conditions: [
        {
          type: "frontmost_application_if",
          bundle_identifiers: ["com\\.tinyspeck\\.slackmacgap"],
        },
      ],
      from: { key_code: "p", modifiers: { mandatory: ["command"] } },
      to: { key_code: "k", modifiers: ["left_command"] },
    },
    // quip cmd + p for file opener
    {
      type: "basic",
      conditions: [
        {
          type: "frontmost_application_if",
          bundle_identifiers: ["com\\.quip\\.Desktop"],
        },
      ],
      from: { key_code: "p", modifiers: { mandatory: ["command"] } },
      to: { key_code: "j", modifiers: ["left_command"] },
    },
    // quip cmd + shift + p for command palate ("command library")
    {
      type: "basic",
      conditions: [
        {
          type: "frontmost_application_if",
          bundle_identifiers: ["com\\.quip\\.Desktop"],
        },
      ],
      from: { key_code: "p", modifiers: { mandatory: ["command", "shift"] } },
      to: { key_code: "j", modifiers: ["left_command", "left_shift"] },
    },
  ],
};

const switch_command_and_option = [
  { from: { key_code: "left_command" }, to: [{ key_code: "left_option" }] },
  { from: { key_code: "left_option" }, to: [{ key_code: "left_command" }] },
  { from: { key_code: "right_command" }, to: [{ key_code: "right_option" }] },
  { from: { key_code: "right_option" }, to: [{ key_code: "right_command" }] },
];

const tetris_key_substitutions = [
  { from: { key_code: "caps_lock" }, to: [{ key_code: "escape" }] },
  { from: { key_code: "escape" }, to: [{ key_code: "caps_lock" }] },
  { from: { key_code: "left_option" }, to: [{ key_code: "v" }] },
];

// unused - just for reference
const fn_function_keys = [
  {
    from: { key_code: "f1" },
    to: { consumer_key_code: "display_brightness_decrement" },
  },
  {
    from: { key_code: "f2" },
    to: { consumer_key_code: "display_brightness_increment" },
  },
  { from: { key_code: "f3" }, to: { key_code: "mission_control" } },
  { from: { key_code: "f4" }, to: { key_code: "launchpad" } },
  { from: { key_code: "f5" }, to: { key_code: "illumination_decrement" } },
  { from: { key_code: "f6" }, to: { key_code: "illumination_increment" } },
  { from: { key_code: "f7" }, to: { consumer_key_code: "rewind" } },
  { from: { key_code: "f8" }, to: { consumer_key_code: "play_or_pause" } },
  { from: { key_code: "f9" }, to: { consumer_key_code: "fast_forward" } },
  { from: { key_code: "f10" }, to: { consumer_key_code: "mute" } },
  { from: { key_code: "f11" }, to: { consumer_key_code: "volume_decrement" } },
  { from: { key_code: "f12" }, to: { consumer_key_code: "volume_increment" } },
];

const fn_function_keys_normal = [
  { from: { key_code: "f1" }, to: [{ key_code: "f1" }] },
  { from: { key_code: "f2" }, to: [{ key_code: "f2" }] },
  { from: { key_code: "f3" }, to: [{ key_code: "f3" }] },
  { from: { key_code: "f4" }, to: [{ key_code: "f4" }] },
  { from: { key_code: "f5" }, to: [{ key_code: "f5" }] },
  { from: { key_code: "f6" }, to: [{ key_code: "f6" }] },
  { from: { key_code: "f7" }, to: [{ key_code: "f7" }] },
  { from: { key_code: "f8" }, to: [{ key_code: "f8" }] },
  { from: { key_code: "f9" }, to: [{ key_code: "f9" }] },
  { from: { key_code: "f10" }, to: [{ key_code: "f10" }] },
  { from: { key_code: "f11" }, to: [{ key_code: "f11" }] },
  { from: { key_code: "f12" }, to: [{ key_code: "f12" }] },
];

const devices = [
  {
    fn_function_keys: fn_function_keys_normal,
    identifiers: {
      is_keyboard: true,
      is_pointing_device: true,
      product_id: 832,
      vendor_id: 1452,
    },
    ignore: false,
    manipulate_caps_lock_led: false,
  },
  {
    fn_function_keys: fn_function_keys_normal,
    identifiers: {
      is_keyboard: true,
      product_id: 4,
      vendor_id: 9494,
    },
    manipulate_caps_lock_led: false,
    simple_modifications: switch_command_and_option,
  },
  {
    fn_function_keys: fn_function_keys_normal,
    identifiers: {
      is_keyboard: true,
      product_id: 6505,
      vendor_id: 12951,
    },
    manipulate_caps_lock_led: false,
    simple_modifications: switch_command_and_option,
  },
];

const virtual_hid_keyboard = { country_code: 0, keyboard_type_v2: "ansi" };

const global_vim_profile = {
  complex_modifications: {
    rules: [
      caps_lock_toggler,
      nav_mode_rule,
      command_for_alfred,
      option_for_notifications,
      misc_shortcuts,
    ],
  },
  virtual_hid_keyboard: virtual_hid_keyboard,
  devices: devices,
  selected: true,
  name: "Global VIM",
};

const tetris_profile = {
  virtual_hid_keyboard: virtual_hid_keyboard,
  simple_modifications: tetris_key_substitutions,
  name: "Tetris",
};

const empty_profile = {
  name: "Empty profile",
  devices: devices,
};

const config = {
  profiles: [global_vim_profile, tetris_profile, empty_profile],
};

export default config;
