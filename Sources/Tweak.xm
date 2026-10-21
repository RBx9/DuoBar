#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import "DuoGlyphView.h"

@interface _UIBatteryView : UIView
@property(nonatomic) double chargePercent;
@property(nonatomic) long long chargingState;
@property(nonatomic) BOOL saverModeActive;
@property(nonatomic, copy) UIColor *bodyColor;
@end

@interface _UIStatusBarSignalView : UIView
@property(nonatomic) long long numberOfActiveBars;
@property(nonatomic) long long numberOfBars;
@property(nonatomic, copy) UIColor *activeColor;
@end
@interface _UIStatusBarWifiSignalView : _UIStatusBarSignalView @end
// When connected to another iPhone's Personal Hotspot, iOS 16 often
// swaps the Wi-Fi strength view for a status-bar image/icon view.
@interface _UIStatusBarImageView : UIImageView @end
@interface _UIStatusBarCellularSignalView : _UIStatusBarSignalView @end
@interface _UIStatusBarForegroundView : UIView @end
@interface _UIStatusBar : UIView @end
@interface CCUIStatusBar : UIView @end
@interface _UIStatusBarStringView : UIView
@property(nonatomic, copy) NSString *text;
@end

static char DuoNativeKey, DuoContainerKey, DuoIconControllerKey;
static char DuoSavedPercentageKey, DuoShiftedTransformKey;
static __weak _UIBatteryView *DuoLastBattery;
static double DuoLastBatteryLevel = -1;
static BOOL DuoLastBatteryCharging = NO;
static BOOL DuoLastBatteryLowPower = NO;
static UIColor *DuoLastBatteryColor;
static Class DuoBatteryClass, DuoWifiClass, DuoCellularClass, DuoForegroundClass, DuoStatusBarClass;
@class DuoStatusController;
static void DuoScanHotspotIndicators(UIView *container);
static BOOL DuoEnabled = YES;
static CGFloat DuoSizeScale = 1.0;

static CGFloat DuoReadSizeScale(void) {
    CFPreferencesAppSynchronize(CFSTR("local.duobar"));
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("SizeScale"), CFSTR("local.duobar")));
    if (![value isKindOfClass:NSNumber.class]) return 1.0;
    double scale = [value doubleValue];
    if (!isfinite(scale)) return 1.0;
    // A safe 70%–140% range; invalid legacy preferences cannot grow the glyph.
    return (CGFloat)fmax(0.70, fmin(1.40, scale));
}
static BOOL DuoSpringBoard = NO;
static NSHashTable<_UIStatusBarStringView *> *DuoPercentageViews;
static NSHashTable<DuoStatusController *> *DuoControllers;
static id DuoActivationObserver;

static BOOL DuoReadEnabled(void) {
    CFPreferencesAppSynchronize(CFSTR("local.duobar"));
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Enabled"), CFSTR("local.duobar")));
    return [value isKindOfClass:NSNumber.class] ? [value boolValue] : YES;
}

// Control Center uses a separate _UIStatusBarStringView for the large "86%" text.
// This view is not one of the native battery/signal glyphs covered below.
static BOOL DuoIsBatteryPercentage(NSString *text) {
    if (![text isKindOfClass:NSString.class]) return NO;
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (![trimmed hasSuffix:@"%"] || trimmed.length < 2 || trimmed.length > 4) return NO;
    NSString *digits = [trimmed substringToIndex:trimmed.length - 1];
    return [digits rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound;
}

// Only touch the Control Center presentation, never app/lock-screen status bars.
static BOOL DuoControlCenterVisible(UIView *view) {
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        NSString *name = NSStringFromClass(ancestor.class);
        if ([name isEqualToString:@"CCUIStatusBar"] ||
            [name isEqualToString:@"CCUIHeaderPocketView"] ||
            [name containsString:@"ControlCenterOverlay"]) return YES;
    }
    if (!DuoSpringBoard) return NO;
    Class cls = NSClassFromString(@"SBControlCenterController");
    SEL shared = NSSelectorFromString(@"sharedInstance");
    if (!cls || ![cls respondsToSelector:shared]) return NO;
    id controller = ((id (*)(id, SEL))objc_msgSend)(cls, shared);
    for (NSString *name in @[@"isVisible", @"isPresented"]) {
        SEL selector = NSSelectorFromString(name);
        if ([controller respondsToSelector:selector] &&
            ((BOOL (*)(id, SEL))objc_msgSend)(controller, selector)) return YES;
    }
    return NO;
}

static void DuoSyncPercentage(_UIStatusBarStringView *view) {
    NSString *saved = objc_getAssociatedObject(view, &DuoSavedPercentageKey);
    if (saved && (!DuoEnabled || !DuoControlCenterVisible(view))) {
        [view setText:saved];
    } else if (!saved && DuoEnabled && DuoControlCenterVisible(view) && DuoIsBatteryPercentage(view.text)) {
        [view setText:view.text];
    }
}

// Move only an overlapping Control Center status indicator (e.g. orientation lock).
// Store the original transform so the stock layout returns whenever DuoBar is off.
static void DuoRestoreShiftedIndicator(UIView *view) {
    NSValue *saved = objc_getAssociatedObject(view, &DuoShiftedTransformKey);
    if (!saved) return;
    view.transform = saved.CGAffineTransformValue;
    objc_setAssociatedObject(view, &DuoShiftedTransformKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Save only drawing state. Keep native views, layout, and accessibility in place.
@interface DuoNativeState : NSObject
@property(nonatomic, weak) UIView *host;
@property(nonatomic, strong) NSMapTable<CALayer *, NSNumber *> *layers;
@property(nonatomic, strong) id contents;
@property(nonatomic) BOOL active;
- (void)cover;
- (void)restore;
@end

@implementation DuoNativeState
- (instancetype)init {
    if ((self = [super init])) self.layers = [NSMapTable weakToStrongObjectsMapTable];
    return self;
}
- (void)cover {
    UIView *host = self.host;
    if (!host) return;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (!self.active || host.layer.contents) self.contents = host.layer.contents;
    host.layer.contents = nil;
    for (CALayer *layer in [host.layer.sublayers copy]) {
        if (![self.layers objectForKey:layer]) [self.layers setObject:@(layer.hidden) forKey:layer];
        layer.hidden = YES;
    }
    self.active = YES;
    [CATransaction commit];
}
- (void)restore {
    if (!self.active) return;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (CALayer *layer in self.layers) layer.hidden = [[self.layers objectForKey:layer] boolValue];
    self.host.layer.contents = self.contents;
    [self.layers removeAllObjects];
    self.contents = nil;
    self.active = NO;
    [CATransaction commit];
}
@end

static void DuoRestoreNative(UIView *host) {
    DuoNativeState *state = objc_getAssociatedObject(host, &DuoNativeKey);
    [state restore];
}

static void DuoCoverNative(UIView *host) {
    DuoNativeState *state = objc_getAssociatedObject(host, &DuoNativeKey);
    if (!state) {
        state = [DuoNativeState new];
        state.host = host;
        objc_setAssociatedObject(host, &DuoNativeKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [state cover];
}

static UIView *DuoStatusContainer(UIView *view) {
    UIView *fallback = nil;
    for (UIView *ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
        NSString *name = NSStringFromClass(ancestor.class);
        if ([name isEqualToString:@"CCUIStatusBar"] ||
            [name containsString:@"ControlCenterOverlay"]) return ancestor;
        if (DuoForegroundClass && [ancestor isKindOfClass:DuoForegroundClass]) return ancestor;
        if (DuoStatusBarClass && [ancestor isKindOfClass:DuoStatusBarClass]) fallback = ancestor;
    }
    return fallback;
}

static BOOL DuoIsVisible(UIView *view, UIView *container) {
    if (!view.window) return NO;
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if (ancestor.hidden || ancestor.alpha <= 0.01) return NO;
        if (ancestor == container) return YES;
    }
    return NO;
}

static void DuoAppendImageName(NSMutableArray<NSString *> *values, id object,
        NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return;
    @try {
        id result = ((id (*)(id, SEL))objc_msgSend)(object, selector);
        if ([result isKindOfClass:NSString.class] && [result length] > 0) {
            [values addObject:[result lowercaseString]];
        }
    } @catch (__unused NSException *exception) {
        // UIKit's private image-name accessors vary by iOS build.
    }
}

static UIImage *DuoHotspotImageForView(UIView *view) {
    if ([view isKindOfClass:UIImageView.class]) {
        UIImage *image = ((UIImageView *)view).image;
        if (image) return image;
    }
    id contents = view.layer.contents;
    CFTypeRef contentRef = (__bridge CFTypeRef)contents;
    if (contentRef && CFGetTypeID(contentRef) == CGImageGetTypeID()) {
        return [UIImage imageWithCGImage:(CGImageRef)contentRef];
    }
    return nil;
}

// iOS sometimes supplies the Personal Hotspot chain as an unnamed template
// image. Its small, wide two-link silhouette gives us a fallback when UIKit
// exposes no accessibility label or asset name.
static BOOL DuoImageLooksLikeChainLink(UIImage *image) {
    CGImageRef source = image.CGImage;
    if (!source) return NO;
    size_t sourceWidth = CGImageGetWidth(source);
    size_t sourceHeight = CGImageGetHeight(source);
    if (sourceWidth < 8 || sourceHeight < 6 || sourceWidth > 256 || sourceHeight > 192) return NO;
    CGFloat aspect = (CGFloat)sourceWidth / (CGFloat)sourceHeight;
    if (aspect < 1.25 || aspect > 2.8) return NO;

    enum { Width = 48, Height = 32, PixelCount = Width * Height };
    uint8_t pixels[PixelCount * 4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) return NO;
    CGContextRef bitmap = CGBitmapContextCreate(pixels, Width, Height, 8, Width * 4,
        colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (!bitmap) return NO;
    CGContextClearRect(bitmap, CGRectMake(0, 0, Width, Height));
    CGContextSetBlendMode(bitmap, kCGBlendModeCopy);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, Width, Height), source);
    CGContextRelease(bitmap);

    uint8_t foreground[PixelCount] = {0};
    int minX = Width, minY = Height, maxX = -1, maxY = -1, ink = 0;
    for (int y = 0; y < Height; y++) {
        for (int x = 0; x < Width; x++) {
            int index = y * Width + x;
            if (pixels[index * 4 + 3] < 80) continue;
            foreground[index] = 1;
            ink++;
            minX = MIN(minX, x); maxX = MAX(maxX, x);
            minY = MIN(minY, y); maxY = MAX(maxY, y);
        }
    }
    if (maxX <= minX || maxY <= minY) return NO;
    int boxWidth = maxX - minX + 1, boxHeight = maxY - minY + 1;
    CGFloat fill = (CGFloat)ink / (CGFloat)(boxWidth * boxHeight);
    if ((CGFloat)boxWidth / (CGFloat)boxHeight < 1.25 ||
        (CGFloat)boxWidth / (CGFloat)boxHeight > 2.8 || fill < 0.08 || fill > 0.62) return NO;

    // Flood-fill transparent pixels from the crop boundary. Enclosed regions
    // are the two holes in a chain-link mark.
    uint8_t exterior[PixelCount] = {0};
    int queue[PixelCount];
    int head = 0, tail = 0;
    for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {
            if (x != minX && x != maxX && y != minY && y != maxY) continue;
            int index = y * Width + x;
            if (!foreground[index] && !exterior[index]) {
                exterior[index] = 1;
                queue[tail++] = index;
            }
        }
    }
    while (head < tail) {
        int index = queue[head++];
        const int neighbors[] = { index - 1, index + 1, index - Width, index + Width };
        for (int i = 0; i < 4; i++) {
            int next = neighbors[i];
            if (next < 0 || next >= PixelCount) continue;
            int nx = next % Width, ny = next / Width;
            if (nx < minX || nx > maxX || ny < minY || ny > maxY ||
                foreground[next] || exterior[next]) continue;
            exterior[next] = 1;
            queue[tail++] = next;
        }
    }
    int holes = 0;
    for (int y = minY; y <= maxY; y++) {
        for (int x = minX; x <= maxX; x++) {
            int start = y * Width + x;
            if (foreground[start] || exterior[start]) continue;
            holes++;
            head = 0; tail = 0;
            exterior[start] = 1;
            queue[tail++] = start;
            while (head < tail) {
                int index = queue[head++];
                int neighbors[] = { index - 1, index + 1, index - Width, index + Width };
                for (int i = 0; i < 4; i++) {
                    int next = neighbors[i];
                    if (next < 0 || next >= PixelCount) continue;
                    int nx = next % Width, ny = next / Width;
                    if (nx < minX || nx > maxX || ny < minY || ny > maxY ||
                        foreground[next] || exterior[next]) continue;
                    exterior[next] = 1;
                    queue[tail++] = next;
                }
            }
        }
    }
    return holes == 2;
}

// Restrict hotspot recognition to status-bar glyphs, never generic app images
// or the names of Wi-Fi networks on the Settings screen. iOS 16 status images
// expose their symbol name differently across point releases, so examine the
// public image description and optional private name accessors when available.
static BOOL DuoIsHotspotIndicator(UIView *view) {
    if (!view) return NO;
    NSString *className = NSStringFromClass(view.class).lowercaseString;
    BOOL statusGlyph = [className containsString:@"statusbar"] ||
                       [className containsString:@"hotspot"] ||
                       [className containsString:@"tether"] ||
                       DuoStatusContainer(view) != nil;
    for (UIView *ancestor = view.superview; !statusGlyph && ancestor; ancestor = ancestor.superview) {
        if ([NSStringFromClass(ancestor.class).lowercaseString containsString:@"statusbar"] ||
            [NSStringFromClass(ancestor.class).lowercaseString containsString:@"controlcenteroverlay"]) {
            statusGlyph = YES;
        }
    }
    if (!statusGlyph) return NO;
    NSMutableArray<NSString *> *tokens = [NSMutableArray arrayWithObjects:
        className,
        view.accessibilityLabel.lowercaseString ?: @"",
        view.accessibilityIdentifier.lowercaseString ?: @"",
        nil];
    UIImage *image = DuoHotspotImageForView(view);
    if (image) {
        if (DuoImageLooksLikeChainLink(image)) return YES;
        [tokens addObject:image.description.lowercaseString ?: @""];
        DuoAppendImageName(tokens, image, @"imageName");
        DuoAppendImageName(tokens, image, @"_imageName");
        DuoAppendImageName(tokens, image, @"symbolImageName");
        DuoAppendImageName(tokens, image, @"_symbolName");
        id asset = [image respondsToSelector:@selector(imageAsset)] ? image.imageAsset : nil;
        if (asset) {
            [tokens addObject:[asset description].lowercaseString ?: @""];
            DuoAppendImageName(tokens, asset, @"name");
        }
    }
    for (NSString *value in tokens) {
        if ([value containsString:@"personal hotspot"] ||
            [value containsString:@"personalhotspot"] ||
            [value containsString:@"personal-hotspot"] ||
            [value containsString:@"tethering"] ||
            [value containsString:@"hotspot"]) return YES;
    }
    return NO;
}

static NSInteger DuoBars(_UIStatusBarSignalView *view, NSInteger maximum) {
    long long total = view.numberOfBars;
    if (total <= 0) return 0;
    double fraction = fmax(0, fmin(1, (double)view.numberOfActiveBars / (double)total));
    return (NSInteger)lround(fraction * maximum);
}

@interface DuoStatusController : NSObject
@property(nonatomic, weak) UIView *container;
@property(nonatomic, strong) NSHashTable<UIView *> *icons;
@property(nonatomic, strong) NSHashTable<UIView *> *shiftedIndicators;
@property(nonatomic, strong) DuoGlyphView *glyph;
@property(nonatomic) BOOL updating;
- (void)update;
@end

@implementation DuoStatusController
- (instancetype)init {
    if ((self = [super init])) {
        self.icons = [NSHashTable weakObjectsHashTable];
        self.shiftedIndicators = [NSHashTable weakObjectsHashTable];
        self.glyph = [[DuoGlyphView alloc] initWithFrame:CGRectZero];
        self.glyph.hidden = YES;
    }
    return self;
}
- (void)update {
    UIView *container = self.container;
    if (!container || self.updating) return;
    self.updating = YES;
    DuoScanHotspotIndicators(container);
    for (UIView *indicator in self.shiftedIndicators.allObjects) DuoRestoreShiftedIndicator(indicator);
    [self.shiftedIndicators removeAllObjects];
    if (!DuoEnabled) {
        self.glyph.hidden = YES;
        for (UIView *icon in self.icons) DuoRestoreNative(icon);
        self.updating = NO;
        return;
    }
    _UIBatteryView *battery = nil;
    BOOL wifiVisible = NO, hotspotVisible = NO;
    UIImage *hotspotImage = nil;
    NSInteger wifiBars = 0, cellularBars = 0;
    CGRect area = CGRectNull;

    for (UIView *icon in self.icons) {
        if (DuoStatusContainer(icon) != container || !DuoIsVisible(icon, container)) {
            DuoRestoreNative(icon);
            continue;
        }
        area = CGRectUnion(area, [icon convertRect:icon.bounds toView:container]);
        if ([icon isKindOfClass:DuoBatteryClass]) {
            _UIBatteryView *candidate = (_UIBatteryView *)icon;
            double level = candidate.chargePercent;
            if (isfinite(level) && level >= 0 && level <= 1) battery = candidate;
        } else if ([icon isKindOfClass:DuoWifiClass]) {
            wifiVisible = YES;
            wifiBars = MAX(wifiBars, DuoBars((_UIStatusBarSignalView *)icon, 3));

        } else if ([icon isKindOfClass:DuoCellularClass]) {
            // With multiple SIM indicators, use the strongest visible line.
            cellularBars = MAX(cellularBars, DuoBars((_UIStatusBarSignalView *)icon, 4));
        } else if (DuoIsHotspotIndicator(icon)) {
            hotspotVisible = YES;
            hotspotImage = DuoHotspotImageForView(icon) ?: hotspotImage;
        }
    }

    if (battery) {
        DuoLastBattery = battery;
        DuoLastBatteryLevel = battery.chargePercent;
        DuoLastBatteryCharging = battery.chargingState != 0;
        DuoLastBatteryLowPower = battery.saverModeActive;
        DuoLastBatteryColor = [battery.bodyColor colorWithAlphaComponent:1];
    }
    // Control Center can remove its native battery view when a Personal
    // Hotspot indicator replaces the Wi-Fi status item. Preserve DuoBar
    // using the last valid battery reading from another status bar.
    BOOL ccHotspotFallback = !battery && hotspotVisible && DuoControlCenterVisible(container);
    double fallbackCharge = DuoLastBatteryLevel;
    if (ccHotspotFallback && !(isfinite(fallbackCharge) && fallbackCharge >= 0 && fallbackCharge <= 1)) {
        UIDevice *device = UIDevice.currentDevice;
        device.batteryMonitoringEnabled = YES;
        fallbackCharge = device.batteryLevel;
    }
    if ((!battery && (!ccHotspotFallback || !isfinite(fallbackCharge) ||
                      fallbackCharge < 0 || fallbackCharge > 1)) ||
        CGRectIsNull(area) || CGRectGetHeight(container.bounds) < 16) {
        self.glyph.hidden = YES;
        for (UIView *icon in self.icons) DuoRestoreNative(icon);
        self.updating = NO;
        return;
    }

    self.glyph.charge = battery ? battery.chargePercent : fallbackCharge;
    self.glyph.charging = battery ? (battery.chargingState != 0) : DuoLastBatteryCharging;
    self.glyph.lowPower = battery ? battery.saverModeActive : DuoLastBatteryLowPower;
    self.glyph.hotspotActive = hotspotVisible;
    self.glyph.hotspotImage = hotspotImage;
    self.glyph.wifiVisible = wifiVisible && !hotspotVisible;
    self.glyph.wifiBars = wifiBars;
    self.glyph.cellularBars = cellularBars;
    self.glyph.foreground = battery
        ? ([battery.bodyColor colorWithAlphaComponent:1] ?: UIColor.labelColor)
        : (DuoLastBatteryColor ?: UIColor.labelColor);

    // Draw in the status-bar container, rather than clipping to a 12pt battery.
    // Preserve UIKit's item spacing and fit compact/landscape status bars.
    // Keep 100% exactly equal to the original glyph, and resize the entire
    // drawing (ring, percentage, Wi-Fi and dots) rather than individual pieces.
    // At 100% keep the exact v0.2.2 geometry. When increasing size,
    // allow a controlled overhang into the status bar's padding so that
    // compact containers can still visibly enlarge the glyph.
    // We don't modify the container's clipping policy or native UIKit views.
    CGFloat baseHeight = MIN(30.0, CGRectGetHeight(container.bounds) - 2.0);
    CGFloat height = baseHeight * DuoSizeScale;
    CGFloat width = height * 32.0 / 34.0;
    CGRect batteryRect = battery
        ? [battery convertRect:battery.bounds toView:container]
        : area;
    CGFloat x = CGRectGetMaxX(area) - width;
    CGFloat y = CGRectGetMidY(batteryRect) - height / 2;
    x = MAX(CGRectGetMinX(container.bounds), MIN(x, CGRectGetMaxX(container.bounds) - width));
    CGFloat extra = MAX(0, height - (CGRectGetHeight(container.bounds) - 2.0)) / 2.0;
    y = MAX(CGRectGetMinY(container.bounds) + 1 - extra,
        MIN(y, CGRectGetMaxY(container.bounds) - height - 1 + extra));

    if (DuoControlCenterVisible(container)) {
        // In Control Center the orientation-lock badge can sit directly behind
        // the new glyph. Give it the unused space formerly occupied by the stock
        // percentage, without hard-coding screen coordinates or altering its state.
        CGRect glyphRect = CGRectMake(x, y, width, height);
        UIView *statusRoot = container;
        for (UIView *parent = container.superview; parent; parent = parent.superview) {
            if ([parent isKindOfClass:DuoStatusBarClass] ||
                [NSStringFromClass(parent.class) isEqualToString:@"CCUIStatusBar"]) {
                statusRoot = parent;
                if ([NSStringFromClass(parent.class) isEqualToString:@"CCUIStatusBar"]) break;
            }
        }
        UIView *nearest = nil;
        CGFloat bestScore = CGFLOAT_MAX;
        NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:statusRoot];
        while (pending.count) {
            UIView *candidate = pending.lastObject;
            [pending removeLastObject];
            [pending addObjectsFromArray:candidate.subviews];
            if (candidate == container || candidate == self.glyph || !candidate.window || candidate.hidden) continue;
            BOOL nativeGlyph = NO;
            for (UIView *icon in self.icons) {
                if (candidate == icon || [candidate isDescendantOfView:icon]) { nativeGlyph = YES; break; }
            }
            if (nativeGlyph) continue;
            NSString *name = NSStringFromClass(candidate.class);
            NSString *label = candidate.accessibilityLabel.lowercaseString ?: @"";
            BOOL orientation = [label containsString:@"orientation"] ||
                [label containsString:@"rotation"] || [label containsString:@"portrait"];
            BOOL image = [name containsString:@"StatusBar"] &&
                ([name containsString:@"ImageView"] || [name containsString:@"IndicatorView"]);
            if (!orientation && !image) continue;
            CGRect rect = [candidate convertRect:candidate.bounds toView:container];
            if (CGRectIsEmpty(rect) || CGRectGetWidth(rect) > 40 || CGRectGetHeight(rect) > 40) continue;
            if (CGRectGetMaxX(rect) < x - 5 || CGRectGetMinX(rect) > CGRectGetMaxX(glyphRect) ||
                CGRectGetMaxY(rect) < y - 5 || CGRectGetMinY(rect) > CGRectGetMaxY(glyphRect) + 5) continue;
            CGFloat score = (orientation ? 0 : 100) + fabs(CGRectGetMidX(rect) - CGRectGetMidX(glyphRect));
            if (score < bestScore) { bestScore = score; nearest = candidate; }
        }
        if (nearest) {
            CGRect rect = [nearest convertRect:nearest.bounds toView:container];
            CGFloat shift = MAX(-24, MIN(0, CGRectGetMinX(glyphRect) - 5 - CGRectGetMaxX(rect)));
            if (shift < -1) {
                objc_setAssociatedObject(nearest, &DuoShiftedTransformKey,
                    [NSValue valueWithCGAffineTransform:nearest.transform], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                nearest.transform = CGAffineTransformTranslate(nearest.transform, shift, 0);
                [self.shiftedIndicators addObject:nearest];
            }
        } else {
            // Some builds do not expose a separate orientation indicator view;
            // reserve a small gap by moving DuoBar to the trailing edge instead.
            x = MIN(CGRectGetMaxX(container.bounds) - width, x + 12);
        }
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.glyph.superview != container) [container addSubview:self.glyph];
    self.glyph.frame = CGRectMake(x, y, width, height);
    [self.glyph setNeedsLayout];
    [self.glyph layoutIfNeeded];
    self.glyph.layer.zPosition = 100;
    self.glyph.hidden = NO;
    for (UIView *icon in self.icons) {
        if (DuoStatusContainer(icon) == container && DuoIsVisible(icon, container)) DuoCoverNative(icon);
    }
    [CATransaction commit];
    [self.glyph setNeedsDisplay];
    self.updating = NO;
}
@end

static void DuoRegisterIcon(UIView *icon) {
    if (![icon isKindOfClass:DuoBatteryClass] && ![icon isKindOfClass:DuoWifiClass]
            && ![icon isKindOfClass:DuoCellularClass] && !DuoIsHotspotIndicator(icon)) return;
    UIView *container = DuoStatusContainer(icon);
    DuoStatusController *previous = objc_getAssociatedObject(icon, &DuoIconControllerKey);
    if (previous && previous.container != container) {
        [previous.icons removeObject:icon];
        DuoRestoreNative(icon);
        [previous update];
        objc_setAssociatedObject(icon, &DuoIconControllerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (!container) {
        DuoRestoreNative(icon);
        return;
    }
    DuoStatusController *controller = objc_getAssociatedObject(container, &DuoContainerKey);
    if (!controller) {
        controller = [DuoStatusController new];
        controller.container = container;
        [DuoControllers addObject:controller];
        objc_setAssociatedObject(container, &DuoContainerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(icon, &DuoIconControllerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [controller.icons addObject:icon];
    [controller update];
}

// Also discover a hotspot icon during status-bar relayout: some iOS 16
// variants only update the image rather than moving its UIImageView.
static void DuoScanHotspotIndicators(UIView *container) {
    if (!container) return;
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:container];
    NSUInteger checked = 0;
    while (pending.count && checked++ < 150) {
        UIView *candidate = pending.lastObject;
        [pending removeLastObject];
        if (DuoIsHotspotIndicator(candidate)) {
            DuoRegisterIcon(candidate);
            continue;
        }
        [pending addObjectsFromArray:candidate.subviews];
    }
}

static void DuoUpdateContainer(UIView *container) {
    DuoStatusController *controller = objc_getAssociatedObject(container, &DuoContainerKey);
    [controller update];
}

static void DuoReloadPreferences(void) {
    BOOL enabled = DuoReadEnabled();
    CGFloat newScale = DuoReadSizeScale();
    if (enabled == DuoEnabled && fabs(newScale - DuoSizeScale) < 0.001) return;
    DuoEnabled = enabled;
    DuoSizeScale = newScale;
    for (_UIStatusBarStringView *view in DuoPercentageViews.allObjects) DuoSyncPercentage(view);
    NSArray<DuoStatusController *> *controllers = DuoControllers.allObjects;
    for (DuoStatusController *controller in controllers) [controller update];
    if (!enabled) {
        // Recompute native visibility after restoring layers cached by the overlay.
        // Run outside controller updates so UIKit can complete its normal layout.
        for (DuoStatusController *controller in controllers) {
            for (UIView *icon in controller.icons.allObjects) {
                [icon setNeedsLayout];
                [icon layoutIfNeeded];
            }
        }
    }
}

static void DuoPreferencesDidChange(CFNotificationCenterRef center, void *observer,
        CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    (void)center; (void)observer; (void)name; (void)object; (void)userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        DuoReloadPreferences();
    });
}

%group DuoPercentageHooks
%hook _UIStatusBarStringView
- (void)setText:(NSString *)text {
    if (DuoEnabled && DuoControlCenterVisible(self) && DuoIsBatteryPercentage(text)) {
        objc_setAssociatedObject(self, &DuoSavedPercentageKey, text, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [DuoPercentageViews addObject:self];
        %orig(@"");
        return;
    }
    objc_setAssociatedObject(self, &DuoSavedPercentageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
    if (DuoIsBatteryPercentage(text)) [DuoPercentageViews addObject:self];
}
- (void)layoutSubviews {
    %orig;
    DuoSyncPercentage(self);
}
%end
%end

%group DuoBatteryHooks
%hook _UIBatteryView
- (void)layoutSubviews {
    DuoRestoreNative(self);
    %orig;
    DuoRegisterIcon(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoRegisterIcon(self);
}
- (void)setChargePercent:(double)value {
    %orig;
    [self setNeedsLayout];
}
- (void)setChargingState:(long long)value {
    %orig;
    [self setNeedsLayout];
}
- (void)setSaverModeActive:(BOOL)value {
    %orig;
    [self setNeedsLayout];
}
- (void)setBodyColor:(UIColor *)color {
    %orig;
    [self setNeedsLayout];
}
- (void)setHidden:(BOOL)hidden {
    %orig;
    DuoRegisterIcon(self);
}
- (void)setAlpha:(CGFloat)alpha {
    %orig;
    DuoRegisterIcon(self);
}
%end
%end

%group DuoSignalDataHooks
%hook _UIStatusBarSignalView
- (void)setNumberOfActiveBars:(long long)bars {
    %orig;
    [self setNeedsLayout];
}
- (void)setNumberOfBars:(long long)bars {
    %orig;
    [self setNeedsLayout];
}
- (void)setActiveColor:(UIColor *)color {
    %orig;
    [self setNeedsLayout];
}
- (void)setHidden:(BOOL)hidden {
    %orig;
    DuoRegisterIcon(self);
}
- (void)setAlpha:(CGFloat)alpha {
    %orig;
    DuoRegisterIcon(self);
}
%end
%end

%group DuoWifiHooks
%hook _UIStatusBarWifiSignalView
- (void)layoutSubviews {
    DuoRestoreNative(self);
    %orig;
    DuoRegisterIcon(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoRegisterIcon(self);
}
- (void)_updateActiveBars {
    DuoRestoreNative(self);
    %orig;
    DuoRegisterIcon(self);
}
%end
%end

%group DuoHotspotImageHooks
%hook _UIStatusBarImageView
- (void)setImage:(UIImage *)image {
    %orig;
    if (DuoIsHotspotIndicator(self)) DuoRegisterIcon(self);
}
- (void)layoutSubviews {
    %orig;
    if (DuoIsHotspotIndicator(self)) DuoRegisterIcon(self);
}
- (void)didMoveToWindow {
    %orig;
    if (DuoIsHotspotIndicator(self)) DuoRegisterIcon(self);
}
%end
%end

%group DuoCellularHooks
%hook _UIStatusBarCellularSignalView
- (void)layoutSubviews {
    DuoRestoreNative(self);
    %orig;
    DuoRegisterIcon(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoRegisterIcon(self);
}
- (void)_updateActiveBars {
    DuoRestoreNative(self);
    %orig;
    DuoRegisterIcon(self);
}
%end
%end

%group DuoForegroundHooks
%hook _UIStatusBarForegroundView
- (void)layoutSubviews {
    %orig;
    DuoUpdateContainer(self);
}
%end
%end

%group DuoStatusBarHooks
%hook _UIStatusBar
- (void)layoutSubviews {
    %orig;
    DuoUpdateContainer(self);
}
%end
%end

%group DuoControlCenterStatusBarHooks
%hook CCUIStatusBar
- (void)layoutSubviews {
    %orig;
    DuoUpdateContainer(self);
}
%end
%end

static BOOL DuoHasSelectors(Class cls, NSArray<NSString *> *selectors) {
    if (!cls || ![cls isSubclassOfClass:UIView.class]) return NO;
    for (NSString *selector in selectors) {
        if (!class_getInstanceMethod(cls, NSSelectorFromString(selector))) return NO;
    }
    return YES;
}

%ctor {
    @autoreleasepool {
        if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 16) return;
        DuoControllers = [NSHashTable weakObjectsHashTable];
        DuoPercentageViews = [NSHashTable weakObjectsHashTable];
        DuoSpringBoard = [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"];
        DuoEnabled = DuoReadEnabled();
        DuoSizeScale = DuoReadSizeScale();
        DuoBatteryClass = NSClassFromString(@"_UIBatteryView");
        DuoWifiClass = NSClassFromString(@"_UIStatusBarWifiSignalView");
        DuoCellularClass = NSClassFromString(@"_UIStatusBarCellularSignalView");
        DuoForegroundClass = NSClassFromString(@"_UIStatusBarForegroundView");
        DuoStatusBarClass = NSClassFromString(@"_UIStatusBar");
        // Enable the complete composition only if all data sources are supported.
        BOOL batteryOK = DuoHasSelectors(DuoBatteryClass,
            @[@"chargePercent", @"chargingState", @"saverModeActive", @"bodyColor",
              @"setChargePercent:", @"setChargingState:", @"setSaverModeActive:", @"setBodyColor:"]);
        BOOL signalOK = DuoHasSelectors(NSClassFromString(@"_UIStatusBarSignalView"),
            @[@"numberOfBars", @"numberOfActiveBars", @"activeColor",
              @"setNumberOfBars:", @"setNumberOfActiveBars:", @"setActiveColor:"]);
        BOOL wifiOK = DuoHasSelectors(DuoWifiClass, @[@"_updateActiveBars"]);
        BOOL cellOK = DuoHasSelectors(DuoCellularClass, @[@"_updateActiveBars"]);
        if (!batteryOK || !signalOK || !wifiOK || !cellOK || !DuoStatusBarClass) return;
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
            DuoPreferencesDidChange, CFSTR("local.duobar/preferences.changed"), NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        DuoActivationObserver = [NSNotificationCenter.defaultCenter
            addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
            queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
                (void)notification;
                DuoReloadPreferences();
            }];
        if (DuoSpringBoard && NSClassFromString(@"_UIStatusBarStringView")) %init(DuoPercentageHooks);
        %init(DuoBatteryHooks);
        %init(DuoSignalDataHooks);
        %init(DuoWifiHooks);
        %init(DuoCellularHooks);
        if (NSClassFromString(@"_UIStatusBarImageView")) %init(DuoHotspotImageHooks);
        %init(DuoStatusBarHooks);
        if (NSClassFromString(@"CCUIStatusBar")) %init(DuoControlCenterStatusBarHooks);
        if (DuoForegroundClass) {
            %init(DuoForegroundHooks);
        }
    }
}
