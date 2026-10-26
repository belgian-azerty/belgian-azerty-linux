# How keyd 2.5.0 (Debian 2.5.0-5 + 0012, as shipped in 0.9.4) chooses devices with our `[ids] *`

Read from the shipped source (dist/keyd_2.5.0.orig.tar.gz + debian patches), 2026-10-25, REVIEW-3.

- `src/device.c` resolve_device_capabilities(): a node is a KEYBOARD if it has all of KEY_1..KEY_0, Q W E R T Y, or
  KEY_BRIGHTNESSUP; it is a MOUSE if it has any EV_REL or EV_ABS axis. A node can be both.
- `src/daemon.c` lookup_config_ent(): "The wildcard should not match mice": a wildcard match (rank 1) is refused only
  when flags == ID_MOUSE exactly. A node that is keyboard AND mouse (flags == ID_KEYBOARD|ID_MOUSE) IS grabbed by `*`.
- `src/config.c` parse_id_section(): `*` is a bare wildcard; there is no `k:*` form, so the config cannot say
  "wildcard, keyboard-only nodes". Exclusions are per device id (`-vvvv:pppp`).
- `src/device.c` device_read_event(): of a grabbed node's pointer events keyd forwards only REL_X, REL_Y, REL_WHEEL,
  REL_HWHEEL, ABS_X, ABS_Y (scaled to 0..1024, ignoring the axis minimum) and BTN_* to "keyd virtual pointer".
  REL_WHEEL_HI_RES / REL_HWHEEL_HI_RES are commented out ("TODO"); every other EV_ABS code (all multitouch ABS_MT_*)
  is dropped.
- keyd's own man page (docs/keyd.rvaiya.scdoc, Note 3): "Mouse support is currently experimental ... It may also be
  necessary to explicitly blacklist mice which are misidentified as keyboards (e.g if you find your mouse misbehaving)."

Consequence (strong inference from the code, not tested): on a device whose touchpad or mouse shares ONE evdev node
with full keyboard keys (some keyboard+touchpad combos, some wireless receivers, some gaming mice with macro keys),
keyd grabs that node; pointer motion then goes through keyd's virtual pointer, high-resolution scrolling is lost, and a
multitouch touchpad on such a node would lose gestures, tap and normal relative motion. Typical laptop touchpads and
TrackPoints are separate pointer-only nodes and are NOT grabbed.

Evidence that the usual case is fine:
- Emulator journals: keyd "ignoring" QEMU USB Tablet, ImExPS/2 mouse, VMware VMMouse, keyd virtual pointer; "match"
  only the keyboards (evidence/raw-logs/2026-10-24-extra-tests/mint/mint-dd-*-probe.txt,
  evidence/raw-logs/installed-run-2026-10-24/boot2-journal.txt).
- T14s real hardware (0.9.1): touchpad worked (Younes's first-hand report, DECISIONS 21:39); the results file lists
  keyboards "Sleep Button;Power Button;AT Translated Set 2 keyboard;Intel HID events;ThinkPad Extra Buttons;Video
  Bus;keyd virtual keyboard" and no touchpad among them (evidence/t14s/belgian-t14s-results.txt line 19).
