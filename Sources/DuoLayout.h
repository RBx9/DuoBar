#ifndef DUO_LAYOUT_H
#define DUO_LAYOUT_H

#include <math.h>

// Pure glyph geometry, kept free of UIKit so tests/layout-test.c can check the
// placement rules off-device. All values are points in the status-bar
// container's coordinate space.
typedef struct {
    double x, y, width, height;
} DuoGlyphFrame;

// minX/minY/maxX/maxY: the container's bounds.
// areaMaxX: right edge of the visible native indicators.
// batteryMidY: vertical centre of the native battery (or of the indicators).
// visibleMinY/visibleMaxY: the part of the container that can be seen, i.e.
// its window intersected with every clipping ancestor. Pass a non-finite or
// empty range when it is unknown.
static inline DuoGlyphFrame DuoComputeGlyphFrame(double minX, double minY, double maxX, double maxY,
        double areaMaxX, double batteryMidY, double scale, double visibleMinY, double visibleMaxY) {
    double containerHeight = maxY - minY;
    // At 100% keep the exact v0.2.2 geometry. Larger sizes may overhang the
    // status bar's padding so compact containers can still enlarge the glyph.
    double height = fmin(30.0, containerHeight - 2.0) * scale;

    // An overhang may only use space that is actually visible. A 20 pt status
    // bar at the top of the screen (Home-button iPhones such as the 8 Plus)
    // has nothing above it, so an enlarged glyph centred on the battery rose
    // off-screen. Limits never pass the container's own edges, so DuoBar still
    // moves with a status bar that slides away.
    double topLimit = -INFINITY, bottomLimit = INFINITY;
    if (visibleMaxY - visibleMinY > 10.0) {
        topLimit = fmin(visibleMinY, minY);
        bottomLimit = fmax(visibleMaxY, maxY);
        // A clipping ancestor smaller than the glyph: shrink rather than cut.
        height = fmin(height, bottomLimit - topLimit - 2.0);
    }

    double width = height * 32.0 / 34.0;
    double x = fmax(minX, fmin(areaMaxX - width, maxX - width));
    double extra = fmax(0.0, height - (containerHeight - 2.0)) / 2.0;
    double y = fmax(minY + 1.0 - extra, fmin(batteryMidY - height / 2.0, maxY - height - 1.0 + extra));
    if (y < topLimit + 1.0) {
        y = topLimit + 1.0;
    } else if (y + height > bottomLimit - 1.0) {
        y = fmax(topLimit + 1.0, bottomLimit - 1.0 - height);
    }
    DuoGlyphFrame frame = {x, y, width, height};
    return frame;
}

// Control Center draws its own status bar and, when it closes, animates that
// bar into the place of the Home Screen's before hiding it. DuoBar therefore
// uses the Home Screen's rule here as well: centred on the battery, right edge
// on the indicators, and limited only by visible space. Clamping it inside
// Control Center's shorter (44 pt) container, or the old 12 pt offset, left it
// up to 12 pt right and 7 pt higher than the Home Screen's DuoBar, so it
// jumped down and left at the moment Control Center finished closing.
static inline DuoGlyphFrame DuoComputeControlCenterGlyphFrame(double minX, double maxX, double containerHeight,
        double areaMaxX, double batteryMidY, double scale, double visibleMinY, double visibleMaxY) {
    double height = fmin(30.0, containerHeight - 2.0) * scale;
    int limited = visibleMaxY - visibleMinY > 10.0;
    if (limited) height = fmin(height, visibleMaxY - visibleMinY - 2.0);
    double width = height * 32.0 / 34.0;
    double x = fmax(minX, fmin(areaMaxX - width, maxX - width));
    double y = batteryMidY - height / 2.0;
    if (limited) y = fmax(visibleMinY + 1.0, fmin(y, visibleMaxY - 1.0 - height));
    DuoGlyphFrame frame = {x, y, width, height};
    return frame;
}

#endif
