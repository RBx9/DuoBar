#import "DuoRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../Shared/DuoMetadata.h"

static NSString *const DuoPreferencesDomain = @"local.duobar";
static CFStringRef const DuoPreferencesNotification = CFSTR("local.duobar/preferences.changed");
static NSString *const DuoRepoURL = @"https://rbx9.github.io/";
static NSString *const DuoSourceURL = @"sileo://source/https://rbx9.github.io/";
static NSString *const DuoGitHubURL = @"https://github.com/RBx9/DuoBar";

@implementation DuoRootListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DuoBar";

    // Add the matching icon to the preference page header as well as Settings' list.
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *icon = [UIImage imageNamed:@"DuoBarIcon"
                              inBundle:bundle
         compatibleWithTraitCollection:nil];
    // Some PreferenceLoader builds expose the image as a file but not via
    // UIKit's named-image cache; load it directly as a fallback.
    if (!icon) {
        NSString *file = [bundle pathForResource:@"DuoBarIcon" ofType:@"png"];
        if (file) icon = [UIImage imageWithContentsOfFile:file];
    }
    if (icon) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 132, 32)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:icon];
        imageView.frame = CGRectMake(0, 2, 28, 28);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 6;
        [titleView addSubview:imageView];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 97, 32)];
        label.text = @"DuoBar";
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont boldSystemFontOfSize:18];
        label.adjustsFontSizeToFitWidth = YES;
        [titleView addSubview:label];
        self.navigationItem.titleView = titleView;
    }
}

- (PSSpecifier *)linkNamed:(NSString *)name
                       URL:(NSString *)url
                    action:(SEL)action {
    PSSpecifier *link = [PSSpecifier preferenceSpecifierNamed:name
        target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
    [link setProperty:url forKey:@"DuoLinkURL"];
    link.buttonAction = action;
    return link;
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *items = [NSMutableArray array];

        PSSpecifier *display = [PSSpecifier groupSpecifierWithName:@"Appearance"];
        [display setProperty:@"Turn DuoBar off to restore the original status-bar icons. Changes take effect immediately."
                      forKey:@"footerText"];
        [items addObject:display];

        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Enable DuoBar"
            target:self set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:) detail:Nil cell:PSSwitchCell edit:Nil];
        [enabled setProperty:DuoPreferencesDomain forKey:@"defaults"];
        [enabled setProperty:@"Enabled" forKey:@"key"];
        [enabled setProperty:@YES forKey:@"default"];
        [items addObject:enabled];

        PSSpecifier *about = [PSSpecifier groupSpecifierWithName:@"About DuoBar"];
        [about setProperty:DUO_DESCRIPTION forKey:@"footerText"];
        [items addObject:about];

        PSSpecifier *version = [PSSpecifier preferenceSpecifierNamed:@"Version"
            target:self set:NULL get:@selector(versionName:)
            detail:Nil cell:PSTitleValueCell edit:Nil];
        [items addObject:version];

        PSSpecifier *developer = [PSSpecifier preferenceSpecifierNamed:@"Developer"
            target:self set:NULL get:@selector(developerName:)
            detail:Nil cell:PSTitleValueCell edit:Nil];
        [items addObject:developer];

        PSSpecifier *links = [PSSpecifier groupSpecifierWithName:@"Links & Updates"];
        [links setProperty:@"RBx9 Repo: https://rbx9.github.io/\nUse the same Sileo source for DuoBar updates and future RBx9 tweaks."
                    forKey:@"footerText"];
        [items addObject:links];

        [items addObject:[self linkNamed:@"RBx9 Repo"
                                       URL:DuoRepoURL
                                    action:@selector(openLink:)]];

        [items addObject:[self linkNamed:@"Add Source to Sileo"
                                       URL:DuoSourceURL
                                    action:@selector(openLink:)]];

        [items addObject:[self linkNamed:@"DuoBar on GitHub"
                                       URL:DuoGitHubURL
                                    action:@selector(openLink:)]];

        NSString *twitterTitle = [NSString stringWithFormat:@"Twitter / X: @%@", DUO_TWITTER_USERNAME];
        NSString *twitterURL = [@"https://twitter.com/" stringByAppendingString:DUO_TWITTER_USERNAME];
        [items addObject:[self linkNamed:twitterTitle
                                       URL:twitterURL
                                    action:@selector(openLink:)]];

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
    (void)specifier;
    return DUO_DEVELOPER_NAME;
}

- (NSString *)versionName:(PSSpecifier *)specifier {
    (void)specifier;
    return DUO_VERSION;
}

- (void)openLink:(PSSpecifier *)specifier {
    NSString *link = [specifier propertyForKey:@"DuoLinkURL"];
    if (![link isKindOfClass:NSString.class]) return;
    NSURL *url = [NSURL URLWithString:link];
    NSString *scheme = url.scheme.lowercaseString;
    if (!url || !([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"sileo"])) return;
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

@end
