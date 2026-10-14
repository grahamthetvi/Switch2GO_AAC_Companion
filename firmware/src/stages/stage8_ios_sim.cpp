/*
  STAGE 8 - iOS Connection & Short-Press Simulator
  ================================================
  Simulates the ESP32-WROOM-32 connecting to an iOS device (iPad / iPhone)
  for both:
    1. BLE HID Keyboard (pairs under iOS Settings -> Bluetooth -> "AAC Scanner")
    2. Custom GATT Companion Service (Config, Status, Command characteristics)

  Switch Simulation:
    - SHORT PRESS ONLY for this test run (Long press disabled).
    - Every short press (tap) of the BOOT button (GPIO 0) or external switch (GPIO 32)
      immediately sends the keystroke ('1'..'4' + Enter) to iOS!
    - Holding the button stays on the ESP32 and will NOT send multiple keystrokes.
    - Serial commands ('s', '1', '2', '3', '4', 'p', 'c') also available.
*/

#include <Arduino.h>
#include <Preferences.h>
#include <NimBLEDevice.h>
#include <BleKeyboard.h>

// ============================== PINS ==============================
static const uint8_t PIN_BOOT_BTN   = 0;   // Onboard BOOT button on ESP32 DevKit
static const uint8_t PIN_SWITCH     = 32;  // External switch jack tip (sleeve to GND)
static const uint8_t PIN_STATUS_LED = 2;   // Onboard LED on ESP32 dev boards

// ============================ CONSTANTS ===========================
static const char* DEVICE_NAME  = "AAC Scanner";
static const char* MANUFACTURER = "Addison Graham";

#define SVC_UUID    "a5c00001-7d2b-4f6e-9c31-5b8e2a1d0c4f"
#define CFG_UUID    "a5c00002-7d2b-4f6e-9c31-5b8e2a1d0c4f"
#define STATUS_UUID "a5c00003-7d2b-4f6e-9c31-5b8e2a1d0c4f"
#define CMD_UUID    "a5c00004-7d2b-4f6e-9c31-5b8e2a1d0c4f"

static const uint8_t NUM_POSITIONS = 4;
static const uint8_t FLAG_SEND_ENTER   = 0x01;
static const uint8_t FLAG_KEY_PHYSICAL = 0x02;
static const uint8_t CFG_VERSION       = 1;
static const size_t  CFG_LEN           = 29;

enum : uint8_t { MODE_IPAD_ONLY = 0, MODE_IPAD_RELAY = 1 };
enum class State : uint8_t { SCANNING = 0, HOLDING = 1, SELECTING = 2, PAUSED = 3 };

struct OptionCfg { uint8_t r, g, b, bright, mode; };
struct Config {
  uint8_t  numChoices;
  uint16_t scanTenths, holdTenths, longPressMs;
  uint8_t  flags;
  OptionCfg opt[NUM_POSITIONS];
};

Config cfg;
Preferences prefs;
State state = State::SCANNING;
uint8_t curChoice = 0; // 0..numChoices-1
uint32_t stepStart = 0, selectStart = 0;
bool simulatedSwitchPressed = false;
uint32_t simPressUntil = 0;

// ============================ BLE SETUP ===========================
NimBLECharacteristic* cfgChar = nullptr;
NimBLECharacteristic* statusChar = nullptr;
NimBLECharacteristic* cmdChar = nullptr;

portMUX_TYPE bleMux = portMUX_INITIALIZER_UNLOCKED;
volatile bool cfgPending = false, cmdPending = false;
uint8_t cfgBuf[CFG_LEN]; size_t cfgLen = 0;
uint8_t cmdBuf[4];       size_t cmdLen = 0;

void setDefaults(Config& c) {
  c.numChoices = 4;
  c.scanTenths = 20;    // 2.0s
  c.holdTenths = 300;   // 30s
  c.longPressMs = 1000; // 1.0s
  c.flags = FLAG_SEND_ENTER;
  for (uint8_t i = 0; i < NUM_POSITIONS; i++) {
    c.opt[i] = {255, 255, 255, 255, MODE_IPAD_ONLY};
  }
}

static uint16_t clamp16(uint16_t v, uint16_t lo, uint16_t hi) {
  return v < lo ? lo : (v > hi ? hi : v);
}

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

class CfgCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* c) override {
    std::string v = c->getValue();
    portENTER_CRITICAL(&bleMux);
    cfgLen = v.size();
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

class SimulatorKeyboard : public BleKeyboard {
 public:
  SimulatorKeyboard() : BleKeyboard(DEVICE_NAME, MANUFACTURER, 100) {}
 protected:
  void onStarted(NimBLEServer* pServer) override {
    setupConfigService(pServer);
  }
};

SimulatorKeyboard kb;

// =========================== STATE HELPERS ========================
const char* stateName(State s) {
  switch (s) {
    case State::SCANNING:  return "SCANNING";
    case State::HOLDING:   return "HOLDING";
    case State::SELECTING: return "SELECTING";
    default:               return "PAUSED";
  }
}

void publishStatus(uint32_t now) {
  static uint8_t last[5] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF};
  static uint32_t lastSent = 0;
  if (!statusChar) return;

  uint8_t st[5];
  bool paused = (state == State::PAUSED);
  st[0] = (uint8_t)state;
  st[1] = paused ? 0 : curChoice + 1;
  st[2] = paused ? 0 : curChoice + 1; // Primary position
  st[3] = kb.isConnected() ? 1 : 0;
  st[4] = 0;

  if (memcmp(st, last, 5) == 0 || (now - lastSent) < 100) return;
  memcpy(last, st, 5);
  lastSent = now;
  statusChar->setValue(st, 5);
  statusChar->notify();
}

// Send short press keystroke to iOS
void sendShortPressKey(uint8_t choiceIndex) {
  char key = '1' + choiceIndex;
  Serial.printf("\n>>> [SHORT PRESS TO iOS] Choice %u (Key '%c') <<<\n", choiceIndex + 1, key);
  if (kb.isConnected()) {
    kb.write((uint8_t)key);
    Serial.printf("    [BLE HID] Transmitted '%c' to iOS\n", key);
    if (cfg.flags & FLAG_SEND_ENTER) {
      kb.write(KEY_RETURN);
      Serial.println("    [BLE HID] Transmitted KEY_RETURN (Enter) to iOS");
    }
  } else {
    Serial.printf("    [BLE HID] Note: iOS not paired yet! (Simulated '%c' + Enter)\n", key);
  }

  // Advance choice for next short press
  curChoice = (choiceIndex + 1) % cfg.numChoices;
  selectStart = millis();
  state = State::SELECTING;
  Serial.printf("    [NEXT CHOICE] Now queued: Choice %u\n", curChoice + 1);
}

// Reads BOOT button (GPIO 0, active LOW) or external switch (GPIO 32, active LOW)
bool isSwitchPressed() {
  if (simulatedSwitchPressed) return true;
  bool bootBtnPressed = (digitalRead(PIN_BOOT_BTN) == LOW);
  bool extSwPressed   = (digitalRead(PIN_SWITCH) == LOW);
  return bootBtnPressed || extSwPressed;
}

// ============================== SETUP =============================
void setup() {
  Serial.begin(115200);
  delay(100);

  pinMode(PIN_BOOT_BTN, INPUT_PULLUP);
  pinMode(PIN_SWITCH, INPUT_PULLUP);
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);

  Serial.println("\n========================================================");
  Serial.println("   Switch2GO AAC Companion - Short-Press Simulator      ");
  Serial.println("========================================================");
  Serial.println("Modes: Short presses go to iOS. Long presses stay on ESP32.");
  Serial.println("\nControls:");
  Serial.println(" - BOOT Button (GPIO 0) / Switch (GPIO 32):");
  Serial.println("     * TAP (Short Press): Immediately sends '1'..'4' + Enter to iOS");
  Serial.println("     * HOLD: Stays on ESP32 without sending duplicate keys");
  Serial.println(" - Serial commands: 's' (tap), '1'..'4' (select choice), 'p' (pause)");
  Serial.println("--------------------------------------------------------");
  Serial.println("Advertising as: 'AAC Scanner'");
  Serial.println("1. Open iOS Settings -> Bluetooth -> Tap 'AAC Scanner' to Pair");
  Serial.println("2. Open Notes or Switch2GO on your iPad/iPhone to see keys");
  Serial.println("========================================================\n");

  prefs.begin("aacscan", false);
  loadConfig();
  kb.begin();

  stepStart = millis();
}

// =============================== LOOP =============================
void loop() {
  uint32_t now = millis();
  static bool lastKbConnected = false;
  static uint32_t lastLedToggle = 0;
  static bool ledState = false;

  // 1. Connection status monitoring
  bool connected = kb.isConnected();
  if (connected != lastKbConnected) {
    lastKbConnected = connected;
    if (connected) {
      Serial.println("\n[BLE] *** CONNECTED TO iOS DEVICE! ***");
      Serial.println("[BLE] Short presses will now appear directly on your iOS device.");
    } else {
      Serial.println("\n[BLE] *** DISCONNECTED FROM iOS DEVICE ***");
      Serial.println("[BLE] Re-advertising as 'AAC Scanner'...");
    }
  }

  // 2. Onboard LED status indication
  if (!connected) {
    // Blinking 1Hz = waiting for iOS connection
    if (now - lastLedToggle >= 500) {
      lastLedToggle = now;
      ledState = !ledState;
      digitalWrite(PIN_STATUS_LED, ledState ? HIGH : LOW);
    }
  } else {
    // Solid ON when connected, brief blink off on key send
    if (state == State::SELECTING && (now - selectStart < 150)) {
      digitalWrite(PIN_STATUS_LED, LOW);
    } else {
      digitalWrite(PIN_STATUS_LED, HIGH);
    }
  }

  if (state == State::SELECTING && (now - selectStart >= 300)) {
    state = State::SCANNING;
  }

  // 3. Serial command handling
  if (Serial.available()) {
    char ch = Serial.read();
    if (ch == 's' || ch == 'S' || ch == ' ') {
      sendShortPressKey(curChoice);
    } else if (ch >= '1' && ch <= '4') {
      sendShortPressKey(ch - '1');
    } else if (ch == 'p' || ch == 'P') {
      state = (state == State::PAUSED) ? State::SCANNING : State::PAUSED;
      Serial.printf("[STATE] %s\n", stateName(state));
    } else if (ch == 'c' || ch == 'C') {
      Serial.printf("[INFO] Choice=%u, BLE=%s\n", curChoice + 1, connected ? "CONNECTED" : "ADVERTISING");
    }
  }

  // 4. Switch handling (Debounced short press)
  static bool lastRaw = false;
  static bool stablePressed = false;
  static uint32_t lastChange = 0;
  static bool pressHandled = false;
  static uint32_t pressStart = 0;

  bool raw = isSwitchPressed();
  if (raw != lastRaw) {
    lastRaw = raw;
    lastChange = now;
  }

  bool justPressed = false;
  bool justReleased = false;
  if ((now - lastChange) >= 25 && raw != stablePressed) {
    stablePressed = raw;
    if (stablePressed) justPressed = true;
    else justReleased = true;
  }

  // Button pressed down
  if (justPressed) {
    pressStart = now;
    pressHandled = false;
  }

  // Long press stays on ESP32: If held longer than 1000ms, mark handled so release doesn't fire
  if (stablePressed && !pressHandled) {
    if (now - pressStart >= 1000) {
      pressHandled = true;
      Serial.println("\n[SWITCH] Button HELD > 1000ms (Long press stays on ESP32, suppressed from iOS)");
    }
  }

  // Button released: If it was a short press (< 1000ms), send to iOS!
  if (justReleased) {
    uint32_t duration = now - pressStart;
    if (!pressHandled && duration < 1000) {
      Serial.printf("\n[SWITCH] Short press detected (Held %lu ms)\n", (unsigned long)duration);
      sendShortPressKey(curChoice);
    } else {
      Serial.printf("[SWITCH] Released after %lu ms\n", (unsigned long)duration);
    }
  }

  // 5. BLE Characteristic Pending Services
  uint8_t localCfg[CFG_LEN]; size_t nCfg = 0; bool haveCfg = false;
  portENTER_CRITICAL(&bleMux);
  if (cfgPending) {
    nCfg = cfgLen;
    memcpy(localCfg, cfgBuf, CFG_LEN);
    cfgPending = false;
    haveCfg = true;
  }
  portEXIT_CRITICAL(&bleMux);

  if (haveCfg) {
    Config c;
    if (unpackConfig(localCfg, nCfg, c)) {
      cfg = c;
      saveConfig();
      uint8_t buf[CFG_LEN]; packConfig(cfg, buf);
      if (cfgChar) cfgChar->setValue(buf, CFG_LEN);
      Serial.printf("[BLE GATT] Config updated from iOS app.\n");
    }
  }

  // 6. Status updates
  publishStatus(now);

  delay(5);
}
