/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal Renderer for Metal Basic 3D. Acts as the update and render delegate for the view controller and performs rendering. In MetalBasic3D, the renderer draws 2 cubes, whos color values change every update.
 */

#import "CubeSceneRenderer.h"
#import "CardboardMetalViewController.h"
#import "CardboardMetalView.h"
#import "CMTransforms.h"
#import "CubeSceneSharedTypes.h"
#import "OBJModel.h"

using namespace CM;
using namespace simd;

typedef struct
{
    simd::float4x4 modelViewProjectionMatrix;
    simd::float4x4 modelViewMatrix;
    simd::float3x3 normalMatrix;
} Uniforms;

@implementation CubeSceneRenderer
{
    // constant synchronization for buffering <kInFlightCommandBuffers> frames
    //dispatch_semaphore_t _inflight_semaphore;
    //id <MTLBuffer> _dynamicConstantBuffer[kInFlightCommandBuffers];
    
    id <MTLDevice> _device;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    
    id<MTLBuffer> vertexBuffer;
    id<MTLBuffer> indexBuffer;
    id<MTLBuffer> uniformBuffer;
    
    NSString *vertexFunctionName;
    NSString *fragmentFunctionName;
    
    //NSTimeInterval lastFrameTime;
    
    simd::float4x4 cameraMatrix;
    simd::float4x4 headMatrix;
    simd::float4x4 viewMatrix;
    simd::float4x4 perspectiveMatrix;
    
    float near;
    float far;
    
    float temp_aspect;
    
    // this value will cycle from 0 to g_max_inflight_buffers whenever a display completes ensuring renderer clients
    // can synchronize between g_max_inflight_buffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
    //NSUInteger _constantDataBufferIndex;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        vertexFunctionName = @"vertex_main";
        fragmentFunctionName = @"fragment_main";
        
        near = 0.01;
        far = 100;
        
        //angularVelocity = CGPointMake(0, 1.0);
        
        //_constantDataBufferIndex = 0;
        //_inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
    }
    return self;
}

#pragma mark Configure

- (void)setup:(CardboardMetalView *)view
{
    _device = view.device;
    
    view.depthPixelFormat   = MTLPixelFormatDepth32Float;
    view.stencilPixelFormat = MTLPixelFormatInvalid;
    view.sampleCount        = 1;
    
    _defaultLibrary = [_device newDefaultLibrary];
    if(!_defaultLibrary)
    {
        NSLog(@">> ERROR: Couldnt create a default shader library");
        assert(0);
    }
    
    if (![self preparePipelineState:view])
    {
        NSLog(@">> ERROR: Couldnt create a valid pipeline state");
        assert(0);
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"teapot2" withExtension:@"obj"];
    OBJModel *teapot = [[OBJModel alloc] initWithContentsOfURL:modelURL];
    
    OBJGroup *baseGroup = [teapot groupAtIndex:1];
    if (baseGroup)
    {
        vertexBuffer = [self newBufferWithBytes:baseGroup->vertices
                                         length:sizeof(Vertex) * baseGroup->vertexCount];
        
        indexBuffer = [self newBufferWithBytes:baseGroup->indices
                                        length:sizeof(IndexType) * baseGroup->indexCount];
    }
    
    // allocate a number of buffers in memory that matches the sempahore count so that
    // we always have one self contained memory buffer for each buffered frame.
    // In this case triple buffering is the optimal way to go so we cycle through 3 memory buffers
    
}

- (BOOL)preparePipelineState:(CardboardMetalView *)view
{
    // Vertex Descriptor
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = 0;
    
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = sizeof(float) * 4;
    
    vertexDescriptor.layouts[0].stride = sizeof(float) * 8;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    // Render pipeline descriptor
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.label = @"TeapotPipeline";
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = view.depthPixelFormat;
    pipelineDescriptor.sampleCount = view.sampleCount;
    pipelineDescriptor.vertexFunction = [_defaultLibrary newFunctionWithName:vertexFunctionName];
    pipelineDescriptor.fragmentFunction = [_defaultLibrary newFunctionWithName:fragmentFunctionName];
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    // Depth and Stencil descriptor
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    NSError *error = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if(!_pipelineState)
    {
        NSLog(@">> ERROR: Failed Aquiring pipeline state: %@", error);
        return NO;
    }
    
    return YES;
}

#pragma mark Render

- (void)prepareNewFrameWithHeadViewMatrix:(simd::float4x4)headViewMatrix
{
    static const simd::float3 EYE = { 0, 0, 0 };
    static const simd::float3 CENTER = { 0, 0, 1.0f};
    static const simd::float3 UP = { 0, 1.0f, 0};
    
    cameraMatrix = CM::lookAt(EYE, CENTER, UP);
    headMatrix = headViewMatrix;
}

//- (void)render:(CardboardMetalView *)view
- (void)drawEyeWithEye:(CBMetalEye *)eye renderEncoder:(id<MTLRenderCommandEncoder>)encoder
{
    // Allow the renderer to preflight 3 frames on the CPU (using a semapore as a guard) and commit them to the GPU.
    // This semaphore will get signaled once the GPU completes a frame's work via addCompletedHandler callback below,
    // signifying the CPU can go ahead and prepare another frame.
    //dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    // Prior to sending any data to the GPU, constant buffers should be updated accordingly on the CPU.
    
    // update uniforms
    simd::float4x4 modelMatrix = translate(0, -0.5f, 0.0f);
    
    viewMatrix = [eye eyeViewMatrix] * cameraMatrix;
    perspectiveMatrix = [eye perspectiveMatrixWithZNear:near zFar:far];
    
    Uniforms uniforms;
    
    simd::float4x4 modelView = viewMatrix * modelMatrix;
    uniforms.modelViewMatrix = modelView;
    
    simd::float4x4 modelViewProj = perspectiveMatrix * modelView;
    uniforms.modelViewProjectionMatrix = modelViewProj;
    
    simd::float3x3 normalMatrix = { modelView.columns[0].xyz, modelView.columns[1].xyz, modelView.columns[2].xyz };
    uniforms.normalMatrix = simd::transpose(simd::inverse(normalMatrix));
    
    uniformBuffer = [self newBufferWithBytes:(void *)&uniforms length:sizeof(Uniforms)];
    
    // end update uniforms
    
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setDepthStencilState:_depthState];
    //[encoder setFrontFacingWinding:MTLWindingCounterClockwise];
    //[encoder setCullMode:MTLCullModeBack];
    
    [self drawTrianglesWithInterleavedBuffer:vertexBuffer
                                 indexBuffer:indexBuffer
                               uniformBuffer:uniformBuffer
                                  indexCount:[indexBuffer length] / sizeof(IndexType)
                               renderEncoder:encoder];

    
    // call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
    //__block dispatch_semaphore_t block_sema = _inflight_semaphore;
    //[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        
        // GPU has completed rendering the frame and is done using the contents of any buffers previously encoded on the CPU for that frame.
        // Signal the semaphore and allow the CPU to proceed and construct the next frame.
    //    dispatch_semaphore_signal(block_sema);
    //}];
    
    // finalize rendering here. this will push the command buffer to the GPU
    
    // This index represents the current portion of the ring buffer being used for a given frame's constant buffer updates.
    // Once the CPU has completed updating a shared CPU/GPU memory buffer region for a frame, this index should be updated so the
    // next portion of the ring buffer can be written by the CPU. Note, this should only be done *after* all writes to any
    // buffers requiring synchronization for a given frame is done in order to avoid writing a region of the ring buffer that the GPU may be reading.
    //_constantDataBufferIndex = (_constantDataBufferIndex + 1) % kInFlightCommandBuffers;
}

- (void)finishFrameWithViewportRect:(CGRect)viewPort renderEncoder:(id<MTLRenderCommandEncoder>)encoder
{
    
}

- (void)reshape:(CardboardMetalView *)view
{
    // when reshape is called, update the view and projection matricies since this means the view orientation or size changed
    temp_aspect = fabsf(view.bounds.size.width / view.bounds.size.height);
//    _projectionMatrix = perspective_fov(kFOVY, aspect, 0.1f, 100.0f);
//    _viewMatrix = lookAt(kEye, kCenter, kUp);
}

#pragma mark Update

- (void)update:(CardboardMetalViewController *)controller
{
//    NSTimeInterval frameTime = CFAbsoluteTimeGetCurrent();
//    NSTimeInterval frameDuration = frameTime - lastFrameTime;
//    lastFrameTime = frameTime;
//    
//    if (frameDuration > 0)
//    {
//
//    }
}

- (void)viewController:(CardboardMetalViewController *)controller willPause:(BOOL)pause
{
    // timer is suspended/resumed
    // Can do any non-rendering related background work here when suspended
}

- (id<MTLBuffer>)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length
{
    return [_device newBufferWithBytes:bytes
                                length:length
                               options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)drawTrianglesWithInterleavedBuffer:(id<MTLBuffer>)pBuffer
                               indexBuffer:(id<MTLBuffer>)iBuffer
                             uniformBuffer:(id<MTLBuffer>)uBuffer
                                indexCount:(size_t)iCount
                             renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder
{
    if (!pBuffer || !iBuffer || !uBuffer)
    {
        return;
    }
    
    // this is kinda like opengl VAO. we set uniforms, vertices and indices
    
    [renderEncoder setVertexBuffer:pBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:uBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBuffer:uBuffer offset:0 atIndex:0];
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                    indexCount:iCount
                                     indexType:MTLIndexTypeUInt16
                                   indexBuffer:iBuffer
                             indexBufferOffset:0];
}


@end
