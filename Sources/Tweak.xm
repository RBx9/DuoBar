#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
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
@interface _UIStatusBarCellularSignalView : _UIStatusBarSignalView @end
@interface _UIStatusBarForegroundView : UIView @end
@interface _UIStatusBar : UIView @end

static char DuoNativeKey, DuoContainerKey, DuoIconControllerKey;
static Class DuoBatteryClass, DuoWifiClass, DuoCellularClass, DuoForegroundClass, DuoStatusBarClass;
@class DuoStatusController;
static BOOL DuoEnabled = YES;
static NSHashTable<DuoStatusController *> *DuoControllers;
static id DuoActivationObserver;

static BOOL DuoReadEnabled(void) {
    CFPreferencesAppSynchronize(CFSTR("local.duobar"));
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Enabled"), CFSTR("local.duobar")));
    return [value isKindOfClass:NSNumber.class] ? [value boolValue] : YES;
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

static NSInteger DuoBars(_UIStatusBarSignalView *view, NSInteger maximum) {
    long long total = view.numberOfBars;
    if (total <= 0) return 0;
    double fraction = fmax(0, fmin(1, (double)view.numberOfActiveBars / (double)total));
    return (NSInteger)lround(fraction * maximum);
}

@interface DuoStatusController : NSObject
@property(nonatomic, weak) UIView *container;
@property(nonatomic, strong) NSHashTable<UIView *> *icons;
@property(nonatomic, strong) DuoGlyphView *glyph;
@property(nonatomic) BOOL updating;
- (void)update;
@end

@implementation DuoStatusController
- (instancetype)init {
    if ((self = [super init])) {
        self.icons = [NSHashTable weakObjectsHashTable];
        self.glyph = [[DuoGlyphView alloc] initWithFrame:CGRectZero];
        self.glyph.hidden = YES;
    }
    return self;
}
- (void)update {
    UIView *container = self.container;
    if (!container || self.updating) return;
    self.updating = YES;
    if (!DuoEnabled) {
        self.glyph.hidden = YES;
        for (UIView *icon in self.icons) DuoRestoreNative(icon);
        self.updating = NO;
        return;
    }
    _UIBatteryView *battery = nil;
    BOOL wifiVisible = NO;
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
        }
    }

    if (!battery || CGRectIsNull(area) || CGRectGetHeight(container.bounds) < 16) {
        self.glyph.hidden = YES;
        for (UIView *icon in self.icons) DuoRestoreNative(icon);
        self.updating = NO;
        return;
    }

    self.glyph.charge = battery.chargePercent;
    self.glyph.charging = battery.chargingState != 0;
    self.glyph.lowPower = battery.saverModeActive;
    self.glyph.wifiVisible = wifiVisible;
    self.glyph.wifiBars = wifiBars;
    self.glyph.cellularBars = cellularBars;
    self.glyph.foreground = [battery.bodyColor colorWithAlphaComponent:1] ?: UIColor.labelColor;

    // Draw in the status-bar container, rather than clipping to a 12pt battery.
    // Preserve UIKit's item spacing and fit compact/landscape status bars.
    CGFloat height = MIN(30, CGRectGetHeight(container.bounds) - 2);
    CGFloat width = height * 32.0 / 34.0;
    CGRect batteryRect = [battery convertRect:battery.bounds toView:container];
    CGFloat x = CGRectGetMaxX(area) - width;
    CGFloat y = CGRectGetMidY(batteryRect) - height / 2;
    x = MAX(CGRectGetMinX(container.bounds), MIN(x, CGRectGetMaxX(container.bounds) - width));
    y = MAX(CGRectGetMinY(container.bounds) + 1,
        MIN(y, CGRectGetMaxY(container.bounds) - height - 1));

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.glyph.superview != container) [container addSubview:self.glyph];
    self.glyph.frame = CGRectMake(x, y, width, height);
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
            && ![icon isKindOfClass:DuoCellularClass]) return;
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

static void DuoUpdateContainer(UIView *container) {
    DuoStatusController *controller = objc_getAssociatedObject(container, &DuoContainerKey);
    [controller update];
}

static void DuoReloadPreferences(void) {
    BOOL enabled = DuoReadEnabled();
    if (enabled == DuoEnabled) return;
    DuoEnabled = enabled;
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
        DuoEnabled = DuoReadEnabled();
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
        %init(DuoBatteryHooks);
        %init(DuoSignalDataHooks);
        %init(DuoWifiHooks);
        %init(DuoCellularHooks);
        %init(DuoStatusBarHooks);
        if (DuoForegroundClass) {
            %init(DuoForegroundHooks);
        }
    }
}
