// Experimental subscription command recovery for iOS 14 / YouTube 19.20.2.
// MIT; preserve the normal tap handler if no valid native subscription command exists.
#import "TweakHeader.h"
#import <HBLog.h>
#import <YouTubeHeader/GPBMessage.h>
#import <YouTubeHeader/ELMNodeController.h>
#import <YouTubeHeader/ELMTouchCommandPropertiesHandler.h>
#import <YouTubeHeader/YTELMContext.h>
#import <YouTubeHeader/YTCommandResponderEvent.h>
#import <YouTubeHeader/YTICommand.h>

static id RBXSafeKVC(id object, NSString *key) {
    if (!object || !key) return nil;
    @try { return [object valueForKey:key]; }
    @catch (NSException *exception) { return nil; }
}

static BOOL RBXIsSubscribeTap(ELMNodeController *controller) {
    if (!controller) return NO;
    NSString *label = [(controller.node.view.accessibilityLabel ?: @"") lowercaseString];
    NSString *identifier = [(controller.node.accessibilityIdentifier ?: @"") lowercaseString];
    NSString *key = [(controller.key ?: @"") lowercaseString];
    BOOL matchingLabel = [label isEqualToString:@"subscribe"] ||
        [label hasPrefix:@"subscribe to "] ||
        [label isEqualToString:@"اشترك"] ||
        [label isEqualToString:@"اشتراك"];
    BOOL matchingIdentifier =
        (([identifier containsString:@"subscribe"] &&
          ![identifier containsString:@"subscribed"] &&
          ![identifier containsString:@"unsubscribe"]) ||
         ([key containsString:@"subscribe"] &&
          ![key containsString:@"subscribed"] &&
          ![key containsString:@"unsubscribe"]));
    return matchingLabel || matchingIdentifier;
}

static YTICommand *RBXFindSubscribeCommand(id value, NSHashTable *seen, NSUInteger depth) {
    if (!value || depth > 7 || [seen containsObject:value]) return nil;
    [seen addObject:value];
    if ([value isKindOfClass:%c(YTICommand)]) {
        NSString *description = [[value description] lowercaseString];
        if ([description containsString:@"subscribeendpoint"] &&
            ![description containsString:@"unsubscribeendpoint"]) return value;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        for (id item in value) {
            YTICommand *cmd = RBXFindSubscribeCommand(item, seen, depth+1);
            if (cmd) return cmd;
        }
        return nil;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        for (id item in [value allValues]) {
            YTICommand *cmd = RBXFindSubscribeCommand(item, seen, depth+1);
            if (cmd) return cmd;
        }
        return nil;
    }
    if ([value isKindOfClass:%c(GPBMessage)]) {
        YTICommand *cmd = RBXFindSubscribeCommand([(GPBMessage *)value firstSubmessage], seen, depth+1);
        if (cmd) return cmd;
    }
    static NSArray<NSString *> *keys;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        keys = @[@"command", @"onTapCommand", @"tapCommand", @"serviceEndpoint",
                 @"navigationEndpoint", @"subscribeCommand", @"onTap", @"endpoint",
                 @"buttonRenderer", @"element", @"data", @"commands", @"actions"];
    });
    for (NSString *key in keys) {
        id item = RBXSafeKVC(value, key);
        if (!item || item == value) continue;
        YTICommand *cmd = RBXFindSubscribeCommand(item, seen, depth+1);
        if (cmd) return cmd;
    }
    return nil;
}

extern void RBXProbeLog(NSString *message);

static BOOL RBXTrySubscribeTap(ELMTouchCommandPropertiesHandler *handler) {
    if (!isLegacy || ![realAppVersion isEqualToString:@"19.20.2"]) return NO;
    ELMNodeController *controller = RBXSafeKVC(handler, @"_controller");
    if (![controller isKindOfClass:%c(ELMNodeController)]) return NO;
    if (!RBXIsSubscribeTap(controller)) return NO;
    RBXProbeLog(@"Legacy tap handler recognized Subscribe node");
    YTELMContext *context = RBXSafeKVC(handler, @"_context");
    id firstResponder = [context parentResponder];
    if (!firstResponder) return NO;
    id entry = RBXSafeKVC(firstResponder, @"elementEntry");
    id nodeElement = [controller element];
    NSHashTable *seen = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
    YTICommand *command = RBXFindSubscribeCommand(nodeElement, seen, 0);
    if (!command) command = RBXFindSubscribeCommand(entry, seen, 0);
    if (!command) {
        RBXProbeLog(@"Legacy tap: no native Subscribe command located");
        HBLogDebug(@"RBx9 SubscribeFix: tap recognized, no native endpoint found");
        return NO;
    }
    UIView *view = controller.node.view;
    if (!view) return NO;
    YTCommandResponderEvent *event = [%c(YTCommandResponderEvent)
        eventWithCommand:command fromView:view entry:entry sendClick:YES firstResponder:firstResponder];
    if (!event) return NO;
    HBLogDebug(@"RBx9 SubscribeFix: dispatching existing subscribe command");
    [event send];
    RBXProbeLog(@"Legacy tap: dispatched existing Subscribe command");
    return YES;
}

%hook ELMTouchCommandPropertiesHandler
- (void)handleTap {
    if (RBXTrySubscribeTap(self)) return;
    %orig;
}
%end

%ctor { %init; }
