//
//  PBPlayground.h
//  Pbind
//
//  Created by Galen Lin on 16/9/22.
//  Copyright © 2016年 galenlin. All rights reserved.
//

#include <targetconditionals.h>

#if (DEBUG && TARGET_IPHONE_SIMULATOR)

#import <Foundation/Foundation.h>

@interface PBPlayground : NSObject

@end

#endif
