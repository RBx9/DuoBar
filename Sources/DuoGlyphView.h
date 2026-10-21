#import <UIKit/UIKit.h>

@interface DuoGlyphView : UIView
@property(nonatomic) double charge;
@property(nonatomic) BOOL charging;
@property(nonatomic) BOOL lowPower;
@property(nonatomic) BOOL wifiVisible;
@property(nonatomic) BOOL hotspotActive;
@property(nonatomic) NSInteger wifiBars;
@property(nonatomic) NSInteger cellularBars;
@property(nonatomic, strong) UIColor *foreground;
@end
