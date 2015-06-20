//
//  TreasureViewController.m
//  CardboardSDK-iOS
//
//

#import "ForestViewController.h"

#import <hfgl/hfglDebugUtils.h>
#import <hfgl/hfglShader.h>
#import <hfgl/hfglMathUtils.h>

#import <AudioToolbox/AudioServices.h>
#import <OpenGLES/ES2/glext.h>
#import <SceneKit/SceneKit.h>

@interface ForestRenderer : NSObject
{
    GLKMatrix4 _perspective;
    GLKMatrix4 _camera;
    GLKMatrix4 _view;
    GLKMatrix4 _headView;
    
    float _zNear;
    float _zFar;
    
    float _timeDelta;
    
    SCNNode *cameraNode;
    SCNRenderer *renderer;
    SCNScene *scene;
}

@end


@implementation ForestRenderer

- (instancetype)init
{
    self = [super init];
    if (!self) { return nil; }
    
    _zNear = 0.01f;
    _zFar = 15.0f;
    
    _timeDelta = 1.0f;

    return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    [EAGLContext setCurrentContext:glView.context];
    
    // Etc
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.2f, 0.2f, 0.2f, 0.5f); // Dark background so text shows up well.
    
    // create a new scene
    scene = [SCNScene sceneNamed:@"art.scnassets/forest.dae"];
    
    [scene.rootNode setTransform:SCNMatrix4Identity];
    
    // create and add a camera to the scene
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    
    SCNNode* playerNode = [SCNNode node];
    [playerNode addChildNode:cameraNode];
    [playerNode setPosition:SCNVector3Make(0, 1.0f, 0)];
    
    [scene.rootNode addChildNode:playerNode];
    
    cameraNode.camera.zNear = _zNear;
    cameraNode.camera.zFar = _zFar;
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0.0, 0);
    [cameraNode setTransform:SCNMatrix4Identity];
    //cameraNode.position = SCNVector3Make(0, 1.0, 0);
    //_camera = SCNMatrix4ToGLKMatrix4(cameraNode.transform);
    
    //[cameraNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:1 z:0 duration:2]]];
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 0);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // retrieve the ship node
    SCNNode *dome = [scene.rootNode childNodeWithName:@"Dome" recursively:YES];
    SCNMaterial *domeMat = dome.geometry.materials.firstObject;
    domeMat.emission.contents = [UIColor colorWithWhite:0.15f alpha:1.0f];
    
    SCNNode *bear = [scene.rootNode childNodeWithName:@"Bear_01" recursively:YES];
    SCNMaterial *bearMat = bear.geometry.materials.firstObject;
    bearMat.emission.contents = [UIColor colorWithWhite:0.25f alpha:1.0f];
    
    renderer = [SCNRenderer rendererWithContext:(void*)glView.context options:nil];
    renderer.scene = scene;

#if defined(DEBUG)
    hfgl::CheckGlErrors();
#endif
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
}

- (void)renderViewDidChangeSize:(CGSize)size
{
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    
    // Build the camera matrix and apply it to the ModelView.
    
    _camera = GLKMatrix4MakeLookAt(0, 0.0, 0,
                                   0, 0.0, -1.0f,
                                   0, 1.0f, 0);
    
    _headView = headViewMatrix;
}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    _view = GLKMatrix4Multiply([eye eyeViewMatrix], _camera);
    _perspective = [eye perspectiveMatrixWithZNear:_zNear zFar:_zFar];
    
    cameraNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Transpose(_view));
    
    [cameraNode.camera setProjectionTransform:SCNMatrix4FromGLKMatrix4(_perspective)];
    
    [renderer render];
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
}

@end


@interface ForestViewController() <CardboardStereoRendererDelegate>

@property (nonatomic) ForestRenderer *forestRenderer;

@property (nonatomic) NSInteger score;

@end


@implementation ForestViewController

- (instancetype)init
{
    self = [super init];
    if (!self) {return nil; }
    
    self.stereoRendererDelegate = self;
    
    return self;
}

- (void)setupRendererWithView:(GLKView *)glView
{
    //[self setVrModeEnabled:NO];
    
    self.forestRenderer = [ForestRenderer new];
    [self.forestRenderer setupRendererWithView:glView];
    
    CGRect eyeFrame = self.view.bounds;
    eyeFrame.size.height = self.view.bounds.size.height;
    eyeFrame.size.width = self.view.bounds.size.width / 2;
    eyeFrame.origin.y = eyeFrame.size.height;
}

- (void)shutdownRendererWithView:(GLKView *)glView
{
    [self.forestRenderer shutdownRendererWithView:glView];
}

- (void)renderViewDidChangeSize:(CGSize)size
{
    [self.forestRenderer renderViewDidChangeSize:size];
}

- (void)prepareNewFrameWithHeadViewMatrix:(GLKMatrix4)headViewMatrix
{
    [self.forestRenderer prepareNewFrameWithHeadViewMatrix:headViewMatrix];

}

- (void)drawEyeWithEye:(CBDEye *)eye
{
    [self.forestRenderer drawEyeWithEye:eye];

}

- (void)finishFrameWithViewportRect:(CGRect)viewPort
{
    [self.forestRenderer finishFrameWithViewportRect:viewPort];
}

- (void)magneticTriggerPressed
{
    
}


@end
