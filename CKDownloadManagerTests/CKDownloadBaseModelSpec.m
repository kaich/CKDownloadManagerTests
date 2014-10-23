//
//  CKDownloadBaseModelSpec.m
//  CKDownloadManager
//
//  Created by mac on 14/10/22.
//  Copyright (c) 2014年 kaicheng. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <CKDownloadManager/CKDownloadBaseModel.h>

SPEC_BEGIN(CKDownloadBaseModelSpec)

describe(@"CKDownloadBaseModel", ^{
    context(@"when created", ^{
        __block CKDownloadBaseModel * baseModel=nil;
        beforeEach(^{
            baseModel=[[CKDownloadBaseModel alloc] init];
        });
        
        afterEach(^{
            baseModel=nil;
        });
        
        it(@"should exist class CKDownloadBaseModel", ^{
            [[[CKDownloadBaseModel class] shouldNot] beNil];
        });
        
        it(@"should not be nil", ^{
            [[baseModel shouldNot] beNil];
        });
        
    });
    
    //http://www.baidu.com , http://www.google.com, http://facebook.com
    context(@"when create and assign dependencies ", ^{
        __block CKDownloadBaseModel * baseModle =nil;
        __block NSArray * dependencies=nil;
        beforeEach(^{
            baseModle =[[CKDownloadBaseModel alloc] init];
            dependencies = @[@"http://www.baidu.com",@"http://www.google.com",@"http://facebook.com"];
            baseModle.dependencies=dependencies;
        });
        
        afterEach(^{
            baseModle=nil;
            dependencies=nil;
        });
        
        it(@".dependencies should containt content be dependencies", ^{
       
            [[baseModle.dependencies should] haveCountOf:3];
            
        });
        
        it(@".dependenciesString should be http://www.baidu.com,http://www.google.com,http://facebook.com", ^{
            NSString * result = [dependencies componentsJoinedByString:@","];
            [[baseModle.dependenciesString should] equal:result];
        });
    });
    
});

SPEC_END
