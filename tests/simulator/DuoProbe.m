// Simulator-only probe, never packaged. Loaded next to a simulator build of
// DuoBar, it reports which private classes and selectors DuoBar depends on
// exist in this iOS runtime, dumps status-bar geometry, and, inside
// SpringBoard with DUO_PROBE_CC=1, traces DuoBar while Control Center closes.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>

static void DuoProbeLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void DuoProbeLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    const char *label = getenv("DUO_PROBE_LABEL");
    // SpringBoard's stdout is not captured by the test, so it can log to a file.
    static FILE *output;
    if (!output) {
        const char *path = getenv("DUO_PROBE_OUT");
        output = path ? fopen(path, "a") : NULL;
        if (!output) output = stdout;
    }
    fprintf(output, "DUOPROBE [%s] %s\n", label ?: "-", line.UTF8String);
    fflush(output);
}

// Every private class and selector DuoBar's hooks or reads depend on.
static NSArray<NSArray *> *DuoProbeManifest(void) {
    return @[
        @[@"_UIBatteryView", @[@"chargePercent", @"chargingState", @"saverModeActive", @"bodyColor",
            @"setChargePercent:", @"setChargingState:", @"setSaverModeActive:", @"setBodyColor:",
            @"layoutSubviews", @"didMoveToWindow", @"setHidden:", @"setAlpha:"]],
        @[@"_UIStatusBarSignalView", @[@"numberOfBars", @"numberOfActiveBars", @"activeColor",
            @"setNumberOfBars:", @"setNumberOfActiveBars:", @"setActiveColor:", @"setHidden:", @"setAlpha:"]],
        @[@"_UIStatusBarWifiSignalView", @[@"_updateActiveBars", @"layoutSubviews", @"didMoveToWindow"]],
        @[@"_UIStatusBarCellularSignalView", @[@"_updateActiveBars", @"layoutSubviews", @"didMoveToWindow"]],
        @[@"_UIStatusBarStringView", @[@"text", @"setText:", @"layoutSubviews", @"didMoveToWindow"]],
        @[@"_UIStatusBarImageView", @[@"setImage:", @"setAccessibilityLabel:", @"layoutSubviews", @"didMoveToWindow"]],
        @[@"_UIStatusBarForegroundView", @[@"layoutSubviews", @"didMoveToWindow"]],
        @[@"_UIStatusBar", @[@"layoutSubviews", @"didMoveToWindow"]],
        @[@"CCUIStatusBar", @[@"layoutSubviews", @"didMoveToWindow"]],
        @[@"CCUIHeaderPocketView", @[]],
        @[@"SBControlCenterController", @[@"+sharedInstance", @"isVisible", @"isPresented"]],
    ];
}

static void DuoProbeReportAPIs(void) {
    // Control Center classes live in a private framework that apps do not load.
    dlopen("/System/Library/PrivateFrameworks/ControlCenterUI.framework/ControlCenterUI", RTLD_LAZY);
    for (NSArray *entry in DuoProbeManifest()) {
        NSString *className = entry[0];
        Class cls = NSClassFromString(className);
        if (!cls) {
            DuoProbeLog(@"api class %@ MISSING", className);
            continue;
        }
        NSMutableArray *chain = [NSMutableArray array];
        for (Class c = class_getSuperclass(cls); c && chain.count < 3; c = class_getSuperclass(c)) {
            [chain addObject:NSStringFromClass(c)];
        }
        DuoProbeLog(@"api class %@ present super=%@", className, [chain componentsJoinedByString:@">"]);
        for (NSString *name in entry[1]) {
            BOOL classMethod = [name hasPrefix:@"+"];
            SEL selector = NSSelectorFromString(classMethod ? [name substringFromIndex:1] : name);
            Method method = classMethod ? class_getClassMethod(cls, selector) : class_getInstanceMethod(cls, selector);
            const char *types = method ? method_getTypeEncoding(method) : NULL;
            DuoProbeLog(@"api sel %@ %@ %@ types=%s", className, name, method ? @"present" : @"MISSING",
                types ?: "-");
        }
    }
}

static NSArray<UIWindow *> *DuoProbeWindows(void) {
    NSMutableOrderedSet<UIWindow *> *windows = [NSMutableOrderedSet orderedSet];
    SEL all = NSSelectorFromString(@"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
    if ([UIWindow respondsToSelector:all]) {
        NSArray *found = ((NSArray *(*)(id, SEL, BOOL, BOOL))objc_msgSend)(UIWindow.class, all, YES, NO);
        if ([found isKindOfClass:NSArray.class]) [windows addObjectsFromArray:found];
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:UIWindowScene.class]) [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }
    return windows.array;
}

static NSString *DuoProbeRect(CGRect r) {
    return [NSString stringWithFormat:@"{%.1f,%.1f,%.1f,%.1f}", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

static void DuoProbeDump(UIView *view, UIWindow *window, NSUInteger depth, NSUInteger *count) {
    if (depth > 40 || *count > 400) return;
    NSString *name = NSStringFromClass(view.class);
    if ([name containsString:@"StatusBar"] || [name containsString:@"Battery"] ||
        [name isEqualToString:@"DuoGlyphView"]) {
        (*count)++;
        NSString *text = @"";
        if ([view respondsToSelector:@selector(text)]) {
            id value = ((id (*)(id, SEL))objc_msgSend)(view, @selector(text));
            if ([value isKindOfClass:NSString.class]) text = value;
        }
        DuoProbeLog(@"view depth=%lu %@ frame=%@ window=%@ hidden=%d alpha=%.2f clips=%d text=\"%@\"",
            (unsigned long)depth, name, DuoProbeRect(view.frame),
            DuoProbeRect([view convertRect:view.bounds toView:window]),
            view.hidden, view.alpha, view.clipsToBounds, text);
    }
    for (UIView *subview in view.subviews) DuoProbeDump(subview, window, depth + 1, count);
}

static void DuoProbeReportLayout(void) {
    UIScreen *screen = UIScreen.mainScreen;
    DuoProbeLog(@"screen bounds=%@ scale=%.0f", DuoProbeRect(screen.bounds), screen.scale);
    for (UIWindow *window in DuoProbeWindows()) {
        CGFloat statusBarHeight = window.windowScene.statusBarManager.statusBarFrame.size.height;
        DuoProbeLog(@"window %@ frame=%@ hidden=%d level=%.0f safeTop=%.1f statusBar=%.1f",
            NSStringFromClass(window.class), DuoProbeRect(window.frame), window.hidden,
            window.windowLevel, window.safeAreaInsets.top, statusBarHeight);
        NSUInteger count = 0;
        DuoProbeDump(window, window, 0, &count);
    }
}

// Sample DuoBar's and the battery's on-screen frames every display frame while
// Control Center is presented and dismissed, so a jump is visible as numbers.
@interface DuoProbeTracer : NSObject
@property(nonatomic, strong) CADisplayLink *link;
@property(nonatomic) CFTimeInterval start;
@property(nonatomic, copy) NSString *phase;
@end

@implementation DuoProbeTracer
- (void)startPhase:(NSString *)phase {
    self.phase = phase;
    self.start = CACurrentMediaTime();
    if (!self.link) {
        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
}
- (void)stop {
    [self.link invalidate];
    self.link = nil;
}
- (void)collect:(UIView *)view into:(NSMutableArray<NSString *> *)items {
    NSString *name = NSStringFromClass(view.class);
    if ([name isEqualToString:@"DuoGlyphView"] || [name isEqualToString:@"_UIBatteryView"]) {
        CALayer *layer = view.layer.presentationLayer ?: view.layer;
        CALayer *root = view.window.layer.presentationLayer ?: view.window.layer;
        CGRect r = [layer convertRect:layer.bounds toLayer:root];
        UIView *container = view.superview;
        while (container && ![NSStringFromClass(container.class) isEqualToString:@"_UIStatusBarForegroundView"]) {
            container = container.superview;
        }
        [items addObject:[NSString stringWithFormat:@"%@%@ win=%@ rect=%@ hidden=%d alpha=%.2f in=%@",
            [name isEqualToString:@"DuoGlyphView"] ? @"glyph" : @"battery",
            view.hidden ? @"(hidden)" : @"", NSStringFromClass(view.window.class), DuoProbeRect(r),
            view.hidden, layer.opacity, container ? NSStringFromClass(container.superview.class) : @"-"]];
    }
    for (UIView *subview in view.subviews) [self collect:subview into:items];
}
- (void)tick:(CADisplayLink *)link {
    (void)link;
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (UIWindow *window in DuoProbeWindows()) {
        if (!window.hidden) [self collect:window into:items];
    }
    DuoProbeLog(@"trace %@ t=%.3f %@", self.phase, CACurrentMediaTime() - self.start,
        [items componentsJoinedByString:@" | "]);
}
@end

static DuoProbeTracer *DuoProbeActiveTracer;

static BOOL DuoProbeCallControlCenter(NSString *verb) {
    Class cls = NSClassFromString(@"SBControlCenterController");
    if (![cls respondsToSelector:@selector(sharedInstance)]) return NO;
    id controller = ((id (*)(id, SEL))objc_msgSend)(cls, @selector(sharedInstance));
    SEL withCompletion = NSSelectorFromString([verb stringByAppendingString:@"Animated:completion:"]);
    SEL animated = NSSelectorFromString([verb stringByAppendingString:@"Animated:"]);
    if ([controller respondsToSelector:withCompletion]) {
        ((void (*)(id, SEL, BOOL, id))objc_msgSend)(controller, withCompletion, YES, nil);
        return YES;
    }
    if ([controller respondsToSelector:animated]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, animated, YES);
        return YES;
    }
    return NO;
}

static void DuoProbeTraceControlCenter(void) {
    DuoProbeActiveTracer = [DuoProbeTracer new];
    [DuoProbeActiveTracer startPhase:@"idle"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL presented = DuoProbeCallControlCenter(@"present");
        DuoProbeLog(@"cc present called=%d", presented);
        [DuoProbeActiveTracer startPhase:@"open"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DuoProbeReportLayout();
        BOOL dismissed = DuoProbeCallControlCenter(@"dismiss");
        DuoProbeLog(@"cc dismiss called=%d", dismissed);
        [DuoProbeActiveTracer startPhase:@"close"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [DuoProbeActiveTracer stop];
        DuoProbeReportLayout();
        DuoProbeLog(@"cc trace done");
    });
}

__attribute__((constructor)) static void DuoProbeInit(void) {
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier ?: @"?";
    BOOL springBoard = [bundle isEqualToString:@"com.apple.springboard"];
    // Only report from the processes the test drives.
    if (!springBoard && ![bundle isEqualToString:@"com.apple.Preferences"]) return;
    double delay = springBoard ? 12.0 : 4.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSOperatingSystemVersion v = NSProcessInfo.processInfo.operatingSystemVersion;
        const char *model = getenv("SIMULATOR_MODEL_IDENTIFIER");
        DuoProbeLog(@"process %@ ios=%ld.%ld.%ld model=%s", bundle, (long)v.majorVersion,
            (long)v.minorVersion, (long)v.patchVersion, model ?: "?");
        DuoProbeReportAPIs();
        DuoProbeReportLayout();
        if (springBoard && getenv("DUO_PROBE_CC")) DuoProbeTraceControlCenter();
    });
}
