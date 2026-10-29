#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
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

static char DuoNativeKey, DuoContainerKey, DuoIconControllerKey, DuoNetworkControllerKey;
static char DuoSavedPercentageKey, DuoChainImageResultKey, DuoRotationOriginalTransformKey;
static __weak _UIBatteryView *DuoLastBattery;
static double DuoLastBatteryLevel = -1;
static BOOL DuoLastBatteryCharging = NO;
static BOOL DuoLastBatteryLowPower = NO;
static UIColor *DuoLastBatteryColor;
// Resolve private UIKit classes at runtime. A compile-time reference such as
// _UIStatusBarStringView.class becomes a non-weak import that stops the dylib
// from loading if a firmware build does not export that class symbol.
static Class DuoBatteryClass, DuoWifiClass, DuoCellularClass, DuoForegroundClass, DuoStatusBarClass, DuoStringClass;
@class DuoStatusController;
static void DuoScanHotspotIndicators(UIView *container);
static BOOL DuoEnabled = YES;
static CGFloat DuoSizeScale = 1.0;
static void DuoRegisterIcon(UIView *icon);
static void DuoRegisterNetworkView(_UIStatusBarStringView *view);
static void DuoScanStatusIcons(UIView *container);

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

// iOS may expose the carrier technology as a compact status-bar text view.
// Keep only the familiar network family label; carrier names and other text
// remain native and are never hidden by DuoBar.
static NSString *DuoNetworkTechnology(NSString *text) {
    if (![text isKindOfClass:NSString.class]) return nil;
    NSString *trimmed = [[text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([trimmed hasPrefix:@"5G"]) return @"5G";
    if ([trimmed hasPrefix:@"LTE"]) return @"LTE";
    return nil;
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

static CGImageRef DuoCreateRasterImage(UIImage *image) {
    CGSize size = image.size;
    if ((!isfinite(size.width) || !isfinite(size.height) || size.width <= 0 || size.height <= 0) && image.CGImage) {
        size = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
    }
    if (!isfinite(size.width) || !isfinite(size.height) || size.width <= 0 || size.height <= 0) return NULL;
    CGFloat scale = MIN(48.0 / size.width, 32.0 / size.height);
    CGSize fitted = CGSizeMake(size.width * scale, size.height * scale);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(48, 32), NO, 1);
    [image drawInRect:CGRectMake((48 - fitted.width) / 2, (32 - fitted.height) / 2,
                                 fitted.width, fitted.height)];
    UIImage *rendered = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRef result = rendered.CGImage ? CGImageRetain(rendered.CGImage) : NULL;
    UIGraphicsEndImageContext();
    return result;
}

// iOS sometimes supplies the Personal Hotspot chain as an unnamed template
// image or vector symbol. Its small, wide two-link silhouette gives us a
// fallback when UIKit exposes no accessibility label or asset name.
static BOOL DuoImageLooksLikeChainLink(UIImage *image) {
    if (!image) return NO;
    NSNumber *cached = objc_getAssociatedObject(image, &DuoChainImageResultKey);
    if (cached) return cached.boolValue;
    CGImageRef source = DuoCreateRasterImage(image);
    if (!source) return NO;
    size_t sourceWidth = CGImageGetWidth(source);
    size_t sourceHeight = CGImageGetHeight(source);
    if (sourceWidth < 8 || sourceHeight < 6 || sourceWidth > 512 || sourceHeight > 512) {
        CGImageRelease(source);
        objc_setAssociatedObject(image, &DuoChainImageResultKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }

    enum { Width = 48, Height = 32, PixelCount = Width * Height };
    uint8_t pixels[PixelCount * 4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace) {
        CGImageRelease(source);
        return NO;
    }
    CGContextRef bitmap = CGBitmapContextCreate(pixels, Width, Height, 8, Width * 4,
        colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (!bitmap) {
        CGImageRelease(source);
        objc_setAssociatedObject(image, &DuoChainImageResultKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }
    CGContextClearRect(bitmap, CGRectMake(0, 0, Width, Height));
    CGContextSetBlendMode(bitmap, kCGBlendModeCopy);
    CGContextDrawImage(bitmap, CGRectMake(0, 0, Width, Height), source);
    CGContextRelease(bitmap);
    CGImageRelease(source);

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
    if (maxX <= minX || maxY <= minY) {
        objc_setAssociatedObject(image, &DuoChainImageResultKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }
    int boxWidth = maxX - minX + 1, boxHeight = maxY - minY + 1;
    CGFloat fill = (CGFloat)ink / (CGFloat)(boxWidth * boxHeight);
    if ((CGFloat)boxWidth / (CGFloat)boxHeight < 1.25 ||
        (CGFloat)boxWidth / (CGFloat)boxHeight > 2.8 || fill < 0.08 || fill > 0.62) {
        objc_setAssociatedObject(image, &DuoChainImageResultKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }

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
    BOOL result = holes == 2;
    objc_setAssociatedObject(image, &DuoChainImageResultKey, @(result), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}

// Restrict hotspot recognition to status-bar glyphs, never generic app images
// or the names of Wi-Fi networks on the Settings screen. iOS 16 status images
// expose their symbol name differently across point releases, so examine the
// public image description and optional private name accessors when available.
static BOOL DuoIsHotspotIndicator(UIView *view) {
    if (!view) return NO;
    // DuoBar draws the same chain image inside its own glyph. Never rediscover
    // and cover that child as if it were a native iOS status-bar indicator.
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if ([ancestor isKindOfClass:DuoGlyphView.class]) return NO;
    }
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

// Restore UIKit's original transform when DuoBar is disabled or Control Center closes.
static void DuoRestoreRotationIndicator(UIView *indicator) {
    NSValue *original = objc_getAssociatedObject(indicator, &DuoRotationOriginalTransformKey);
    if (!original) return;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    indicator.transform = original.CGAffineTransformValue;
    [CATransaction commit];
    objc_setAssociatedObject(indicator, &DuoRotationOriginalTransformKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
@property(nonatomic, strong) NSHashTable<_UIStatusBarStringView *> *networkViews;
@property(nonatomic, strong) NSHashTable<UIView *> *shiftedIndicators;
@property(nonatomic, strong) DuoGlyphView *glyph;
@property(nonatomic) BOOL updating;
@property(nonatomic) BOOL updateScheduled;
- (void)scheduleUpdate;
- (void)update;
@end

@implementation DuoStatusController
- (instancetype)init {
    if ((self = [super init])) {
        self.icons = [NSHashTable weakObjectsHashTable];
        self.networkViews = [NSHashTable weakObjectsHashTable];
        self.shiftedIndicators = [NSHashTable weakObjectsHashTable];
        self.glyph = [[DuoGlyphView alloc] initWithFrame:CGRectZero];
        self.glyph.hidden = YES;
    }
    return self;
}
- (void)scheduleUpdate {
    if (self.updateScheduled || self.updating) return;
    self.updateScheduled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.updateScheduled = NO;
        [self update];
    });
}
- (void)update {
    UIView *container = self.container;
    if (!container || self.updating) return;
    self.updating = YES;
    // Recompute a new non-accumulating shift each layout cycle.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (UIView *view in self.shiftedIndicators.allObjects) DuoRestoreRotationIndicator(view);
    [self.shiftedIndicators removeAllObjects];
    [CATransaction commit];
    DuoScanHotspotIndicators(container);
    if (!DuoEnabled) {
        self.glyph.hidden = YES;
        for (UIView *icon in self.icons) DuoRestoreNative(icon);
        for (_UIStatusBarStringView *view in self.networkViews) DuoRestoreNative(view);
        self.updating = NO;
        return;
    }
    _UIBatteryView *battery = nil;
    BOOL wifiVisible = NO, hotspotVisible = NO;
    UIImage *hotspotImage = nil;
    NSString *networkType = nil;
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

    for (_UIStatusBarStringView *view in self.networkViews) {
        if (DuoStatusContainer(view) != container || !DuoIsVisible(view, container)) {
            DuoRestoreNative(view);
            continue;
        }
        NSString *candidate = DuoNetworkTechnology(view.text);
        if ([candidate isEqualToString:@"5G"] || (!networkType && candidate)) {
            networkType = candidate;
        }
    }

    if (battery) {
        DuoLastBattery = battery;
        DuoLastBatteryLevel = battery.chargePercent;
        DuoLastBatteryCharging = battery.chargingState != 0;
        DuoLastBatteryLowPower = battery.saverModeActive;
        DuoLastBatteryColor = [battery.bodyColor colorWithAlphaComponent:1];
    }
    // Some per-app status bars and Control Center presentations omit the
    // native battery view. Use UIDevice's reading so the whole DuoBar remains
    // available wherever a battery glyph is not present in this container.
    BOOL batteryFallback = !battery;
    double fallbackCharge = DuoLastBatteryLevel;
    BOOL fallbackCharging = DuoLastBatteryCharging;
    BOOL fallbackLowPower = DuoLastBatteryLowPower;
    if (batteryFallback) {
        UIDevice *device = UIDevice.currentDevice;
        device.batteryMonitoringEnabled = YES;
        if (!isfinite(fallbackCharge) || fallbackCharge < 0 || fallbackCharge > 1) {
            fallbackCharge = device.batteryLevel;
        }
        fallbackCharging = device.batteryState == UIDeviceBatteryStateCharging ||
                           device.batteryState == UIDeviceBatteryStateFull;
        fallbackLowPower = NSProcessInfo.processInfo.isLowPowerModeEnabled;
    }
    if ((!battery && (!isfinite(fallbackCharge) ||
                      fallbackCharge < 0 || fallbackCharge > 1)) ||
        CGRectIsNull(area) || CGRectGetHeight(container.bounds) < 16) {
        // UIKit briefly reports empty/zero-sized status-bar geometry while
        // rotating and while Control Center swaps its status-bar hierarchy.
        // Keep the last valid DuoBar and cover any native views that have
        // already moved into this same container; restoring them here makes
        // the stock battery flash back for the duration of that transition.
        BOOL keepTransitionOverlay = CGRectGetHeight(container.bounds) < 16 &&
            self.glyph.superview == container && !self.glyph.hidden && container.window;
        if (keepTransitionOverlay) {
            for (UIView *icon in self.icons) {
                if (DuoStatusContainer(icon) == container && DuoIsVisible(icon, container))
                    DuoCoverNative(icon);
            }
            for (_UIStatusBarStringView *view in self.networkViews) {
                if (DuoStatusContainer(view) == container && DuoIsVisible(view, container) &&
                    DuoNetworkTechnology(view.text)) DuoCoverNative(view);
            }
            [self.glyph setNeedsDisplay];
            self.updating = NO;
            return;
        }
        self.glyph.hidden = YES;
        for (UIView *icon in self.icons) DuoRestoreNative(icon);
        for (_UIStatusBarStringView *view in self.networkViews) DuoRestoreNative(view);
        self.updating = NO;
        return;
    }

    self.glyph.charge = battery ? battery.chargePercent : fallbackCharge;
    self.glyph.charging = battery ? (battery.chargingState != 0) : fallbackCharging;
    self.glyph.lowPower = battery ? battery.saverModeActive : fallbackLowPower;
    self.glyph.hotspotActive = hotspotVisible;
    self.glyph.hotspotImage = hotspotImage;
    self.glyph.networkType = networkType;
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

    BOOL inControlCenter = DuoControlCenterVisible(container);
    if (inControlCenter) {
        // Preserve the hotspot beta's stable Control Center glyph position.
        x = MIN(CGRectGetMaxX(container.bounds) - width, x + 12);
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
    for (_UIStatusBarStringView *view in self.networkViews) {
        if (DuoStatusContainer(view) == container && DuoIsVisible(view, container) &&
            DuoNetworkTechnology(view.text)) DuoCoverNative(view);
    }
    if (inControlCenter && container.window) {
        // The orientation-lock icon can be a SIBLING of DuoBar's foreground
        // view, not its descendant. First check our container, then the CC
        // window. All geometry and movement limits must use window points:
        // clamping to the narrow battery container previously prevented
        // the lock from leaving the circle even with a larger gap.
        UIWindow *window = container.window;
        CGRect ring = [self.glyph convertRect:self.glyph.bounds toView:window];
        UIView *chosen = nil;
        CGFloat bestScore = CGFLOAT_MAX;
        for (NSInteger pass = 0; pass < 2 && !chosen; pass++) {
            UIView *root = pass == 0 ? container : window;
            if (pass == 1 && root == container) break;
            NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:root];
            NSUInteger inspected = 0;
            while (pending.count && inspected++ < (pass == 0 ? 200 : 1200)) {
                UIView *candidate = pending.lastObject;
                [pending removeLastObject];
                if (candidate == self.glyph || [candidate isDescendantOfView:self.glyph]) continue;
                // Visit the root's children too; rotation lock may be a sibling.
                [pending addObjectsFromArray:candidate.subviews];
                if (candidate == root || candidate.window != window ||
                    candidate.hidden || candidate.alpha <= 0.01) continue;

                BOOL nativeIcon = NO;
                for (UIView *icon in self.icons) {
                    if (candidate == icon || [candidate isDescendantOfView:icon]) {
                        nativeIcon = YES;
                        break;
                    }
                }
                if (nativeIcon) continue;

                NSString *cls = NSStringFromClass(candidate.class).lowercaseString;
                NSString *label = candidate.accessibilityLabel.lowercaseString ?: @"";
                NSString *identifier = candidate.accessibilityIdentifier.lowercaseString ?: @"";
                BOOL rotationLock = [cls containsString:@"orientation"] ||
                    [cls containsString:@"rotationlock"] ||
                    [cls containsString:@"portraitlock"] ||
                    [label containsString:@"orientation"] ||
                    [label containsString:@"rotation"] ||
                    [label containsString:@"portrait"] ||
                    [identifier containsString:@"orientation"] ||
                    [identifier containsString:@"rotation"];
                BOOL statusImage = [cls containsString:@"statusbar"] &&
                    ([cls containsString:@"image"] || [cls containsString:@"indicator"]);

                if (!rotationLock && !statusImage) continue;
                CGRect r = [candidate convertRect:candidate.bounds toView:window];
                if (CGRectIsEmpty(r) || CGRectGetWidth(r) < 4 ||
                    CGRectGetHeight(r) < 4 || CGRectGetWidth(r) > 38 ||
                    CGRectGetHeight(r) > 38 ||
                    !CGRectIntersectsRect(r, CGRectInset(ring, -12.0, -9.0)))
                    continue;
                // Do not change the hotspot link or other DuoBar content.
                if (DuoIsHotspotIndicator(candidate)) continue;
                CGFloat score = (rotationLock ? 0 : 100) +
                    fabs(CGRectGetMidX(r) - CGRectGetMidX(ring));
                if (score < bestScore) {
                    chosen = candidate;
                    bestScore = score;
                }
            }
        }
        if (chosen) {
            CGRect r = [chosen convertRect:chosen.bounds toView:window];
            CGFloat desiredRight = CGRectGetMinX(ring) - 10.0;
            // Clamp to the visible WINDOW, not to the small status-icon
            // container. This leaves room to move the lock beside DuoBar.
            CGFloat windowLeft = CGRectGetMinX(window.bounds) + 3.0;
            CGFloat minShift = windowLeft - CGRectGetMinX(r);
            CGFloat shift = MAX(minShift, MIN(0.0, desiredRight - CGRectGetMaxX(r)));
            if (shift < -1.0) {
                objc_setAssociatedObject(chosen, &DuoRotationOriginalTransformKey,
                    [NSValue valueWithCGAffineTransform:chosen.transform],
                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                chosen.transform = CGAffineTransformTranslate(chosen.transform, shift, 0);
                [self.shiftedIndicators addObject:chosen];
            }
        }
    }
    [CATransaction commit];
    [self.glyph setNeedsDisplay];
    self.updating = NO;
}
@end

static void DuoRegisterIcon(UIView *icon) {
    // Controllers and their weak tables are main-thread state. A stray
    // off-main UIKit setter must not mutate them while layout enumerates.
    if (!NSThread.isMainThread) return;
    if (![icon isKindOfClass:DuoBatteryClass] && ![icon isKindOfClass:DuoWifiClass]
            && ![icon isKindOfClass:DuoCellularClass] && !DuoIsHotspotIndicator(icon)) return;
    UIView *container = DuoStatusContainer(icon);
    DuoStatusController *previous = objc_getAssociatedObject(icon, &DuoIconControllerKey);
    if (previous && previous.container != container) {
        [previous.icons removeObject:icon];
        DuoRestoreNative(icon);
        [previous scheduleUpdate];
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
    [controller scheduleUpdate];
}

static void DuoRegisterNetworkView(_UIStatusBarStringView *view) {
    if (!view || !NSThread.isMainThread) return;
    NSString *technology = DuoNetworkTechnology(view.text);
    UIView *container = technology ? DuoStatusContainer(view) : nil;
    DuoStatusController *previous = objc_getAssociatedObject(view, &DuoNetworkControllerKey);
    if (previous && (previous.container != container || !technology)) {
        [previous.networkViews removeObject:view];
        DuoRestoreNative(view);
        [previous scheduleUpdate];
        objc_setAssociatedObject(view, &DuoNetworkControllerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        previous = nil;
    }
    if (!technology || !container) {
        DuoRestoreNative(view);
        return;
    }
    DuoStatusController *controller = previous ?: objc_getAssociatedObject(container, &DuoContainerKey);
    if (!controller) {
        controller = [DuoStatusController new];
        controller.container = container;
        [DuoControllers addObject:controller];
        objc_setAssociatedObject(container, &DuoContainerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(view, &DuoNetworkControllerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [controller.networkViews addObject:view];
    [controller scheduleUpdate];
}

// A status-bar container can replace its children during rotation and
// Control Center presentation. Scan that small subtree after UIKit's layout
// so newly created battery/network views are registered before the next frame.
static void DuoScanStatusIcons(UIView *container) {
    if (!container) return;
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:container];
    NSUInteger checked = 0;
    while (pending.count && checked++ < 500) {
        UIView *candidate = pending.lastObject;
        [pending removeLastObject];
        if ([candidate isKindOfClass:DuoBatteryClass] ||
            [candidate isKindOfClass:DuoWifiClass] ||
            [candidate isKindOfClass:DuoCellularClass] ||
            DuoIsHotspotIndicator(candidate)) {
            DuoRegisterIcon(candidate);
        } else if (DuoStringClass && [candidate isKindOfClass:DuoStringClass]) {
            DuoRegisterNetworkView((_UIStatusBarStringView *)candidate);
        }
        [pending addObjectsFromArray:candidate.subviews];
    }
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
        if (DuoIsHotspotIndicator(candidate)) DuoRegisterIcon(candidate);
        [pending addObjectsFromArray:candidate.subviews];
    }
}

// Keep already-overlaid native icons covered in the SAME layout pass.
// The old layout hooks restored stock layers then deferred re-covering to
// the next main queue cycle, exposing a frame of stock battery and signal.
static void DuoKeepNativeCoveredDuringLayout(UIView *icon) {
    if (!DuoEnabled || !icon.window || !NSThread.isMainThread) return;
    DuoStatusController *controller = objc_getAssociatedObject(icon, &DuoIconControllerKey);
    if (!controller || controller.glyph.hidden ||
        controller.glyph.superview != controller.container ||
        !DuoIsVisible(icon, controller.container)) return;
    DuoCoverNative(icon);
}

static void DuoKeepNetworkCoveredDuringLayout(_UIStatusBarStringView *view) {
    if (!DuoEnabled || !view.window || !NSThread.isMainThread ||
        !DuoNetworkTechnology(view.text)) return;
    DuoStatusController *controller = objc_getAssociatedObject(view, &DuoNetworkControllerKey);
    if (!controller || controller.glyph.hidden || controller.glyph.superview != controller.container ||
        !DuoIsVisible(view, controller.container)) return;
    DuoCoverNative(view);
}

static void DuoUpdateContainer(UIView *container) {
    if (!NSThread.isMainThread) return;
    DuoScanStatusIcons(container);
    DuoStatusController *controller = objc_getAssociatedObject(container, &DuoContainerKey);
    if (!controller) return;
    if (!controller.updating) {
        // Recompute synchronously after UIKit has laid out the status bar.
        // This keeps DuoBar aligned and re-covers UIKit's freshly drawn
        // battery layers before a rotation/Control Center transition renders.
        [controller update];
    } else {
        [controller scheduleUpdate];
    }
    [controller scheduleUpdate];
}

static void DuoReloadPreferences(void) {
    BOOL enabled = DuoReadEnabled();
    CGFloat newScale = DuoReadSizeScale();
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

%group DuoStatusStringHooks
%hook _UIStatusBarStringView
- (void)setText:(NSString *)text {
    if (DuoSpringBoard && DuoEnabled && DuoControlCenterVisible(self) && DuoIsBatteryPercentage(text)) {
        objc_setAssociatedObject(self, &DuoSavedPercentageKey, text, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [DuoPercentageViews addObject:self];
        %orig(@"");
        return;
    }
    if (DuoSpringBoard) objc_setAssociatedObject(self, &DuoSavedPercentageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig;
    if (DuoSpringBoard && DuoIsBatteryPercentage(text)) [DuoPercentageViews addObject:self];
    DuoRegisterNetworkView(self);
    DuoKeepNetworkCoveredDuringLayout(self);
}
- (void)layoutSubviews {
    %orig;
    if (DuoSpringBoard) DuoSyncPercentage(self);
    DuoRegisterNetworkView(self);
    DuoKeepNetworkCoveredDuringLayout(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoRegisterNetworkView(self);
    DuoKeepNetworkCoveredDuringLayout(self);
}
%end
%end

%group DuoBatteryHooks
%hook _UIBatteryView
- (void)layoutSubviews {
    %orig;
    DuoRegisterIcon(self);
    DuoKeepNativeCoveredDuringLayout(self);
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
    %orig;
    DuoRegisterIcon(self);
    DuoKeepNativeCoveredDuringLayout(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoRegisterIcon(self);
}
- (void)_updateActiveBars {
    %orig;
    DuoRegisterIcon(self);
    DuoKeepNativeCoveredDuringLayout(self);
}
%end
%end

%group DuoHotspotImageHooks
%hook _UIStatusBarImageView
- (void)setImage:(UIImage *)image {
    %orig;
    if (DuoIsHotspotIndicator(self)) DuoRegisterIcon(self);
}
- (void)setAccessibilityLabel:(NSString *)label {
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
    %orig;
    DuoRegisterIcon(self);
    DuoKeepNativeCoveredDuringLayout(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoRegisterIcon(self);
}
- (void)_updateActiveBars {
    %orig;
    DuoRegisterIcon(self);
    DuoKeepNativeCoveredDuringLayout(self);
}
%end
%end

%group DuoForegroundHooks
%hook _UIStatusBarForegroundView
- (void)layoutSubviews {
    %orig;
    DuoScanHotspotIndicators(self);
    DuoUpdateContainer(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoScanHotspotIndicators(self);
    DuoUpdateContainer(self);
}
%end
%end

%group DuoStatusBarHooks
%hook _UIStatusBar
- (void)layoutSubviews {
    %orig;
    DuoScanHotspotIndicators(self);
    DuoUpdateContainer(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoScanHotspotIndicators(self);
    DuoUpdateContainer(self);
}
%end
%end

%group DuoControlCenterStatusBarHooks
%hook CCUIStatusBar
- (void)layoutSubviews {
    %orig;
    DuoScanHotspotIndicators(self);
    DuoUpdateContainer(self);
}
- (void)didMoveToWindow {
    %orig;
    DuoScanHotspotIndicators(self);
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
        DuoStringClass = NSClassFromString(@"_UIStatusBarStringView");
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
        void (^refreshStatusBars)(NSNotification *) = ^(NSNotification *notification) {
                (void)notification;
                DuoReloadPreferences();
            };
        NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
        id foregroundObserver = [notificationCenter addObserverForName:
            UIApplicationWillEnterForegroundNotification object:nil queue:NSOperationQueue.mainQueue
            usingBlock:refreshStatusBars];
        id activeObserver = [notificationCenter addObserverForName:
            UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue
            usingBlock:refreshStatusBars];
        DuoActivationObserver = @[foregroundObserver, activeObserver];
        if (DuoStringClass) %init(DuoStatusStringHooks);
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
