//
//  CKDownloadPathManagerTests.m
//  CKDownloadManager
//
//  Created by mac on 14/10/22.
//  Copyright (c) 2014年 kaicheng. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <CKDownloadManager/CKDownloadPathManager.h>

SPEC_BEGIN(CKDownloadPathManagerTests)

describe(@"CKDownloadPathManager", ^{

    
    context(@"when set url", ^{
        __block  NSURL * url=nil;
        __block  NSString * toPath=nil;
        __block  NSString * tmpPath=nil;
        beforeAll(^{
            url=[NSURL URLWithString:@"http://www.google.com/12345.txt"];
            [CKDownloadPathManager SetURL:url toPath:&toPath tempPath:&tmpPath];
        });
        
        it(@"to path should not be nil ", ^{
            [[toPath should] beNonNil];
        });
        
        it(@"tmp path should not be nil", ^{
            [[tmpPath should] beNonNil];
        });
        
        it(@"to path should be file path", ^{
            NSURL * url =[NSURL fileURLWithPath:toPath];
            [[url should] beNonNil];
        });
        
        
        it(@"tmp path should be file path", ^{
            NSURL * url =[NSURL fileURLWithPath:tmpPath];
            [[url should] beNonNil];
        });
    });
    
    
    context(@"when remove exist file", ^{
        __block NSString * path =nil;
        __block NSString * tmpPath=nil;
        __block NSURL * url =nil;
        beforeEach(^{
    
            url=[NSURL URLWithString:@"http://www.google.com/12345.txt"];
            [CKDownloadPathManager SetURL:url toPath:&path tempPath:&tmpPath];
        
            NSData * data =[@"you are a person !" dataUsingEncoding:NSUTF8StringEncoding];
            
            [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            [[NSFileManager defaultManager] createFileAtPath:tmpPath contents:data attributes:nil];
        });
        
        afterEach(^{
            NSFileManager * mgr =[NSFileManager defaultManager];
            if([mgr fileExistsAtPath:path])
            {
                [mgr removeItemAtPath:path error:nil];
            }
            
            if([mgr fileExistsAtPath:tmpPath])
            {
                [mgr removeItemAtPath:tmpPath error:nil];
            }
            
        });
        
        it(@"lib file should exist", ^{
            BOOL isOK =[[NSFileManager defaultManager] fileExistsAtPath:path];
            [[theValue(isOK) should] beYes];
        });
        
        it(@"tmp file should exist", ^{
            BOOL isTmpOK =[[NSFileManager defaultManager] fileExistsAtPath:tmpPath];
            [[theValue(isTmpOK) should] beYes];
        });
        
        it(@"downloadSize should not be 0", ^{
            float size= [CKDownloadPathManager downloadContentSizeWithURL:url];
            [[theValue(size) shouldNot] beZero];
        });
        
        it(@"lib file should removed", ^{
            [CKDownloadPathManager removeFileWithURL:url];
            BOOL isOK =[[NSFileManager defaultManager] fileExistsAtPath:path];
            [[theValue(isOK) should] beNo];
        });
        
        it(@"tmp file should be ", ^{
            [CKDownloadPathManager removeFileWithURL:url];
            BOOL isOK =[[NSFileManager defaultManager] fileExistsAtPath:tmpPath];
            [[theValue(isOK) should] beNo];
        });
        
    });
    
});

SPEC_END
