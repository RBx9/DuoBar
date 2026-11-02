// DuoBar iOS 14 rootful/Taurine compatibility prototype.
// Deliberately separate from the existing iOS 16 Rootless/RootHide hooks.
// Only loaded in SpringBoard. Missing iOS 14 private symbols fail closed;
// no guessing method signatures or forcing iOS 16-only native setters.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <math.h>
#import "DuoGlyphView.h"

static char Duo14ControllerKey;
static BOOL Duo14Enabled = YES;
static CGFloat Duo14Scale = 1.0;
static NSHashTable *Duo14Controllers;

static BOOL Duo14ReadEnabled(void) {
    CFPreferencesAppSynchronize(CFSTR("local.duobar"));
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(
        CFSTR("Enabled"), CFSTR("local.duobar")));
    return [value isKindOfClass:NSNumber.class] ? [value boolValue] : YES;
}
static CGFloat Duo14ReadScale(void) {
    CFPreferencesAppSynchronize(CFSTR("local.duobar"));
    id value = CFBridgingRelease(CFPreferencesCopyAppValue(
        CFSTR("SizeScale"), CFSTR("local.duobar")));
    if (![value isKindOfClass:NSNumber.class]) return 1.0;
    double x = [value doubleValue];
    return isfinite(x) ? MAX(0.7, MIN(1.4, x)) : 1.0;
}

static BOOL Duo14IsVisible(UIView *view, UIView *host) {
    if (!view || !view.window || view.bounds.size.width < 3 ||
        view.bounds.size.height < 3) return NO;
    for (UIView *p = view; p; p = p.superview) {
        if (p.hidden || p.alpha < 0.01) return NO;
        if (p == host) return YES;
    }
    return NO;
}

// Only call introspection selectors after checking they exist. Selector
// signatures vary by OS release; never call setters from iOS 16 here.
static NSInteger Duo14Bars(UIView *view, NSInteger maximum) {
    SEL totalSel = NSSelectorFromString(@"numberOfBars");
    SEL activeSel = NSSelectorFromString(@"numberOfActiveBars");
    if (![view respondsToSelector:totalSel] ||
        ![view respondsToSelector:activeSel]) return 0;
    @try {
        long long total = ((long long (*)(id, SEL))objc_msgSend)(view,totalSel);
        long long active = ((long long (*)(id, SEL))objc_msgSend)(view,activeSel);
        if (total <= 0 || total > 20 || active < 0 || active > total) return 0;
        return MAX(0, MIN(maximum, (NSInteger)lround((double)active * maximum / total)));
    } @catch (__unused NSException *exception) { return 0; }
}

static double Duo14BatteryLevel(UIView *battery) {
    SEL percent = NSSelectorFromString(@"chargePercent");
    if (battery && [battery respondsToSelector:percent]) {
        @try {
            double level = ((double (*)(id,SEL))objc_msgSend)(battery,percent);
            if (isfinite(level) && level >= 0 && level <= 1) return level;
            if (isfinite(level) && level > 1 && level <= 100) return level / 100.;
        } @catch (__unused NSException *exception) {}
    }
    UIDevice *device = UIDevice.currentDevice;
    device.batteryMonitoringEnabled = YES;
    double value = device.batteryLevel;
    return isfinite(value) && value >= 0 && value <= 1 ? value : -1;
}

static void Duo14FindIcons(UIView *host, UIView **battery, UIView **wifi,
                           UIView **cellular) {
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:host];
    NSUInteger scanned = 0;
    while (queue.count && ++scanned <= 220) {
        UIView *view = queue.lastObject;
        [queue removeLastObject];
        NSString *name = NSStringFromClass(view.class).lowercaseString;
        // Skip our own custom views when discovering native UIKit icons.
        if ([view isKindOfClass:DuoGlyphView.class]) continue;
        if (view != host && Duo14IsVisible(view,host)) {
            BOOL statusClass = [name containsString:@"statusbar"] ||
                               [name containsString:@"batteryview"] ||
                               [name containsString:@"signalview"];
            if (statusClass && [name containsString:@"battery"] && !*battery) {
                *battery = view;
            } else if (statusClass &&
                       ([name containsString:@"wifi"] || [name containsString:@"wi-fi"]) &&
                       !*wifi) {
                *wifi = view;
            } else if (statusClass && [name containsString:@"cellular"] &&
                       !*cellular) {
                *cellular = view;
            }
        }
        [queue addObjectsFromArray:view.subviews];
    }
}

@interface Duo14Controller : NSObject
@property(nonatomic,weak) UIView *host;
@property(nonatomic,weak) UIView *coveredBattery;
@property(nonatomic,strong) DuoGlyphView *glyph;
@property(nonatomic) float savedBatteryOpacity;
@property(nonatomic) BOOL batteryCovered;
@property(nonatomic) BOOL pending;
@property(nonatomic) BOOL updating;
- (void)schedule;
- (void)refresh;
- (void)restoreBattery;
@end
@implementation Duo14Controller
- (instancetype)init {
    if ((self=[super init])) {
        _glyph=[[DuoGlyphView alloc] initWithFrame:CGRectZero];
        _glyph.hidden=YES;
    }
    return self;
}
- (void)restoreBattery {
    if (self.batteryCovered && self.coveredBattery) {
        self.coveredBattery.layer.opacity = self.savedBatteryOpacity;
    }
    self.coveredBattery=nil;
    self.batteryCovered=NO;
}
- (void)schedule {
    if (self.pending || self.updating) return;
    self.pending=YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.pending=NO;
        [self refresh];
    });
}
- (void)refresh {
    if (self.updating) return;
    UIView *host=self.host;
    if (!host) { [self restoreBattery]; return; }
    self.updating=YES;
    if (!Duo14Enabled || !host.window) {
        [self restoreBattery];
        self.glyph.hidden=YES;
        self.updating=NO;
        return;
    }
    UIView *battery=nil, *wifi=nil, *cellular=nil;
    Duo14FindIcons(host,&battery,&wifi,&cellular);
    double charge=Duo14BatteryLevel(battery);
    // Never replace native icons until iOS 14's actual battery glyph is found.
    // This keeps the status bar intact if the target device differs.
    if (!battery || charge < 0 || !Duo14IsVisible(battery,host)) {
        [self restoreBattery];
        self.glyph.hidden=YES;
        self.updating=NO;
        return;
    }
    CGRect r=[battery convertRect:battery.bounds toView:host];
    if (CGRectIsEmpty(r) || !isfinite(r.origin.x) || !isfinite(r.origin.y)) {
        [self restoreBattery];
        self.glyph.hidden=YES;
        self.updating=NO;
        return;
    }
    if (self.coveredBattery != battery) [self restoreBattery];

    UIDevice *device=UIDevice.currentDevice;
    device.batteryMonitoringEnabled=YES;
    UIDeviceBatteryState state=device.batteryState;
    self.glyph.charge=charge;
    self.glyph.charging=(state==UIDeviceBatteryStateCharging ||
                         state==UIDeviceBatteryStateFull);
    self.glyph.lowPower=NSProcessInfo.processInfo.isLowPowerModeEnabled;
    self.glyph.wifiVisible=(wifi != nil);
    self.glyph.wifiBars=wifi ? Duo14Bars(wifi,3) : 0;
    self.glyph.cellularBars=cellular ? Duo14Bars(cellular,4) : 0;
    self.glyph.hotspotActive=NO;
    self.glyph.foreground=UIColor.labelColor;
    CGFloat nativeHeight=CGRectGetHeight(r);
    CGFloat base=MAX(20,MIN(30,nativeHeight+7));
    CGFloat h=base*Duo14Scale;
    CGFloat w=h*32.0/34.0;
    CGRect bounds=host.bounds;
    CGFloat x=CGRectGetMaxX(r)-w;
    CGFloat y=CGRectGetMidY(r)-h/2.;
    x=MAX(CGRectGetMinX(bounds),MIN(x,CGRectGetMaxX(bounds)-w));
    // Don't move status-bar layout or global system view positions.
    if (self.glyph.superview != host) [host addSubview:self.glyph];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.glyph.frame=CGRectMake(x,y,w,h);
    self.glyph.layer.zPosition=100;
    self.glyph.hidden=NO;
    // Only cover battery artwork. Keep cellular/Wi-Fi views untouched until
    // tested on a real iOS 14 device; don't create invisible signal gaps.
    if (!self.batteryCovered) {
        self.savedBatteryOpacity=battery.layer.opacity;
        self.coveredBattery=battery;
        self.batteryCovered=YES;
    }
    battery.layer.opacity=0;
    [CATransaction commit];
    [self.glyph setNeedsDisplay];
    self.updating=NO;
}
@end

static void Duo14ScheduleHost(UIView *host) {
    if (!host.window || NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 14) return;
    Duo14Controller *controller=objc_getAssociatedObject(host,&Duo14ControllerKey);
    if (!controller) {
        controller=[Duo14Controller new];
        controller.host=host;
        objc_setAssociatedObject(host,&Duo14ControllerKey,controller,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [Duo14Controllers addObject:controller];
    }
    [controller schedule];
}

static void Duo14RefreshAll(void) {
    Duo14Enabled=Duo14ReadEnabled();
    Duo14Scale=Duo14ReadScale();
    for (Duo14Controller *controller in Duo14Controllers.allObjects) {
        [controller refresh];
    }
}
static void Duo14PreferenceChanged(CFNotificationCenterRef center,void *observer,
                                    CFStringRef name,const void *object,
                                    CFDictionaryRef userInfo) {
    (void)center; (void)observer; (void)name; (void)object; (void)userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{ Duo14RefreshAll(); });
}

%group Duo14ModernStatusBar
%hook _UIStatusBar
- (void)layoutSubviews {
    %orig;
    Duo14ScheduleHost(self);
}
- (void)didMoveToWindow {
    %orig;
    Duo14ScheduleHost(self);
}
%end
%end

// Some iOS 14 layouts use a different status-bar view class. Only one
// hook group is activated, and only when that class is available.
%group Duo14LegacyStatusBar
%hook UIStatusBar
- (void)layoutSubviews {
    %orig;
    Duo14ScheduleHost(self);
}
- (void)didMoveToWindow {
    %orig;
    Duo14ScheduleHost(self);
}
%end
%end

%ctor {
    @autoreleasepool {
        if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 14) return;
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) return;
        Duo14Controllers=[NSHashTable weakObjectsHashTable];
        Duo14Enabled=Duo14ReadEnabled();
        Duo14Scale=Duo14ReadScale();
        UIDevice.currentDevice.batteryMonitoringEnabled=YES;
        if (NSClassFromString(@"_UIStatusBar")) {
            %init(Duo14ModernStatusBar);
        } else if (NSClassFromString(@"UIStatusBar")) {
            %init(Duo14LegacyStatusBar);
        } else {
            // No known iOS 14 status-bar host. Fail safely, do not inject.
            return;
        }
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,Duo14PreferenceChanged,CFSTR("local.duobar/preferences.changed"),
            NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
        NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
        for (NSString *name in @[UIDeviceBatteryLevelDidChangeNotification,
                                UIDeviceBatteryStateDidChangeNotification,
                                NSProcessInfoPowerStateDidChangeNotification]) {
            [nc addObserverForName:name object:nil queue:NSOperationQueue.mainQueue
                      usingBlock:^(__unused NSNotification *notification){
                for (Duo14Controller *controller in Duo14Controllers.allObjects)
                    [controller schedule];
            }];
        }
    }
}
