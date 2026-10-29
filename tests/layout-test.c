// Off-device checks for DuoBar's glyph placement (Sources/DuoLayout.h).
// Build and run: cc -std=c99 -Wall -Wextra -Werror tests/layout-test.c -lm -o layout-test && ./layout-test
#include <math.h>
#include <stdio.h>

#include "../Sources/DuoLayout.h"

static int failures = 0;

#define CHECK(condition, ...) do { \
    if (!(condition)) { \
        failures++; \
        printf("FAIL %s:%d: ", __FILE__, __LINE__); \
        printf(__VA_ARGS__); \
        printf("\n"); \
    } \
} while (0)

// The v2.7.1/beta5 formula, used to prove that layouts which already fit on
// screen are unchanged.
static DuoGlyphFrame OldFrame(double minX, double minY, double maxX, double maxY,
        double areaMaxX, double batteryMidY, double scale) {
    double height = fmin(30.0, maxY - minY - 2.0) * scale;
    double width = height * 32.0 / 34.0;
    double x = fmax(minX, fmin(areaMaxX - width, maxX - width));
    double extra = fmax(0.0, height - (maxY - minY - 2.0)) / 2.0;
    double y = fmax(minY + 1.0 - extra, fmin(batteryMidY - height / 2.0, maxY - height - 1.0 + extra));
    DuoGlyphFrame frame = {x, y, width, height};
    return frame;
}

static int Same(DuoGlyphFrame a, DuoGlyphFrame b) {
    return fabs(a.x - b.x) < 1e-9 && fabs(a.y - b.y) < 1e-9 &&
           fabs(a.width - b.width) < 1e-9 && fabs(a.height - b.height) < 1e-9;
}

int main(void) {
    // Scales from the Settings slider: 70% to 140%.
    for (int step = 0; step <= 14; step++) {
        double scale = 0.70 + step * 0.05;

        // Face ID iPhones: notch (44-50 pt) and Dynamic Island (54-62 pt)
        // status bars at the top of the screen keep the exact previous frame
        // at every size.
        const double notchHeights[] = {44, 47, 48, 50, 54, 59, 62};
        for (int i = 0; i < 7; i++) {
            double h = notchHeights[i];
            DuoGlyphFrame old = OldFrame(0, 0, 390, h, 370, h / 2, scale);
            DuoGlyphFrame now = DuoComputeGlyphFrame(0, 0, 390, h, 370, h / 2, scale, 0, 844);
            CHECK(Same(old, now), "notch %.0fpt at %.0f%% changed: y %.2f -> %.2f", h, scale * 100, old.y, now.y);
        }

        // Compact Control Center containers sit below the top of the window:
        // their existing overhang is visible and must stay exactly as before.
        const double ccOffsets[] = {12, 20};
        for (int i = 0; i < 2; i++) {
            double top = -ccOffsets[i];
            DuoGlyphFrame old = OldFrame(0, 0, 120, 20, 110, 10, scale);
            DuoGlyphFrame now = DuoComputeGlyphFrame(0, 0, 120, 20, 110, 10, scale, top, 844 + top);
            CHECK(Same(old, now), "Control Center offset %.0f at %.0f%% changed", ccOffsets[i], scale * 100);
        }

        // iPhone 8 Plus (and other Home-button iPhones): a 20 pt status bar at
        // the very top of a 736 pt screen. Keep the chosen size, and never let
        // the ring rise above the screen edge.
        DuoGlyphFrame old = OldFrame(0, 0, 414, 20, 400, 10, scale);
        DuoGlyphFrame plus = DuoComputeGlyphFrame(0, 0, 414, 20, 400, 10, scale, 0, 736);
        CHECK(fabs(plus.height - old.height) < 1e-9, "8 Plus at %.0f%% resized %.2f -> %.2f",
              scale * 100, old.height, plus.height);
        CHECK(fabs(plus.x - old.x) < 1e-9, "8 Plus at %.0f%% moved horizontally", scale * 100);
        CHECK(plus.y >= 1.0 - 1e-9, "8 Plus at %.0f%% top is at %.2f pt, off or touching the screen edge",
              scale * 100, plus.y);
        if (old.y >= 1.0) CHECK(Same(old, plus), "8 Plus at %.0f%% changed although it fit", scale * 100);

        // A status bar sliding up off-screen keeps DuoBar at the same place
        // within the bar, so the glyph leaves together with it.
        DuoGlyphFrame sliding = DuoComputeGlyphFrame(0, 0, 414, 20, 400, 10, scale, 8, 744);
        CHECK(Same(plus, sliding), "sliding status bar at %.0f%% detached DuoBar", scale * 100);

        // If an ancestor clips to the 20 pt bar, shrink to fit instead of cutting the ring.
        DuoGlyphFrame clipped = DuoComputeGlyphFrame(0, 0, 414, 20, 400, 10, scale, 0, 20);
        CHECK(clipped.y >= 0 && clipped.y + clipped.height <= 20 + 1e-9,
              "clipped bar at %.0f%% cut the ring: %.2f..%.2f", scale * 100, clipped.y, clipped.y + clipped.height);

        // Unknown visibility falls back to the previous formula.
        DuoGlyphFrame unknown = DuoComputeGlyphFrame(0, 0, 414, 20, 400, 10, scale, NAN, NAN);
        CHECK(Same(old, unknown), "unknown visibility at %.0f%% changed the frame", scale * 100);
    }

    DuoGlyphFrame large = DuoComputeGlyphFrame(0, 0, 414, 20, 400, 10, 1.40, 0, 736);
    DuoGlyphFrame previous = OldFrame(0, 0, 414, 20, 400, 10, 1.40);
    printf("iPhone 8 Plus at 140%%: %.1f pt ring, top %.1f pt (was %.1f pt, above the screen)\n",
           large.height, large.y, previous.y);
    if (failures) {
        printf("%d layout check(s) failed\n", failures);
        return 1;
    }
    printf("All layout checks passed\n");
    return 0;
}
