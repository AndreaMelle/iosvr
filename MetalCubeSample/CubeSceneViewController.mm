//
//  CubeSceneViewController.m
//  iosvr
//
//  Created by Andrea Melle on 24/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "CubeSceneViewController.h"
#import "CubeSceneRenderer.h"

@implementation CubeSceneViewController
{
    
}
@synthesize viewDelegate = _viewDelegate;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        _viewDelegate = [[CubeSceneRenderer alloc] init];
        self.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setVrModeEnabled:NO];
    [self setDistortionCorrectionEnabled:NO];
}

- (void)update:(CardboardMetalViewController *)controller
{
    [(CubeSceneRenderer*)self.viewDelegate update:controller];
}

- (void)viewController:(CardboardMetalViewController *)controller willPause:(BOOL)pause
{
    [(CubeSceneRenderer*)self.viewDelegate viewController:controller willPause:pause];
}

@end
