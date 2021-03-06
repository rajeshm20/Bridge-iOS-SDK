//
//  SBBUploadManager.m
//  BridgeSDK
//
//  Created by Erin Mounts on 10/9/14.
//
//	Copyright (c) 2014-2016 Sage Bionetworks
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without
//	modification, are permitted provided that the following conditions are met:
//	    * Redistributions of source code must retain the above copyright
//	      notice, this list of conditions and the following disclaimer.
//	    * Redistributions in binary form must reproduce the above copyright
//	      notice, this list of conditions and the following disclaimer in the
//	      documentation and/or other materials provided with the distribution.
//	    * Neither the name of Sage Bionetworks nor the names of BridgeSDk's
//		  contributors may be used to endorse or promote products derived from
//		  this software without specific prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//	DISCLAIMED. IN NO EVENT SHALL SAGE BIONETWORKS BE LIABLE FOR ANY
//	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "SBBUploadManager.h"
#import "NSData+SBBAdditions.h"
#import "SBBComponentManager.h"
#import "SBBAuthManager.h"
#import "SBBNetworkManagerInternal.h"
#import "SBBObjectManager.h"
#import "SBBUploadSession.h"
#import "SBBUploadRequest.h"
#import "NSError+SBBAdditions.h"
#import "SBBErrors.h"
#import "BridgeSDKInternal.h"
#import "NSDate+SBBAdditions.h"

#define UPLOAD_API GLOBAL_API_PREFIX @"/uploads"
#define UPLOAD_STATUS_API GLOBAL_API_PREFIX @"/uploadstatuses"

static NSString * const kSBBUploadAPI =                 UPLOAD_API;
static NSString * const kSBBUploadCompleteAPIFormat =   UPLOAD_API @"/%@/complete";
static NSString * const kSBBUploadStatusAPIFormat =     UPLOAD_STATUS_API @"/%@";

static NSString *kUploadFilesKey = @"SBBUploadFilesKey";
static NSString *kUploadRequestsKey = @"SBBUploadRequestsKey";
static NSString *kUploadSessionsKey = @"SBBUploadSessionsKey";
static NSString *kUploadRetryAfterDelayKey = @"SBBUploadRetryAfterDelayKey";

#pragma mark - SBBUploadCompletionWrapper

@interface SBBUploadCompletionWrapper : NSObject

@property (nonatomic, copy) SBBUploadManagerCompletionBlock completion;

- (instancetype)initWithBlock:(SBBUploadManagerCompletionBlock)block;

@end

@implementation SBBUploadCompletionWrapper

- (instancetype)initWithBlock:(SBBUploadManagerCompletionBlock)block
{
    if (self = [super init]) {
        self.completion = block;
    }
    
    return self;
}

@end

#pragma mark - SBBUploadManager

@interface SBBUploadManager () <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) SBBObjectManager *cleanObjectManager;

@property (nonatomic, strong) NSMutableDictionary *uploadCompletionHandlers;

@end

@implementation SBBUploadManager
@synthesize uploadDelegate = _uploadDelegate;

+ (instancetype)defaultComponent
{
    static SBBUploadManager *shared;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self instanceWithRegisteredDependencies];
        shared.networkManager.backgroundTransferDelegate = shared;
        
        // check if any uploads that got 503 status codes from S3 or Bridge errors are due for a retry
        // whenever the app comes to the foreground
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [shared retryUploadsAfterDelay];
        }];
        
        // also check right away
        [shared retryUploadsAfterDelay];
    });
    
    return shared;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.uploadCompletionHandlers = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (NSURL *)tempUploadDirURL
{
    NSURL *appSupportDir = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *bundleName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSURL *uploadDir = [[appSupportDir URLByAppendingPathComponent:bundleName] URLByAppendingPathComponent:@"SBBUploadManager"];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:uploadDir withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Error attempting to create uploadDir at path %@:\n%@", uploadDir.absoluteURL, error);
    }
    
    return uploadDir;
}

- (NSURL *)tempFileForFileURL:(NSURL *)fileURL
{
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSUUID UUID] UUIDString], [fileURL lastPathComponent]];
    NSURL *tempFileURL = [[self tempUploadDirURL] URLByAppendingPathComponent:fileName];
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:tempFileURL error:&error];
    if (error) {
        NSLog(@"Error copying file %@ to temp file %@:\n%@", [fileURL path], [tempFileURL path], error);
        tempFileURL = nil;
    }
    
    if (tempFileURL) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *filesForTempFiles = [[defaults dictionaryForKey:kUploadFilesKey] mutableCopy];
        [filesForTempFiles setObject:[fileURL path] forKey:[tempFileURL path]];
        [defaults setObject:filesForTempFiles forKey:kUploadFilesKey];
        [defaults synchronize];
    }
    
    return tempFileURL;
}

- (NSString *)fileForTempFile:(NSString *)tempFilePath
{
    NSString *file = nil;
    if (tempFilePath.length) {
        file = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUploadFilesKey][tempFilePath];
    }
    
    return file;
}

- (void)cleanUpTempFile:(NSString *)tempFilePath
{
    if (tempFilePath.length) {
        // remove it from the upload files map
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *files = [[defaults dictionaryForKey:kUploadFilesKey] mutableCopy];
        [files removeObjectForKey:tempFilePath];
        [defaults setObject:files forKey:kUploadFilesKey];
        [defaults synchronize];
        
        // delete the temp file
        NSURL *tempFile = [NSURL fileURLWithPath:tempFilePath];
        if  (!tempFile) {
            NSLog(@"Could not create NSURL for temp file %@", tempFilePath);
        }
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtURL:tempFile error:&error]) {
            NSLog(@"Failed to remove temp file %@, error:\n%@", tempFilePath, error);
        }
    }
}

- (SBBUploadManagerCompletionBlock)completionBlockForFile:(NSString *)file
{
    SBBUploadCompletionWrapper *wrapper = [_uploadCompletionHandlers objectForKey:file];
    return wrapper.completion;
}

- (void)setCompletionBlock:(SBBUploadManagerCompletionBlock)completion forFile:(NSString *)file
{
    if (!completion) {
        [self removeCompletionBlockForFile:file];
        return;
    }
    SBBUploadCompletionWrapper *wrapper = [[SBBUploadCompletionWrapper alloc] initWithBlock:completion];
    [_uploadCompletionHandlers setObject:wrapper forKey:file];
}

- (void)removeCompletionBlockForFile:(NSString *)file
{
    [_uploadCompletionHandlers removeObjectForKey:file];
}

- (void)setUploadRequestJSON:(id)json forFile:(NSString *)fileURLString
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *uploadRequests = [[defaults dictionaryForKey:kUploadRequestsKey] mutableCopy];
    if (!uploadRequests) {
        uploadRequests = [NSMutableDictionary dictionary];
    }
    if (json) {
        [uploadRequests setObject:json forKey:fileURLString];
    } else {
        [uploadRequests removeObjectForKey:fileURLString];
    }
    [defaults setObject:uploadRequests forKey:kUploadRequestsKey];
    [defaults synchronize];
}

- (NSDictionary *)uploadRequestJSONForFile:(NSString *)fileURLString
{
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUploadRequestsKey][fileURLString];
}

- (SBBUploadRequest *)uploadRequestForFile:(NSString *)fileURLString
{
    SBBUploadRequest *uploadRequest = nil;
    id json = [self uploadRequestJSONForFile:fileURLString];
    if (json) {
        uploadRequest = [_cleanObjectManager objectFromBridgeJSON:json];
    }
    
    return uploadRequest;
}

- (void)setUploadSessionJSON:(id)json forFile:(NSString *)fileURLString
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *uploadSessions = [[defaults dictionaryForKey:kUploadSessionsKey] mutableCopy];
    if (!uploadSessions) {
        uploadSessions = [NSMutableDictionary dictionary];
    }
    if (json) {
        [uploadSessions setObject:json forKey:fileURLString];
    } else {
        [uploadSessions removeObjectForKey:fileURLString];
    }
    [defaults setObject:uploadSessions forKey:kUploadSessionsKey];
    [defaults synchronize];
}

- (SBBUploadSession *)uploadSessionForFile:(NSString *)fileURLString
{
    SBBUploadSession *uploadSession = nil;
    id json = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUploadSessionsKey][fileURLString];
    if (json) {
        uploadSession = [_cleanObjectManager objectFromBridgeJSON:json];
    }
    
    return uploadSession;
}

- (NSDate *)retryTimeForFile:(NSString *)fileURLString
{
    NSDate *retryTime = nil;
    NSString *jsonDate = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUploadRetryAfterDelayKey][fileURLString];
    if (jsonDate) {
        retryTime = [NSDate dateWithISO8601String:jsonDate];
    }
    
    return retryTime;
}

- (void)setRetryAfterDelayForFile:(NSString *)fileURLString
{
    NSTimeInterval delay = 5. * 60.; // at least 5 minutes, actually whenever we get to it after that
#if DEBUG
    NSLog(@"Will retry upload of file %@ after %lf seconds.", fileURLString, delay);
#endif
    NSDate *retryTime = [NSDate dateWithTimeIntervalSinceNow:delay];
    
    [self setRetryTime:retryTime forFile:fileURLString];
}

- (void)setRetryTime:(NSDate *)retryTime forFile:(NSString *)fileURLString {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *retryUploads = [[defaults dictionaryForKey:kUploadRetryAfterDelayKey] mutableCopy];
    if (!retryUploads) {
        retryUploads = [NSMutableDictionary dictionary];
    }
    if (retryTime) {
        retryUploads[fileURLString] = [retryTime ISO8601String];
    } else {
        [retryUploads removeObjectForKey:fileURLString];
    }
    [defaults setObject:retryUploads forKey:kUploadRetryAfterDelayKey];
    [defaults synchronize];
}

- (void)retryUploadsAfterDelay
{
    [((SBBNetworkManager *)self.networkManager).backgroundSession.delegateQueue addOperationWithBlock:^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSDictionary *retryUploads = [[defaults dictionaryForKey:kUploadRetryAfterDelayKey] mutableCopy];
        for (NSString *fileURLString in retryUploads.allKeys) {
            NSDate *retryTime = [self retryTimeForFile:fileURLString];
            if ([retryTime timeIntervalSinceNow] <= 0.) {
                [self setRetryTime:nil forFile:fileURLString];
                NSDictionary *uploadRequestJSON = [self uploadRequestJSONForFile:fileURLString];
                [self kickOffUploadForFile:fileURLString uploadRequestJSON:uploadRequestJSON];
            }
        }
    }];
}

// When uploading a file to Bridge, first we use background download to get an SBBUploadSession object from Bridge.
// Then we use the pre-signed URL in that SBBUploadSession to upload our file to S3.
// When that finishes, we tell Bridge that the requested upload is completed.
// To avoid having multiple layers of nested completion handlers in one method, they're broken out by step:

// --- Here's the completion handler for the step where we tell Bridge the upload completed:
- (void)toldBridgeFileUploadedWithTask:(NSURLSessionUploadTask *)uploadTask forBridgeSession:(SBBUploadSession *)uploadSession error:(NSError *)error
{
#if DEBUG
    if (error) {
        NSLog(@"Error calling upload complete for upload ID %@:\n%@", uploadSession.id, error);
    } else {
        NSString* uploadStatusUrlString = nil;
        if ([self.networkManager isKindOfClass:[SBBNetworkManager class]]) {
            NSString* relativeUrl = [NSString stringWithFormat:kSBBUploadStatusAPIFormat, uploadSession.id];
            NSURL* url = [(SBBNetworkManager*) self.networkManager URLForRelativeorAbsoluteURLString:relativeUrl];
            uploadStatusUrlString = [url absoluteString];
            if ([_uploadDelegate respondsToSelector:@selector(uploadManager:uploadOfFile:completedWithVerificationURL:)]) {
                [_uploadDelegate uploadManager:self uploadOfFile:uploadTask.taskDescription completedWithVerificationURL:url];
            }
        }
        NSLog(@"Successfully called upload complete for upload ID %@, check status with curl -H \"Bridge-Session:%@\" %@", uploadSession.id, [self.authManager.authDelegate sessionTokenForAuthManager:self.authManager], uploadStatusUrlString);
    }
#endif
    [self completeUploadOfFile:uploadTask.taskDescription withError:error];
}

- (void)handleUploadHTTPStatusCode:(NSInteger)httpStatusCode forUploadFilePath:(NSString *)filePath
{
    switch (httpStatusCode) {
        case 403:
        case 500: {
            // 403 for our purposes means the pre-signed url timed out before starting the actual upload to S3.
            // 500 means internal server error ("We encountered an internal error. Please try again.")
            // either way we should try again immediately
#if DEBUG
            NSLog(@"Background file upload to S3 failed with HTTP status %ld; retrying...", (long)httpStatusCode);
#endif
            NSDictionary *uploadRequestJSON = [self uploadRequestJSONForFile:filePath];
            [self kickOffUploadForFile:filePath uploadRequestJSON:uploadRequestJSON];
        } break;
            
        case 503: {
            // 503 means service not available or the requests are coming too fast, so try again after
            // at least a minimum delay
            
#if DEBUG
            NSLog(@"Background file upload to S3 failed with HTTP status 503.");
#endif
            [self setRetryAfterDelayForFile:filePath];
        } break;
            
        default: {
            // iOS handles redirects automatically so only e.g. 307 resource not changed etc. from the 300 range should end up here
            // (along with all unhandled 4xx and 5xx of course)
            NSString *description = [NSString stringWithFormat:@"Background file upload to S3 failed with HTTP status %ld", (long)httpStatusCode];
            NSError *s3Error = [NSError errorWithDomain:SBB_ERROR_DOMAIN code:SBBErrorCodeS3UploadErrorResponse userInfo:@{NSLocalizedDescriptionKey: description}];
            [self completeUploadOfFile:filePath withError:s3Error];
        } break;
    }
}

// --- Here's the completion handler for the step where we upload the file to S3:
- (void)uploadedFileToS3WithTask:(NSURLSessionUploadTask *)uploadTask response:(NSHTTPURLResponse *)httpResponse error:(NSError *)error
{
    NSInteger httpStatusCode = httpResponse.statusCode;
    NSString *filePath = uploadTask.taskDescription;
    
    // client-side networking issue
    if (error) {
        [self completeUploadOfFile:filePath withError:error];
        return;
    }
    
    // server didn't like the request, or otherwise hiccupped
    if (httpStatusCode >= 300) {
        [self handleUploadHTTPStatusCode:httpStatusCode forUploadFilePath:filePath];
        
        // early exit
        return;
    }
    
    // tell the API we done did it
    SBBUploadSession *uploadSession = [self uploadSessionForFile:filePath];
    [self setUploadSessionJSON:nil forFile:filePath];
    NSString *uploadId = uploadSession.id;
    if (!uploadId.length) {
        NSAssert(uploadId, @"uploadId is nil");
    }
    NSString *ref = [NSString stringWithFormat:kSBBUploadCompleteAPIFormat, uploadId];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [self.authManager addAuthHeaderToHeaders:headers];
    [self.networkManager post:ref headers:headers parameters:nil background:YES completion:^(NSURLSessionTask *task, id responseObject, NSError *error) {
        [self toldBridgeFileUploadedWithTask:uploadTask forBridgeSession:uploadSession error:error];
    }];
}

// --- And here's the completion handler for getting the SBBUploadSession in the first place:
- (void)downloadedBridgeUploadSessionWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask fileURL:(NSURL *)file
{
    NSError *error;
    NSData *jsonData = [NSData dataWithContentsOfURL:file options:0 error:&error];
    if (error) {
        NSLog(@"Error reading downloaded UploadSession file into an NSData object:\n%@", error);
        [self completeUploadOfFile:downloadTask.taskDescription withError:error];
        return;
    }
    
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        [self completeUploadOfFile:downloadTask.taskDescription withError:error];
        NSLog(@"Error deserializing downloaded UploadSession data into objects:\n%@", error);
        return;
    }
    
    SBBUploadSession *uploadSession = [_cleanObjectManager objectFromBridgeJSON:jsonObject];
    SBBUploadRequest *uploadRequest = [self uploadRequestForFile:downloadTask.taskDescription];
    if (!uploadRequest || !uploadRequest.contentLength || !uploadRequest.contentType || !uploadRequest.contentMd5) {
        NSLog(@"Failed to retrieve upload request headers for temp file %@", downloadTask.taskDescription);
        NSString *desc = [NSString stringWithFormat:@"Error retrieving upload request headers for temp file URL:\n%@", downloadTask.taskDescription];
        error = [NSError errorWithDomain:SBB_ERROR_DOMAIN code:SBBErrorCodeTempFileError userInfo:@{NSLocalizedDescriptionKey: desc}];
        [self completeUploadOfFile:downloadTask.taskDescription withError:error];
        return;
    }
    [self setUploadRequestJSON:nil forFile:downloadTask.taskDescription];
    if ([uploadSession isKindOfClass:[SBBUploadSession class]]) {
#if DEBUG
        NSLog(@"Successfully obtained upload session with upload ID %@", uploadSession.id);
#endif
        [self setUploadSessionJSON:jsonObject forFile:downloadTask.taskDescription];
        NSDictionary *uploadHeaders =
        @{
          @"Content-Length": [uploadRequest.contentLength stringValue],
          @"Content-Type": uploadRequest.contentType,
          @"Content-MD5": uploadRequest.contentMd5
          };
        NSURL *fileUrl = [NSURL fileURLWithPath:downloadTask.taskDescription];
        [self.networkManager uploadFile:fileUrl httpHeaders:uploadHeaders toUrl:uploadSession.url taskDescription:downloadTask.taskDescription completion:^(NSURLSessionTask *task, NSHTTPURLResponse *response, NSError *error) {
#if DEBUG
            if (error || response.statusCode >= 300) {
                NSLog(@"Error uploading to S3 for upload ID %@\nHTTP status: %@\n%@", uploadSession.id, @(response.statusCode), error);
            } else {
                NSLog(@"Successfully uploaded to S3 for upload ID %@", uploadSession.id);
            }
#endif
            [self uploadedFileToS3WithTask:(NSURLSessionUploadTask *)task response:response error:error];
        }];
    } else {
        NSError *error = [NSError generateSBBObjectNotExpectedClassErrorForObject:uploadSession expectedClass:[SBBUploadSession class]];
        [self completeUploadOfFile:downloadTask.taskDescription withError:error];
    }
}

- (void)uploadFileToBridge:(NSURL *)fileUrl contentType:(NSString *)contentType completion:(SBBUploadManagerCompletionBlock)completion
{
    if (![fileUrl isFileURL] || ![[NSFileManager defaultManager] isReadableFileAtPath:[fileUrl path]]) {
        NSLog(@"Attempting to upload an URL that's not a readable file URL:\n%@", fileUrl);
        if (completion) {
            completion([NSError generateSBBNotAFileURLErrorForURL:fileUrl]);
        }
        if (_uploadDelegate) {
            [_uploadDelegate uploadManager:self uploadOfFile:[fileUrl absoluteString] completedWithError:[NSError generateSBBNotAFileURLErrorForURL:fileUrl]];
        }
        return;
    }
    
    // make a temp copy with a unique name
    NSURL *tempFileURL = [self tempFileForFileURL:fileUrl];
    if (!tempFileURL) {
        if (completion) {
            completion([NSError generateSBBTempFileErrorForURL:fileUrl]);
        }
        return;
    }
    [((SBBNetworkManager *)self.networkManager).backgroundSession.delegateQueue addOperationWithBlock:^{
        [self setCompletionBlock:completion forFile:[tempFileURL path]];
    }];
    
    if (!_cleanObjectManager) {
        _cleanObjectManager = [SBBObjectManager objectManager];
    }
    
    // default to generic binary file if type not specified
    if (!contentType) {
        contentType = @"application/octet-stream";
    }
    
    NSString *name = [fileUrl lastPathComponent];
    NSData *fileData = [NSData dataWithContentsOfURL:tempFileURL];
    if (!fileData) {
        if (completion) {
            completion([NSError generateSBBTempFileReadErrorForURL:fileUrl]);
        }
        return;
    }
    SBBUploadRequest *uploadRequest = [SBBUploadRequest new];
    uploadRequest.name = name;
    uploadRequest.contentLengthValue = fileData.length;
    uploadRequest.contentType = contentType;
    uploadRequest.contentMd5 = [fileData contentMD5];
    NSString *filePath = [tempFileURL path];
    // don't use the shared SBBObjectManager--we want to use only SDK default objects for types
    NSDictionary *uploadRequestJSON = [_cleanObjectManager bridgeJSONFromObject:uploadRequest];
    
    [((SBBNetworkManager *)self.networkManager).backgroundSession.delegateQueue addOperationWithBlock:^{
        [self kickOffUploadForFile:filePath uploadRequestJSON:uploadRequestJSON];
    }];
    
    // while we're at it, see if there are any uploads due for a retry after getting a 503 status code from S3 or an error from Bridge.
    [self retryUploadsAfterDelay];
}

// This presumes uploadFileToBridge:contentType:completion: was called to set things up for this file,
// so can be used for both the initial upload attempt and any retries due to 403 (presigned url timed out).
// It also presumes it's being called from within the background NSURLSession's delegate queue.
- (void)kickOffUploadForFile:(NSString *)filePath uploadRequestJSON:(NSDictionary *)uploadRequestJSON
{
    // this starts the process by downloading the Bridge UploadSession.
    [self setUploadRequestJSON:uploadRequestJSON forFile:filePath];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [self.authManager addAuthHeaderToHeaders:headers];
    
    __block NSURLSessionDownloadTask *downloadTask = [self.networkManager downloadFileFromURLString:kSBBUploadAPI method:@"POST" httpHeaders:headers parameters:uploadRequestJSON taskDescription:filePath downloadCompletion:^(NSURL *file) {
        [self downloadedBridgeUploadSessionWithDownloadTask:downloadTask fileURL:file];
    } taskCompletion:^(NSURLSessionTask *task, NSHTTPURLResponse *response, NSError *error) {
        // We don't care about this unless there was a network error, or an HTTP response indicating an error.
        // Otherwise we'll have gotten and handled the downloaded file url in the downloadCompletion block, above.
        if (error) {
            // network error--we'll only get here if the error didn't include resume data
#if DEBUG
            NSLog(@"Request to Bridge for UploadSession failed due to network error.");
#endif
            [self setRetryAfterDelayForFile:filePath];
        } else if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode < 300) {
                // these are not the codes you're looking for--move along
                return;
            }
            error = [NSError generateSBBErrorForStatusCode:statusCode];
            switch (statusCode) {
                case 412:
                    // not consented--don't retry; we shouldn't be uploading data in the first place
                    [self completeUploadOfFile:task.taskDescription withError:error];
                    break;
                    
                default:
                    // anything else, retry after a delay
#if DEBUG
                    NSLog(@"Request to Bridge for UploadSession failed with HTTP status %ld.", statusCode);
#endif
                    [self setRetryAfterDelayForFile:filePath];
                    break;
            }
        }
    }];
}

#pragma mark - Delegate methods

- (void)completeUploadOfFile:(NSString *)file withError:(NSError *)error
{
    SBBUploadManagerCompletionBlock completion = [self completionBlockForFile:file];
    if (completion) {
        [self removeCompletionBlockForFile:file];
        completion(error);
    }
    if (_uploadDelegate) {
        NSString *originalFile = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUploadFilesKey][file];
        [_uploadDelegate uploadManager:self uploadOfFile:originalFile completedWithError:error];
    }
    [self cleanUpTempFile:file];
    [self setUploadRequestJSON:nil forFile:file];
    [self setUploadSessionJSON:nil forFile:file];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"Session became invalid! Error:\n%@", error);
    
    // handle completion (failure) for all outstanding uploads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *files = [defaults dictionaryForKey:kUploadFilesKey];
    for (NSString *file in files.allKeys) {
        [self completeUploadOfFile:file withError:error];
    }
    
    // clear everything out
    [_uploadCompletionHandlers removeAllObjects];
    [defaults removeObjectForKey:kUploadRequestsKey];
    [defaults removeObjectForKey:kUploadSessionsKey];
    [defaults removeObjectForKey:kUploadFilesKey];
    
    NSError *fileError;
    [[NSFileManager defaultManager] removeItemAtURL:[self tempUploadDirURL] error:&fileError];
    if (fileError) {
        NSLog(@"Error removing temp upload file directory:\n%@", fileError);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    // This is actually an indirect delegate, with calls passed through from SBBNetworkManager's session delegate.
    // We use the same protocol to avoid needless duplication, and this method is required by that protocol,
    // but between the original session delegate and completion handlers, there's nothing left for us to do here.
}

@end
