#import "DuoGlyphView.h"
#import <math.h>

static CGFloat DuoRadians(CGFloat degrees) { return degrees * (CGFloat)M_PI / 180.0; }

@interface DuoGlyphView ()
@property(nonatomic, strong) UIImageView *hotspotImageView;
@end

static void DuoArc(CGPoint center, CGFloat radius, CGFloat start, CGFloat end, UIColor *color) {
    if (end <= start) return;
    UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:center radius:radius
        startAngle:DuoRadians(start) endAngle:DuoRadians(end) clockwise:YES];
    arc.lineWidth = 2.6;
    arc.lineCapStyle = kCGLineCapRound;
    [color setStroke];
    [arc stroke];
}

@implementation DuoGlyphView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        self.isAccessibilityElement = NO;
        self.accessibilityElementsHidden = YES;
        self.contentMode = UIViewContentModeRedraw;
        self.foreground = UIColor.labelColor;
        self.hotspotImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.hotspotImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.hotspotImageView.userInteractionEnabled = NO;
        self.hotspotImageView.isAccessibilityElement = NO;
        self.hotspotImageView.accessibilityElementsHidden = YES;
        self.hotspotImageView.image = [[UIImage systemImageNamed:@"link"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.hotspotImageView.tintColor = self.foreground;
        self.hotspotImageView.hidden = YES;
        [self addSubview:self.hotspotImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat scale = MIN(self.bounds.size.width / 32.0, self.bounds.size.height / 34.0);
    CGFloat left = (self.bounds.size.width - 32.0 * scale) / 2.0;
    CGFloat top = (self.bounds.size.height - 34.0 * scale) / 2.0;
    if (self.networkType.length > 0) {
        self.hotspotImageView.frame = CGRectMake(left + 9.5 * scale, top + 19.0 * scale,
                                                  13.0 * scale, 8.0 * scale);
    } else {
        self.hotspotImageView.frame = CGRectMake(left + 8.5 * scale, top + 12.5 * scale,
                                                  15.0 * scale, 10.0 * scale);
    }
}

- (void)setHotspotActive:(BOOL)hotspotActive {
    _hotspotActive = hotspotActive;
    self.hotspotImageView.hidden = !hotspotActive;
    [self setNeedsDisplay];
}

- (void)setHotspotImage:(UIImage *)hotspotImage {
    _hotspotImage = hotspotImage;
    UIImage *image = hotspotImage ?: [UIImage systemImageNamed:@"link"];
    self.hotspotImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.hotspotImageView.tintColor = self.foreground ?: UIColor.labelColor;
    [self.hotspotImageView setNeedsLayout];
}

- (void)setNetworkType:(NSString *)networkType {
    _networkType = [networkType copy];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setForeground:(UIColor *)foreground {
    _foreground = foreground;
    self.hotspotImageView.tintColor = foreground ?: UIColor.labelColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context || self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;
    CGFloat scale = MIN(self.bounds.size.width / 32.0, self.bounds.size.height / 34.0);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, (self.bounds.size.width - 32 * scale) / 2,
                                  (self.bounds.size.height - 34 * scale) / 2);
    CGContextScaleCTM(context, scale, scale);

    double level = isfinite(self.charge) ? fmax(0, fmin(1, self.charge)) : 0;
    UIColor *foreground = self.foreground ?: UIColor.labelColor;
    UIColor *inactive = [foreground colorWithAlphaComponent:0.18];
    UIColor *battery = foreground;
    if (self.lowPower) battery = UIColor.systemYellowColor;
    else if (self.charging) battery = UIColor.systemGreenColor;
    else if (level <= 0.20) battery = UIColor.systemRedColor;

    // Leave a visible gap between the lower round caps and the cellular dots.
    // At 50%, the whole left arc is filled, matching the supplied reference.
    CGPoint center = CGPointMake(16, 17);
    DuoArc(center, 13, 150, 220, inactive);
    DuoArc(center, 13, -40, 30, inactive);
    CGFloat sweep = (CGFloat)level * 140;
    DuoArc(center, 13, 150, 150 + MIN(70, sweep), battery);
    DuoArc(center, 13, -40, -40 + MAX(0, sweep - 70), battery);

    NSString *percentage = [NSString stringWithFormat:@"%ld", (long)lround(level * 100)];
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:8.0 weight:UIFontWeightHeavy];
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSTextAlignmentCenter;
    CGRect textArea = CGRectMake(6, (10 - font.lineHeight) / 2, 20, font.lineHeight);
    [percentage drawInRect:textArea withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: foreground,
        NSParagraphStyleAttributeName: paragraph,
    }];

    if (self.networkType.length > 0) {
        // Keep the carrier family label readable while fitting within the battery circle.
        UIFont *networkFont = [UIFont systemFontOfSize:8.5 weight:UIFontWeightHeavy];
        NSMutableParagraphStyle *networkParagraph = [NSMutableParagraphStyle new];
        networkParagraph.alignment = NSTextAlignmentCenter;
        [self.networkType drawInRect:CGRectMake(4, 9.0, 24, 10.5)
            withAttributes:@{
                NSFontAttributeName: networkFont,
                NSForegroundColorAttributeName: foreground,
                NSParagraphStyleAttributeName: networkParagraph,
            }];
    }

    if (self.hotspotActive) {
        // The matching iOS status-bar image is drawn by hotspotImageView.
    } else if (self.wifiVisible) {
        CGContextSaveGState(context);
        if (self.networkType.length > 0) {
            CGContextTranslateCTM(context, 10.7, 18.1);
            CGContextScaleCTM(context, 0.56, 0.56);
        } else {
            CGContextTranslateCTM(context, 9, 13);
            CGContextScaleCTM(context, 0.78, 0.78);
        }
        [self drawWiFiWithForeground:foreground inactive:inactive];
        CGContextRestoreGState(context);
    }

    NSInteger cellular = MAX(0, MIN(4, self.cellularBars));
    const CGPoint dots[] = {{7.5, 28}, {13, 30.2}, {19, 30.2}, {24.5, 28}};
    for (NSInteger i = 0; i < 4; i++) {
        [(i < cellular ? foreground : inactive) setFill];
        [[UIBezierPath bezierPathWithOvalInRect:
            CGRectMake(dots[i].x - 1.65, dots[i].y - 1.65, 3.3, 3.3)] fill];
    }

    if (self.charging) {
        UIBezierPath *bolt = [UIBezierPath bezierPath];
        [bolt moveToPoint:CGPointMake(28.7, 1.2)];
        [bolt addLineToPoint:CGPointMake(25.8, 4.8)];
        [bolt addLineToPoint:CGPointMake(27.5, 4.8)];
        [bolt addLineToPoint:CGPointMake(26.8, 7.5)];
        [bolt addLineToPoint:CGPointMake(29.8, 3.8)];
        [bolt addLineToPoint:CGPointMake(28.0, 3.8)];
        [bolt closePath];
        [battery setFill];
        [bolt fill];
    }

    CGContextRestoreGState(context);
}

- (void)drawWiFiWithForeground:(UIColor *)foreground inactive:(UIColor *)inactive {
    NSInteger bars = MAX(0, MIN(3, self.wifiBars));
    UIBezierPath *outer = [UIBezierPath bezierPath];
    [outer moveToPoint:CGPointMake(1.5, 4)];
    [outer addCurveToPoint:CGPointMake(16.5, 4)
            controlPoint1:CGPointMake(5.8, 0.1) controlPoint2:CGPointMake(12.2, 0.1)];
    outer.lineWidth = 2.15;
    outer.lineCapStyle = kCGLineCapRound;
    [(bars >= 3 ? foreground : inactive) setStroke];
    [outer stroke];

    UIBezierPath *inner = [UIBezierPath bezierPath];
    [inner moveToPoint:CGPointMake(4.4, 7.25)];
    [inner addCurveToPoint:CGPointMake(13.6, 7.25)
            controlPoint1:CGPointMake(7, 5) controlPoint2:CGPointMake(11, 5)];
    inner.lineWidth = 2.15;
    inner.lineCapStyle = kCGLineCapRound;
    [(bars >= 2 ? foreground : inactive) setStroke];
    [inner stroke];

    [(bars >= 1 ? foreground : inactive) setFill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(7.4, 9.5, 3.2, 3.2)] fill];
}

@end
