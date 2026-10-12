// STAGE 5 - pause button test (untested starter)
// Same timing sketch as Stage 4, on GPIO33. Pass: clean DOWN/UP lines.
#include <Arduino.h>

#define PIN_SWITCH 33

bool lastStable = false;
bool lastRaw = false;
uint32_t lastChange = 0;
uint32_t downAt = 0;

void setup() {
  Serial.begin(115200);
  pinMode(PIN_SWITCH, INPUT_PULLUP);
}

void loop() {
  bool raw = digitalRead(PIN_SWITCH) == LOW;  // LOW = pressed
  uint32_t now = millis();
  if (raw != lastRaw) {
    lastRaw = raw;
    lastChange = now;
  }
  if (now - lastChange >= 30 && raw != lastStable) {  // 30 ms debounce
    lastStable = raw;
    if (raw) {
      downAt = now;
      Serial.println("DOWN");
    } else {
      uint32_t d = now - downAt;
      Serial.printf("UP after %lu ms -> %s\n", (unsigned long)d,
                    d >= 1000 ? "LONG" : "SHORT");
    }
  }
}
