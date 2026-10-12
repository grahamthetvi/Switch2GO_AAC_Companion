// Electronics case. See README heading "Prints".
// Interior starting size 140 x 100 x 45 mm. Hole sizes are parameters —
// measure your boards, jack threads, and button bushing before printing.
//
// Print two parts:
//   part = "box";  // base with cutouts and standoffs
//   part = "lid";  // screw-down lid
//   part = "both"; // preview assembly

$fn = 64;

part = "both";

// --- Envelope ---
inner_x = 140;
inner_y = 100;
inner_z = 45;
wall = 2.8;
floor_t = 2.8;
lid_t = 2.8;
corner_r = 4;
insert_d = 4.2;             // M3 heat-set insert OD, to verify
insert_h = 5;
screw_clear = 3.2;          // M3 clearance in the lid
lid_recess = 6.5;           // counterbore for an M3 button head

// --- Cutouts (add 0.3–0.5 mm clearance after measuring) ---
usbc_w = 9.4;
usbc_h = 3.6;
usbc_z = 8;                 // center height from floor inside

switch_jack_d = 6.5;        // many 3.5 mm panel jacks ~6 mm threads
switch_key_w = 8;
switch_key_h = 2;

pause_d = 12.5;             // often 12 or 16 mm — measure the bushing
pause_ring_od = 18;
pause_ring_h = 2.5;         // raised ring so it is harder to press by accident

esp32_usb_w = 12;
esp32_usb_h = 8;
esp32_usb_z = 10;

power_sw_w = 20;
power_sw_h = 13;

led_exit_d = 8;

cord_exit_w = 4.5;          // Option A: four labeled cord exits + strain-relief
cord_exit_h = 4.5;
cord_clamp_t = 3;

label_h = 0.6;              // deboss depth

// Standoff grid (placeholder; move after measuring board holes)
standoff_h = 6;
standoff_od = 7;
standoff_id = 2.6;          // M2.5 self-tap starting hole

module rounded_box(size, r) {
    hull() {
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (size[0] / 2 - r), y * (size[1] / 2 - r), 0])
                cylinder(h = size[2], r = r);
    }
}

module label(txt, size = 5) {
    linear_extrude(label_h + 0.05)
        text(txt, size = size, halign = "center", valign = "center",
             font = "Liberation Sans:style=Bold");
}

module outer_shell() {
    rounded_box([inner_x + 2 * wall, inner_y + 2 * wall, inner_z + floor_t], corner_r);
}

module inner_cavity() {
    translate([0, 0, floor_t])
        rounded_box([inner_x, inner_y, inner_z + 1], max(0.1, corner_r - wall));
}

module lid_insert_posts() {
    positions = [
        [-(inner_x / 2 - 4), -(inner_y / 2 - 4)],
        [ (inner_x / 2 - 4), -(inner_y / 2 - 4)],
        [-(inner_x / 2 - 4),  (inner_y / 2 - 4)],
        [ (inner_x / 2 - 4),  (inner_y / 2 - 4)]
    ];
    for (p = positions) {
        translate([p[0], p[1], floor_t - 0.4])
            difference() {
                cylinder(h = inner_z, d = insert_d + 3.2);
                translate([0, 0, inner_z - insert_h])
                    cylinder(h = insert_h + 0.2, d = insert_d);
            }
    }
}

module placeholder_standoffs() {
    // Four generic standoffs near the ESP32 / perfboard area (front-left).
    // Reposition after you measure the boards.
    origin = [-inner_x / 2 + 28, -inner_y / 2 + 28];
    span = [47, 26];
    for (x = [-0.5, 0.5], y = [-0.5, 0.5])
        translate([origin[0] + x * span[0], origin[1] + y * span[1], floor_t - 0.4])
            difference() {
                cylinder(h = standoff_h + 0.4, d = standoff_od);
                translate([0, 0, 1.4])
                    cylinder(h = standoff_h, d = standoff_id);
            }
}

module front_cutouts() {
    // Front (+Y): SWITCH jack, PAUSE, four cord exits labeled 1–4
    y = inner_y / 2 + wall / 2;

    // Switch jack, left
    translate([-inner_x / 2 + 28, y, floor_t + 14])
        rotate([90, 0, 0])
            cylinder(h = wall + 2, d = switch_jack_d, center = true);
    // Anti-rotation key slot
    translate([-inner_x / 2 + 28, y, floor_t + 14 - switch_jack_d / 2])
        cube([switch_key_w, wall + 2, switch_key_h], center = true);

    // Pause button, right of switch
    translate([-inner_x / 2 + 58, y, floor_t + 16])
        rotate([90, 0, 0])
            cylinder(h = wall + 2, d = pause_d, center = true);

    // Cord exits 1–4, evenly along the right half of the front
    for (i = [0 : 3]) {
        x = 10 + i * 18;
        translate([x, y, floor_t + 10])
            cube([cord_exit_w, wall + 2, cord_exit_h], center = true);
    }
}

module back_cutouts() {
    // Back (−Y): USB-C 5V IN, ESP32 programming USB, power switch, LED cable
    y = -(inner_y / 2 + wall / 2);

    translate([-40, y, floor_t + usbc_z])
        cube([usbc_w, wall + 2, usbc_h], center = true);

    translate([-10, y, floor_t + esp32_usb_z])
        cube([esp32_usb_w, wall + 2, esp32_usb_h], center = true);

    translate([22, y, floor_t + 12])
        cube([power_sw_w, wall + 2, power_sw_h], center = true);

    translate([52, y, floor_t + 10])
        rotate([90, 0, 0])
            cylinder(h = wall + 2, d = led_exit_d, center = true);
}

module front_labels() {
    y = inner_y / 2 + wall - label_h + 0.01;
    translate([-inner_x / 2 + 28, y, floor_t + 24])
        rotate([90, 0, 180])
            label("SWITCH", 4);
    translate([-inner_x / 2 + 58, y, floor_t + 26])
        rotate([90, 0, 180])
            label("PAUSE", 4);
    for (i = [0 : 3]) {
        x = 10 + i * 18;
        translate([x, y, floor_t + 16])
            rotate([90, 0, 180])
                label(str(i + 1), 5);
    }
}

module back_labels() {
    y = -(inner_y / 2 + wall - label_h + 0.01);
    translate([-40, y, floor_t + usbc_z + 8])
        rotate([90, 0, 0])
            label("5V IN", 4);
    translate([52, y, floor_t + 18])
        rotate([90, 0, 0])
            label("LED", 4);
}

module pause_ring() {
    translate([-inner_x / 2 + 58, inner_y / 2 + wall - 0.4, floor_t + 16])
        rotate([-90, 0, 0])
            difference() {
                cylinder(h = pause_ring_h + 0.4, d = pause_ring_od);
                translate([0, 0, -0.1])
                    cylinder(h = pause_ring_h + 0.6, d = pause_d);
            }
}

module cord_clamps() {
    // Printed strain-relief bars just inside each cord exit
    for (i = [0 : 3]) {
        x = 10 + i * 18;
        translate([x, inner_y / 2 - 6, floor_t - 0.4])
            difference() {
                cube([cord_exit_w + 6, cord_clamp_t, 8.4], center = false);
                translate([3, -0.1, 3.4])
                    cube([cord_exit_w, cord_clamp_t + 0.2, cord_exit_h]);
            }
    }
}

module box() {
    difference() {
        outer_shell();
        inner_cavity();
        front_cutouts();
        back_cutouts();
        front_labels();
        back_labels();
        // Open the top for the lid
        translate([0, 0, floor_t + inner_z])
            cube([inner_x + 2 * wall + 2, inner_y + 2 * wall + 2, 4], center = true);
    }
    lid_insert_posts();
    placeholder_standoffs();
    pause_ring();
    cord_clamps();
}

module lid() {
    difference() {
        rounded_box([inner_x + 2 * wall, inner_y + 2 * wall, lid_t], corner_r);
        // Screw holes + counterbores matching the insert posts
        positions = [
            [-(inner_x / 2 - 4), -(inner_y / 2 - 4)],
            [ (inner_x / 2 - 4), -(inner_y / 2 - 4)],
            [-(inner_x / 2 - 4),  (inner_y / 2 - 4)],
            [ (inner_x / 2 - 4),  (inner_y / 2 - 4)]
        ];
        for (p = positions) {
            translate([p[0], p[1], -0.1])
                cylinder(h = lid_t + 0.2, d = screw_clear);
            translate([p[0], p[1], lid_t - 1.4])
                cylinder(h = 2, d = lid_recess);
        }
        translate([0, 0, lid_t - label_h + 0.01])
            label("AAC SCANNER", 8);
    }
}

if (part == "box") {
    box();
} else if (part == "lid") {
    lid();
} else {
    box();
    translate([0, 0, floor_t + inner_z + 2])
        lid();
}
