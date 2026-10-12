// LED hood + rail for one trifold position (3 WS2812E LEDs).
// Starting sizes from the build guide Section 12.1 — measure your strip
// and retune before printing a full set.
// Print mouth-down for clean walls.

$fn = 48;

// --- Strip (measure yours; 5 V 60/m is often 10 mm wide, ~16.7 mm pitch) ---
led_pitch = 16.7;
leds_per_group = 3;
strip_width = 10;
strip_thickness = 2.2;
rail_channel_extra = 1;     // channel ~1 mm wider than the strip
rail_channel_depth = 2;
rail_wall = 2.4;
rail_lip = 0.8;             // holds the strip without relying on adhesive
zip_slot_w = 3.2;
zip_slot_h = 1.6;

// --- Hood (rectangular snoot) ---
led_opening_w = 55;         // inner opening at the LED end
led_opening_h = 14;
mouth_w = 100;              // flare at the mouth (guide: 90–110)
mouth_h = 60;               // flare at the mouth (guide: 50–70)
hood_depth = 60;            // guide: 50–70
wall = 2.4;
visor_length = 18;          // student-side brim so LEDs stay out of view
visor_drop = 10;
trap_count = 4;             // shallow light-trap grooves on inner walls
trap_depth = 0.6;
trap_width = 1.2;

// --- Wire exit and data-arrow mark ---
wire_slot_w = 6;
wire_slot_h = 4;
arrow_mark = true;

module rail() {
    inner_w = leds_per_group * led_pitch + 4;
    inner_d = strip_width + rail_channel_extra;
    outer_w = inner_w + 2 * rail_wall;
    outer_d = inner_d + 2 * rail_wall;
    outer_h = rail_channel_depth + rail_wall + rail_lip;

    difference() {
        cube([outer_w, outer_d, outer_h], center = true);

        // Strip channel, open at the top except for side lips
        translate([0, 0, rail_wall / 2])
            cube([inner_w, inner_d, rail_channel_depth + rail_lip + 0.2], center = true);

        // Lip gap so the strip seats, then lips keep it from lifting
        translate([0, 0, outer_h / 2 - rail_lip / 2 + 0.05])
            cube([inner_w - 4, inner_d - 2 * rail_lip, rail_lip + 0.2], center = true);

        // Wire exit at the DIN end (negative X)
        translate([-outer_w / 2 + rail_wall / 2, 0, rail_wall / 2 - strip_thickness / 4])
            cube([rail_wall + 0.4, wire_slot_w, wire_slot_h], center = true);

        // Zip-tie slots along both long walls
        for (s = [-1, 1])
            for (x = [-inner_w / 4, inner_w / 4])
                translate([x, s * (outer_d / 2 - 0.4), 0])
                    cube([zip_slot_w, 2, zip_slot_h], center = true);
    }

    if (arrow_mark) {
        // Raised arrow on the DIN end: data flows +X (away from DIN)
        translate([-outer_w / 2 + 6, 0, outer_h / 2])
            linear_extrude(0.6)
                polygon([[-3, -2.5], [3, 0], [-3, 2.5]]);
    }
}

module hood_outer() {
    hull() {
        translate([0, 0, 0])
            cube([led_opening_w + 2 * wall, led_opening_h + 2 * wall, 0.2], center = true);
        translate([0, 0, hood_depth])
            cube([mouth_w + 2 * wall, mouth_h + 2 * wall, 0.2], center = true);
    }
}

module hood_inner() {
    hull() {
        translate([0, 0, -0.2])
            cube([led_opening_w, led_opening_h, 0.2], center = true);
        translate([0, 0, hood_depth + 0.2])
            cube([mouth_w, mouth_h, 0.2], center = true);
    }
}

module visor() {
    // Extra wall on the student side of the mouth (negative Y)
    translate([0, -(mouth_h / 2 + wall / 2), hood_depth - visor_drop / 2])
        cube([mouth_w + 2 * wall, wall, visor_length + visor_drop], center = true);
}

module light_traps() {
    for (i = [1 : trap_count]) {
        z = i * hood_depth / (trap_count + 1);
        t = z / hood_depth;
        w = led_opening_w + t * (mouth_w - led_opening_w);
        h = led_opening_h + t * (mouth_h - led_opening_h);
        translate([0, 0, z]) {
            // Grooves on the four inner walls
            for (sx = [-1, 1])
                translate([sx * (w / 2 - trap_depth / 2), 0, 0])
                    cube([trap_depth, h - 2, trap_width], center = true);
            for (sy = [-1, 1])
                translate([0, sy * (h / 2 - trap_depth / 2), 0])
                    cube([w - 2, trap_depth, trap_width], center = true);
        }
    }
}

module hood() {
    difference() {
        union() {
            hood_outer();
            visor();
        }
        hood_inner();
        light_traps();
        // Opening into the rail at the LED end
        translate([0, 0, -0.5])
            cube([led_opening_w - 2, led_opening_h - 2, 4], center = true);
    }
}

module assembly() {
    // Overlap the rail into the hood so they fuse into one printable body.
    rail_h = rail_channel_depth + rail_wall + rail_lip;
    translate([0, 0, -rail_h / 2 + 0.6])
        rail();
    hood();
}

assembly();
