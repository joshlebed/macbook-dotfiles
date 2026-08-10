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

const app_bundle_identifiers_with_option_f_to_toggle_case_and_word_search = [
  "com\\.microsoft\\.VSCode",
  "com\\.todesktop\\.230313mzl4w4u92", // cursor
];

// Mouse layer: caps + control turns the right hand into a pointer.
//
// This is the fallback for having no working mouse — including the one case
// other automation can't cover. Karabiner emits these events through its
// virtual HID device, so the window server treats them as real hardware.
// macOS security prompts (e.g. "iTerm would like to use Bluetooth") ignore
// synthetic clicks from Hammerspoon or AppleScript, but accept these — and
// that prompt is exactly what stands between you and re-pairing a mouse.
const pointer_speed = 1536;
const pointer_precise_speed = 250;
const pointer_scroll_speed = 32;

const pointer_direction_keys = [
  { key_code: "i", axis: "y", direction: -1 },
  { key_code: "k", axis: "y", direction: 1 },
  { key_code: "j", axis: "x", direction: -1 },
  { key_code: "l", axis: "x", direction: 1 },
];

// The plain and shift-held variants can't collide regardless of order: a
// manipulator matches only when every pressed modifier appears in its
// mandatory or optional set, so control+shift never matches the control-only
// entry. Nothing else in nav_mode claims control on these keys either.
const mouse_mappings = [
  ...pointer_direction_keys.map(({ key_code, axis, direction }) => ({
    from: { key_code, modifiers: { mandatory: ["control"] } },
    to: { mouse_key: { [axis]: direction * pointer_speed } },
  })),
  ...pointer_direction_keys.map(({ key_code, axis, direction }) => ({
    from: { key_code, modifiers: { mandatory: ["control", "shift"] } },
    to: { mouse_key: { [axis]: direction * pointer_precise_speed } },
  })),
  // hold a click key while moving with ijkl to drag
  {
    from: { key_code: "semicolon", modifiers: { mandatory: ["control"] } },
    to: { pointing_button: "button1" },
  },
  {
    from: { key_code: "quote", modifiers: { mandatory: ["control"] } },
    to: { pointing_button: "button2" },
  },
  // vertical_wheel is a raw HID wheel delta, so macOS natural scrolling
  // decides which way the content actually goes: negative scrolls up here.
  {
    from: { key_code: "p", modifiers: { mandatory: ["control"] } },
    to: { mouse_key: { vertical_wheel: -pointer_scroll_speed } },
  },
  {
    from: { key_code: "slash", modifiers: { mandatory: ["control"] } },
    to: { mouse_key: { vertical_wheel: pointer_scroll_speed } },
  },
];

const nav_mappings = [
  // mouse layer — defined above, gated behind nav_mode like everything else
  // (caps+control; must stay first so it wins over the plain ijkl arrows)
  ...mouse_mappings,
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

  // caps + v for chatgpt hotkey
  {
    type: "basic",
    from: { key_code: "v" },
    to: {
      key_code: "v",
      modifiers: ["left_command", "left_option", "left_control"],
    },
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

// Option + ijkl = command + shift + arrows, with or without caps held.
//
// Placed *before* nav_mode_rule in the rules list on purpose. Karabiner
// evaluates the flattened manipulator list top to bottom and applies only the
// first match, so sitting ahead of nav_mode is what makes this binding
// genuinely caps-independent — and stops a future nav_mode binding on ijkl
// from silently shadowing it.
//
// The strict `mandatory: ["option"]` with no optional modifiers is the whole
// safety story: a manipulator matches only when every pressed modifier is
// listed, so command+option+i never reaches this rule. That leaves Chrome's
// cmd+opt+i / cmd+opt+j (devtools, console) and nav_mode's caps+cmd+ijkl
// page/word jumps untouched. Adding `optional: ["any"]` here would break all
// of them.
//
// Mandatory modifiers are removed from the to event, so the app receives a
// clean cmd+shift+arrow: the option flag is consumed rather than riding along
// as cmd+shift+opt+arrow, and option never reaches the app as the dead-key
// composer that bare option+i normally is.
const option_arrow_direction_keys = [
  { key_code: "i", arrow: "up_arrow" },
  { key_code: "k", arrow: "down_arrow" },
  { key_code: "j", arrow: "left_arrow" },
  { key_code: "l", arrow: "right_arrow" },
];

const option_ijkl_arrows = {
  description: "option + ijkl = command + shift + arrows",
  manipulators: option_arrow_direction_keys.map(({ key_code, arrow }) => ({
    type: "basic",
    from: { key_code, modifiers: { mandatory: ["option"] } },
    to: { key_code: arrow, modifiers: ["left_command", "left_shift"] },
  })),
};

// TODO: fix this so shift + press cmd, option + press cmd, etc does nothing
const command_for_raycast = {
  description: "tap command to open raycast",
  manipulators: [
    {
      type: "basic",
      from: { key_code: "left_command", modifiers: { optional: ["any"] } },
      to: [{ key_code: "left_command", lazy: true }],
      to_if_alone: [{ key_code: "spacebar", modifiers: ["left_option"] }],
    },
  ],
};

const option_f_to_toggle_case_and_word_search = {
  type: "basic",
  conditions: [
    {
      type: "frontmost_application_if",
      bundle_identifiers:
        app_bundle_identifiers_with_option_f_to_toggle_case_and_word_search,
    },
  ],
  from: { key_code: "f", modifiers: { mandatory: ["left_option"] } },
  to: [
    {
      key_code: "w",
      modifiers: ["left_command", "left_option"],
    },
    {
      key_code: "c",
      modifiers: ["left_command", "left_option"],
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
    option_f_to_toggle_case_and_word_search,
    // clear all notifications
    {
      type: "basic",
      from: {
        key_code: "4",
        modifiers: { mandatory: ["option", "shift"] },
      },
      to: {
        shell_command:
          "/Users/joshlebed/.config/scripts/clear-notifications.sh",
      },
    },
    // excel formatting
    // relies on the cmd + option + n/b shortcuts as excel macros
    {
      type: "basic",
      conditions: [
        {
          type: "frontmost_application_if",
          bundle_identifiers: ["com\\.microsoft\\.Excel"],
        },
      ],
      from: { key_code: "hyphen", modifiers: { mandatory: ["command"] } },
      to: { key_code: "b", modifiers: ["left_command", "left_option"] },
    },
    {
      type: "basic",
      conditions: [
        {
          type: "frontmost_application_if",
          bundle_identifiers: ["com\\.microsoft\\.Excel"],
        },
      ],
      from: { key_code: "equal_sign", modifiers: { mandatory: ["command"] } },
      to: { key_code: "n", modifiers: ["left_command", "left_option"] },
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
      // must precede nav_mode_rule — see the comment on option_ijkl_arrows
      option_ijkl_arrows,
      nav_mode_rule,
      command_for_raycast,
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
