#import "DuoRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import "../Shared/DuoMetadata.h"

static NSString *const DuoPreferencesDomain = @"local.duobar";
static CFStringRef const DuoPreferencesNotification = CFSTR("local.duobar/preferences.changed");

@implementation DuoRootListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DuoBar";
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *items = [NSMutableArray array];

        PSSpecifier *controls = [PSSpecifier groupSpecifierWithName:@"DuoBar"];
        [controls setProperty:@"Turn DuoBar off to restore the original status-bar icons. Changes apply immediately."
                       forKey:@"footerText"];
        [items addObject:controls];

        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Enable DuoBar"
            target:self set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:) detail:Nil cell:PSSwitchCell edit:Nil];
        [enabled setProperty:DuoPreferencesDomain forKey:@"defaults"];
        [enabled setProperty:@"Enabled" forKey:@"key"];
        [enabled setProperty:@YES forKey:@"default"];
        [items addObject:enabled];

        PSSpecifier *about = [PSSpecifier groupSpecifierWithName:@"About"];
        [about setProperty:DUO_DESCRIPTION forKey:@"footerText"];
        [items addObject:about];

        PSSpecifier *developer = [PSSpecifier preferenceSpecifierNamed:@"Developer"
            target:self set:NULL get:@selector(developerName:)
            detail:Nil cell:PSTitleValueCell edit:Nil];
        [items addObject:developer];

        PSSpecifier *version = [PSSpecifier preferenceSpecifierNamed:@"Version"
            target:self set:NULL get:@selector(versionName:)
            detail:Nil cell:PSTitleValueCell edit:Nil];
        [items addObject:version];

        NSString *twitterTitle = [NSString stringWithFormat:@"Twitter / X: @%@", DUO_TWITTER_USERNAME];
        PSSpecifier *twitter = [PSSpecifier preferenceSpecifierNamed:twitterTitle
            target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
        twitter.buttonAction = @selector(openTwitter:);
        [items addObject:twitter];

        _specifiers = items;
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    CFPreferencesAppSynchronize((__bridge CFStringRef)DuoPreferencesDomain);
    id value = CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,
        (__bridge CFStringRef)DuoPreferencesDomain));
    return [value isKindOfClass:NSNumber.class] ? value : [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSNumber *enabled = @([value boolValue]);
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)enabled,
        (__bridge CFStringRef)DuoPreferencesDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)DuoPreferencesDomain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        DuoPreferencesNotification, NULL, NULL, YES);
}

- (NSString *)developerName:(PSSpecifier *)specifier {
    return DUO_DEVELOPER_NAME;
}

- (NSString *)versionName:(PSSpecifier *)specifier {
    return DUO_VERSION;
}

- (void)openTwitter:(PSSpecifier *)specifier {
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = @"https";
    components.host = @"twitter.com";
    components.path = [@"/" stringByAppendingString:DUO_TWITTER_USERNAME];
    NSURL *url = components.URL;
    if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

@end
