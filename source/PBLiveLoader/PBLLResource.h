//
//  PBLLResource.h
//  Pbind
//
//  Created by galen on 17/7/30.
//

#import "PBLLOptions.h"
#include <targetconditionals.h>

#if (PBLIVE_ENABLED)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PBLLResource : NSObject

@property (nonatomic, strong, class, readonly) UIImage *logoImage;
@property (nonatomic, strong, class, readonly) UIImage *copyImage;
@property (nonatomic, strong, class, readonly) NSString *pbindTitle;
@property (nonatomic, strong, class, readonly) UIColor *pbindColor;

@end

#endif
