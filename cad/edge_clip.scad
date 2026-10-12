// Trifold edge clip with a hood-arm mount (build guide Section 12.2).
// Measure your board thickness and set panel_thickness before printing.
// Starting sizes only — foam/poster trifolds vary.

$fn = 48;

panel_thickness = 5;        // measure yours
clip_width = 40;
clip_depth = 28;            // how far the U jaws go down the panel
clip_wall = 3;
clip_grip = 0.4;            // extra squeeze on the inner faces
fillet = 1.2;

arm_length = 40;            // reaches toward the choice surface
arm_w = 16;
arm_t = 4;
arm_drop = 8;               // slight drop so the hood sits above the panel

hood_mount_hole = 3.2;      // M3 clearance
hood_mount_cs = 6.2;        // counterbore for a button head

module rounded_cube(size, r) {
    hull() {
        for (x = [-1, 1], y = [-1, 1], z = [-1, 1])
            translate([
                x * (size[0] / 2 - r),
                y * (size[1] / 2 - r),
                z * (size[2] / 2 - r)
            ])
                sphere(r);
    }
}

module u_clip() {
    inner_t = panel_thickness - clip_grip;
    outer_t = inner_t + 2 * clip_wall;
    outer_h = clip_depth + clip_wall;

    difference() {
        translate([0, 0, outer_h / 2])
            rounded_cube([clip_width, outer_t, outer_h], fillet);

        // Slot that slides over the panel from -Z
        translate([0, 0, clip_depth / 2 - 0.1])
            cube([clip_width + 1, inner_t, clip_depth + 0.2], center = true);

        // Lead-in chamfer at the open end
        translate([0, 0, 0])
            rotate([0, 90, 0])
                linear_extrude(clip_width + 2, center = true)
                    polygon([
                        [0, -inner_t / 2 - 0.6],
                        [0, inner_t / 2 + 0.6],
                        [-3, inner_t / 2],
                        [-3, -inner_t / 2]
                    ]);
    }
}

module hood_arm() {
    difference() {
        union() {
            // Arm extends in +Y (toward the choice). Overlaps the clip body so they fuse.
            translate([0, arm_length / 2 - 2, clip_depth + clip_wall - arm_t / 2 - arm_drop])
                cube([arm_w, arm_length, arm_t], center = true);
            translate([0, clip_wall, clip_depth + clip_wall - arm_t / 2 - arm_drop / 2])
                cube([arm_w, clip_wall * 2, arm_t + arm_drop], center = true);
        }
        translate([0, arm_length + clip_wall / 2 - 8, clip_depth + clip_wall - arm_t / 2 - arm_drop])
            cylinder(h = arm_t + 2, d = hood_mount_hole, center = true);
        translate([0, arm_length + clip_wall / 2 - 8, clip_depth + clip_wall - arm_drop + 0.2])
            cylinder(h = 2, d = hood_mount_cs, center = true);
    }
}

union() {
    u_clip();
    hood_arm();
}
