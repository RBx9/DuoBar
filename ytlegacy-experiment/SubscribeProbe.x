// RBx9 Subscribe diagnostic instrumentation — YouTube 19.20.2 on iOS 14.
// No URL bodies, auth tokens, account info, or button text is recorded.
#import "TweakHeader.h"
#import <UIKit/UIKit.h>
#import <YouTubeHeader/ELMTouchCommandPropertiesHandler.h>
#import <YouTubeHeader/YTCommandResponderEvent.h>

static NSString *RBXProbePath(void) {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (!documents) return nil;
    return [documents stringByAppendingPathComponent:@"RBx9YouTubeSubscribeDebug.txt"];
}

void RBXProbeLog(NSString *message) {
    NSString *path = RBXProbePath();
    if (!path || !message) return;
    @synchronized ([NSFileManager defaultManager]) {
        NSMutableString *output = [NSMutableString string];
        NSString *existing = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (existing.length > 24000)
            existing = [existing substringFromIndex:existing.length - 16000];
        if (existing) [output appendString:existing];
        [output appendFormat:@"%@ | %@\n", [NSDate date], message];
        [output writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

static BOOL RBXStringLooksSubscribe(NSString *s) {
    if (![s isKindOfClass:[NSString class]]) return NO;
    NSString *value = [s lowercaseString];
    if ([value containsString:@"unsubscribe"] || [value containsString:@"subscribed"])
        return NO;
    return [value containsString:@"subscribe"] || [value containsString:@"اشترك"] || [value containsString:@"اشتراك"];
}

static BOOL RBXSubscribeViewOnPath(UIView *view) {
    for (NSUInteger i = 0; view && i < 14; i++, view = view.superview) {
        if (RBXStringLooksSubscribe(view.accessibilityIdentifier) ||
            RBXStringLooksSubscribe(view.accessibilityLabel))
            return YES;
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (RBXStringLooksSubscribe([button titleForState:UIControlStateNormal]))
                return YES;
        }
        if ([view isKindOfClass:[UILabel class]]) {
            if (RBXStringLooksSubscribe(((UILabel *)view).text))
                return YES;
        }
    }
    return NO;
}

static NSTimeInterval RBXLastTouchAt = 0;
static BOOL RBXLastTouchMatched = NO;

%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {
        for (UITouch *touch in [event touchesForWindow:self]) {
            if (touch.phase != UITouchPhaseEnded) continue;
            UIView *tapped = [self hitTest:[touch locationInView:self] withEvent:event];
            RBXLastTouchAt = [NSDate timeIntervalSinceReferenceDate];
            RBXLastTouchMatched = RBXSubscribeViewOnPath(tapped);
            NSMutableArray *classes = [NSMutableArray array];
            for (UIView *v = tapped; v && classes.count < 7; v = v.superview)
                [classes addObject:NSStringFromClass([v class])];
            RBXProbeLog([NSString stringWithFormat:@"touch match=%d viewPath=%@",
                          RBXLastTouchMatched, [classes componentsJoinedByString:@">"]]);
            // Actual output is kept free of coordinates and visible text.
        }
    }
    %orig;
}
%end

%hook YTCommandResponderEvent
- (void)send {
    if ([NSDate timeIntervalSinceReferenceDate] - RBXLastTouchAt < 4) {
        RBXProbeLog([NSString stringWithFormat:@"YTCommandResponderEvent send; afterSubscribeHit=%d", RBXLastTouchMatched]);
    }
    %orig;
}
%end

%ctor {
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.google.ios.youtube"]) {
        RBXProbeLog(@"Diagnostic loaded: touch path + YT command send hooks enabled");
        %init;
    }
}
