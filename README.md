# Switch2GO AAC Companion

ESP32 single-switch light scanner for a trifold choice board. It lights up to four choices in sequence, takes a long press as a selection, types `1`–`4` plus Enter to the iPad as a Bluetooth keyboard, and can close a dry-contact relay so a power select box sees a switch press.

Wiring, parts, bench tests, and safety notes live in [AAC_Switch_Scanner_Build_Guide.docx](AAC_Switch_Scanner_Build_Guide.docx). This firmware has not been run on hardware. Work through the guide’s Stage 0–10 tests before using it with a student.

This device is **not** the four-switch `Switch2GO-XXXX` dongle. It advertises as **AAC Scanner**. The iPad app lives in a separate repo.

## Firmware

Requires [PlatformIO](https://platformio.org/) (`pio` on the PATH).

```bash
cd firmware
pio run -e scanner            # compile
pio run -e scanner -t upload  # flash
pio device monitor            # 115200 baud
```

Bench sketches from the guide, one env each:

| Env | What it tests |
| --- | --- |
| `scanner` | Full firmware |
| `stage3_led` | 12 WS2812E LEDs on GPIO18 |
| `stage4_switch` | Student jack on GPIO32 |
| `stage5_pause` | Pause button on GPIO33 |
| `stage6_relay` | Relays on GPIO25/26/27/14 |
| `stage7_keyboard` | BLE HID keys only |

Example: `pio run -e stage3_led -t upload`

Pins, brightness cap, and layout table are at the top of [firmware/src/main.cpp](firmware/src/main.cpp). If relay 4 clicks at boot, change `PIN_RELAY[3]` from 14 to 13.

Hold PAUSE while powering on to start config-only BLE (no keyboard) if the iPad cannot reach the custom service while the HID keyboard is connected.

## Prints

Parametric OpenSCAD in [cad/](cad/). Sizes are starting values from the guide — measure your strip, jack, button, and boards, then change the named variables at the top of each file.

```bash
openscad -o /tmp/led_hood.stl cad/led_hood.scad
openscad -o /tmp/edge_clip.stl cad/edge_clip.scad
openscad -D 'part="box"' -o /tmp/case_box.stl cad/electronics_case.scad
openscad -D 'part="lid"' -o /tmp/case_lid.stl cad/electronics_case.scad
```

## BLE contract (for the iPad app)

Device name: `AAC Scanner`

| Item | UUID | Properties |
| --- | --- | --- |
| Scanner service | `A5C00001-7D2B-4F6E-9C31-5B8E2A1D0C4F` | — |
| Config | `A5C00002-7D2B-4F6E-9C31-5B8E2A1D0C4F` | Read, Write |
| Status | `A5C00003-7D2B-4F6E-9C31-5B8E2A1D0C4F` | Read, Notify |
| Command | `A5C00004-7D2B-4F6E-9C31-5B8E2A1D0C4F` | Write |

On a long press the device types the choice number (`1`–`N`) then Enter, unless config flag bit1 is set (physical position instead). Selections still fire the relay when the keyboard is not connected.

**Config** is 29 bytes, version `0x01`, little-endian. Bytes: version, numChoices (1–4), scanTenths, holdTenths, longPressMs, flags (bit0 = send Enter, bit1 = physical-position keys), then four positions of R,G,B,brightness,mode (`0` = iPad only, `1` = iPad + relay).

**Status** is 5 bytes: state (`0` SCANNING, `1` HOLDING, `2` SELECTING, `3` PAUSED), current choice 1–N (`0` if paused), primary position 1–4, keyboard connected (`0`/`1`), hold seconds left.

**Commands:** `01` pause, `02` resume, `03` toggle pause, `10 nn` pulse relay position 1–4, `7F A5` factory-reset settings.

iOS often hides an already-paired keyboard from a scan. Use `retrieveConnectedPeripherals(withServices:)` with the scanner service UUID.

## For the teacher

1. Plug in the power bank, then the student switch. Label on the case: **5V IN**, **SWITCH**, **PAUSE**, cords **1–4**.
2. Pair the iPad with **AAC Scanner** in Settings → Bluetooth.
3. Cords 1 and 2 go to power select box #1; cords 3 and 4 to box #2.
4. **PAUSE** turns the lights off and ignores the switch. Resume starts at the first choice.
5. Unplug or plug the switch only while paused.

This is a 5 V USB-bank device. Relays switch only the low-voltage switch lines of the power select boxes. They never switch mains.
