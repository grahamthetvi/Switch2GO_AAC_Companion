// STAGE 7 - BLE keyboard test (untested starter). Build with -D USE_NIMBLE.
// Pair as "AAC Scanner", open Notes, long-press the switch: 1 then a new line, then 2, ...
#include <Arduino.h>
#include <BleKeyboard.h>

BleKeyboard kb("AAC Scanner", "Addison Graham", 100);

#define PIN_SWITCH 32

int n = 0;

void setup() {
  Serial.begin(115200);
  pinMode(PIN_SWITCH, INPUT_PULLUP);
  kb.begin();
}

void loop() {
  static uint32_t downAt = 0;
  static bool down = false;
  bool p = digitalRead(PIN_SWITCH) == LOW;
  if (p && !down) {
    down = true;
    downAt = millis();
  }
  if (!p && down) {
    down = false;
    if (millis() - downAt >= 1000 && kb.isConnected()) {
      kb.write((uint8_t)('1' + n));
      kb.write(KEY_RETURN);
      Serial.printf("sent %c + Enter\n", '1' + n);
      n = (n + 1) % 4;
    }
  }
  delay(10);
}
