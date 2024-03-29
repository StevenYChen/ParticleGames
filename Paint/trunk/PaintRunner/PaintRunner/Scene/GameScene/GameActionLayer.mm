//
//  GameActionLayer.m
//  PaintRunner
//
//  Created by Kelvin on 9/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GameActionLayer.h"

@implementation GameActionLayer

@synthesize contactListener;
@synthesize player;
@synthesize gameScore;
@synthesize highScore;

-(void) setupWorld {    
    b2Vec2 gravity = b2Vec2(0.0f, -20.0f);
    bool doSleep = true;
    world = new b2World(gravity, doSleep);            
}

-(void) setupDebugDraw {  
    debugDraw = new GLESDebugDraw(PTM_RATIO * [[CCDirector sharedDirector] contentScaleFactor]);
    world->SetDebugDraw(debugDraw);
    debugDraw->SetFlags(b2DebugDraw::e_shapeBit);  
}

-(void) createPlatforms {
    int tempWidth = arc4random()%5 + 5;
    int tempHeight = arc4random()%10 + 1;
    int tempSpacing = arc4random()%4 + 2;
    double spacingWidth = tempSpacing*20.0;
    double initialOffset = 50.0;
    double heightOffset = 5.0;
    if (initialPlatform == TRUE) {
        [platformsWidths insertObject:[NSNumber numberWithDouble:(50.0*tempWidth+winSize.width)*PTP_Ratio] atIndex:platformCount];
        [platformsHeights insertObject:[NSNumber numberWithDouble:10*PTP_Ratio] atIndex:platformCount];
        [platformsCentersX insertObject:[NSNumber numberWithDouble: initialOffset*PTP_Ratio+[[platformsWidths objectAtIndex:platformCount] doubleValue]/2.0] atIndex:platformCount];
        [platformsCentersY insertObject:[NSNumber numberWithDouble: tempHeight*heightOffset*PTP_Ratio + [[platformsHeights objectAtIndex:platformCount]doubleValue]/2.0] atIndex:platformCount];
        
        initialPlatform = FALSE;
        platformCount ++;
    }else if(player.position.x*PTP_Ratio > [[platformsCentersX objectAtIndex:0]doubleValue]-200*PTP_Ratio && spawnPlatform == TRUE){
        [platformsWidths insertObject:[NSNumber numberWithDouble:(50.0*tempWidth+winSize.width)*PTP_Ratio] atIndex:platformCount];
        [platformsHeights insertObject:[NSNumber numberWithDouble:10*PTP_Ratio] atIndex:platformCount];
        
        //cetner.x[n] = (center[n-1].x + width[n-1]/2 + width[n]/2) where n is the current platform
        [platformsCentersX insertObject:[NSNumber numberWithDouble:                                                             [[platformsCentersX objectAtIndex:platformCount-1]doubleValue] + spacingWidth*PTP_Ratio +                           [[platformsWidths objectAtIndex:platformCount-1] doubleValue]/2.0 +                                                 [[platformsWidths objectAtIndex:platformCount] doubleValue]/2.0] atIndex:platformCount];
        [platformsCentersY insertObject:[NSNumber numberWithDouble: tempHeight*heightOffset*PTP_Ratio + [[platformsHeights objectAtIndex:platformCount]doubleValue]/2.0] atIndex:platformCount];
        
        spawnPlatform = FALSE;
        platformCount ++;   
    }
}

-(void) updatePlatformVerticesWithTime:(ccTime)dt andSpeed:(float)speed{
    
    nPlatformsVertices = 0;
    nPlatformsBox2dVertices = 0;
    if (pixelWinSize.width > 480.0) { 
        speed = speed*PTP_Ratio;
    }
    for (int i=0; i<platformCount; i++) {
        [platformsCentersX replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:[[platformsCentersX objectAtIndex:i]doubleValue] - speed*dt]];
        
        float x1 = [[platformsCentersX objectAtIndex:i]doubleValue] - [[platformsWidths objectAtIndex:i]doubleValue]/2.0;
        float x2 = [[platformsCentersX objectAtIndex:i]doubleValue] + [[platformsWidths objectAtIndex:i]doubleValue]/2.0;  
        float y1 = [[platformsCentersY objectAtIndex:i]doubleValue] - [[platformsHeights objectAtIndex:i]doubleValue]/2.0;    
        float y2 = [[platformsCentersY objectAtIndex:i]doubleValue] + [[platformsHeights objectAtIndex:i]doubleValue]/2.0;    
        
        //sets up vertices for drawing
        platformsVertices[nPlatformsVertices++] = CGPointMake(x1, y1);
        platformsVertices[nPlatformsVertices++] = CGPointMake(x1, y2);
        platformsVertices[nPlatformsVertices++] = CGPointMake(x2, y2);
        platformsVertices[nPlatformsVertices++] = CGPointMake(x2, y2);
        platformsVertices[nPlatformsVertices++] = CGPointMake(x1, y1);
        platformsVertices[nPlatformsVertices++] = CGPointMake(x2, y1);
        
        platformsBox2dVertices[nPlatformsBox2dVertices++] = CGPointMake(x1/PTP_Ratio, y1/PTP_Ratio);
        platformsBox2dVertices[nPlatformsBox2dVertices++] = CGPointMake(x1/PTP_Ratio, y2/PTP_Ratio);
        platformsBox2dVertices[nPlatformsBox2dVertices++] = CGPointMake(x2/PTP_Ratio, y1/PTP_Ratio);
        platformsBox2dVertices[nPlatformsBox2dVertices++] = CGPointMake(x2/PTP_Ratio, y2/PTP_Ratio);
    }
    
    for (int i=0; i<platformCount; i++) {
        if ([[platformsCentersX objectAtIndex:i]doubleValue] < -[[platformsWidths objectAtIndex:i]doubleValue]) {
            [platformsCentersX removeObjectAtIndex:i];
            [platformsCentersY removeObjectAtIndex:i];
            [platformsWidths removeObjectAtIndex:i];
            [platformsHeights removeObjectAtIndex:i];
            platformCount--;
            
            spawnPlatform = TRUE;
        }
    }
}

-(void) spawnObstacleAtTime:(ccTime)dt{
  /* CGPoint tempVert[100];
    [obstacles setVertices:tempVert];*/
    
    obstacleTimePassed += dt;
    airObstacleTimePassed += dt;
        
    double widthOffset; 
    if (levelMovingLeft) {
        widthOffset = winSize.width*2.0;
    }else{
        widthOffset = -winSize.width;
    }
    if (spawnObstacle == FALSE) {
        obstacleSpawnTimer = arc4random()%3 + 1;
        spawnObstacle = TRUE;
    }
    if (spawnAirObstacle == FALSE) {
        airObstacleSpawnTimer = arc4random()%5+3;
        spawnAirObstacle = TRUE;
    }
    if (spawnObstacle == TRUE && obstacleTimePassed > obstacleSpawnTimer) {
        int tempWidth = arc4random()%5;
        int tempHeight = arc4random()%5;
        
        [obstacleWidths insertObject:[NSNumber numberWithDouble:(40.0*tempWidth+100.0)*PTP_Ratio] atIndex:obstacleCount];
        [obstacleHeights insertObject:[NSNumber numberWithDouble:10.0*PTP_Ratio] atIndex:obstacleCount];
        [obstacleCentersX insertObject:[NSNumber numberWithDouble:widthOffset*PTP_Ratio + [[obstacleWidths objectAtIndex:obstacleCount] doubleValue]/2.0] atIndex:obstacleCount];
        [obstacleCentersY insertObject:[NSNumber numberWithDouble:30*PTP_Ratio + [[obstacleHeights objectAtIndex:obstacleCount]doubleValue]/2.0] atIndex:obstacleCount];
        
        obstacleCount ++ ;
        
        //sets up layers count of obstacle
        int tempLayerHeight = arc4random()%3;
        int layerCount = arc4random()%2;
        double layerHeight = tempLayerHeight*20.0 + 40.0;
        if (layerCount == 1) {
            [obstacleWidths insertObject:[NSNumber numberWithDouble:(40.0*tempWidth+100.0)*PTP_Ratio] atIndex:obstacleCount];
            [obstacleHeights insertObject:[NSNumber numberWithDouble:10.0*PTP_Ratio] atIndex:obstacleCount];
            [obstacleCentersX insertObject:[NSNumber numberWithDouble:[[obstacleCentersX objectAtIndex:obstacleCount-1]doubleValue]] atIndex:obstacleCount];
            [obstacleCentersY insertObject:[NSNumber numberWithDouble:[[obstacleCentersY objectAtIndex:obstacleCount-1]doubleValue] + layerHeight*PTP_Ratio] atIndex:obstacleCount];
            
            obstacleCount ++ ;   
            
            [obstacleWidths insertObject:[NSNumber numberWithDouble:(40.0*tempWidth+100.0)*PTP_Ratio] atIndex:obstacleCount];
            [obstacleHeights insertObject:[NSNumber numberWithDouble:10.0*PTP_Ratio] atIndex:obstacleCount];
            [obstacleCentersX insertObject:[NSNumber numberWithDouble:[[obstacleCentersX objectAtIndex:obstacleCount-1]doubleValue]] atIndex:obstacleCount];
            [obstacleCentersY insertObject:[NSNumber numberWithDouble:[[obstacleCentersY objectAtIndex:obstacleCount-1]doubleValue] + layerHeight*PTP_Ratio] atIndex:obstacleCount];
            
            obstacleCount ++ ;  
        }else if(layerCount == 0){
            [obstacleWidths insertObject:[NSNumber numberWithDouble:(40.0*tempWidth+100.0)*PTP_Ratio] atIndex:obstacleCount];
            [obstacleHeights insertObject:[NSNumber numberWithDouble:10.0*PTP_Ratio] atIndex:obstacleCount];
            [obstacleCentersX insertObject:[NSNumber numberWithDouble:[[obstacleCentersX objectAtIndex:obstacleCount-1]doubleValue]] atIndex:obstacleCount];
            [obstacleCentersY insertObject:[NSNumber numberWithDouble:[[obstacleCentersY objectAtIndex:obstacleCount-1]doubleValue] + layerHeight*PTP_Ratio] atIndex:obstacleCount];
            
            obstacleCount ++ ;  
        }
        
        //if true sets up another obstacle next to the current one
  /*      if (arc4random()%3 == 0) {
            tempWidth = arc4random()%5;
            tempHeight = arc4random()%5;
            
            [obstacleWidths insertObject:[NSNumber numberWithDouble:(10.0*tempWidth+40.0)*PTP_Ratio] atIndex:obstacleCount];
            [obstacleHeights insertObject:[NSNumber numberWithDouble:(12.0*tempHeight+40.0)*PTP_Ratio] atIndex:obstacleCount];
            [obstacleCentersX insertObject:[NSNumber numberWithDouble:[[obstacleCentersX objectAtIndex:obstacleCount-1]doubleValue] + [[obstacleWidths objectAtIndex:obstacleCount-1]doubleValue]/2.0 + [[obstacleWidths objectAtIndex:obstacleCount]doubleValue]/2.0] atIndex:obstacleCount];
            [obstacleCentersY insertObject:[NSNumber numberWithDouble:10*PTP_Ratio + [[obstacleHeights objectAtIndex:obstacleCount]doubleValue]/2.0] atIndex:obstacleCount];
            
            obstacleCount ++ ;            
        }*/
        spawnObstacle = FALSE;
        obstacleTimePassed = 0.0;
    }
    if (spawnAirObstacle == TRUE && airObstacleTimePassed > airObstacleSpawnTimer) {
        
        int tempWidth = arc4random()%7;
        int tempHeight = arc4random()%3;
        int spawnHeight = arc4random()%10;
        if (levelMovingLeft) {
            widthOffset = winSize.width*2.0 + 30.0;
        }else{
            widthOffset = -winSize.width;
        }
        
        [obstacleWidths insertObject:[NSNumber numberWithDouble:(20.0*tempWidth+40.0)*PTP_Ratio] atIndex:obstacleCount];
        [obstacleHeights insertObject:[NSNumber numberWithDouble:(10.0*tempHeight+20.0)*PTP_Ratio] atIndex:obstacleCount];
        [obstacleCentersX insertObject:[NSNumber numberWithDouble:widthOffset*PTP_Ratio + [[obstacleWidths objectAtIndex:obstacleCount] doubleValue]/2.0] atIndex:obstacleCount];
        [obstacleCentersY insertObject:[NSNumber numberWithDouble:winSize.height/2.0*PTP_Ratio + [[obstacleHeights objectAtIndex:obstacleCount]doubleValue]/2.0 + (spawnHeight*10.0+15.0)*PTP_Ratio] atIndex:obstacleCount];
        
        obstacleCount ++;
        spawnAirObstacle = FALSE;
        airObstacleTimePassed = 0.0;
    }
}

-(void) updateObstacleVerticesWithTime:(ccTime)dt andSpeed:(float)speed{
   
    nObstalceVertices = 0;
    nObstalceBox2dVertices = 0;
    if (pixelWinSize.width > 480.0) { 
        speed = speed*PTP_Ratio;
    }
    for (int i=0; i<obstacleCount; i++) {
        [obstacleCentersX replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:[[obstacleCentersX objectAtIndex:i]doubleValue] - speed*dt]];
        
        float x1 = [[obstacleCentersX objectAtIndex:i]doubleValue] - [[obstacleWidths objectAtIndex:i]doubleValue]/2.0;
        float x2 = [[obstacleCentersX objectAtIndex:i]doubleValue] + [[obstacleWidths objectAtIndex:i]doubleValue]/2.0;  
        float y1 = [[obstacleCentersY objectAtIndex:i]doubleValue] - [[obstacleHeights objectAtIndex:i]doubleValue]/2.0;    
        float y2 = [[obstacleCentersY objectAtIndex:i]doubleValue] + [[obstacleHeights objectAtIndex:i]doubleValue]/2.0;    
    
        //sets up vertices for drawing
        obstacleVertices[nObstalceVertices++] = CGPointMake(x1, y1);
        obstacleVertices[nObstalceVertices++] = CGPointMake(x1, y2);
        obstacleVertices[nObstalceVertices++] = CGPointMake(x2, y2);
        obstacleVertices[nObstalceVertices++] = CGPointMake(x2, y2);
        obstacleVertices[nObstalceVertices++] = CGPointMake(x1, y1);
        obstacleVertices[nObstalceVertices++] = CGPointMake(x2, y1);
        
        obstacleBox2dVertices[nObstalceBox2dVertices++] = CGPointMake(x1/PTP_Ratio, y1/PTP_Ratio);
        obstacleBox2dVertices[nObstalceBox2dVertices++] = CGPointMake(x1/PTP_Ratio, y2/PTP_Ratio);
        obstacleBox2dVertices[nObstalceBox2dVertices++] = CGPointMake(x2/PTP_Ratio, y1/PTP_Ratio);
        obstacleBox2dVertices[nObstalceBox2dVertices++] = CGPointMake(x2/PTP_Ratio, y2/PTP_Ratio);
    }
    
    if (levelMovingLeft) {
        for (int i=0; i<obstacleCount; i++) {
            if ([[obstacleCentersX objectAtIndex:i]doubleValue] < -[[obstacleWidths objectAtIndex:i]doubleValue]) {
                [obstacleCentersX removeObjectAtIndex:i];
                [obstacleCentersY removeObjectAtIndex:i];
                [obstacleWidths removeObjectAtIndex:i];
                [obstacleHeights removeObjectAtIndex:i];
                obstacleCount--;
            }
        }
    }else{
        for (int i=obstacleCount-1; i>0; i--) {
            if ([[obstacleCentersX objectAtIndex:i]doubleValue] > winSize.width*PTP_Ratio + [[obstacleWidths objectAtIndex:i]doubleValue]){
                [obstacleCentersX removeObjectAtIndex:i];
                [obstacleCentersY removeObjectAtIndex:i];
                [obstacleWidths removeObjectAtIndex:i];
                [obstacleHeights removeObjectAtIndex:i];
                obstacleCount--;
            }
        }
    }
}

-(void) draw {
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    //begin drawing obstacle/platforms
  /*  glColor4f(0.1, 0.1, 0.1, 1.0);
    glVertexPointer(2, GL_FLOAT, 0, obstacleVertices);
    glDrawArrays(GL_TRIANGLES, 0, nObstalceVertices);*/
    
    glColor4f(0.5, 0.5, 0.5, 0.75);
    glVertexPointer(2, GL_FLOAT, 0, platformsVertices);
    glDrawArrays(GL_TRIANGLES, 0, nPlatformsVertices);

    //end drawing obstacle/platforms

    world->DrawDebugData();
    
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void) createObstacleBody {
    ///////////////////////////////////
    //Creates top body for obstacle 
    ///////////////////////////////////
    if(obstacleTopBody) {
        world->DestroyBody(obstacleTopBody);
    }
    
    b2BodyDef obstacleTopBodyDef;
    obstacleTopBodyDef.type = b2_staticBody;
    obstacleTopBodyDef.position = b2Vec2(0,0);
    obstacleTopBody = world->CreateBody(&obstacleTopBodyDef);
    
    b2PolygonShape obstacleTopshape;
    b2FixtureDef obstacleTopFixture;
    obstacleTopFixture.shape = &obstacleTopshape;
    obstacleTopFixture.restitution = 0.0;
   // obstacleTopFixture.friction = 0.0;
    
    ///////////////////////////////////
    //Creates bottom body for obstacle 
    ///////////////////////////////////
    if(obstacleBottomBody) {
        world->DestroyBody(obstacleBottomBody);
    }
    
    b2BodyDef obstacleBottomBodyDef;
    obstacleBottomBodyDef.type = b2_staticBody;
    obstacleBottomBodyDef.position = b2Vec2(0,0);
    obstacleBottomBody = world->CreateBody(&obstacleBottomBodyDef);
    
    b2PolygonShape obstacleBottomShape;
    b2FixtureDef obstacleBottomFixture;
    obstacleBottomFixture.shape = &obstacleBottomShape;
  //  obstacleBottomFixture.restitution = 0.0;

    //////////////////////////////////
    //Creates side body for obstacle 
    //////////////////////////////////
    if (obstacleSideBody) {
        world->DestroyBody(obstacleSideBody);
    }
    
    b2BodyDef obstacleSideBodyDef;
    obstacleSideBodyDef.type = b2_staticBody;
    obstacleSideBodyDef.position = b2Vec2(0,0);
    obstacleSideBody = world->CreateBody(&obstacleSideBodyDef);
    
    b2PolygonShape obstacleSideShape;    
    b2FixtureDef obstacleSideFixture;
    obstacleSideFixture.shape = &obstacleSideShape;
    obstacleSideFixture.density = 1.0;
    obstacleSideFixture.restitution = 0.0;
    
    //////////////////////////////////
    //Setsup obstacle vertices
    //////////////////////////////////
    b2Vec2 lowerLeft, lowerRight, upperLeft, upperRight;
    for (int i=0; i<nObstalceBox2dVertices; i+=4) {
        //obstacle top and bottom bodies
        upperLeft = b2Vec2((obstacleBox2dVertices[i+1].x+5.0)/PTM_RATIO, obstacleBox2dVertices[i+1].y/PTM_RATIO);
        upperRight =  b2Vec2((obstacleBox2dVertices[i+3].x-5.0)/PTM_RATIO, obstacleBox2dVertices[i+1].y/PTM_RATIO);
        lowerLeft = b2Vec2((obstacleBox2dVertices[i].x+5.0)/PTM_RATIO, obstacleBox2dVertices[i].y/PTM_RATIO);
        lowerRight =  b2Vec2((obstacleBox2dVertices[i+2].x-5.0)/PTM_RATIO, obstacleBox2dVertices[i+2].y/PTM_RATIO);
        
        obstacleTopshape.SetAsEdge(upperLeft, upperRight);
        obstacleTopBody->CreateFixture(&obstacleTopFixture);
        obstacleBottomShape.SetAsEdge(lowerLeft, lowerRight);
        obstacleBottomBody->CreateFixture(&obstacleBottomFixture);
        
        //obstacle side bodies
        lowerLeft = b2Vec2(obstacleBox2dVertices[i].x/PTM_RATIO, obstacleBox2dVertices[i].y/PTM_RATIO);
        upperLeft = b2Vec2(obstacleBox2dVertices[i+1].x/PTM_RATIO, obstacleBox2dVertices[i+1].y/PTM_RATIO);
        lowerRight =  b2Vec2(obstacleBox2dVertices[i+2].x/PTM_RATIO, obstacleBox2dVertices[i+2].y/PTM_RATIO);
        upperRight =  b2Vec2(obstacleBox2dVertices[i+3].x/PTM_RATIO, obstacleBox2dVertices[i+3].y/PTM_RATIO);
        
        obstacleSideShape.SetAsEdge(lowerLeft, upperLeft);
        obstacleSideBody->CreateFixture(&obstacleSideFixture);
        obstacleSideShape.SetAsEdge(lowerRight, upperRight);
        obstacleSideBody->CreateFixture(&obstacleSideFixture);
    }
}

- (void) createPlatformBody {
    ///////////////////////////////////
    //Creates top body for platforms 
    ///////////////////////////////////
    if(platformsTopAndBottomBody) {
        world->DestroyBody(platformsTopAndBottomBody);
    }
    
    b2BodyDef platformsTopAndBottomBodyDef;
    platformsTopAndBottomBodyDef.type = b2_staticBody;
    platformsTopAndBottomBodyDef.position = b2Vec2(0,0);
    platformsTopAndBottomBody = world->CreateBody(&platformsTopAndBottomBodyDef);
    
    b2PolygonShape platformsTopAndBottomshape;
    b2FixtureDef platformsTopAndBottomFixture;
    platformsTopAndBottomFixture.shape = &platformsTopAndBottomshape;
    platformsTopAndBottomFixture.restitution = 0.0;
    // obstacleTopFixture.friction = 0.0;
    
    //////////////////////////////////
    //Creates side body for platforms 
    //////////////////////////////////
    if (platformsSideBody) {
        world->DestroyBody(platformsSideBody);
    }
    
    b2BodyDef platformsSideBodyDef;
    platformsSideBodyDef.type = b2_staticBody;
    platformsSideBodyDef.position = b2Vec2(0,0);
    platformsSideBody = world->CreateBody(&platformsSideBodyDef);
    
    b2PolygonShape platformsSideShape;    
    b2FixtureDef platformsSideFixture;
    platformsSideFixture.shape = &platformsSideShape;
    platformsSideFixture.density = 1.0;
    platformsSideFixture.restitution = 0.0;

    //////////////////////////////////
    //Setsup obstacle vertices
    //////////////////////////////////
    b2Vec2 lowerLeft, lowerRight, upperLeft, upperRight;
    for (int i=0; i<nPlatformsBox2dVertices; i+=4) {
        //obstacle top and bottom bodies
        upperLeft = b2Vec2((platformsBox2dVertices[i+1].x+5.0)/PTM_RATIO, platformsBox2dVertices[i+1].y/PTM_RATIO);
        upperRight =  b2Vec2((platformsBox2dVertices[i+3].x-5.0)/PTM_RATIO, platformsBox2dVertices[i+1].y/PTM_RATIO);
        lowerLeft = b2Vec2((platformsBox2dVertices[i].x+5.0)/PTM_RATIO, platformsBox2dVertices[i].y/PTM_RATIO);
        lowerRight =  b2Vec2((platformsBox2dVertices[i+2].x-5.0)/PTM_RATIO, platformsBox2dVertices[i+2].y/PTM_RATIO);
        
        platformsTopAndBottomshape.SetAsEdge(upperLeft, upperRight);
        platformsTopAndBottomBody->CreateFixture(&platformsTopAndBottomFixture);
        platformsTopAndBottomshape.SetAsEdge(lowerLeft, lowerRight);
        platformsTopAndBottomBody->CreateFixture(&platformsTopAndBottomFixture);
        
        //obstacle side bodies
        lowerLeft = b2Vec2(platformsBox2dVertices[i].x/PTM_RATIO, platformsBox2dVertices[i].y/PTM_RATIO);
        upperLeft = b2Vec2(platformsBox2dVertices[i+1].x/PTM_RATIO, platformsBox2dVertices[i+1].y/PTM_RATIO);
        /*lowerRight =  b2Vec2(platformsBox2dVertices[i+2].x/PTM_RATIO, platformsBox2dVertices[i+2].y/PTM_RATIO);
        upperRight =  b2Vec2(platformsBox2dVertices[i+3].x/PTM_RATIO, platformsBox2dVertices[i+3].y/PTM_RATIO);*/
        
        platformsSideShape.SetAsEdge(lowerLeft, upperLeft);
        platformsSideBody->CreateFixture(&platformsSideFixture);
        //platformsSideShape.SetAsEdge(lowerRight, upperRight);
        //platformsSideBody->CreateFixture(&platformsSideFixture);
    }
}

-(void) createPlayer {
    player = [[[Player alloc] initWithWorld:world] retain];
    [sceneSpriteBatchNode addChild:player z:1000];
}


-(void) createPaintChips {
    paintChipCache = [[PaintChipCache alloc] initWithWorld:world];
    CCArray *tempArray = [paintChipCache totalPaintChips];
    for (int i = 0; i < [tempArray count]; i++) {
        PaintChip *tempPC = [tempArray objectAtIndex:i];
        [sceneSpriteBatchNode addChild:tempPC z:1000];
    }
}

-(void) resetGame {
    jumpBufferCount = 0;
    playerStartJump = NO;
    playerEndJump = NO;
    changeDirectionToLeft = YES;
    levelMovingLeft = YES;
    screenOffsetX = 0.0;
    screenOffsetY = 0.0;
    levelTimePassed = 0.0;
    paintTimePassed = 0.0;
    PIXELS_PER_SECOND = 200.0;
    MAX_PIXELS_PER_SECOND = 200.0;
    gameScore = 0;
    
    //Reset Paintchips
    [paintChipCache resetPaintChips];
    
    //Clean background
    
    //Remove platforms
    
    //Reset player
    [player resetPlayer];
}

-(id) initWithGameUILayer:(GameUILayer *)gameUILayer andBackgroundLayer:(GameBackgroundLayer*)gameBGLayer {
    if ((self = [super init])) {
        winSize = [CCDirector sharedDirector].winSize;

        //Setup layers
        uiLayer = gameUILayer;
        backgroundLayer = gameBGLayer;
        [uiLayer setGameActionLayer:self];
        
        //Setup initialial variables
        self.isTouchEnabled = YES;
        jumpBufferCount = 0;
        playerStartJump = NO;
        playerEndJump = NO;
        changeDirectionToLeft = YES;
        levelMovingLeft = YES;
        screenOffsetX = 0.0;
        screenOffsetY = 0.0;
        levelTimePassed = 0.0;
        paintTimePassed = 0.0;
        PIXELS_PER_SECOND = 200.0;
        MAX_PIXELS_PER_SECOND = 200.0;
        gameScore = 0;
        
        //For obstacle drawing
        //determines screen size in pixels
       // obstacles = [Obstacles node];
        pixelWinSize = [[[UIScreen mainScreen] currentMode] size];
        if (pixelWinSize.width > 480.0) {
            PTP_Ratio = 2.0;  
        } else {
            PTP_Ratio = 1.0;
        }
        obstacleCount = 0;
        obstacleCentersX = [[NSMutableArray alloc] init];
        obstacleCentersY = [[NSMutableArray alloc] init];
        obstacleWidths = [[NSMutableArray alloc] init];
        obstacleHeights = [[NSMutableArray alloc] init];
        obstacleTimePassed = 0.0;
        airObstacleTimePassed = 0.0;
        obstacleSpawnTimer = 0;
        airObstacleSpawnTimer = 0;
        spawnObstacle = FALSE;
        
        //Draws platform
        platformsCentersX = [[NSMutableArray alloc] init];
        platformsCentersY = [[NSMutableArray alloc] init];
        platformsWidths = [[NSMutableArray alloc] init];
        platformsHeights = [[NSMutableArray alloc] init];
        platformCount = 0;
        initialPlatform = TRUE;
        spawnPlatform = TRUE;
        
        /*if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
         [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"scene3atlas-hd.plist"];
         sceneSpriteBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"scene3atlas-hd.png"];
         } else {
         [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"scene3atlas.plist"];
         sceneSpriteBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"scene3atlas.png"];
         }*/
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"game1atlas.plist"];
        sceneSpriteBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"game1atlas.png"];
        [self addChild:sceneSpriteBatchNode z:1];
        
        //Create world and objects
        [self setupWorld];
        [self setupDebugDraw];
        [self createPlayer];
        [self createPaintChips];
        [self createPlatforms];

        //Create contact listener
        contactListener = new MyContactListener();
        world->SetContactListener(contactListener);
        
        //Update Tick
        [self scheduleUpdate];     
    }
    return self;
}

-(void) updateBackgroundState:(ccTime)dt {
    //////////////////////////////////
    //Calculate offset to shift screen
    //////////////////////////////////
    /*levelTimePassed += dt;
    
    if (levelTimePassed > 15.0) {
        levelTimePassed = 0;
        
        if (changeDirectionToLeft) {
            changeDirectionToLeft = NO;
            if (MAX_PIXELS_PER_SECOND < 300.0) {
                MAX_PIXELS_PER_SECOND = MAX_PIXELS_PER_SECOND + 50;
            }
        } else {
            changeDirectionToLeft = YES;
            if (MAX_PIXELS_PER_SECOND > -300.0) {
                MAX_PIXELS_PER_SECOND = MAX_PIXELS_PER_SECOND - 50;
            }
        }
        
        MAX_PIXELS_PER_SECOND *= -1;
    }
    
    if (changeDirectionToLeft) {
        if (PIXELS_PER_SECOND < MAX_PIXELS_PER_SECOND) {
            float change = MAX_PIXELS_PER_SECOND/2;
            PIXELS_PER_SECOND += change*dt;
        }
    } else {
        if (PIXELS_PER_SECOND > MAX_PIXELS_PER_SECOND) {
            float change = MAX_PIXELS_PER_SECOND/2;
            //PIXELS_PER_SECOND -= 50.0*dt;
            PIXELS_PER_SECOND += change*dt;
        }
    }
    
    if (PIXELS_PER_SECOND > 0) {
        levelMovingLeft = YES;
    } else {
        levelMovingLeft = NO;
    }
    
    screenOffsetX += PIXELS_PER_SECOND * dt;
    float backgroundWidth = [backgroundLayer background].contentSize.width;
    if(screenOffsetX >= backgroundWidth) {
        screenOffsetX = screenOffsetX - backgroundWidth;
    }*/
    
    //Comment top part out for one way scrolling
    //Uncomment bottom part as well
    //Calculates how fast to scroll the level based on PIXELS_PER_SECOND
    screenOffsetX += PIXELS_PER_SECOND * dt;
    float backgroundWidth = [backgroundLayer background].contentSize.width;
    if(screenOffsetX >= backgroundWidth) {
        screenOffsetX = screenOffsetX - backgroundWidth;
    }
    
    //Calculates when to scroll the screen to keep the player within the screen when jumping too high. Right now the screen will start to scroll when player jumps over half the screen (winSize.height/2).
    float prevScreenOffsetY = screenOffsetY;
    if (player.position.y > winSize.height/2) {
        screenOffsetY = (winSize.height/2 - player.position.y)*0.4;
        self.position = ccp(self.position.x, screenOffsetY);
    } else if (player.position.y <= winSize.height/2) {
        self.position = ccp(self.position.x, 0.0);
        self.scale = 1.0;
    }
    
    //Calculates how much to scale the screen when screen begins to scroll.
    float yPos = screenOffsetY - prevScreenOffsetY;
    self.scale = self.scale + yPos*dt/10;
    
    //Calculates how much to move the X offset of the layer to keep the player in the same location on screen with the zoom out effect
    float scaledOffsetX = winSize.width/2*(1-self.scale);
    self.position = ccp(-scaledOffsetX, self.position.y);
        
    //Updates the background with the correct offsets so that the drawing will match where the player is on screen.
    [backgroundLayer updateBackground:dt 
                       playerPosition:[player openGLPosition] 
            andPlayerPreviousPosition:[player previousPosition] 
                    andPlayerOnGround:player.isTouchingGround 
                       andPlayerScale:[player basePlayerScale]
                     andScreenOffsetX:screenOffsetX
                     andScreenOffsetY:yPos
                             andScale:self.scale];
}

-(void) updateScore:(ccTime)dt {
    gameScore += dt;
}

-(void) physicsSimulation:(ccTime)dt {
    /////////////////////
    //Physics Simulations
    /////////////////////
    static double UPDATE_INTERVAL = 1.0f/60.0f;
    static double MAX_CYCLES_PER_FRAME = 5;
    static double timeAccumulator = 0;
    
    timeAccumulator += dt;    
    if (timeAccumulator > (MAX_CYCLES_PER_FRAME * UPDATE_INTERVAL)) {
        timeAccumulator = UPDATE_INTERVAL;
    }    
    
    int32 velocityIterations = 3;
    int32 positionIterations = 2;
    while (timeAccumulator >= UPDATE_INTERVAL) {        
        timeAccumulator -= UPDATE_INTERVAL;        
        world->Step(UPDATE_INTERVAL, 
                    velocityIterations, positionIterations);        
        //world->ClearForces();
        
        for(b2Body *b = world->GetBodyList(); b != NULL; b = b->GetNext()) {    
            if (b->GetUserData() != NULL) {
                Box2DSprite *sprite = (Box2DSprite *) b->GetUserData();
                sprite.position = ccp(b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
                sprite.rotation = CC_RADIANS_TO_DEGREES(b->GetAngle() * -1);
            }
        }
    }
}

-(void) detectContacts:(ccTime)dt {
    ///////////////////////////////
    //Detect contacts from listener
    ///////////////////////////////
    if (player != NULL) {
        player.isTouchingGround = NO;
    }
    
    std::vector<MyContact>::iterator pos;
    for (pos = contactListener->_contacts.begin(); pos != contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        
        //Check if player has touched the ground 
        if ((contact.fixtureA->GetBody() == groundBody && contact.fixtureB->GetBody() == player.body) || 
            (contact.fixtureA->GetBody() == player.body && contact.fixtureB->GetBody() == groundBody)) {
            player.isTouchingGround = YES;
            player.doubleJumpAvailable = YES;
        }
    
        //Check if player has touched a paint chip
        NSMutableArray *tempVisiblePaintChips = [paintChipCache visiblePaintChips];
        for (int i = 0; i < [tempVisiblePaintChips count]; i++) {
            PaintChip *tempPC = [tempVisiblePaintChips objectAtIndex:i];
            
            if ((contact.fixtureA->GetBody() == tempPC.body && contact.fixtureB->GetBody() == player.body) || 
                (contact.fixtureA->GetBody() == player.body && contact.fixtureB->GetBody() == tempPC.body)) {
                tempPC.isHit = YES;
                gameScore += 10;
            }
        }
        
        //Check if player has touched the top of the obstacle
        if ((contact.fixtureA->GetBody() == obstacleTopBody && contact.fixtureB->GetBody() == player.body) || 
            (contact.fixtureA->GetBody() == player.body && contact.fixtureB->GetBody() == obstacleTopBody)) {
            player.isTouchingGround = YES;
            player.doubleJumpAvailable = YES;
        }
        
        if ((contact.fixtureA->GetBody() == platformsTopAndBottomBody && contact.fixtureB->GetBody() == player.body) || 
            (contact.fixtureA->GetBody() == player.body && contact.fixtureB->GetBody() == platformsTopAndBottomBody)) {
            player.isTouchingGround = YES;
            player.doubleJumpAvailable = YES;
        }
        
        if ((contact.fixtureA->GetBody() == platformsSideBody && contact.fixtureB->GetBody() == player.body) || 
            (contact.fixtureA->GetBody() == player.body && contact.fixtureB->GetBody() == platformsSideBody)) {
            CCLOG(@"sidebody touched");
            player.died = YES;
            PIXELS_PER_SECOND = 0.0;    
        }
        
        //Checks for contact between player and side face of obstacle
        for (int i=0; i<obstacleCount; i++) {
            if ((contact.fixtureA->GetBody() == obstacleSideBody && contact.fixtureB->GetBody() == player.body) || 
                (contact.fixtureA->GetBody() == player.body && contact.fixtureB->GetBody() == obstacleSideBody)) {
                
                //placeholder
            }
        }
    }
}

-(void) playerJumpBuffer {
    //////////////////////////////
    //Update player jump buffer
    //////////////////////////////
    if (playerStartJump) {
        if (jumpBufferCount <= 2) {
            player.isJumping = YES;
            jumpBufferCount++;
        }
        
        if (jumpBufferCount > 2 && playerEndJump) {
            playerEndJump = NO;
            player.isJumping = NO;
        }
    }
}

-(void) paintChipControl:(ccTime)dt {
    paintTimePassed += dt;
    if (paintTimePassed > 3) {
        [paintChipCache addPaintChips];
        paintTimePassed = 0.0;
    }
}

-(void) updateStatesOfObjects:(ccTime)dt {
    //////////////////////////////
    //Update states of all objects
    //////////////////////////////
    CCArray *listOfGameObjects = [sceneSpriteBatchNode children];
    for (GameCharacter *tempChar in listOfGameObjects) {
        [tempChar updateStateWithDeltaTime:dt];
    }
}

-(void) update:(ccTime)dt {
    [self updateBackgroundState:dt];
    [self updateScore:dt];
    [self physicsSimulation:dt];
    [self detectContacts:dt];
    [self playerJumpBuffer];
    [self paintChipControl:dt];

    [self updateStatesOfObjects:dt];
    [player updateStateWithDeltaTime:dt andSpeed:PIXELS_PER_SECOND];
    [paintChipCache updatePaintChipsWithTime:dt andSpeed:PIXELS_PER_SECOND];
    
    //obstacle updates
//    [self createObstacleBody];
  //  [self spawnObstacleAtTime:dt];
   // [self updateObstacleVerticesWithTime:dt andSpeed:PIXELS_PER_SECOND];
    [self createPlatformBody];
    [self createPlatforms];
    [self updatePlatformVerticesWithTime:dt andSpeed:PIXELS_PER_SECOND];
}

-(BOOL) isTouchingLeftSide:(CGPoint)touchLocation {
    CGRect leftBox = CGRectMake(0,0,winSize.width/2, winSize.height);
    return CGRectContainsPoint(leftBox, touchLocation);
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for( UITouch *touch in touches ) {
        CGPoint location = [touch locationInView:[touch view]];
        location = [[CCDirector sharedDirector] convertToGL:location];
        BOOL isTouchingLeftSide = [self isTouchingLeftSide:location];
        //BOOL isTouchingRightSide = [self isTouchingRightSide:location];
        
        if (isTouchingLeftSide) {
            if (player.isTouchingGround || player.doubleJumpAvailable) {
                if (player.doubleJumpAvailable == NO) {
                    player.doubleJumpAvailable = YES;
                } else {
                    player.doubleJumpAvailable = NO;
                }
                
                playerStartJump = YES;
                player.isJumpingLeft = YES;
                player.jumpTime = 0.0;
      //          backgroundLayer.baseBrushColor = [backgroundLayer randomBrushColor];
                jumpBufferCount = 0;
            }
        } else {
            if (player.isTouchingGround || player.doubleJumpAvailable) {
                if (player.doubleJumpAvailable == NO) {
                    player.doubleJumpAvailable = YES;
                } else {
                    player.doubleJumpAvailable = NO;
                }
                
                playerStartJump = YES;
                player.isJumpingLeft = NO;
                player.jumpTime = 0.0;
      //          backgroundLayer.baseBrushColor = [backgroundLayer randomBrushColor];
                jumpBufferCount = 0;
            }
        }
    }
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    playerEndJump = YES;
}

-(void) ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

-(void) dealloc {
    if (world) {
        delete world;
        world = NULL;
    }
    if (debugDraw) {
        delete debugDraw;
        debugDraw = NULL;
    }
    
    [player release];
    [platformCache release];
    [paintChipCache release];
    [super dealloc];
}



@end
