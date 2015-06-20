//
//  CardboardStereoView.h
//
//  Created by Ricardo Sánchez-Sáez on 01/02/2015.
//

#import <UIKit/UIKit.h>

#import "CardboardViewController.h"


@interface CardboardStereoView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                      context:(EAGLContext *)glContext;
- (instancetype)initWithFrame:(CGRect)frame
                      context:(EAGLContext *)glContext
                         lock:(NSRecursiveLock *)lock;

- (void)updateGLTextureForEye:(CBDEyeType)eyeType;
- (void)renderTextureForEye:(CBDEyeType)eyeType;

@end
