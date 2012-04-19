//
//  ViewController.m
//  ProgressView
//
//  Created by Guillermo Enriquez on 3/14/12.
//  Copyright (c) 2012 nacho4d. All rights reserved.
//

#import "ViewController.h"
#import "N4ProgressView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	N4ProgressView *pv = [[N4ProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	float progress = 0.1;
	[pv setFrame:CGRectMake(10, 10, 300, 300)];
	[pv setProgress:progress];
	[self.view addSubview:pv];
	[pv release];

	UIProgressView *p = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	[p setFrame:CGRectMake(10, 10, 300, 300)];
	[p setProgress:progress];
	[self.view addSubview:p];
	[p release];

	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		float progress = 1.0;
		[pv setProgress:progress animated:YES];
		[p setProgress:progress animated:YES];

		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			float progress = 0.1;
			[pv setProgress:progress animated:YES];
			[p setProgress:progress animated:YES];
		});
	});
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
