#import "DuoRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>
#import "../Shared/DuoMetadata.h"

static NSString *const DuoPreferencesDomain = @"local.duobar";
static CFStringRef const DuoPreferencesNotification = CFSTR("local.duobar/preferences.changed");
static NSString *const DuoRepoURL = @"https://rbx9.github.io/";
static NSString *const DuoSourceURL = @"sileo://source/https://rbx9.github.io/";
static NSString *const DuoGitHubURL = @"https://github.com/RBx9/DuoBar";
// Developer-provided PayPal payment page for optional donations.
static NSString *const DuoPayPalURL = @"https://www.paypal.com/ncp/payment/7733S7H9UF8U6";

@interface DuoRootListController ()
@property(nonatomic, strong) PSSpecifier *duoSizeSlider;
@property(nonatomic, strong) PSSpecifier *duoSizeLabel;
@end

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

        PSSpecifier *sizeGroup = [PSSpecifier groupSpecifierWithName:@"DuoBar Size"];
        [sizeGroup setProperty:@"Move the slider to resize DuoBar. 100% matches the original size; larger sizes are limited by the space available in compact status bars."
                        forKey:@"footerText"];
        [items addObject:sizeGroup];

        PSSpecifier *sizeValue = [PSSpecifier preferenceSpecifierNamed:@"Current Size"
            target:self set:NULL get:@selector(sizePercent:)
            detail:Nil cell:PSTitleValueCell edit:Nil];
        self.duoSizeLabel = sizeValue;
        [items addObject:sizeValue];

        PSSpecifier *sizeSlider = [PSSpecifier preferenceSpecifierNamed:nil
            target:self set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:) detail:Nil cell:PSSliderCell edit:Nil];
        [sizeSlider setProperty:DuoPreferencesDomain forKey:@"defaults"];
        [sizeSlider setProperty:@"SizeScale" forKey:@"key"];
        [sizeSlider setProperty:@(1.0) forKey:@"default"];
        [sizeSlider setProperty:@(0.70) forKey:@"min"];
        [sizeSlider setProperty:@(1.40) forKey:@"max"];
        [sizeSlider setProperty:@YES forKey:@"isSegmented"];
        [sizeSlider setProperty:@(15) forKey:@"segmentCount"];
        [sizeSlider setProperty:@YES forKey:@"isContinuous"];
        self.duoSizeSlider = sizeSlider;
        [items addObject:sizeSlider];

        PSSpecifier *resetSize = [PSSpecifier preferenceSpecifierNamed:@"Reset Size to 100%"
            target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
        resetSize.buttonAction = @selector(resetSize:);
        [items addObject:resetSize];

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

        PSSpecifier *support = [PSSpecifier groupSpecifierWithName:@"Support Development"];
        [support setProperty:@"DuoBar is completely free, and it will stay that way. If you enjoy using it and would like to support its development, an optional donation helps me spend more time improving DuoBar, releasing updates, and creating new tweaks. Thank you!"
                      forKey:@"footerText"];
        [items addObject:support];

        [items addObject:[self linkNamed:@"Support via PayPal"
                                       URL:DuoPayPalURL
                                    action:@selector(openLink:)]];

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

- (NSString *)sizePercent:(PSSpecifier *)specifier {
    (void)specifier;
    NSNumber *size = [self readPreferenceValue:self.duoSizeSlider];
    CGFloat scale = [size respondsToSelector:@selector(doubleValue)] ? size.doubleValue : 1.0;
    return [NSString stringWithFormat:@"%ld%%", (long)lround(fmax(0.70, fmin(1.40, scale)) * 100.0)];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key.length) return;

    NSNumber *stored = nil;
    if ([key isEqualToString:@"SizeScale"]) {
        double number = [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 1.0;
        if (!isfinite(number)) number = 1.0;
        // 15 discrete positions, 5% increments from 70% to 140%.
        number = fmax(0.70, fmin(1.40, round(number * 20.0) / 20.0));
        stored = @(number);
    } else {
        stored = @([value boolValue]);
    }

    NSNumber *previous = [self readPreferenceValue:specifier];
    if ([previous isKindOfClass:NSNumber.class] && fabs(previous.doubleValue - stored.doubleValue) < 0.0001) return;

    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)stored,
        (__bridge CFStringRef)DuoPreferencesDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)DuoPreferencesDomain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        DuoPreferencesNotification, NULL, NULL, YES);
    if ([key isEqualToString:@"SizeScale"] && self.duoSizeLabel) {
        [self reloadSpecifier:self.duoSizeLabel animated:NO];
    }
}

- (void)resetSize:(PSSpecifier *)specifier {
    (void)specifier;
    [self setPreferenceValue:@(1.0) specifier:self.duoSizeSlider];
    if (self.duoSizeSlider) [self reloadSpecifier:self.duoSizeSlider animated:NO];
    if (self.duoSizeLabel) [self reloadSpecifier:self.duoSizeLabel animated:NO];
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
