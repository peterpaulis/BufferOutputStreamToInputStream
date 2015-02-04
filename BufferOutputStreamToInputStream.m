//
//  BufferWriter.m
//  Streams
//
//  Created by Peter Paulis on 03/02/15.
//  Copyright (c) 2015 Peter Paulis. All rights reserved.
//

#import "BufferOutputStreamToInputStream.h"

#import "NSStream+BoundPairAdditions.h"

#define BufferedStreamBufferSize    512
#define TotalBufferCapacityHint     4096*1024 // 4MB
#define CleanDataBufferOverOffset   (TotalBufferCapacityHint / 2.)

@interface BufferOutputStreamToInputStream()

@property (nonatomic, strong, readwrite) NSOutputStream * outputStream;
@property (strong, nonatomic, readwrite) NSInputStream * inputStream;

@property (nonatomic, strong) NSMutableData * dataBuffer;
@property (nonatomic, assign) NSUInteger offset;

@property (nonatomic, assign) BOOL hasSpaceAvailable;

@end

@implementation BufferOutputStreamToInputStream

- (id)init {
    
    self = [super init];
    if (self) {
    
        // create bounded input and output stream
        NSOutputStream * os;
        NSInputStream * is;
        [NSStream createBoundInputStream:&is outputStream:&os bufferSize:512];
        self.outputStream = os;
        self.inputStream = is;
        
    }
    return self;
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Getters / Setters
////////////////////////////////////////////////////////////////////////

- (NSMutableData *)dataBuffer {
    
    if (_dataBuffer) {
        return _dataBuffer;
    }
    
    _dataBuffer = [[NSMutableData alloc] initWithCapacity:TotalBufferCapacityHint];
    return _dataBuffer;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////

- (void)openOutputStream {
    
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
}

- (void)closeOutputStream {
    
    [self.outputStream close];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.outputStream.delegate = nil;
    
}

- (void)addDataToBuffer:(NSData *)data {
    
    NSAssert([self.outputStream streamStatus] == NSStreamStatusOpen, @"NOT OPENED");
    
    [self.dataBuffer appendData:data];
    
    if (self.hasSpaceAvailable) {
        [self sendDataChunk];
    }
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (BOOL)sendDataChunk {
    
    if (self.dataBuffer == nil) {
        return NO;
    }
    
    NSUInteger dataLength = [self.dataBuffer length];
    NSUInteger readLength = BufferedStreamBufferSize;
    
    if (self.offset == dataLength) {
    
        // all data written so far
        return NO;
    
    } else if ((self.offset + BufferedStreamBufferSize) > dataLength) {
    
        // more data than can be written
        readLength = dataLength - self.offset;
    
    }
    
    if (readLength <= 0) {
        return NO;
    }
    
    uint8_t *readBytes = (uint8_t*)malloc(readLength);
    [self.dataBuffer getBytes:readBytes range:NSMakeRange(self.offset, readLength)];
    
    NSInteger writtenLength = [self.outputStream write:readBytes maxLength:readLength];
    if (writtenLength > 0) {
        
        self.offset += writtenLength;
        
        if (self.offset >= CleanDataBufferOverOffset) {
        
            NSRange range = NSMakeRange(0, self.offset);
            [self.dataBuffer replaceBytesInRange:range withBytes:NULL length:0];
            self.offset = 0;
            
        }
        
    } else if (writtenLength < 0) {
        
        NSLog(@"WRITE BUFFER FAILED");
        return NO;
        
    }

    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSStream
////////////////////////////////////////////////////////////////////////

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    if (aStream == self.outputStream) {
        
        if (eventCode == NSStreamEventHasSpaceAvailable) {
            
            if ([self sendDataChunk]) {
                self.hasSpaceAvailable = NO;
            } else {
                self.hasSpaceAvailable = YES;
            }
            
        } else if (eventCode == NSStreamEventErrorOccurred) {
            
            NSLog(@"STREAM ERROR %@", aStream.streamError);
            
        }
        
    }
    
}

@end
