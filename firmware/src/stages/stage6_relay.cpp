// STAGE 6 - relay test (untested starter)
// Jumpers on H. Watch the first second after reset: if relay 4 (GPIO14) blips,
// move PIN_RELAY[3] to 13 in the full firmware as well.
#include <Arduino.h>

const int RELAY_PINS[4] = {25, 26, 27, 14};
const bool RELAY_ACTIVE_HIGH = true;  // jumpers on H

void relayWrite(int i, bool on) {
  digitalWrite(RELAY_PINS[i], (on == RELAY_ACTIVE_HIGH) ? HIGH : LOW);
}

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < 4; i++) {
    pinMode(RELAY_PINS[i], OUTPUT);
    relayWrite(i, false);
  }
}

void loop() {
  for (int i = 0; i < 4; i++) {
    Serial.printf("Relay position %d ON\n", i + 1);
    relayWrite(i, true);
    delay(700);
    relayWrite(i, false);
    delay(700);
  }
}
