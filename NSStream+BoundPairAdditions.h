//
//  NSStream+BoundPairAdditions.h
//  Streams
//
//  Created by Peter Paulis on 03/02/15.
//  Copyright (c) 2015 Peter Paulis. All rights reserved.
//

// Code taken from here
// https://developer.apple.com/library/ios/samplecode/SimpleURLConnections/Listings/PostController_m.html

#import <Foundation/Foundation.h>

@interface NSStream (BoundPairAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize;

@end