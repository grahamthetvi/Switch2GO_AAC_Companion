/*
  AAC Switch Scanner - starter firmware
  =====================================
  STATUS: UNTESTED STARTER CODE. It has not been compiled or run on hardware.
  Bench-test every feature (Section 8 of the build guide) before using it
  with a student.

  Board:     ESP32-WROOM-32 dev board (PlatformIO board = esp32dev)
  Libraries: FastLED 3.6+, NimBLE-Arduino 1.4.x, ESP32-BLE-Keyboard (T-vK)
             built with -D USE_NIMBLE, Preferences (built in)

  Behavior summary:
    SCANNING  : light moves between active choices every scanTenths/10 s
    short press -> HOLDING : light stays on the current choice for holdTenths/10 s
    long press  -> SELECTING : send '1'..'4' (+ Enter), close relay while held
                              (if that position is in iPad+relay mode)
    pause button -> PAUSED (LEDs off, switch ignored) / back to SCANNING
*/
#include <Arduino.h>
#include <FastLED.h>
#include <Preferences.h>
#include <NimBLEDevice.h>
#include <BleKeyboard.h>   // requires -D USE_NIMBLE

// ============================== PINS ==============================
#define PIN_LED_DATA 18                                   // -> level shifter LV1
static const uint8_t PIN_SWITCH = 32;                     // 3.5mm jack tip (sleeve->GND)
static const uint8_t PIN_PAUSE  = 33;                     // button to GND
static const uint8_t PIN_RELAY[4] = {25, 26, 27, 14};     // positions 1..4 (14 -> 13 if it clicks at boot)
static const uint8_t PIN_KEEPALIVE = 4;                   // optional MOSFET dummy load

// ======================= HARDWARE OPTIONS =========================
static const bool     RELAY_ACTIVE_HIGH = true;    // true = module jumpers on H (or NPN + L mode)
static const uint8_t  NUM_POSITIONS     = 4;
static const uint8_t  LEDS_PER_POS      = 3;
static const uint8_t  NUM_LEDS          = NUM_POSITIONS * LEDS_PER_POS;
static const uint8_t  LED_GLOBAL_MAX_BRIGHTNESS = 100;  // 0-255 safety cap (~40%)
static const uint16_t LED_POWER_LIMIT_MA = 500;         // FastLED power limiter
static const uint32_t DEBOUNCE_MS        = 30;
static const uint32_t RELAY_MIN_MS       = 200;   // box always sees at least this long a press
static const uint32_t RELAY_MAX_MS       = 5000;  // safety cap (ASSUMPTION - confirm)
static const uint32_t SELECT_FEEDBACK_MS = 800;   // blink after a selection
static const bool     SELECT_BLINK       = true;
static const bool     RESTART_FROM_FIRST_AFTER_SELECT = true;  // ASSUMPTION
static const bool     KEEPALIVE_ENABLED  = false; // power-bank keep-alive (Section 4.4)
static const uint32_t KEEPALIVE_PERIOD_MS = 15000;
static const uint32_t KEEPALIVE_PULSE_MS  = 500;
static const char*    DEVICE_NAME = "AAC Scanner";

// ============================ BLE UUIDs ===========================
#define SVC_UUID    "a5c00001-7d2b-4f6e-9c31-5b8e2a1d0c4f"
#define CFG_UUID    "a5c00002-7d2b-4f6e-9c31-5b8e2a1d0c4f"
#define STATUS_UUID "a5c00003-7d2b-4f6e-9c31-5b8e2a1d0c4f"
#define CMD_UUID    "a5c00004-7d2b-4f6e-9c31-5b8e2a1d0c4f"

// ============================= CONFIG =============================
enum : uint8_t { MODE_IPAD_ONLY = 0, MODE_IPAD_RELAY = 1 };
static const uint8_t FLAG_SEND_ENTER   = 0x01;
static const uint8_t FLAG_KEY_PHYSICAL = 0x02;
static const uint8_t CFG_VERSION = 1;
static const size_t  CFG_LEN     = 29;

struct OptionCfg { uint8_t r, g, b, bright, mode; };
struct Config {
  uint8_t  numChoices;
  uint16_t scanTenths, holdTenths, longPressMs;
  uint8_t  flags;
  OptionCfg opt[NUM_POSITIONS];   // indexed by PHYSICAL position 0..3
};
Config cfg;
Preferences prefs;

// Which physical positions light up for each logical choice.
// bit0 = position 1 (left) ... bit3 = position 4 (right).
// Rows 1 and 3 are ASSUMPTIONS to confirm (see build guide Section 2.3).
static const uint8_t LAYOUT[5][4] = {
  {0, 0, 0, 0},
  {0b0110, 0, 0, 0},                 // 1 choice : middle panel (pos 2+3 together)
  {0b0010, 0b0100, 0, 0},            // 2 choices: pos 2, pos 3
  {0b0001, 0b0110, 0b1000, 0},       // 3 choices: left, middle(2+3), right
  {0b0001, 0b0010, 0b0100, 0b1000},  // 4 choices: 1, 2, 3, 4
};

void setDefaults(Config& c) {
  c.numChoices = 4; c.scanTenths = 20; c.holdTenths = 300; c.longPressMs = 1000;
  c.flags = FLAG_SEND_ENTER;
  for (uint8_t i = 0; i < NUM_POSITIONS; i++) c.opt[i] = {255, 255, 255, 255, MODE_IPAD_ONLY};
}

static uint16_t clamp16(uint16_t v, uint16_t lo, uint16_t hi) { return v < lo ? lo : (v > hi ? hi : v); }

void packConfig(const Config& c, uint8_t* d) {
  d[0] = CFG_VERSION; d[1] = c.numChoices;
  d[2] = c.scanTenths & 0xFF;  d[3] = c.scanTenths >> 8;
  d[4] = c.holdTenths & 0xFF;  d[5] = c.holdTenths >> 8;
  d[6] = c.longPressMs & 0xFF; d[7] = c.longPressMs >> 8;
  d[8] = c.flags;
  for (uint8_t i = 0; i < NUM_POSITIONS; i++) {
    uint8_t* p = d + 9 + i * 5;
    p[0] = c.opt[i].r; p[1] = c.opt[i].g; p[2] = c.opt[i].b; p[3] = c.opt[i].bright; p[4] = c.opt[i].mode;
  }
}

bool unpackConfig(const uint8_t* d, size_t n, Config& out) {
  if (n != CFG_LEN || d[0] != CFG_VERSION) return false;
  if (d[1] < 1 || d[1] > 4) return false;
  Config c;
  c.numChoices  = d[1];
  c.scanTenths  = clamp16(d[2] | (d[3] << 8), 5, 600);
  c.holdTenths  = clamp16(d[4] | (d[5] << 8), 10, 1200);
  c.longPressMs = clamp16(d[6] | (d[7] << 8), 300, 5000);
  c.flags       = d[8] & (FLAG_SEND_ENTER | FLAG_KEY_PHYSICAL);
  for (uint8_t i = 0; i < NUM_POSITIONS; i++) {
    const uint8_t* p = d + 9 + i * 5;
    c.opt[i] = {p[0], p[1], p[2], p[3], (uint8_t)(p[4] == MODE_IPAD_RELAY ? MODE_IPAD_RELAY : MODE_IPAD_ONLY)};
  }
  out = c;
  return true;
}

void saveConfig() {
  uint8_t buf[CFG_LEN]; packConfig(cfg, buf);
  prefs.putBytes("cfg", buf, CFG_LEN);
}

void loadConfig() {
  setDefaults(cfg);
  uint8_t buf[CFG_LEN];
  if (prefs.getBytesLength("cfg") == CFG_LEN) {
    prefs.getBytes("cfg", buf, CFG_LEN);
    Config c;
    if (unpackConfig(buf, CFG_LEN, c)) cfg = c;
  }
}

// ============================== STATE =============================
enum class State : uint8_t { SCANNING = 0, HOLDING = 1, SELECTING = 2, PAUSED = 3 };
State    state = State::SCANNING;
uint8_t  curChoice = 0;                 // logical choice index 0..numChoices-1
uint32_t stepStart = 0, holdStart = 0, selectStart = 0;
uint32_t pressStart = 0;
bool     pressArmed = false, longFired = false;

CRGB leds[NUM_LEDS];

// ---------------------------- Debouncer ---------------------------
struct Debouncer {
  uint8_t pin = 0; bool stable = false, lastRaw = false; uint32_t lastChange = 0;
  bool rose = false, fell = false;   // rose = just pressed, fell = just released
  void begin(uint8_t p) {
    pin = p; pinMode(pin, INPUT_PULLUP);
    lastRaw = stable = (digitalRead(pin) == LOW);
  }
  void update(uint32_t now) {
    rose = fell = false;
    bool raw = (digitalRead(pin) == LOW);  // LOW = pressed
    if (raw != lastRaw) { lastRaw = raw; lastChange = now; }
    if ((now - lastChange) >= DEBOUNCE_MS && raw != stable) {
      stable = raw;
      if (stable) rose = true; else fell = true;
    }
  }
  bool pressed() const { return stable; }
};
Debouncer sw, pauseBtn;

// ------------------------------ Relays ----------------------------
int8_t   relayPos = -1;        // physical position currently closed, -1 = none
uint32_t relayOnAt = 0;
bool     relayWantOff = false;

void relayWrite(uint8_t pos, bool on) {
  digitalWrite(PIN_RELAY[pos], (on == RELAY_ACTIVE_HIGH) ? HIGH : LOW);
}
void relayStart(uint8_t pos, uint32_t now) {
  if (relayPos >= 0) relayWrite(relayPos, false);
  relayPos = pos; relayOnAt = now; relayWantOff = false;
  relayWrite(pos, true);
  Serial.printf("[relay] position %u CLOSED\n", pos + 1);
}
void relayForceOff() {
  if (relayPos >= 0) { relayWrite(relayPos, false); Serial.printf("[relay] position %d OPEN\n", relayPos + 1); }
  relayPos = -1; relayWantOff = false;
}
void relayService(uint32_t now) {
  if (relayPos < 0) return;
  uint32_t onFor = now - relayOnAt;
  if ((relayWantOff && onFor >= RELAY_MIN_MS) || onFor >= RELAY_MAX_MS) relayForceOff();
}

// ------------------------------ Helpers ---------------------------
uint8_t choiceMask(uint8_t choice) {
  if (cfg.numChoices < 1 || cfg.numChoices > 4 || choice >= cfg.numChoices) return 0;
  return LAYOUT[cfg.numChoices][choice];
}
uint8_t primaryPos(uint8_t mask) { return mask ? (uint8_t)__builtin_ctz(mask) : 0; }
uint32_t scanMs() { return (uint32_t)cfg.scanTenths * 100; }
uint32_t holdMs() { return (uint32_t)cfg.holdTenths * 100; }
const char* stateName(State s) {
  switch (s) { case State::SCANNING: return "SCANNING"; case State::HOLDING: return "HOLDING";
               case State::SELECTING: return "SELECTING"; default: return "PAUSED"; }
}
void setState(State s) {
  if (s != state) { state = s; Serial.printf("[state] %s choice=%u\n", stateName(s), curChoice + 1); }
}
void advance() { curChoice = (curChoice + 1) % cfg.numChoices; }

// =============================== BLE ==============================
NimBLECharacteristic* cfgChar = nullptr;
NimBLECharacteristic* statusChar = nullptr;
NimBLECharacteristic* cmdChar = nullptr;

// BLE callbacks run in the BLE task: copy data, handle it later in loop().
portMUX_TYPE bleMux = portMUX_INITIALIZER_UNLOCKED;
volatile bool cfgPending = false, cmdPending = false;
uint8_t cfgBuf[CFG_LEN]; size_t cfgLen = 0;
uint8_t cmdBuf[4];       size_t cmdLen = 0;

class CfgCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* c) override {
    std::string v = c->getValue();
    portENTER_CRITICAL(&bleMux);
    cfgLen = v.size();                                   // real length, checked later
    memcpy(cfgBuf, v.data(), v.size() < CFG_LEN ? v.size() : CFG_LEN);
    cfgPending = true;
    portEXIT_CRITICAL(&bleMux);
  }
} cfgCallbacks;

class CmdCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* c) override {
    std::string v = c->getValue();
    portENTER_CRITICAL(&bleMux);
    cmdLen = v.size() < sizeof(cmdBuf) ? v.size() : sizeof(cmdBuf);
    memcpy(cmdBuf, v.data(), cmdLen);
    cmdPending = true;
    portEXIT_CRITICAL(&bleMux);
  }
} cmdCallbacks;

void setupConfigService(NimBLEServer* server) {
  NimBLEService* svc = server->createService(SVC_UUID);
  cfgChar    = svc->createCharacteristic(CFG_UUID, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE);
  statusChar = svc->createCharacteristic(STATUS_UUID, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  cmdChar    = svc->createCharacteristic(CMD_UUID, NIMBLE_PROPERTY::WRITE);
  cfgChar->setCallbacks(&cfgCallbacks);
  cmdChar->setCallbacks(&cmdCallbacks);
  uint8_t buf[CFG_LEN]; packConfig(cfg, buf);
  cfgChar->setValue(buf, CFG_LEN);
  uint8_t st[5] = {0, 1, 1, 0, 0};
  statusChar->setValue(st, sizeof(st));
  svc->start();
}

// Subclass the keyboard so our service is added to the SAME GATT server,
// after the HID services are created and before advertising starts.
class ScannerKeyboard : public BleKeyboard {
 public:
  ScannerKeyboard() : BleKeyboard(DEVICE_NAME, "Addison Graham", 100) {}
 protected:
  void onStarted(NimBLEServer* pServer) override { setupConfigService(pServer); }
};
ScannerKeyboard keyboard;
bool configOnlyMode = false;   // pause button held at boot -> no keyboard (fallback)

bool kbConnected() { return !configOnlyMode && keyboard.isConnected(); }

// ============================ Actions =============================
void setPaused(bool p, uint32_t now) {
  if (p) { relayForceOff(); pressArmed = false; setState(State::PAUSED); }
  else   { curChoice = 0; stepStart = now; setState(State::SCANNING); }
}

void doSelect(uint32_t now) {
  uint8_t mask = choiceMask(curChoice);
  if (!mask) return;
  uint8_t pos = primaryPos(mask);
  char key = (cfg.flags & FLAG_KEY_PHYSICAL) ? ('1' + pos) : ('1' + curChoice);
  Serial.printf("[select] choice %u (position %u) key '%c'\n", curChoice + 1, pos + 1, key);
  if (kbConnected()) {
    keyboard.write((uint8_t)key);
    if (cfg.flags & FLAG_SEND_ENTER) keyboard.write(KEY_RETURN);
  } else {
    Serial.println("[select] keyboard not connected - keys skipped");
  }
  if (cfg.opt[pos].mode == MODE_IPAD_RELAY) relayStart(pos, now);
  selectStart = now;
  setState(State::SELECTING);
}

void applyConfig(const Config& c) {
  cfg = c;
  if (curChoice >= cfg.numChoices) curChoice = 0;
  saveConfig();
  uint8_t buf[CFG_LEN]; packConfig(cfg, buf);
  if (cfgChar) cfgChar->setValue(buf, CFG_LEN);
  Serial.printf("[config] choices=%u scan=%.1fs hold=%.1fs long=%ums flags=0x%02X\n",
                cfg.numChoices, cfg.scanTenths / 10.0, cfg.holdTenths / 10.0, cfg.longPressMs, cfg.flags);
}

void handleCommand(const uint8_t* d, size_t n, uint32_t now) {
  if (n < 1) return;
  switch (d[0]) {
    case 0x01: setPaused(true, now); break;
    case 0x02: setPaused(false, now); break;
    case 0x03: setPaused(state != State::PAUSED, now); break;
    case 0x10:
      if (n >= 2 && d[1] >= 1 && d[1] <= 4 && relayPos < 0) { relayStart(d[1] - 1, now); relayWantOff = true; }
      break;
    case 0x7F:
      if (n >= 2 && d[1] == 0xA5) { Config c; setDefaults(c); applyConfig(c); }
      break;
    default: break;
  }
}

void serviceBlePending(uint32_t now) {
  uint8_t local[CFG_LEN]; size_t n = 0; bool haveCfg = false, haveCmd = false;
  uint8_t lc[4]; size_t ln = 0;
  portENTER_CRITICAL(&bleMux);
  if (cfgPending) { n = cfgLen; memcpy(local, cfgBuf, CFG_LEN); cfgPending = false; haveCfg = true; }
  if (cmdPending) { ln = cmdLen; memcpy(lc, cmdBuf, ln); cmdPending = false; haveCmd = true; }
  portEXIT_CRITICAL(&bleMux);
  if (haveCfg) {
    Config c;
    if (unpackConfig(local, n, c)) applyConfig(c);
    else Serial.printf("[config] rejected write (len=%u)\n", (unsigned)n);
  }
  if (haveCmd) handleCommand(lc, ln, now);
}

void publishStatus(uint32_t now) {
  static uint8_t last[5] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
  static uint32_t lastSent = 0;
  if (!statusChar) return;
  uint8_t st[5];
  bool paused = (state == State::PAUSED);
  st[0] = (uint8_t)state;
  st[1] = paused ? 0 : curChoice + 1;
  st[2] = paused ? 0 : primaryPos(choiceMask(curChoice)) + 1;
  st[3] = kbConnected() ? 1 : 0;
  uint32_t left = 0;
  if (state == State::HOLDING) {
    uint32_t el = now - holdStart;
    left = el < holdMs() ? (holdMs() - el + 999) / 1000 : 0;
  }
  st[4] = left > 255 ? 255 : (uint8_t)left;
  if (memcmp(st, last, 5) == 0 || (now - lastSent) < 100) return;
  memcpy(last, st, 5); lastSent = now;
  statusChar->setValue(st, 5);
  statusChar->notify();
}

// ============================== LEDs ==============================
void render(uint32_t now) {
  static uint32_t lastShow = 0;
  if (now - lastShow < 20) return;          // ~50 fps is plenty
  lastShow = now;
  FastLED.clear();
  bool on = true;
  if (state == State::PAUSED) on = false;
  if (state == State::SELECTING && SELECT_BLINK) on = ((now - selectStart) / 125) % 2 == 0;
  if (on) {
    uint8_t mask = choiceMask(curChoice);
    for (uint8_t pos = 0; pos < NUM_POSITIONS; pos++) {
      if (!(mask & (1 << pos))) continue;
      CRGB c(cfg.opt[pos].r, cfg.opt[pos].g, cfg.opt[pos].b);
      c.nscale8_video(cfg.opt[pos].bright);
      for (uint8_t k = 0; k < LEDS_PER_POS; k++) leds[pos * LEDS_PER_POS + k] = c;
    }
  }
  FastLED.show();
}

// ============================ Keep-alive ==========================
void keepAliveService(uint32_t now) {
  if (!KEEPALIVE_ENABLED) return;
  digitalWrite(PIN_KEEPALIVE, (now % KEEPALIVE_PERIOD_MS) < KEEPALIVE_PULSE_MS ? HIGH : LOW);
}

// ============================== SETUP =============================
void setup() {
  // 1) Relays OFF first, before anything else.
  for (uint8_t i = 0; i < NUM_POSITIONS; i++) { relayWrite(i, false); pinMode(PIN_RELAY[i], OUTPUT); relayWrite(i, false); }
  pinMode(PIN_KEEPALIVE, OUTPUT); digitalWrite(PIN_KEEPALIVE, LOW);

  Serial.begin(115200);
  delay(50);
  Serial.println("\nAAC Switch Scanner (UNTESTED starter firmware)");

  sw.begin(PIN_SWITCH);
  pauseBtn.begin(PIN_PAUSE);

  FastLED.addLeds<WS2812B, PIN_LED_DATA, GRB>(leds, NUM_LEDS);   // WS2812E: color order to verify
  FastLED.setBrightness(LED_GLOBAL_MAX_BRIGHTNESS);
  FastLED.setMaxPowerInVoltsAndMilliamps(5, LED_POWER_LIMIT_MA);
  FastLED.clear(true);

  prefs.begin("aacscan", false);
  loadConfig();

  // Fallback "config only" mode: hold PAUSE while powering on.
  configOnlyMode = pauseBtn.pressed();
  if (configOnlyMode) {
    Serial.println("[ble] CONFIG-ONLY mode (no keyboard). Reboot to return to normal.");
    NimBLEDevice::init(DEVICE_NAME);
    NimBLEServer* server = NimBLEDevice::createServer();
    setupConfigService(server);
    NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
    adv->addServiceUUID(SVC_UUID);
    adv->start();
    state = State::PAUSED;   // stay dark and ignore the switch in this mode
  } else {
    keyboard.begin();        // creates HID + calls onStarted() -> our service
    Serial.println("[ble] advertising as keyboard");
  }
  stepStart = millis();
}

// =============================== LOOP =============================
void loop() {
  uint32_t now = millis();
  sw.update(now);
  pauseBtn.update(now);
  serviceBlePending(now);

  // ---- pause button (ignored in config-only mode) ----
  if (pauseBtn.rose && !configOnlyMode) setPaused(state != State::PAUSED, now);

  // ---- student switch ----
  if (sw.rose) {
    pressStart = now; longFired = false;
    pressArmed = (state == State::SCANNING || state == State::HOLDING);
  }
  if (pressArmed && sw.pressed() && !longFired && (now - pressStart) >= cfg.longPressMs) {
    longFired = true; pressArmed = false;
    doSelect(now);                           // LONG press: select
  }
  if (sw.fell) {
    if (longFired) {
      relayWantOff = true;                   // relay opens on release (min RELAY_MIN_MS)
    } else if (pressArmed && (state == State::SCANNING || state == State::HOLDING)) {
      holdStart = now;                       // SHORT press: hold (or restart hold)
      setState(State::HOLDING);
    }
    pressArmed = false;
  }

  // ---- timers ----
  switch (state) {
    case State::SCANNING:
      if (!sw.pressed() && (now - stepStart) >= scanMs()) { advance(); stepStart = now;
        Serial.printf("[scan] choice %u\n", curChoice + 1); }
      break;
    case State::HOLDING:
      if (!sw.pressed() && (now - holdStart) >= holdMs()) {   // ASSUMPTION: resume at next choice
        advance(); stepStart = now; setState(State::SCANNING);
      }
      break;
    case State::SELECTING:
      if (!sw.pressed() && relayPos < 0 && (now - selectStart) >= SELECT_FEEDBACK_MS) {
        if (RESTART_FROM_FIRST_AFTER_SELECT) curChoice = 0; else advance();
        stepStart = now; setState(State::SCANNING);
      }
      break;
    case State::PAUSED:
      break;
  }

  relayService(now);
  render(now);
  publishStatus(now);
  keepAliveService(now);
  delay(2);
}
