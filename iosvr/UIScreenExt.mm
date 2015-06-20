//
//  UIScreenExt.cpp
//  iosvr
//
//  Created by Andrea Melle on 02/04/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#include "UIScreenExt.h"
#include <UIKit/UIKit.h>
#include <algorithm>
#include <sys/utsname.h>

// Enable to make the lens-distorted viewports slightly
// smaller on iPhone 6/6+ and bigger on iPhone 5/5s

@interface UIScreenHelper : NSObject
{
    iosvr::UIScreenExt* orientationDelegate;
}

+ (CGSize)OrientationAwareSize;
+ (CGSize)SizeFixedToPortrait;

- (void)registerOrientationDelegate:(iosvr::UIScreenExt *)del;
- (void)unregisterOrientationDelegate:(iosvr::UIScreenExt *)del;

+ (BOOL)CBScreenIsRetina;
+ (BOOL)CBScreenIsIpad;
+ (BOOL)CBScreenIsIphone;

@end

@implementation UIScreenHelper

- (void)registerOrientationDelegate:(iosvr::UIScreenExt *)del
{
    orientationDelegate = del;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)unregisterOrientationDelegate:(iosvr::UIScreenExt *)del
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    orientationDelegate = 0;
}

- (void)orientationDidChange:(NSNotification *)notification
{
    if(orientationDelegate != 0)
    {
        orientationDelegate->notifyDeviceOrientationChange();
    }
}

+ (CGSize)OrientationAwareSize
{
    // Starting on iOS 8 bounds are orientation dependepent
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1)
        && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

+ (BOOL)CBScreenIsRetina { return ([[UIScreen mainScreen] scale] == 2.0); }
+ (BOOL)CBScreenIsIpad   { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad); }
+ (BOOL)CBScreenIsIphone { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone); }
+ (BOOL)CBScreenIsIphone5Width { return [UIScreenHelper CBScreenIsIphone4Width]; }

+ (BOOL)CBScreenIsIphone4Width
{
    return ([UIScreenHelper CBScreenIsIphone] && [UIScreenHelper SizeFixedToPortrait].width == 320.0);
}
                                                  
+ (BOOL)CBScreenIsIphone4Height
{
    return ([UIScreenHelper CBScreenIsIphone] && [UIScreenHelper SizeFixedToPortrait].height == 480.0);
}

+ (BOOL)CBScreenIsIphone5Height
{
    return ([UIScreenHelper CBScreenIsIphone] && [UIScreenHelper SizeFixedToPortrait].height == 568.0);
}

+ (BOOL)CBScreenIsIphone6Width
{
    return ([UIScreenHelper CBScreenIsIphone] && [UIScreenHelper SizeFixedToPortrait].width == 375.0);
}

+ (BOOL)CBScreenIsIphone6Height
{
    return ([UIScreenHelper CBScreenIsIphone] && [UIScreenHelper SizeFixedToPortrait].height == 667.0);
}

+ (BOOL)CBScreenIsIphone6PlusWidth
{
    return ([UIScreenHelper CBScreenIsIphone] && [[UIScreen mainScreen] scale] == 3.0f && [UIScreenHelper SizeFixedToPortrait].width == 414.0);
}

+ (BOOL)CBScreenIsIphone6PlusHeight
{
    return ([UIScreenHelper CBScreenIsIphone] && [[UIScreen mainScreen] scale] == 3.0f && [UIScreenHelper SizeFixedToPortrait].height == 736.0);
}

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

+ (BOOL)CBScreenIsIphone5
{
    return ([UIScreenHelper CBScreenIsIphone] && SCREEN_MAX_LENGTH == 568.0f);
}

+ (BOOL)CBScreenIsIphone6
{
    return ([UIScreenHelper CBScreenIsIphone] && SCREEN_MAX_LENGTH == 667.0f);
}

+ (BOOL)CBScreenIsIphone6plus
{
    return ([UIScreenHelper CBScreenIsIphone] && SCREEN_MAX_LENGTH == 736.0f);
}

+ (CGSize)SizeFixedToPortrait
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    return CGSizeMake(MIN(size.width, size.height), MAX(size.width, size.height));
}

@end

namespace iosvr
{
    
    GLfloat UIScreenExt::DefaultBorderSizeMeters = 0.003f;
    
    UIScreenExt::UIScreenExt()
    {
        screenHelper = [[UIScreenHelper alloc] init];
        [(UIScreenHelper*)screenHelper registerOrientationDelegate:this];
        
        mCorrectViewportSize = false;
        mPhysicalSizeScale = 1.0f;
        
        if ([UIScreenHelper CBScreenIsIphone5])
        {
            mPhysicalSizeScale = 1.2f;
        }
        
    }
    
    UIScreenExt::~UIScreenExt()
    {
        this->clearAllObservers();
        [(UIScreenHelper*)screenHelper unregisterOrientationDelegate:this];
        [(id)screenHelper release];
    }
    
    void UIScreenExt::notifyDeviceOrientationChange()
    {
        this->notifyObservers();
    }
    
    void UIScreenExt::addObserver(OrientationObserver* observer)
    {
        std::vector<OrientationObserver*>::iterator it = std::find(observers.begin(), observers.end(), observer);
        if(it == observers.end())
        {
            observers.push_back(observer);
        }
    }
    
    void UIScreenExt::removeObserver(OrientationObserver* observer)
    {
        std::vector<OrientationObserver*>::iterator it = std::find(observers.begin(), observers.end(), observer);
        if(it != observers.end())
        {
            observers.erase(it);
        }
    }
    
    void UIScreenExt::clearAllObservers()
    {
        observers.clear();
    }
    
    void UIScreenExt::notifyObservers()
    {
        std::vector<OrientationObserver*>::iterator it;
        for(it = observers.begin(); it != observers.end(); ++it)
        {
            (*it)->OnOrientationChanged();
        }
    }
    
    GLfloat UIScreenExt::getPhysicalSizeScale()
    {
        return mPhysicalSizeScale;
    }
    
    bool UIScreenExt::getCorrectViewportSize()
    {
        return mCorrectViewportSize;
    }
    
    GLfloat UIScreenExt::getDisplayScale()
    {
        return [[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)] ? [UIScreen mainScreen].nativeScale :[UIScreen mainScreen].scale;
    }
    
    GLfloat UIScreenExt::getBorderMeters()
    {
        const GLfloat defaultBorderSizeMeters = DefaultBorderSizeMeters;
        GLfloat borderSizeMeters = defaultBorderSizeMeters;
        
        if(this->mCorrectViewportSize)
        {
            if ([UIScreenHelper CBScreenIsIphone5Width])
            {
                borderSizeMeters = 0.006f;
            }
            else if ([UIScreenHelper CBScreenIsIphone6Width]|| [UIScreenHelper CBScreenIsIphone6PlusWidth])
            {
                borderSizeMeters = 0.001f;
            }
        }
        
        return borderSizeMeters;
    }
    
    GLint UIScreenExt::getOrientationAwareWidth()
    {
        return [UIScreenHelper OrientationAwareSize].width;
    }
    
    GLint UIScreenExt::getOrientationAwareHeight()
    {
        return [UIScreenHelper OrientationAwareSize].height;
    }
    
    GLfloat UIScreenExt::getPixelsPerInch(GLfloat scale)
    {
        // Default iPhone retina pixels per inch
        GLfloat pixelsPerInch = 163.0f * 2;
        struct utsname sysinfo;
        if (uname(&sysinfo) == 0)
        {
            NSString *identifier = [NSString stringWithUTF8String:sysinfo.machine];
            NSArray *deviceClassArray =
            @[
              // iPads
              @{@"identifiers":
                    @[@"iPad1,1",
                      @"iPad2,1", @"iPad2,2", @"iPad2,3", @"iPad2,4",
                      @"iPad3,1", @"iPad3,2", @"iPad3,3", @"iPad3,4",
                      @"iPad3,5", @"iPad3,6", @"iPad4,1", @"iPad4,2"],
                @"pointsPerInch": @132.0f},
              // iPhones, iPad Minis and simulators
              @{@"identifiers":
                    @[@"iPod5,1",
                      @"iPhone1,1", @"iPhone1,2",
                      @"iPhone2,1",
                      @"iPhone3,1", @"iPhone3,2", @"iPhone3,3",
                      @"iPhone4,1",
                      @"iPhone5,1", @"iPhone5,2", @"iPhone5,3", @"iPhone5,4",
                      @"iPhone6,1", @"iPhone6,2",
                      @"iPhone7,1", @"iPhone7,2",
                      @"iPad2,5", @"iPad2,6", @"iPad2,7",
                      @"iPad4,4", @"iPad4,5",
                      @"i386", @"x86_64"],
                @"pointsPerInch":  @163.0f } ];
            for (NSDictionary *deviceClass in deviceClassArray)
            {
                for (NSString *deviceId in deviceClass[@"identifiers"])
                {
                    if ([identifier isEqualToString:deviceId])
                    {
                        pixelsPerInch = (GLfloat)[deviceClass[@"pointsPerInch"] floatValue] * scale;
                        break;
                    }
                }
            }
        }
        return pixelsPerInch;
    }
    
    
}