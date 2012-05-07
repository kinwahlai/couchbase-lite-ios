//
//  TDGNUstep.m
//  TouchDB
//
//  Created by Jens Alfke on 2/27/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//

#import "TDGNUstep.h"
#import <Foundation/Foundation.h>


@interface NSError (GNUstep)
+ (NSError*) _last;
@end


int digittoint(int c) {
    if (!isxdigit(c))
        return 0;
    else if (c <= '9')
        return c - '0';
    else if (c <= 'F')
        return 10 + c - 'A';
    else
        return 10 + c - 'a';
}


CFAbsoluteTime CFAbsoluteTimeGetCurrent(void) {
    // NOTE: The time base for this isn't the same as CF's (1970 vs 2001), but this is only being
    // used in TouchDB to calculate relative times, so that doesn't matter.
    return time(NULL);
}


static NSComparisonResult callComparator(id a, id b, void* context) {
    return ((NSComparator)context)(a, b);
}

@implementation NSArray (GNUstep)

- (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr {
    return [self sortedArrayUsingFunction: &callComparator context: cmptr];
}

@end

@implementation NSMutableArray (GNUstep)

- (void)sortUsingComparator:(NSComparator)cmptr {
    [self sortUsingFunction: &callComparator context: cmptr];
}

@end



@implementation NSData (GNUstep)

+ (id)dataWithContentsOfFile:(NSString *)path
                     options:(NSDataReadingOptions)options
                       error:(NSError **)errorPtr
{
    NSData* data;
    if (options & NSDataReadingMappedIfSafe)
        data = [self dataWithContentsOfMappedFile: path];
    else
        data = [self dataWithContentsOfFile: path];
    if (!data && errorPtr)
        *errorPtr = [NSError _last];
    return data;
}

- (NSRange)rangeOfData:(NSData *)dataToFind
               options:(NSDataSearchOptions)options
                 range:(NSRange)searchRange
{
    NSParameterAssert(dataToFind);
    // TODO: Implement NSDataSearchBackwards
    NSAssert(!(options & NSDataSearchBackwards), @"NSDataSearchBackwards not implemented yet");
    NSUInteger patternLen = dataToFind.length;
    if (patternLen == 0)
        return NSMakeRange(NSNotFound, 0);
    const void* patternBytes = dataToFind.bytes;
    NSUInteger myLen = self.length;
    const void* myBytes = self.bytes;
    const void* start = NULL;
    if (options & NSDataSearchAnchored) {
        if (patternLen <= myLen && memcmp(myBytes, patternBytes, patternLen) == 0)
            start = myBytes;
    } else {
        start = memmem(myBytes, myLen, patternBytes, patternLen);
    }
    if (!start)
        return NSMakeRange(NSNotFound, 0);
    return NSMakeRange(start - myBytes, patternLen);
}

@end
