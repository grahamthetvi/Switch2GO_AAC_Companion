// STAGE 7 - BLE keyboard test. Build with -D USE_NIMBLE.
// Pair as "AAC Scanner", open Notes, long-press the switch or BOOT button: 1 then a new line, then 2, ...
#include <Arduino.h>
#include <BleKeyboard.h>

BleKeyboard kb("AAC Scanner", "Addison Graham", 100);

#define PIN_SWITCH 32
#define PIN_BOOT_BTN 0
#define PIN_STATUS_LED 2

int n = 0;

void setup() {
  Serial.begin(115200);
  pinMode(PIN_SWITCH, INPUT_PULLUP);
  pinMode(PIN_BOOT_BTN, INPUT_PULLUP);
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);
  kb.begin();
  Serial.println("\n[STAGE 7] BLE Keyboard Test");
  Serial.println("Advertising as: 'AAC Scanner'");
  Serial.println("Use the onboard BOOT button (GPIO 0) or external switch (GPIO 32)");
  Serial.println("Hold for >= 1s to send '1'..'4' + Enter to iOS");
}

void loop() {
  static uint32_t downAt = 0;
  static bool down = false;
  static uint32_t lastBlink = 0;
  static bool ledState = false;

  // LED feedback: slow blink while disconnected, solid when connected
  if (!kb.isConnected()) {
    if (millis() - lastBlink >= 500) {
      lastBlink = millis();
      ledState = !ledState;
      digitalWrite(PIN_STATUS_LED, ledState ? HIGH : LOW);
    }
  } else {
    digitalWrite(PIN_STATUS_LED, HIGH);
  }

  bool p = (digitalRead(PIN_SWITCH) == LOW) || (digitalRead(PIN_BOOT_BTN) == LOW);
  if (p && !down) {
    down = true;
    downAt = millis();
    Serial.println("Button DOWN");
  }
  if (!p && down) {
    down = false;
    uint32_t duration = millis() - downAt;
    Serial.printf("Button UP after %lu ms\n", (unsigned long)duration);
    if (duration >= 1000) {
      if (kb.isConnected()) {
        kb.write((uint8_t)('1' + n));
        kb.write(KEY_RETURN);
        Serial.printf("--> Sent '%c' + Enter to iOS\n", '1' + n);
        n = (n + 1) % 4;
      } else {
        Serial.println("--> iOS keyboard not connected yet. Open iOS Settings -> Bluetooth -> 'AAC Scanner'");
      }
    } else {
      Serial.println("--> Short press (< 1s). Hold for >= 1s for long press selection.");
    }
  }
  delay(10);
}
