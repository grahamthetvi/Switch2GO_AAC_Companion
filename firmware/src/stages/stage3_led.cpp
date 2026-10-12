// STAGE 3 - LED test (untested starter)
// Bench-test: red, then green, then blue, then dim white on each of 12 LEDs.
// If red and green are swapped, change GRB to RGB in addLeds.
#include <Arduino.h>
#include <FastLED.h>

#define PIN_LED_DATA 18
#define NUM_LEDS 12

CRGB leds[NUM_LEDS];

void setup() {
  FastLED.addLeds<WS2812B, PIN_LED_DATA, GRB>(leds, NUM_LEDS);
  FastLED.setBrightness(60);  // keep low for testing
  FastLED.setMaxPowerInVoltsAndMilliamps(5, 500);
}

void loop() {
  const CRGB colors[] = {CRGB::Red, CRGB::Green, CRGB::Blue, CRGB(80, 80, 80)};
  for (CRGB c : colors) {
    for (int i = 0; i < NUM_LEDS; i++) {
      FastLED.clear();
      leds[i] = c;
      FastLED.show();
      delay(150);
    }
  }
}
