// Switch2GO AAC Companion electronics case.
// Housing adapted from the Switch2Select enclosure (switch2select.scad).
// Copyright (C) 2026 Switch2Select contributors
// SPDX-License-Identifier: CERN-OHL-W-2.0
// Original hardware design. Inspired by Chatterbox, Copyright (c) 2025 Neil Squire.
// https://github.com/makersmakingchange/Chatterbox
//
// Student wall (y = 0): scan-switch jack, and the LED-strip port
// (female 3-prong: +5 V, DO/DIN, GND). The four input jacks are gone.
// Partner wall (y = outer_y): four output cord holes and the pause/resume
// button. Short wall at x = 0: female USB-C power inlet.

// "bottom", "lid", or "both" (bottom and lid side by side).
part = "both"; // [bottom, lid, both]

// Assembled outside size. The lid skin sits on the bottom rim.
outer_x = 200;
// Clears the scan cradle on the student wall and the wrap rods on the
// output wall, with room between them for the ESP32 and relay modules.
outer_y = 140;
outer_z = 55;
wall = 2.4;
// Outside vertical corners. Flat faces keep the full outside size.
corner_r = 6;
// Outside bottom edges. Same 2 mm as the long edges of the simple stand.
// Kept under the wall thickness so the floor and the sides stay flat above it.
bottom_edge_r = 2;

floor_t = wall;
lid_t = wall;
bottom_z = outer_z - lid_t;

// Lid lip drops inside the bottom opening.
fit_gap = 0.4;
lip_t = 2;
lip_h = 4;
// Outside bevel on the free edge, so the lip finds the opening.
lip_lead = 0.8;
layout_gap = 20;

// Corner bosses in the bottom; M3 clearance holes in the lid.
// The post is only the pilot plus a short blind floor. Below that it slopes
// into the corner walls instead of standing on the floor. The lid screws
// load the threads; the two walls hold the post.
m3_clear = 3.4;
m3_tap = 2.8;
boss_od = 12;
boss_inset = 8;
pilot_depth = 10;
// Below the rim, so the lid sits on the wall. A 0.2 mm layer cannot close it.
boss_top_gap = 0.4;
boss_floor = 2;
// Runout into the corner. Long enough that the underside stays within
// 45 degrees of vertical, so it prints without support.
boss_run = 16;
// Buried in the corner wall. The bridge from the post to this nub closes
// the gap between the post and the inner fillet.
nub_d = 1.6;

// Scan switch: a 3.5 mm jack pushes in through a 9.1 mm hole. The cradle is
// a hair larger and as deep as the jack cylinder. A shoulder stops the
// cylinder. The cord leaves through that shoulder. The passage is open at
// the top so the lead drops in. A round cord binds in a passage of its own
// width, so the opening is 0.4 mm larger and no more.
jack_d = 9.1;
jack_cradle_clear = 0.4;
jack_body_len = 27.3;
jack_cradle_wall = 2.4;
jack_stop_t = 4;
cradle_bite = 0.2;
// Lead in the scan-jack cradle. Output cords use output_cord_d, not this.
cord_diameter = 6.6;
cord_clear = 0.4;

// Pause/resume. button_d is the finished hole diameter. The hold button is gone.
button_d = 13.4;
button_back = 9;
button_back_gap = 7.55;
button_back_t = 2.4;
// Rails beside each button. Facing the partner wall from outside, +X is
// left, so the station's left wall is the +X rail of the pause button.
button_rail = 2.4;
button_rail_gap = 0.8;
button_bar_t = 2.4;

// Female USB-C power inlet on the short wall at x = 0 (the numeral 1 end),
// the same side as before. usb_z is the center of the opening above the
// outside bottom. The bottom of the cutout is the resting edge of the
// connector body, usb_floor_gap above the interior floor (z = floor_t).
usb_w = 13.2;
usb_h = 8;
usb_clear = 2;
usb_floor_gap = 3;
usb_z = floor_t + usb_floor_gap + usb_h / 2;
usb_y = outer_y / 2;

// Four output cords, one per choice. The student-wall input jacks that
// used to share this spacing are gone.
option_count = 4;
jack_margin = 40;
// Scan-jack center height. Was 16, under the four input jacks at 28.
// Those jacks are removed, so the scan jack moves up into that open wall.
scan_z = 32;
// Center height of each output cord hole.
output_z = 40;
// Round hole the output cord passes through. The plug stays outside.
output_cord_d = 4;
control_z = 16;

// Facing the partner wall from outside, left is +X.
// Pause/resume of the selection. The hole stays here; the labels shift.
pause_x = 140;

// One pair of rods per output cord, centered on that hole. Four cords,
// eight rods. The foot is wider than the shaft and runs through the floor
// so each post is printed as part of the case. Port spacing is 40 mm and
// a pair's feet span 28 mm, so diameter and pitch stay as they are.
// Height was 22 mm. The posts now stop wrap_rod_lid_gap under the lid's
// inner face (the rim, at bottom_z). The lid lip hangs lower, but only
// along the wall, inboard of these posts, so it does not limit the height.
wrap_rod_d = 8;
wrap_rod_lid_gap = 2.5;
wrap_rod_h = bottom_z - wrap_rod_lid_gap;
wrap_rod_clear = 8;
wrap_rod_pitch = wrap_rod_d + wrap_rod_clear;
wrap_rod_foot_extra = 2;
wrap_rod_foot_gap = 2;

// Stand bolts through the lid. enclosure/stand.scad uses these same centers.
stand_bolt_y = 94;
stand_bolt_xs = [28, 64, 136, 172];

// Card-ring harness enters through the lid. stand.scad repeats this opening.
ring_port_x = 114;
ring_port_y = 96;
ring_port_w = 12;
ring_port_h = 10;

// Hole across the cradle, just under the jack. 4 mm clears a small zip tie.
// The center sits less than a radius below the seat, so the hole opens
// into the channel and the tie can loop the jack body.
zip_d = 4;
zip_seat_drop = 0.6;

// Proud height of the raised Latin letters. The sink embeds them in the wall.
raise_h = 0.8;
raise_sink = 0.2;
numeral_size = 6;
numeral_dx = 12;
mark_gap = 2.2;
label_font = "Liberation Sans:style=Bold";

// Grade 1 braille, uncontracted: one cell per letter, and a number sign
// plus one cell per digit. Dot shape matches the Switch2Select braille.
// Proud height is 0.8 mm so an FDM layer can form the cap.
braille_dot_d = 1.5;
braille_dot_h = 0.8;
braille_dot_spacing = 2.5;
braille_cell_spacing = 6.5;
braille_gap = 2;
braille_embed = 0.04;
braille_fn = 32;

grill_x = 42;
grill_y = 32;
grill_slot_w = 3;
grill_slot_n = 7;

button_mark_z = control_z + button_d / 2 + mark_gap + numeral_size / 2;
grill_slot_rib = (grill_y - grill_slot_n * grill_slot_w) / (grill_slot_n - 1);
lip_notch = boss_inset + boss_od / 2 + 1.5 - wall - fit_gap;
raise_total = raise_h + raise_sink;

jack_id = jack_d + jack_cradle_clear;
jack_outer_w = jack_id + 2 * jack_cradle_wall;
cord_hole_d = cord_diameter + cord_clear;
// Inward face of the student shoulder. The bite overlaps the wall only,
// so the pocket from the inner face is the full jack body.
student_cradle_end = wall + jack_body_len + jack_stop_t;
braille_dot_r = braille_dot_d / 2;

// Print sits just under the scan jack. Braille spelling "scan" is under that.
scan_text_z = scan_z - jack_d / 2 - mark_gap - numeral_size / 2;
scan_braille_z = scan_text_z - numeral_size / 2 - braille_gap - braille_dot_r;
// Digit braille is above its numeral.
choice_braille_z = output_z + numeral_size / 2 + braille_gap
  + 2 * braille_dot_spacing + braille_dot_r;
// "pause" braille sits under the raised word. Beside the letters, the
// cells ran into the print. The cells are wider than the word, so the
// block is shifted toward -X until it also clears the pause hole.
pause_label_gap = 2;
pause_braille_z = button_mark_z - numeral_size / 2 - pause_label_gap - braille_dot_r;

// Partner-wall braille reads toward -X. This is dot 1 of the first cell
// when the word is centered on center_x.
function partner_braille_x(center_x, n) =
  center_x + word_w(n) / 2 - braille_dot_r;

// Student-wall braille reads toward +X.
function student_braille_x(center_x, n) =
  center_x - word_w(n) / 2 + braille_dot_r;

function option_x(i) =
  jack_margin + i * (outer_x - 2 * jack_margin) / (option_count - 1);

// Inboard face of the button cross-bar. Wrap rods sit just inside this.
function button_y_bar() =
  outer_y - wall - button_back_gap - button_back_t - button_bar_t;

function wrap_rod_y() =
  button_y_bar() - wrap_rod_foot_gap - (wrap_rod_d / 2 + wrap_rod_foot_extra);

function corner_x(i) = (i == 1 || i == 3) ? outer_x - boss_inset : boss_inset;
function corner_y(i) = (i >= 2) ? outer_y - boss_inset : boss_inset;

function boss_straight_z() =
  bottom_z - boss_top_gap - pilot_depth - boss_floor;

// Mid-wall on the diagonal, inside the outer skin and past the inner fillet.
function corner_nub_reach() = corner_r - wall / 2;

function corner_nub_xy(i) = [
  (corner_x(i) < outer_x / 2 ? corner_r : outer_x - corner_r)
    + (corner_x(i) < outer_x / 2 ? -1 : 1) * corner_nub_reach() / sqrt(2),
  (corner_y(i) < outer_y / 2 ? corner_r : outer_y - corner_r)
    + (corner_y(i) < outer_y / 2 ? -1 : 1) * corner_nub_reach() / sqrt(2)
];

// From the nub to the far side of the post. The runout has to be at least this
// long or the underside overhangs past 45 degrees.
function boss_far() =
  sqrt(
    pow(corner_x(0) - corner_nub_xy(0)[0], 2)
    + pow(corner_y(0) - corner_nub_xy(0)[1], 2)
  ) + boss_od / 2;

function dot_offset(d) = [
  d > 3 ? braille_dot_spacing : 0,
  -((d - 1) % 3) * braille_dot_spacing
];

function word_w(n) = (n - 1) * braille_cell_spacing + braille_dot_spacing + braille_dot_d;

// Advance widths of Liberation Sans Bold at numeral_size.
power_text_w = 17.7;
pause_text_w = 17.34;
scan_text_w = 13.68;
// Raised "pause" is shifted along -X, off the hole center. Braille is
// under that word. Its right edge stops pause_label_gap short of the hole.
pause_text_x = pause_x - button_d / 2 - pause_label_gap - pause_text_w / 2;
pause_braille_x = pause_x - button_d / 2 - pause_label_gap - word_w(5) / 2;
// Student wall (y = 0). 15 mm along X, 9.5 mm vertical. Female 3-prong
// LED-strip connector: +5 V, DO/DIN, GND. Moved along +X so the opening
// and the "port" label clear the scan jack and its labels.
front_cut_w = 15;
front_cut_h = 9.5;
front_cut_gap = 4;
front_cut_x = outer_x / 2 + word_w(4) + front_cut_gap;
front_cut_z = bottom_z / 2;
port_text_w = 11.66;
port_text_z = front_cut_z + front_cut_h / 2 + pause_label_gap + numeral_size / 2;
port_braille_z = port_text_z + numeral_size / 2 + pause_label_gap
  + 2 * braille_dot_spacing + braille_dot_r;
// Above the power opening on the numeral 1 short wall.
usb_top = usb_z + usb_h / 2;
power_text_y = usb_y;
power_text_z = usb_top + usb_clear + numeral_size / 2;

// Grade 1 "power" above those letters. Origin is dot 1 of the first cell.
// Facing this wall from outside, the word reads toward -Y.
power_braille_y = usb_y + (word_w(5) - braille_dot_d) / 2;
power_braille_z = power_text_z + numeral_size / 2 + usb_clear + braille_dot_r
  + 2 * braille_dot_spacing;

module rounded_prism(size, r) {
  hull() {
    for (x = [r, size[0] - r])
      for (y = [r, size[1] - r])
        translate([x, y, 0])
          cylinder(h = size[2], r = r, $fn = 64);
  }
}

// Quarter torus for one bottom corner. Starts along +X and sweeps toward +Y.
module bottom_corner_torus(r_major, r_minor) {
  rotate_extrude(angle = 90, $fn = 64)
    translate([r_major, 0])
      circle(r = r_minor, $fn = 32);
}

// Vertical corners stay at corner_r. The bottom edge is a smaller radius,
// and the top face stays flat for the lid.
module rounded_bottom_prism(size, corner_r, edge_r) {
  cr = corner_r;
  er = edge_r;
  overlap = 0.02;
  translate([0, 0, er - overlap])
    rounded_prism([size[0], size[1], size[2] - er + overlap], cr);
  translate([er, er, 0])
    rounded_prism([size[0] - 2 * er, size[1] - 2 * er, er + overlap], cr - er);
  translate([cr - overlap, er, er])
    rotate([0, 90, 0])
      cylinder(h = size[0] - 2 * cr + 2 * overlap, r = er, $fn = 64);
  translate([cr - overlap, size[1] - er, er])
    rotate([0, 90, 0])
      cylinder(h = size[0] - 2 * cr + 2 * overlap, r = er, $fn = 64);
  translate([er, cr - overlap, er])
    rotate([-90, 0, 0])
      cylinder(h = size[1] - 2 * cr + 2 * overlap, r = er, $fn = 64);
  translate([size[0] - er, cr - overlap, er])
    rotate([-90, 0, 0])
      cylinder(h = size[1] - 2 * cr + 2 * overlap, r = er, $fn = 64);
  translate([cr, cr, er])
    rotate([0, 0, 180])
      bottom_corner_torus(cr - er, er);
  translate([size[0] - cr, cr, er])
    rotate([0, 0, -90])
      bottom_corner_torus(cr - er, er);
  translate([cr, size[1] - cr, er])
    rotate([0, 0, 90])
      bottom_corner_torus(cr - er, er);
  translate([size[0] - cr, size[1] - cr, er])
    bottom_corner_torus(cr - er, er);
}

module hole_y(x, z, d, y0, depth) {
  translate([x, y0, z])
    rotate([-90, 0, 0])
      cylinder(h = depth, d = d, $fn = 64);
}

module slot_y(x, z, w, h, y0, depth) {
  translate([x - w / 2, y0, z - h / 2])
    cube([w, depth, h]);
}

// w runs along Y. The numeral 1 end is the face at x = 0.
module slot_x(y, z, w, h, x0, depth) {
  translate([x0, y - w / 2, z - h / 2])
    cube([depth, w, h]);
}

module student_cutouts() {
  // Scan switch only. The four input-method jacks are not cut.
  hole_y(outer_x / 2, scan_z, jack_d, -1, wall + 2);
  // LED-strip port. Rectangular through-cut: front_cut_w along X,
  // front_cut_h vertical. Female 3-prong: +5 V, DO/DIN, GND.
  slot_y(front_cut_x, front_cut_z, front_cut_w, front_cut_h, -1, wall + 2);
}

module partner_cutouts() {
  y0 = outer_y - wall - 1;
  depth = wall + 2;
  // Round cord holes, one per choice. Diameter is output_cord_d.
  for (i = [0:option_count - 1])
    hole_y(option_x(i), output_z, output_cord_d, y0, depth);
  // Pause/resume of the selection.
  hole_y(pause_x, control_z, button_d, y0, depth);
}

// Power lead on the short wall at the numeral 1 end. No microSD slot.
module end_cutouts() {
  slot_x(usb_y, usb_z, usb_w, usb_h, -1, wall + 2);
}

// U cradle opening upward. The back is a shoulder around the cord passage.
// The passage is open above the cord so the lead drops in. The jack is
// wider than that opening, so the shoulder still stops the cylinder.
// inward is +1 on the student wall and -1 on the partner wall.
module jack_cradle(x, z, y_inner, inward) {
  id = jack_id;
  t = jack_cradle_wall;
  len = jack_body_len;
  y0 = y_inner - inward * cradle_bite;
  y_far = y_inner + inward * len;
  y_a = min(y0, y_far);
  y_b = max(y0, y_far);
  y_stop = y_far + inward * jack_stop_t;
  ys_a = min(y_far, y_stop);
  ys_b = max(y_far, y_stop);
  translate([x - id / 2 - t, y_a, z - id / 2 - t])
    cube([jack_outer_w, y_b - y_a, t]);
  translate([x - id / 2 - t, y_a, z - id / 2])
    cube([t, y_b - y_a, id]);
  translate([x + id / 2, y_a, z - id / 2])
    cube([t, y_b - y_a, id]);
  difference() {
    translate([x - id / 2 - t, ys_a, z - id / 2 - t])
      cube([jack_outer_w, ys_b - ys_a, id + t]);
    translate([x, ys_a - 0.4, z])
      rotate([-90, 0, 0])
        cylinder(h = ys_b - ys_a + 0.8, d = cord_hole_d, $fn = 48);
    translate([x - cord_hole_d / 2, ys_a - 0.4, z])
      cube([cord_hole_d, ys_b - ys_a + 0.8, id / 2 + t + 1]);
  }
}

module jack_buttress(x, z, y_inner, inward) {
  len = jack_body_len + jack_stop_t;
  y0 = y_inner - inward * cradle_bite;
  y_far = y_inner + inward * len;
  y_a = min(y0, y_far);
  y_b = max(y0, y_far);
  top = z - jack_id / 2 - jack_cradle_wall + 0.05;
  if (top > 0)
    translate([x - jack_outer_w / 2, y_a, 0])
      cube([jack_outer_w, y_b - y_a, top]);
}

// Across the cradle (along X), so the tie crosses the plug axis (Y).
// The top of the hole breaks into the channel and the tie loops the jack.
module jack_zip_cut(x, z, y_inner, inward) {
  seat = z - jack_id / 2;
  y_mid = y_inner + inward * (jack_body_len / 2);
  translate([x - jack_outer_w / 2 - 0.8, y_mid, seat - zip_seat_drop])
    rotate([0, 90, 0])
      cylinder(h = jack_outer_w + 1.6, d = zip_d, $fn = 24);
}

module student_jack_hardware() {
  // Scan cradle only. The buttress still runs to the floor so the higher
  // cradle is attached, the same way the low cradle was.
  difference() {
    union() {
      jack_cradle(outer_x / 2, scan_z, wall, 1);
      jack_buttress(outer_x / 2, scan_z, wall, 1);
    }
    jack_zip_cut(outer_x / 2, scan_z, wall, 1);
  }
}

// Two rods per output cord, centered on that hole, so each wire wraps
// its own pair. Shaft and foot both start at z = 0 and fuse with the floor.
module output_wrap_rods() {
  y_rod = wrap_rod_y();
  foot_h = floor_t + 1.2;
  for (i = [0:option_count - 1])
    for (s = [-1, 1])
      translate([option_x(i) + s * wrap_rod_pitch / 2, y_rod, 0]) {
        cylinder(h = wrap_rod_h, d = wrap_rod_d, $fn = 48);
        cylinder(h = foot_h, d = wrap_rod_d + 2 * wrap_rod_foot_extra, $fn = 48);
      }
}

// 9 mm square the button hits, 7.55 mm behind the inner face.
// Rails stay outside the hole and run down to the floor.
// omit_left_wall drops the +X rail. That is the left wall when facing
// the partner wall from outside.
module button_backing(x, z, omit_left_wall = false) {
  y_inner = outer_y - wall;
  y_hit = y_inner - button_back_gap;
  y_back = y_hit - button_back_t;
  y_bar = y_back - button_bar_t;
  rail_reach = y_inner + 0.2 - y_bar;
  plate_top = z + button_back / 2;
  x_rail_neg = x - (button_d / 2 + button_rail_gap) - button_rail;
  bar_end = omit_left_wall
    ? x + button_d / 2
    : x + button_d / 2 + button_rail_gap + button_rail;
  translate([x - button_back / 2, y_back - 0.05, z - button_back / 2])
    cube([button_back, button_back_t + 0.05, button_back]);
  translate([x_rail_neg, y_bar, z - button_back / 2])
    cube([bar_end - x_rail_neg, button_bar_t, button_back]);
  translate([x_rail_neg, y_bar, 0])
    cube([button_rail, rail_reach, plate_top]);
  if (!omit_left_wall)
    translate([x + button_d / 2 + button_rail_gap, y_bar, 0])
      cube([button_rail, rail_reach, plate_top]);
}

module corner_bosses() {
  z0 = boss_straight_z();
  h = pilot_depth + boss_floor;
  for (i = [0:3]) {
    nx = corner_nub_xy(i)[0];
    ny = corner_nub_xy(i)[1];
    hull() {
      translate([corner_x(i), corner_y(i), z0])
        cylinder(h = h, d = boss_od, $fn = 64);
      translate([nx, ny, z0])
        cylinder(h = h, d = nub_d, $fn = 24);
    }
    hull() {
      translate([corner_x(i), corner_y(i), z0])
        cylinder(h = 0.2, d = boss_od, $fn = 64);
      translate([nx, ny, z0])
        cylinder(h = 0.2, d = nub_d, $fn = 24);
      translate([nx, ny, z0 - boss_run])
        cylinder(h = 0.2, d = nub_d, $fn = 24);
    }
  }
}

module corner_pilots() {
  for (i = [0:3])
    translate([
      corner_x(i),
      corner_y(i),
      bottom_z - boss_top_gap - pilot_depth
    ])
      cylinder(h = pilot_depth + 1, d = m3_tap, $fn = 32);
}

module glyph_student(x, z, label, size) {
  translate([x, raise_sink, z])
    rotate([90, 0, 0])
      linear_extrude(height = raise_total)
        text(label, size = size, font = label_font, halign = "center", valign = "center");
}

// Outside face at x = 0. Facing that wall, the word reads toward -Y.
module glyph_end(y, z, label, size) {
  translate([raise_sink, y, z])
    rotate([0, 0, -90])
      rotate([90, 0, 0])
        linear_extrude(height = raise_total)
          text(label, size = size, font = label_font, halign = "center", valign = "center");
}

module glyph_partner(x, z, label, size) {
  translate([x, outer_y + raise_h, z])
    rotate([90, 0, 0])
      mirror([1, 0, 0])
        linear_extrude(height = raise_total)
          text(label, size = size, font = label_font, halign = "center", valign = "center");
}

// Rod plus hemisphere, same construction as braille-label. The total
// length includes a short embed so the dot fuses with the wall; the
// part outside the wall is braille_dot_h.
module braille_dot() {
  eps = 0.01;
  total_h = braille_dot_h + braille_embed;
  cap_r = min(braille_dot_r, total_h);
  stem_h = total_h - cap_r;
  if (stem_h > 0)
    translate([0, 0, -eps])
      cylinder(r = braille_dot_r, h = stem_h + eps, $fn = braille_fn);
  if (cap_r == braille_dot_r)
    translate([0, 0, stem_h])
      intersection() {
        sphere(r = braille_dot_r, $fn = braille_fn);
        translate([-braille_dot_r - eps, -braille_dot_r - eps, -eps])
          cube([
            2 * braille_dot_r + 2 * eps,
            2 * braille_dot_r + 2 * eps,
            braille_dot_r + 2 * eps
          ]);
      }
  else {
    R = (braille_dot_r * braille_dot_r + total_h * total_h) / (2 * total_h);
    intersection() {
      translate([0, 0, total_h - R])
        sphere(r = R, $fn = braille_fn);
      translate([0, 0, -eps])
        cylinder(r = braille_dot_r + eps, h = total_h + eps, $fn = braille_fn);
    }
  }
}

module student_dot(x, z) {
  translate([x, braille_embed, z])
    rotate([90, 0, 0])
      braille_dot();
}

// Outside face at x = 0. Same construction as the student wall, turned so
// the dots leave through that face.
module end_dot(y, z) {
  translate([braille_embed, y, z])
    rotate([0, 0, -90])
      rotate([90, 0, 0])
        braille_dot();
}

module partner_dot(x, z) {
  translate([x, outer_y - braille_embed, z])
    rotate([-90, 0, 0])
      braille_dot();
}

module student_braille(origin_x, origin_z, cells) {
  for (ci = [0:len(cells) - 1])
    for (d = cells[ci])
      student_dot(
        origin_x + ci * braille_cell_spacing + dot_offset(d)[0],
        origin_z + dot_offset(d)[1]
      );
}

module partner_braille(origin_x, origin_z, cells) {
  for (ci = [0:len(cells) - 1])
    for (d = cells[ci])
      partner_dot(
        origin_x - ci * braille_cell_spacing - dot_offset(d)[0],
        origin_z + dot_offset(d)[1]
      );
}

// Facing the numeral 1 end from outside, cells run toward -Y.
module end_braille(origin_y, origin_z, cells) {
  for (ci = [0:len(cells) - 1])
    for (d = cells[ci])
      end_dot(
        origin_y - ci * braille_cell_spacing - dot_offset(d)[0],
        origin_z + dot_offset(d)[1]
      );
}

// Grade 1 digits: number sign, then a-d, so the cells read 1-4 and not a-d.
function digit_cells(n) =
  n == 1 ? [[3, 4, 5, 6], [1]] :
  n == 2 ? [[3, 4, 5, 6], [1, 2]] :
  n == 3 ? [[3, 4, 5, 6], [1, 4]] :
  [[3, 4, 5, 6], [1, 4, 5]];

// Grade 1 "scan".
word_scan = [[2, 3, 4], [1, 4], [1], [1, 3, 4, 5]];
// Grade 1 "power".
word_power = [[1, 2, 3, 4], [1, 3, 5], [2, 4, 5, 6], [1, 5], [1, 2, 3, 5]];
// Grade 1 "pause" (pause/resume of the selection).
word_pause = [[1, 2, 3, 4], [1], [1, 3, 6], [2, 3, 4], [1, 5]];
// Grade 1 "port": the LED-strip connector (+5 V, DO/DIN, GND).
word_port = [[1, 2, 3, 4], [1, 3, 5], [1, 2, 3, 5], [2, 3, 4, 5]];

module student_marks() {
  // Raised "scan" under the jack, then braille spelling scan.
  glyph_student(outer_x / 2, scan_text_z, "scan", numeral_size);
  student_braille(student_braille_x(outer_x / 2, 4), scan_braille_z, word_scan);
  // Raised "port" above the 15 x 9.5 mm opening, then braille spelling port.
  glyph_student(front_cut_x, port_text_z, "port", numeral_size);
  student_braille(student_braille_x(front_cut_x, 4), port_braille_z, word_port);
}

module partner_marks() {
  for (i = [0:option_count - 1]) {
    // Raised choice number, with Grade 1 digit braille above it.
    glyph_partner(option_x(i) + numeral_dx, output_z, str(i + 1), numeral_size);
    partner_braille(
      partner_braille_x(option_x(i) + numeral_dx, 2),
      choice_braille_z,
      digit_cells(i + 1)
    );
  }
  // Pause/resume. Letters are to -X of the hole. Braille spelling pause
  // is under those letters, clear of the hole.
  glyph_partner(pause_text_x, button_mark_z, "pause", numeral_size);
  partner_braille(partner_braille_x(pause_braille_x, 5), pause_braille_z, word_pause);
}

module end_marks() {
  glyph_end(power_text_y, power_text_z, "power", numeral_size);
  end_braille(power_braille_y, power_braille_z, word_power);
}

module bottom() {
  difference() {
    union() {
      difference() {
        rounded_bottom_prism([outer_x, outer_y, bottom_z], corner_r, bottom_edge_r);
        translate([wall, wall, floor_t])
          rounded_prism([
            outer_x - 2 * wall,
            outer_y - 2 * wall,
            bottom_z - floor_t + 1
          ], corner_r - wall);
        student_cutouts();
        partner_cutouts();
        end_cutouts();
      }
      corner_bosses();
      student_marks();
      partner_marks();
      end_marks();
      student_jack_hardware();
      output_wrap_rods();
      // Left wall of the pause station omitted: the +X rail.
      button_backing(pause_x, control_z, true);
    }
    corner_pilots();
  }
}

// Triangular prism along +X. The right angle is the near top edge. +Y and -Z
// are the legs, so the cut removes the outside top corner of a lip.
module lip_bevel(length, c) {
  hull() {
    cube([length, 0.02, 0.02]);
    translate([0, c, 0])
      cube([length, 0.02, 0.02]);
    translate([0, 0, -c])
      cube([length, 0.02, 0.02]);
  }
}

module lid_lip() {
  ox = outer_x - 2 * (wall + fit_gap);
  oy = outer_y - 2 * (wall + fit_gap);
  top = lip_h + 0.2;
  translate([wall + fit_gap, wall + fit_gap, lid_t - 0.2])
    difference() {
      cube([ox, oy, top]);
      translate([lip_t, lip_t, -1])
        cube([ox - 2 * lip_t, oy - 2 * lip_t, lip_h + 2]);
      for (px = [0, ox - lip_notch])
        for (py = [0, oy - lip_notch])
          translate([px, py, -1])
            cube([lip_notch, lip_notch, lip_h + 2]);
      // Free edge is +Z. Bevel the outside so the lip finds the opening.
      translate([0, 0, top])
        lip_bevel(ox, lip_lead);
      translate([0, oy, top])
        mirror([0, 1, 0])
          lip_bevel(ox, lip_lead);
      translate([0, oy, top])
        rotate([0, 0, -90])
          lip_bevel(oy, lip_lead);
      translate([ox, 0, top])
        rotate([0, 0, 90])
          lip_bevel(oy, lip_lead);
    }
}

module speaker_grill() {
  pitch = grill_slot_w + grill_slot_rib;
  for (i = [0:grill_slot_n - 1])
    translate([
      -grill_x / 2,
      -grill_y / 2 + i * pitch,
      -1
    ])
      cube([grill_x, grill_slot_w, lid_t + 2]);
}

module lid_screw_holes() {
  for (i = [0:3])
    translate([corner_x(i), corner_y(i), -1])
      cylinder(h = lid_t + lip_h + 2, d = m3_clear, $fn = 48);
}

module lid() {
  difference() {
    union() {
      rounded_prism([outer_x, outer_y, lid_t], corner_r);
      lid_lip();
    }
    lid_screw_holes();
    translate([outer_x / 2, outer_y / 2, 0])
      speaker_grill();
    ring_cable_port();
    stand_bolt_holes();
  }
}

module ring_cable_port() {
  translate([
    ring_port_x - ring_port_w / 2,
    ring_port_y - ring_port_h / 2,
    -1
  ])
    cube([ring_port_w, ring_port_h, lid_t + 2]);
}

module stand_bolt_holes() {
  for (x = stand_bolt_xs)
    translate([x, stand_bolt_y, -1])
      cylinder(h = lid_t + 2, d = m3_clear, $fn = 32);
}

module enclosure() {
  if (part == "bottom")
    bottom();
  else if (part == "lid")
    lid();
  else if (part == "both") {
    bottom();
    translate([outer_x + layout_gap, 0, 0])
      lid();
  }
}

assert(
  part == "bottom" || part == "lid" || part == "both",
  "part must be \"bottom\", \"lid\", or \"both\""
);
assert(abs(button_d - 13.4) < 0.001, "button holes must be 13.4 mm");
assert(abs(output_cord_d - 4) < 0.001, "output cord holes must be 4 mm circles");
assert(
  (outer_x - 2 * jack_margin) / (option_count - 1)
    > wrap_rod_pitch + wrap_rod_d + 2 * wrap_rod_foot_extra,
  "output wrap-rod pairs collide"
);
assert(
  option_x(0) - wrap_rod_pitch / 2 - wrap_rod_d / 2 - wrap_rod_foot_extra > wall + 2 &&
    option_x(option_count - 1) + wrap_rod_pitch / 2 + wrap_rod_d / 2 + wrap_rod_foot_extra
      < outer_x - wall - 2,
  "wrap rods must stay inside the cavity"
);
assert(
  pause_x - button_d / 2 > corner_r &&
    pause_x + button_d / 2 < outer_x - corner_r &&
    control_z - button_d / 2 > bottom_edge_r + 2,
  "pause hole must stay on the flat partner wall"
);
assert(
  pause_text_x + pause_text_w / 2 + pause_label_gap <= pause_x - button_d / 2 &&
    pause_text_x - pause_text_w / 2 > corner_r,
  "pause letters must sit to -X of the hole on the flat wall"
);
assert(
  button_mark_z + numeral_size / 2 + 1 < output_z - output_cord_d / 2,
  "button labels must sit below the output cord holes"
);
assert(scan_z >= 28, "scan switch must sit in the band freed by the input jacks");
assert(
  scan_z - jack_d / 2 > bottom_edge_r + floor_t,
  "scan jack must stay on the flat student wall"
);
assert(
  bottom_z - lip_h > scan_z + jack_id / 2 + 2,
  "lid lip must clear the scan jack cradle"
);
assert(
  student_cradle_end + 4 < wrap_rod_y() - (wrap_rod_d / 2 + wrap_rod_foot_extra),
  "scan cradle collides with the wrap rods"
);
assert(
  wrap_rod_y() - (wrap_rod_d / 2 + wrap_rod_foot_extra) > stand_bolt_y + 8,
  "wrap rods collide with the stand bolt nuts"
);
assert(
  wrap_rod_lid_gap >= 2 && wrap_rod_lid_gap <= 3 &&
    abs(wrap_rod_h - (bottom_z - wrap_rod_lid_gap)) < 0.001,
  "wrap rods must stop 2 to 3 mm under the lid"
);
assert(
  wrap_rod_y() + wrap_rod_d / 2 + wrap_rod_foot_extra
    < outer_y - wall - fit_gap - lip_t - 2,
  "wrap rod feet must stay clear of the lid lip"
);
assert(abs(braille_dot_d - 1.5) < 0.001, "braille dot diameter must be 1.5 mm");
assert(abs(braille_dot_h - 0.8) < 0.001, "braille dot height must be 0.8 mm");
assert(abs(braille_dot_spacing - 2.5) < 0.001, "braille dot pitch must be 2.5 mm");
assert(
  braille_cell_spacing >= 6 && braille_cell_spacing <= 6.5,
  "braille cell pitch must be 6 to 6.5 mm"
);
assert(abs(raise_h - 0.8) < 0.001, "raised print height must be 0.8 mm");
assert(
  scan_text_z + numeral_size / 2 + 1 < scan_z - jack_d / 2 &&
    scan_braille_z + braille_dot_r + 1 < scan_text_z - numeral_size / 2 &&
    scan_braille_z - 2 * braille_dot_spacing - braille_dot_r > bottom_edge_r + 2 &&
    outer_x / 2 - scan_text_w / 2 > corner_r,
  "scan print and braille must sit under the jack on the flat wall"
);
assert(
  choice_braille_z - 2 * braille_dot_spacing - braille_dot_r
    > output_z + numeral_size / 2 + 1 &&
    choice_braille_z + braille_dot_r < bottom_z - 1 &&
    option_x(0) + numeral_dx - word_w(2) / 2 > corner_r &&
    option_x(option_count - 1) + numeral_dx + word_w(2) / 2 < outer_x - corner_r,
  "choice braille must sit above its numeral on the flat wall"
);
assert(
  pause_braille_z + braille_dot_r + pause_label_gap
    <= button_mark_z - numeral_size / 2 + 0.05 &&
    pause_braille_z - 2 * braille_dot_spacing - braille_dot_r > bottom_edge_r + 2 &&
    pause_braille_x + word_w(5) / 2 + pause_label_gap
      <= pause_x - button_d / 2 + 0.05 &&
    pause_braille_x - word_w(5) / 2 > corner_r + 4 &&
    pause_braille_z + braille_dot_r + 2 < output_z - output_cord_d / 2,
  "pause braille must clear the letters, the hole, and the cord holes"
);
assert(
  abs(front_cut_w - 15) < 0.001 && abs(front_cut_h - 9.5) < 0.001,
  "student-wall cutout must be 15 mm by 9.5 mm"
);
assert(
  front_cut_x - word_w(4) / 2 >= outer_x / 2 + word_w(4) / 2 + 4 &&
    front_cut_x + word_w(4) / 2 <= outer_x - corner_r - 4 &&
    front_cut_z - front_cut_h / 2 >= bottom_edge_r + 4 &&
    port_braille_z + braille_dot_r <= bottom_z - 4 &&
    port_text_z - numeral_size / 2 + 0.05
      >= front_cut_z + front_cut_h / 2 + 2,
  "port opening and labels must clear the scan labels, the wall ends, and the rim"
);
assert(cord_clear <= 0.4, "cord clearance must stay at or under 0.4 mm");
assert(cord_hole_d < jack_d, "cord opening must leave a shoulder on the jack end");
assert(corner_r - wall >= 2, "inner corner must stay printable");
assert(
  bottom_edge_r + 0.3 < wall && corner_r > 2 * bottom_edge_r,
  "bottom edge radius must leave a flat wall and fit the vertical corner"
);
assert(boss_floor >= 1.5, "boss needs a floor under the pilot");
assert(boss_top_gap >= 0.3, "boss must stay below the rim so the lid seats on the wall");
assert(
  sqrt(
    pow(wall + fit_gap + lip_notch - boss_inset, 2)
    + pow(wall + fit_gap + lip_t - boss_inset, 2)
  ) - boss_od / 2 >= 1.5,
  "lid lip must clear the corner boss"
);
assert(lip_lead >= 0.6 && lip_lead < lip_t && lip_lead < lip_h / 2, "lip lead-in must ease entry and leave a straight section");
assert(
  bottom_z - 1 > output_z + output_cord_d / 2 &&
    output_z - output_cord_d / 2 > bottom_edge_r + floor_t &&
    option_x(0) - output_cord_d / 2 > corner_r &&
    option_x(option_count - 1) + output_cord_d / 2 < outer_x - corner_r,
  "output cord holes must stay on the flat partner wall"
);
assert(
  corner_nub_reach() + nub_d / 2 < corner_r - 0.2,
  "corner nub must stay inside the outer skin"
);
assert(
  corner_nub_reach() - nub_d / 2 > corner_r - wall,
  "corner nub must sit in the wall"
);
assert(boss_run >= boss_far(), "boss runout overhangs more than 45 degrees");
assert(
  boss_straight_z() - boss_run > floor_t + 10,
  "boss runout must stay clear of the floor"
);
assert(
  wall + fit_gap + lip_notch > corner_r + (corner_r - wall) / sqrt(2) + 1,
  "lid lip notch must clear the rounded inner corner"
);
assert(zip_d >= 3 && zip_d <= 4, "zip tie hole must be 3 mm to 4 mm");
assert(zip_seat_drop < zip_d / 2, "zip tie hole must open into the jack channel");
assert(
  usb_z - usb_h / 2 >= bottom_edge_r + floor_t &&
    usb_y - usb_w / 2 >= corner_r &&
    usb_y + usb_w / 2 <= outer_y - corner_r,
  "power opening must stay on the flat short wall"
);
assert(abs(usb_floor_gap - 3) < 0.001, "USB-C must be 3 mm off the interior floor");
assert(
  abs((usb_z - usb_h / 2) - (floor_t + usb_floor_gap)) < 0.001,
  "USB-C cutout bottom must sit usb_floor_gap above the interior floor"
);
assert(abs(usb_y - outer_y / 2) < 0.001, "power opening must be centered on the short wall");
assert(
  power_text_z - numeral_size / 2 + 0.01 >= usb_top + usb_clear &&
    power_text_y - power_text_w / 2 >= corner_r &&
    power_text_y + power_text_w / 2 <= outer_y - corner_r,
  "power letters must sit above the opening on the flat short wall"
);
assert(
  power_braille_z - 2 * braille_dot_spacing - braille_dot_r + 0.01
    >= power_text_z + numeral_size / 2 + usb_clear &&
    power_braille_z + braille_dot_r < bottom_z - 1 &&
    power_braille_y + braille_dot_r <= outer_y - corner_r &&
    power_braille_y - (word_w(5) - braille_dot_d) - braille_dot_r >= corner_r,
  "power braille must sit above the letters on the flat short wall"
);
echo(scan_z = scan_z);
echo(usb_z = usb_z);
echo(usb_cutout_bottom = usb_z - usb_h / 2);
echo(usb_floor_gap = usb_floor_gap);
echo(output_cord_d = output_cord_d);
echo(button_d = button_d);
echo(pause_x = pause_x);
echo(pause_text_x = pause_text_x);
echo(pause_braille_x = pause_braille_x);
echo(pause_braille_z = pause_braille_z);
echo(front_cut_x = front_cut_x);
echo(front_cut_z = front_cut_z);
echo(wrap_rod_y = wrap_rod_y());
echo(cord_hole_d = cord_hole_d);

enclosure();
