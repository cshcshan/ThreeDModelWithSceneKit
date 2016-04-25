//
//  GameViewController.m
//  ThreeDModelWithSceneKit
//
//  Created by Han Chen on 25/4/2016.
//  Copyright (c) 2016年 Han Chen. All rights reserved.
//

#import "GameViewController.h"
#import <AFNetworking.h>
#import <SSZipArchive.h>

// http://www.the-nerd.be/2014/11/07/dynamically-load-collada-files-in-scenekit-at-runtime/

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    // create a new scene
//    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
//
//    // create and add a camera to the scene
//    SCNNode *cameraNode = [SCNNode node];
//    cameraNode.camera = [SCNCamera camera];
//    [scene.rootNode addChildNode:cameraNode];
//    
//    // place the camera
//    cameraNode.position = SCNVector3Make(0, 0, 15);
//    
//    // create and add a light to the scene
//    SCNNode *lightNode = [SCNNode node];
//    lightNode.light = [SCNLight light];
//    lightNode.light.type = SCNLightTypeOmni;
//    lightNode.position = SCNVector3Make(0, 10, 10);
//    [scene.rootNode addChildNode:lightNode];
//    
//    // create and add an ambient light to the scene
//    SCNNode *ambientLightNode = [SCNNode node];
//    ambientLightNode.light = [SCNLight light];
//    ambientLightNode.light.type = SCNLightTypeAmbient;
//    ambientLightNode.light.color = [UIColor darkGrayColor];
//    [scene.rootNode addChildNode:ambientLightNode];
//    
//    // retrieve the ship node
//    SCNNode *ship = [scene.rootNode childNodeWithName:@"ship" recursively:YES];
//    
//    // animate the 3d object
//    [ship runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:1]]];
//    
//    // retrieve the SCNView
//    SCNView *scnView = (SCNView *)self.view;
//    
//    // set the scene to the view
//    scnView.scene = scene;
//    
//    // allows the user to manipulate the camera
//    scnView.allowsCameraControl = YES;
//        
//    // show statistics such as fps and timing information
//    scnView.showsStatistics = YES;
//
//    // configure the view
//    scnView.backgroundColor = [UIColor blackColor];
//    
//    // add a tap gesture recognizer
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    NSMutableArray *gestureRecognizers = [NSMutableArray array];
//    [gestureRecognizers addObject:tapGesture];
//    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
//    scnView.gestureRecognizers = gestureRecognizers;
  
  [self downloadZip];
}

- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0){
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        // get its material
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // highlight it
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        
        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            
            material.emission.contents = [UIColor blackColor];
            
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [UIColor redColor];
        
        [SCNTransaction commit];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Download And Unzip

- (void)downloadZip {
  NSString *zipFileName = @"product-optimized.scnassets.zip";
  NSString *urlString = [@"http://localhost/something" stringByAppendingPathComponent:zipFileName];
  
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
  
  NSURL *URL = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  
  NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
  } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    NSLog(@"File downloaded to: %@", filePath);
    
    // Unzip the archive
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *inputPath = [documentsDirectory stringByAppendingPathComponent:zipFileName];
    NSString *outputPath = [documentsDirectory stringByAppendingPathComponent:@"output"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
      [[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSError *zipError = nil;
    
    [SSZipArchive unzipFileAtPath:inputPath toDestination:outputPath overwrite:YES password:nil error:&zipError];
    
    if( zipError ){
      NSLog(@"[GameVC] Something went wrong while unzipping: %@", zipError.debugDescription);
    }else {
      NSLog(@"[GameVC] Archive unzipped successfully");
      [self startScene];
    }
    
  }];
  [downloadTask resume];
  
}

#pragma mark - Start Scene

- (void) startScene {
  NSString *daeFileName = @"AudiR8.dae";
  NSString *scnassetsName = @"product-optimized.scnassets";
  NSString *daeFilePath = [[@"output" stringByAppendingPathComponent:scnassetsName] stringByAppendingPathComponent:daeFileName];
  
  // Load the downloaded scene
  NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
  documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:daeFilePath];
  
  SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:documentsDirectoryURL options:nil];
  
  // List identifiers
  [self listIdentifiersOfSceneSource:sceneSource];
  
  // Create a new scene
  SCNScene *scene = [SCNScene scene];
  
  // create and add a camera to the scene
  SCNNode *cameraNode = [SCNNode node];
  cameraNode.camera = [SCNCamera camera];
  [scene.rootNode addChildNode:cameraNode];
  
  // place the camera
  cameraNode.position = SCNVector3Make(0, 0, 15);
  
  // create and add a light to the scene
  SCNNode *lightNode = [SCNNode node];
  lightNode.light = [SCNLight light];
  lightNode.light.type = SCNLightTypeOmni;
  lightNode.position = SCNVector3Make(0, 10, 10);
  [scene.rootNode addChildNode:lightNode];
  
  // create and add an ambient light to the scene
  SCNNode *ambientLightNode = [SCNNode node];
  ambientLightNode.light = [SCNLight light];
  ambientLightNode.light.type = SCNLightTypeAmbient;
  ambientLightNode.light.color = [UIColor darkGrayColor];
  [scene.rootNode addChildNode:ambientLightNode];
  
  // Add node to the scene
  for (NSString *node in [sceneSource identifiersOfEntriesWithClass:[SCNNode class]]) {
    [scene.rootNode addChildNode:[sceneSource entryWithIdentifier:node withClass:[SCNNode class]]];
  }
  
  // retrieve the SCNView
  SCNView *scnView = (SCNView *)self.view;
  
  // set the scene to the view
  scnView.scene = scene;
  
  // allows the user to manipulate the camera
  scnView.allowsCameraControl = YES;
  
  // show statistics such as fps and timing information
  scnView.showsStatistics = YES;
  
  // configure the view
  scnView.backgroundColor = [UIColor blackColor];
  
  // add a tap gesture recognizer
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  NSMutableArray *gestureRecognizers = [NSMutableArray array];
  [gestureRecognizers addObject:tapGesture];
  [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
  scnView.gestureRecognizers = gestureRecognizers;
}

- (void) listIdentifiersOfSceneSource:(SCNSceneSource *) sceneSource {
  
  NSArray *animationIdentifiers = [sceneSource identifiersOfEntriesWithClass:[CAAnimation class]];
  for (NSString *identifier in animationIdentifiers) {
    NSLog(@"Animation: %@", identifier);
  }
  //  NSArray *imageIdentifiers = [sceneSource identifiersOfEntriesWithClass:[NSImage class]];
  NSArray *cameraIdentidiers = [sceneSource identifiersOfEntriesWithClass:[SCNCamera class]];
  for (NSString *identifier in cameraIdentidiers) {
    NSLog(@"Camera: %@", identifier);
  }
  NSArray *geometryIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNGeometry class]];
  for (NSString *identifier in geometryIdentifiers) {
    NSLog(@"Geometry: %@", identifier);
  }
  NSArray *lightIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNLight class]];
  for (NSString *identifier in lightIdentifiers) {
    NSLog(@"Light: %@", identifier);
  }
  NSArray *materialIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNMaterial class]];
  for (NSString *identifier in materialIdentifiers) {
    NSLog(@"Material: %@", identifier);
  }
  NSArray *morpherIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNMorpher class]];
  for (NSString *identifier in morpherIdentifiers) {
    NSLog(@"Morpher: %@", identifier);
  }
  NSArray *nodeIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNNode class]];
  for (NSString *identifier in nodeIdentifiers) {
    NSLog(@"Node: %@", identifier);
  }
  NSArray *sceneIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNScene class]];
  for (NSString *identifier in sceneIdentifiers) {
    NSLog(@"Scene: %@", identifier);
  }
  NSArray *skinnerIdentifiers = [sceneSource identifiersOfEntriesWithClass:[SCNSkinner class]];
  for (NSString *identifier in skinnerIdentifiers) {
    NSLog(@"Skinner: %@", identifier);
  }
}

@end
