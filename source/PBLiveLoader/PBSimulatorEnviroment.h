//
//  PBSimulatorEnviroment.h
//  Pbind
//
//  Created by Galen Lin on 13/03/2017.
//

#if (DEBUG)

#include <targetconditionals.h>
#import <Foundation/Foundation.h>

#if (TARGET_IPHONE_SIMULATOR)

FOUNDATION_STATIC_INLINE NSString *PBLLProjectPath() {
    return [[@(__FILE__) stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
}

FOUNDATION_STATIC_INLINE NSString *PBLLMainBundlePath() {
    NSString *projectPath = PBLLProjectPath();
    NSString *projectName = [projectPath lastPathComponent];
    return [projectPath stringByAppendingPathComponent:projectName];
}

FOUNDATION_STATIC_INLINE NSString *PBLLMockingAPIPath() {
    return [PBLLProjectPath() stringByAppendingPathComponent:@"PBLocalhost"];
}

#endif

#endif
