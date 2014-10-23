//
//  CKDownloadManagerTests.m
//  CKDownloadManagerTests
//
//  Created by mac on 14/10/22.
//  Copyright (c) 2014年 kaicheng. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <CKDownloadManager/CKDownloadManager.h>


SPEC_BEGIN(CKDownloadManagerSpec);

describe(@"CKDownloadManagerSpec", ^{
    
     //instance test
     context(@"when create with sharedInstance", ^{
         CKDownloadManager * mgr =[CKDownloadManager sharedInstance];
         it(@"should not be nil", ^{
             [mgr shouldNotBeNil];
         });
         
         it(@"should be sharedInstance", ^{
             [[mgr should] equal:[CKDownloadManager  sharedInstance]];
         });
     });
    
    
    //single task test
    context(@"when  download single task", ^{
       __block  NSURL * url =nil;
       __block  CKDownloadManager * mgr = nil;
        __block  CKDownloadBaseModel * model = nil;
       beforeAll(^{
           mgr=[CKDownloadManager sharedInstance];
       });
       
        afterAll(^{
            mgr=nil;
        });
        
       beforeEach(^{
           url=[NSURL URLWithString:@"http://d.app.i4.cn/image/icon/2014/10/20/11/1413775670156_103049.jpg"];
           model=[[CKDownloadBaseModel alloc] init];
           model.URLString=url.absoluteString;
           model.title=@"downloadImage";
           
       });
        
        afterEach(^{
            model=nil;
            [mgr deleteWithURL:url];
            url =nil;
        });
        
        it(@"downloadStartBlock should be call and task  be class CKDownloadBaseModel", ^{
            __block id  task =nil;
            __weak typeof (mgr) weakMgr=mgr;
            __block NSArray * downloadEntities=nil;
            mgr.downloadStartBlock=^(id<CKDownloadModelProtocal> downloadTask,NSInteger index){
                task=downloadTask;
                downloadEntities=[weakMgr.downloadEntities copy];
            };
            
            [mgr startDownloadWithURL:url entity:model];
            [[expectFutureValue(task) shouldEventually] beNonNil];
            [[expectFutureValue(task) shouldEventually] beKindOfClass:[CKDownloadBaseModel class]];
            [[expectFutureValue(downloadEntities) shouldEventually] contain:task];
            
        });
        
        it(@"downloadStatusChangedBlock should be call and task not be nil", ^{
            __block id task=nil;
            mgr.downloadStatusChangedBlock=^(id<CKDownloadModelProtocal> downloadTask, id attachTarget , BOOL isFiltered){
                task=downloadTask;
            };
            
            [mgr startDownloadWithURL:url entity:model];
            
            [[expectFutureValue(task) shouldEventually] beNonNil];
            [[expectFutureValue(theValue([task downloadState])) shouldEventually] beBetween:theValue(kDSDownloading) and:theValue(kDSWaitDownload)];
        });
        
        it(@"downloadCompleteBlock should be call and downloadCompleteEntities should not be nil", ^{
            __block id task=nil;
            mgr.downloadCompleteBlock =^(id<CKDownloadModelProtocal> completedTask,NSInteger downloadIndex,NSInteger completeIndex,BOOL isFiltered){
                task=completedTask;
            };
            [mgr startDownloadWithURL:url entity:model];
            
            
            [[expectFutureValue(task) shouldEventuallyBeforeTimingOutAfter(10)] beNonNil];
            [[expectFutureValue(mgr.downloadCompleteEntities) shouldEventuallyBeforeTimingOutAfter(10)] haveCountOf:1];
            [[expectFutureValue(mgr.downloadEntities) shouldEventuallyBeforeTimingOutAfter(10)] haveCountOf:0];
        });
        
        it(@"delete task then downloadEntities count should be 0", ^{
            [mgr deleteWithURL:url];
            [[mgr.downloadEntities should] haveCountOf:0];
            [[mgr.downloadCompleteEntities should] haveCountOf:0];
        });
        
    });
    
    
    //test single task start and dependency
    context(@"when download single task and a dependency", ^{
        __block  NSURL * url =nil;
        __block  NSURL * dependencyUrl=nil;
        __block  CKDownloadManager * mgr = nil;
        __block  CKDownloadBaseModel * model = nil;
        __block  CKDownloadBaseModel * dependencyModel=nil;
        beforeAll(^{
            mgr=[CKDownloadManager sharedInstance];
        });
        
        afterAll(^{
            mgr=nil;
        });
        
        beforeEach(^{
            url=[NSURL URLWithString:@"http://d.app.i4.cn/image/icon/2014/10/20/11/1413775670156_103049.jpg"];
            
            dependencyUrl =[NSURL URLWithString:@"http://d.app.i4.cn/image/icon/2014/09/17/16/1410941145757_838519.jpg"];
            
            model=[[CKDownloadBaseModel alloc] init];
            model.URLString=url.absoluteString;
            model.title=@"downloadImage";
            model.dependencies=@[dependencyUrl];
            
            dependencyModel=[[CKDownloadBaseModel alloc] init];
            dependencyModel.URLString=dependencyUrl.absoluteString;
            dependencyModel.title=@"downloadDependencyImage";
            
        });
        
        afterEach(^{
            model=nil;
            dependencyModel=nil;
            [mgr deleteWithURL:url];
            [mgr deleteWithURL:dependencyUrl];
            url =nil;
            dependencyUrl =nil;
        });
        
        it(@"dependecy task should first start", ^{
            __block id<CKDownloadModelProtocal>  task =nil;
            __block DownloadState state=kDSWaitDownload;
            __block DownloadState dependencyState=kDSWaitDownload;
            mgr.downloadStartBlock=^(id<CKDownloadModelProtocal> downloadTask,NSInteger index){
                if(!task)
                {
                    task=downloadTask;
                    
                    state=model.downloadState;
                    dependencyState=dependencyModel.downloadState;
                }
            };
            
            [mgr startDownloadWithURL:url entity:model dependencies:@{dependencyUrl: dependencyModel}];
            
            [[expectFutureValue(task.URLString) shouldEventually] equal:dependencyUrl.absoluteString];
            
            [[expectFutureValue(theValue(state)) shouldEventually] equal:theValue(kDSWaitDownload)];
            [[expectFutureValue(theValue(dependencyState)) shouldEventually] equal:theValue(kDSWaitDownload)];
        });
        
        
        it(@"dependency task should be downloading at first", ^{
            __block id<CKDownloadModelProtocal>  task =nil;
            __block DownloadState state=kDSWaitDownload;
            __block DownloadState dependencyState=kDSWaitDownload;
            mgr.downloadStatusChangedBlock=^(id<CKDownloadModelProtocal> downloadTask, id attachTarget , BOOL isFiltered){
                if(!task)
                {
                    task=downloadTask;
                    
                    state=model.downloadState;
                    dependencyState=dependencyModel.downloadState;
                }
            };
            
            [mgr startDownloadWithURL:url entity:model dependencies:@{dependencyUrl: dependencyModel}];
            [[expectFutureValue(theValue(state)) shouldEventually] equal:theValue(kDSWaitDownload)];
            [[expectFutureValue(theValue(dependencyState)) shouldEventually] equal:theValue(kDSWaitDownload)];
            
        });
        
        it(@"dependency task should be completed at first", ^{
            __block id<CKDownloadModelProtocal>  task =nil;
            __block DownloadState state=kDSWaitDownload;
            __block DownloadState dependencyState=kDSWaitDownload;
            mgr.downloadCompleteBlock=^(id<CKDownloadModelProtocal> completedTask,NSInteger downloadIndex,NSInteger completeIndex,BOOL isFiltered){
                if(!task)
                {
                    task=completedTask;
                    state=model.downloadState;
                    dependencyState=dependencyModel.downloadState;
                }
            };
            
            [mgr startDownloadWithURL:url entity:model dependencies:@{dependencyUrl: dependencyModel}];
          
            [[expectFutureValue(theValue(state)) shouldNotEventually] equal:theValue(kDSDownloadComplete)];
            [[expectFutureValue(theValue(dependencyState)) shouldEventually] equal:theValue(kDSDownloadComplete)];
        });

    });
    
    
    //mutil task test
    context(@"when download mutil task", ^{
        __block CKDownloadManager * mgr = nil;
        __block NSArray * urls = nil;
        __block NSMutableArray * models = nil;
        __block NSDictionary * downloadDic= nil;
        beforeAll(^{
            mgr=[CKDownloadManager sharedInstance];
        });
        
        beforeEach(^{
            urls=@[URL(@"http://d.app.i4.cn/image/icon/2014/10/20/11/1413775670156_103049.jpg"),URL(@"http://d.app.i4.cn/image/icon/2014/05/21/20/1400676599891_112917.jpg"),URL(@"http://d.app.i4.cn/image/icon/2014/09/17/16/1410941145757_838519.jpg")];
            
            models=[NSMutableArray array];
            for(NSURL *emUrl in urls)
            {
                CKDownloadBaseModel * model=[[CKDownloadBaseModel alloc] init];
                model.URLString=emUrl.absoluteString;
                model.title=@"downloadImage";
                [models addObject:model];
            }
            
            
            downloadDic = @{urls[0]: models[0],urls[1]:models[1],urls[2]:models[2]};
        });
        
        afterEach(^{
            [mgr deleteWithURL:urls[0]];
            [mgr deleteWithURL:urls[1]];
            [mgr deleteWithURL:urls[2]];
            urls=nil;
            models=nil;

        });
        
        afterAll(^{
            mgr =nil;
        });
        
        
        it(@"call downloadStartMutilEnumExtralBlock should be  3 times", ^{
            __block  int times =0;
            
            mgr.downloadStartMutilEnumExtralBlock=^(id<CKDownloadModelProtocal> downloadTask,NSInteger index){
                
                times++;
            };
            
            [mgr startdownloadWithURLKeyEntityDictionary:downloadDic URLKeyDependenciesDictionary:nil];
            
            [[expectFutureValue(theValue(times)) shouldEventually] equal:theValue(3)];
        });
        
       it(@"downloading and complete sum count should be 3", ^{
           
           __block  int sum =0;
           __weak typeof (mgr) weakMgr=mgr;
           mgr.downloadStartMutilBlock=^(NSArray *  prapareStartModels , NSArray * indexPathes){
               
                sum = weakMgr.downloadCompleteEntities.count + weakMgr.downloadEntities.count;
           };
           
           [mgr startdownloadWithURLKeyEntityDictionary:downloadDic URLKeyDependenciesDictionary:nil];
           
           [[expectFutureValue(theValue(sum)) shouldEventually] equal:theValue(3)];
       });
        
        it(@"delete 1 task rest should be 2 and call downloadDeleteMultiEnumExtralBlock should be 1", ^{
            __block int times=0;
            __block id<CKDownloadModelProtocal>  task=nil;
            mgr.downloadDeleteMultiEnumExtralBlock=^(id<CKDownloadModelProtocal>  completedTask, NSInteger index, BOOL isCompleteTask,BOOL isFiltered){
                times ++;
                task=completedTask;
            };
            
            
            [mgr startdownloadWithURLKeyEntityDictionary:downloadDic URLKeyDependenciesDictionary:nil];
            [mgr deleteTasksWithURLs:@[urls[0]] isDownloading:YES];
            
            int sum =mgr.downloadEntities.count + mgr.downloadCompleteEntities.count;
            NSString * expectURLStr= ((NSURL*)urls[0]).absoluteString;
            
            [[expectFutureValue(theValue(sum)) shouldEventually] equal:theValue(2)];
            [[expectFutureValue(theValue(times)) shouldEventually] equal:theValue(1)];
            [[expectFutureValue(task.URLString) shouldEventually] equal:expectURLStr];
        });
       
        it(@"delete 2 task downloadDeleteMultiBlock shoould call 1 times", ^{
            __block int times=0;
            mgr.downloadDeleteMultiBlock=^(BOOL isDownloading , NSArray *  prapareDeleteModels , NSArray * indexPathes,BOOL isDeleteAll){
                times++;
            };
            
            [mgr startdownloadWithURLKeyEntityDictionary:downloadDic URLKeyDependenciesDictionary:nil];
            [mgr deleteAllWithState:YES];
            [[expectFutureValue(theValue(times)) shouldEventually] equal:theValue(1)];
        });
        
        
    });
    
    
    //test download pause resum  isAllDownloading isHasDownloading status test
    context(@"when mutil task download", ^{
        __block CKDownloadManager * mgr = nil;
        __block NSArray * urls = nil;
        __block NSMutableArray * models = nil;
        __block NSDictionary * downloadDic= nil;
        
        beforeAll(^{
            mgr=[CKDownloadManager sharedInstance];
        });
        
        beforeEach(^{
            urls=@[URL(@"http://d.app.i4.cn/soft/2014/10/22/20/c1413981175775_277500.ipa"),URL(@"http://d.app.i4.cn/soft/2014/10/23/10/c1414032810033_655085.ipa"),URL(@"http://d.app.i4.cn/soft/2014/10/08/17/c1412759543673_858945.ipa")];
            
            models=[NSMutableArray array];
            int i=0;
            for(NSURL *emUrl in urls)
            {
                
                CKDownloadBaseModel * model=[[CKDownloadBaseModel alloc] init];
                model.URLString=emUrl.absoluteString;
                model.title=[@"downloadApp" stringByAppendingFormat:@"%d",i];
                [models addObject:model];
                
                i++;
            }
            
            
            downloadDic = @{urls[0]: models[0],urls[1]:models[1],urls[2]:models[2]};
            
            
            [mgr startdownloadWithURLKeyEntityDictionary:downloadDic URLKeyDependenciesDictionary:nil];
            
        });
        
        afterEach(^{
            [mgr deleteWithURL:urls[0]];
            [mgr deleteWithURL:urls[1]];
            [mgr deleteWithURL:urls[2]];
            urls=nil;
            models=nil;
            downloadDic=nil;

            
        });
        
        afterAll(^{
            mgr =nil;
        });
        
        
        it(@"puase one isAllDownloading should be false", ^{
            __weak typeof (mgr) weakMgr =mgr;
            __block BOOL  isAllDownloading = YES;
             NSURL * expectURL=urls[0];
            
            mgr.downloadStatusChangedBlock = ^(id<CKDownloadModelProtocal> downloadTask, id attachTarget , BOOL isFiltered){
                if(downloadTask.downloadState==kDSDownloadPause)
                {
                    isAllDownloading =weakMgr.isAllDownloading;
                }
            };
            
           
            [mgr performSelector:@selector(pauseWithURL:) withObject:expectURL afterDelay:1];
            
            [[expectFutureValue(theValue(isAllDownloading)) shouldEventuallyBeforeTimingOutAfter(3)] beNo];
            
            
            
        });
        
        
    });
    
});

SPEC_END

