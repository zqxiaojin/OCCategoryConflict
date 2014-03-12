//
//  main.cpp
//  OCCategoryConflict
//
//  Created by Jin on 3/11/14.
//  Copyright (c) 2014 Jin. All rights reserved.
//

#include <iostream>
#import <Foundation/Foundation.h>

NSString* nmToLibToFile(NSString* path)
{
    NSString* cmd = [NSString stringWithFormat:@"nm -j \"%@\" 2>&1", path];
    
    FILE* output = popen([cmd UTF8String] , "r+");
    
    
    NSMutableData* data = [[NSMutableData alloc] initWithCapacity:4];
    unsigned long bufferMax = 1024;
    Byte* buffer[bufferMax];
    unsigned long bufReaded = 0;
    while ((bufReaded = fread(buffer, sizeof(Byte), bufferMax, output)) > 0)
    {
        [data appendBytes:buffer length:bufReaded];
    }
    
    
    pclose(output);
    
    NSString* result = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    return result;
}

static NSMutableDictionary* methodDic = [[NSMutableDictionary alloc] initWithCapacity:4];

void parse(NSString* symlist, NSString* path)
{
    NSArray* arr = [symlist componentsSeparatedByString:@"\n"];
    for (NSString* line in arr)
    {
        static NSArray* charArr = @[@"[", @"]", @"(", @")"];
        BOOL isMatch = false;
        for (NSString* str in charArr)
        {
            if ([line rangeOfString:str].location != NSNotFound)
                isMatch = true;
            else
            {
                isMatch = false;break;
            }
        }
        if (isMatch)
        {
            
            NSRange left = [line rangeOfString:@"("];
            NSRange right = [line rangeOfString:@")"];
            NSMutableString* newLine = [line mutableCopy];
            [newLine deleteCharactersInRange:NSMakeRange(left.location, right.location - left.location + 1)];
            NSString* oldPath = [methodDic objectForKey:newLine];
            if (oldPath)
            {
                if (![oldPath isEqualToString:path])
                {
                    NSString* outStr = [NSString stringWithFormat:@"%@\tboth in %@ and %@\n", newLine , oldPath , path];
                    puts([outStr UTF8String]);
                }
            }
            else
            {
                [methodDic setObject:path forKey:newLine];
            }
        }
    }
}

int main(int argc, const char * argv[])
{
    if (argc != 2)
    {
    errorPath:
        puts("give me a dir, please~");
        return 0;
    }
    
    NSString* dir = [NSString stringWithUTF8String:argv[1]];
    printf("search *.a Category Conflict at %s\n\n", [dir UTF8String]);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir])
    {
        goto errorPath;
    }
    
    NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
    NSString* path = NULL;
    while ((path = [enumerator nextObject]))
    {
        if ([[path pathExtension] isEqualToString:@"a"])
        {
            NSString* result = nmToLibToFile([dir stringByAppendingString:path]);
            parse(result, [path lastPathComponent]);
        }
    }
    
    puts("done");
    
    return 0;
}

