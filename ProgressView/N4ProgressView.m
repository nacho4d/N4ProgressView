//
//  ProgressView.m
//  ProgressView
//
//  Created by Guillermo Enriquez on 3/14/12.
//  Copyright (c) 2012 nacho4d. All rights reserved.
//

#import "N4ProgressView.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define TRACK_WIDTH 36.0f

typedef struct _N4CubicBezier {
float p0, p1, p2, p3;
} N4CubicBezier;
CG_INLINE N4CubicBezier N4CubicBezierMake(float p0, float p1, float p2, float p3);
CG_INLINE N4CubicBezier N4CubicBezierMake(float p0, float p1, float p2, float p3) {
	N4CubicBezier b;
	b.p0 = p0; b.p1 = p1; b.p2 = p2; b.p3 = p3;
	return b;
}
CG_INLINE float N4CubicBezierValueAtTime(N4CubicBezier b, float t);
CG_INLINE float N4CubicBezierValueAtTime(N4CubicBezier b, float t) {
	if (t < 0) t = 0;
	if (t > 1) t = 1;
	// http://en.wikipedia.org/wiki/Bezier_curve
	// B(t) = (1-t)^3*p0 + 3*(1-t)^2*t*p1 + 3*(1-t)*t^2*p2 + t^3*p3
	const float a = (1-t);
	float val = a*a*a*b.p0 + 3*a*a*t*b.p1 + 3*a*t*t*b.p2 + t*t*t*b.p3;
	return val;
}

#pragma mark -

@interface N4ProgressView () // Internal
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) float progressBeforeAnimation;
@end

@implementation N4ProgressView
@synthesize startTime, progressBeforeAnimation;

- (void)drawRect:(CGRect)rect
{
	//NSLog(@"trackTintColor:%@, progressTintColor:%@, progress: %f", self.trackTintColor, self.progressTintColor, self.progress);
	CGContextRef c = UIGraphicsGetCurrentContext();

	CGContextSaveGState(c);
	CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
	CGContextSetLineWidth(c, 1.0);
	CGContextStrokeRect(c, rect);
	CGContextRestoreGState(c);

	CGContextSaveGState(c);
	{
		CGContextTranslateCTM(c, rect.size.width/2+0.5, rect.size.height/2+0.5);
		CGContextStrokeRect(c, rect);
		CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
		[self drawTrackInContext:c];
		if (startTime) {
			// Calculate the animation duration
			float animationDuration = fabs(self.progress - self.progressBeforeAnimation)*0.7;

			// calculate the progress that should be drawn here
			N4CubicBezier bezier = N4CubicBezierMake(0, 0.34, 0.67, 1);
			NSTimeInterval t = ([[NSDate date] timeIntervalSince1970] - startTime)/animationDuration;
			float increment = N4CubicBezierValueAtTime(bezier, t);
			float curProgress = self.progressBeforeAnimation + (self.progress - self.progressBeforeAnimation)*increment;

			// Draw the progress
			[self drawProgress:curProgress inContext:c];

			// If the progress is still too much then redraw self again - This is the animation
			if (fabs(curProgress - self.progress) > 0.0001) {
				[self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:0.01];
			} else {
				self.startTime = 0;
			}
		} else {
			// Draw the progress only once - No animation
			[self drawProgress:self.progress inContext:c];
		}
	}
	CGContextRestoreGState(c);
}

- (void)drawTrackInContext:(CGContextRef)c
{
	CGContextSaveGState(c);

	// Draw track
	const CGRect rect = self.bounds;
	CGColorRef trackTintColor = (self.trackTintColor)?self.trackTintColor.CGColor:[UIColor whiteColor].CGColor;

	// Add external arc to the path
	const CGPoint center = CGPointZero;
	const CGFloat radius = MIN(rect.size.width, rect.size.height)/2.0f;
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, center.x, center.y);
	CGPathAddArc(path, NULL, center.x, center.y, radius, DEGREES_TO_RADIANS(-90), DEGREES_TO_RADIANS(270), false);
	CGPathCloseSubpath(path);

	// Add internal arc to the path
	const CGFloat innerRadius = radius - TRACK_WIDTH;
	CGPathMoveToPoint(path, NULL, center.x, center.y);
	CGPathAddArc(path, NULL, center.x, center.y, innerRadius, DEGREES_TO_RADIANS(-90), DEGREES_TO_RADIANS(270), false);
	CGPathCloseSubpath(path);

	// Add path to the context and draw it
	CGContextAddPath(c, path);
	CFRelease(path);
	CGContextSetFillColorWithColor(c, trackTintColor);
	CGContextEOFillPath(c);

	CGContextRestoreGState(c);
}

- (void)drawProgress:(float)theProgress inContext:(CGContextRef)c
{
	CGContextSaveGState(c);

	CGColorRef progressTintColor = (self.progressTintColor)?self.progressTintColor.CGColor:[UIColor colorWithRed:36.0/255 green:114.0/255 blue:210.0/255 alpha:1.0].CGColor;
	const CGRect rect = self.bounds;

	const CGFloat rO = MIN(rect.size.width/2, rect.size.height/2);				// Big circle (arc) radius
	const CGFloat ro = TRACK_WIDTH*0.5;											// Small circle (arc) radius
	const CGPoint cO = CGPointZero;												// Big arc center
	const CGFloat theta = asinf(ro/(rO-ro));									// Angle of inclination of small arc
	CGAffineTransform t;														// Affine transform to calculate center of small arcs
	t = CGAffineTransformMakeRotation(theta);
	const CGPoint co = CGPointApplyAffineTransform(CGPointMake(0, ro-rO), t);	// First small arc center
	const CGFloat startAngle = DEGREES_TO_RADIANS(-90)+theta;					// start angle of big arc
	const CGFloat endAngle = DEGREES_TO_RADIANS(360*theProgress-90)-theta;	//end angle of big arc
	t = CGAffineTransformMakeRotation(endAngle + DEGREES_TO_RADIANS(90));
	const CGPoint ci = CGPointApplyAffineTransform(CGPointMake(0, ro-rO), t);	// Second small arc center

	// Add External arc to the path
	// Is made of:
	// 1. small arc that makes the start of the real arc
	// 2. big arc : real arc
	// 3. small arc that makes the end of the real arc
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, cO.x, cO.y);
	CGPathAddArc(path, NULL, co.x, co.y, ro, DEGREES_TO_RADIANS(90)+theta, DEGREES_TO_RADIANS(270)+theta, false);
	CGPathAddArc(path, NULL, cO.x, cO.y, rO, startAngle, endAngle, false);
	CGPathAddArc(path, NULL, ci.x, ci.y, ro, endAngle, DEGREES_TO_RADIANS(180)+endAngle, false);
	CGPathCloseSubpath(path);

	// Add internal arc to the path
	CGPathMoveToPoint(path, NULL, cO.x, cO.y);
	CGPathAddArc(path, NULL, cO.x, cO.y, rO-TRACK_WIDTH, startAngle, endAngle, false);
	CGPathCloseSubpath(path);

	// Add path to the context and draw it
	CGContextAddPath(c, path);
	CFRelease(path);
	CGContextSetFillColorWithColor(c, progressTintColor);
	CGContextEOFillPath(c);

	//NSLog(@"thetha: %f startAngle:%f endAngle:%f progressDrawn:%f total(theta+endAngle-startAngle+theta):%f",
	//	  RADIANS_TO_DEGREES(theta), RADIANS_TO_DEGREES(startAngle), RADIANS_TO_DEGREES(endAngle), theProgress, RADIANS_TO_DEGREES(theta*2 + endAngle - startAngle)/360.0);

	CGContextRestoreGState(c);
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
	if (animated) {
		// Do the animations here since UIProgressView won't do it when drawRect: method is overridden
		// "UIProgressView's -setProgress:animated: will not animate when -drawRect: has been overridden."
		// I could use CoreAnimation but that will imply linking to QuartzCore and this is intended to be
		// a drop-in replace of UIProgressView
		self.startTime = [[NSDate date] timeIntervalSince1970];
		self.progressBeforeAnimation = self.progress;
		[super setProgress:progress animated:NO]; // This will internally drawRect: which is what we want
	} else {
		self.startTime = 0;
		[super setProgress:progress animated:animated];
	}
}

@end
