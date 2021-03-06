//
//  SBBActivity.m
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
// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SBBActivity.h instead.
//

#import "_SBBActivity.h"
#import "ModelObjectInternal.h"
#import "NSDate+SBBAdditions.h"

#import "SBBSurveyReference.h"
#import "SBBSurveyResponseReference.h"
#import "SBBTaskReference.h"

@interface _SBBActivity()

@end

// see xcdoc://?url=developer.apple.com/library/etc/redirect/xcode/ios/602958/documentation/Cocoa/Conceptual/CoreData/Articles/cdAccessorMethods.html
@interface NSManagedObject (Activity)

@property (nullable, nonatomic, retain) NSString* activityType;

@property (nullable, nonatomic, retain) NSString* guid;

@property (nullable, nonatomic, retain) NSString* label;

@property (nullable, nonatomic, retain) NSString* labelDetail;

@property (nullable, nonatomic, retain) NSManagedObject *schedule;

@property (nullable, nonatomic, retain) NSManagedObject *scheduledActivity;

@property (nullable, nonatomic, retain) NSManagedObject *survey;

@property (nullable, nonatomic, retain) NSManagedObject *surveyResponse;

@property (nullable, nonatomic, retain) NSManagedObject *task;

@end

@implementation _SBBActivity

- (instancetype)init
{
	if((self = [super init]))
	{

	}

	return self;
}

#pragma mark Scalar values

#pragma mark Dictionary representation

- (void)updateWithDictionaryRepresentation:(NSDictionary *)dictionary objectManager:(id<SBBObjectManagerProtocol>)objectManager
{
    [super updateWithDictionaryRepresentation:dictionary objectManager:objectManager];

    self.activityType = [dictionary objectForKey:@"activityType"];

    self.guid = [dictionary objectForKey:@"guid"];

    self.label = [dictionary objectForKey:@"label"];

    self.labelDetail = [dictionary objectForKey:@"labelDetail"];

        NSDictionary *surveyDict = [dictionary objectForKey:@"survey"];
    if(surveyDict != nil)
    {
        SBBSurveyReference *surveyObj = [objectManager objectFromBridgeJSON:surveyDict];
        self.survey = surveyObj;

    }
        NSDictionary *surveyResponseDict = [dictionary objectForKey:@"surveyResponse"];
    if(surveyResponseDict != nil)
    {
        SBBSurveyResponseReference *surveyResponseObj = [objectManager objectFromBridgeJSON:surveyResponseDict];
        self.surveyResponse = surveyResponseObj;

    }
        NSDictionary *taskDict = [dictionary objectForKey:@"task"];
    if(taskDict != nil)
    {
        SBBTaskReference *taskObj = [objectManager objectFromBridgeJSON:taskDict];
        self.task = taskObj;

    }

}

- (NSDictionary *)dictionaryRepresentationFromObjectManager:(id<SBBObjectManagerProtocol>)objectManager
{
    NSMutableDictionary *dict = [[super dictionaryRepresentationFromObjectManager:objectManager] mutableCopy];

    [dict setObjectIfNotNil:self.activityType forKey:@"activityType"];

    [dict setObjectIfNotNil:self.guid forKey:@"guid"];

    [dict setObjectIfNotNil:self.label forKey:@"label"];

    [dict setObjectIfNotNil:self.labelDetail forKey:@"labelDetail"];

	[dict setObjectIfNotNil:[objectManager bridgeJSONFromObject:self.survey] forKey:@"survey"];

	[dict setObjectIfNotNil:[objectManager bridgeJSONFromObject:self.surveyResponse] forKey:@"surveyResponse"];

	[dict setObjectIfNotNil:[objectManager bridgeJSONFromObject:self.task] forKey:@"task"];

	return [dict copy];
}

- (void)awakeFromDictionaryRepresentationInit
{
	if(self.sourceDictionaryRepresentation == nil)
		return; // awakeFromDictionaryRepresentationInit has been already executed on this object.

	[self.task awakeFromDictionaryRepresentationInit];
	[self.survey awakeFromDictionaryRepresentationInit];
	[self.surveyResponse awakeFromDictionaryRepresentationInit];

	[super awakeFromDictionaryRepresentationInit];
}

#pragma mark Core Data cache

- (NSEntityDescription *)entityForContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription entityForName:@"Activity" inManagedObjectContext:context];
}

- (instancetype)initWithManagedObject:(NSManagedObject *)managedObject objectManager:(id<SBBObjectManagerProtocol>)objectManager cacheManager:(id<SBBCacheManagerProtocol>)cacheManager
{

    if (self = [super initWithManagedObject:managedObject objectManager:objectManager cacheManager:cacheManager]) {

        self.activityType = managedObject.activityType;

        self.guid = managedObject.guid;

        self.label = managedObject.label;

        self.labelDetail = managedObject.labelDetail;

            NSManagedObject *surveyManagedObj = managedObject.survey;
        Class surveyClass = [SBBObjectManager bridgeClassFromType:surveyManagedObj.entity.name];
        SBBSurveyReference *surveyObj = [[surveyClass alloc] initWithManagedObject:surveyManagedObj objectManager:objectManager cacheManager:cacheManager];
        if(surveyObj != nil)
        {
          self.survey = surveyObj;
        }
            NSManagedObject *surveyResponseManagedObj = managedObject.surveyResponse;
        Class surveyResponseClass = [SBBObjectManager bridgeClassFromType:surveyResponseManagedObj.entity.name];
        SBBSurveyResponseReference *surveyResponseObj = [[surveyResponseClass alloc] initWithManagedObject:surveyResponseManagedObj objectManager:objectManager cacheManager:cacheManager];
        if(surveyResponseObj != nil)
        {
          self.surveyResponse = surveyResponseObj;
        }
            NSManagedObject *taskManagedObj = managedObject.task;
        Class taskClass = [SBBObjectManager bridgeClassFromType:taskManagedObj.entity.name];
        SBBTaskReference *taskObj = [[taskClass alloc] initWithManagedObject:taskManagedObj objectManager:objectManager cacheManager:cacheManager];
        if(taskObj != nil)
        {
          self.task = taskObj;
        }
    }

    return self;

}

- (NSManagedObject *)createInContext:(NSManagedObjectContext *)cacheContext withObjectManager:(id<SBBObjectManagerProtocol>)objectManager cacheManager:(id<SBBCacheManagerProtocol>)cacheManager
{
    NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Activity" inManagedObjectContext:cacheContext];
    [self updateManagedObject:managedObject withObjectManager:objectManager cacheManager:cacheManager];

    // Calling code will handle saving these changes to cacheContext.

    return managedObject;
}

- (NSManagedObject *)saveToContext:(NSManagedObjectContext *)cacheContext withObjectManager:(id<SBBObjectManagerProtocol>)objectManager cacheManager:(id<SBBCacheManagerProtocol>)cacheManager
{
    NSManagedObject *managedObject = [cacheManager cachedObjectForBridgeObject:self inContext:cacheContext];
    if (managedObject) {
        [self updateManagedObject:managedObject withObjectManager:objectManager cacheManager:cacheManager];
    }

    // Calling code will handle saving these changes to cacheContext.

    return managedObject;
}

- (void)updateManagedObject:(NSManagedObject *)managedObject withObjectManager:(id<SBBObjectManagerProtocol>)objectManager cacheManager:(id<SBBCacheManagerProtocol>)cacheManager
{

    [super updateManagedObject:managedObject withObjectManager:objectManager cacheManager:cacheManager];
    NSManagedObjectContext *cacheContext = managedObject.managedObjectContext;

    managedObject.activityType = ((id)self.activityType == [NSNull null]) ? nil : self.activityType;

    managedObject.guid = ((id)self.guid == [NSNull null]) ? nil : self.guid;

    managedObject.label = ((id)self.label == [NSNull null]) ? nil : self.label;

    managedObject.labelDetail = ((id)self.labelDetail == [NSNull null]) ? nil : self.labelDetail;

    // destination entity SurveyReference is not directly cacheable, so delete it and create the replacement
    if (managedObject.survey) {
        [cacheContext deleteObject:managedObject.survey];
    }
    NSManagedObject *relMoSurvey = [self.survey createInContext:cacheContext withObjectManager:objectManager cacheManager:cacheManager];

    [managedObject setSurvey:relMoSurvey];

    // destination entity SurveyResponseReference is not directly cacheable, so delete it and create the replacement
    if (managedObject.surveyResponse) {
        [cacheContext deleteObject:managedObject.surveyResponse];
    }
    NSManagedObject *relMoSurveyResponse = [self.surveyResponse createInContext:cacheContext withObjectManager:objectManager cacheManager:cacheManager];

    [managedObject setSurveyResponse:relMoSurveyResponse];

    // destination entity TaskReference is not directly cacheable, so delete it and create the replacement
    if (managedObject.task) {
        [cacheContext deleteObject:managedObject.task];
    }
    NSManagedObject *relMoTask = [self.task createInContext:cacheContext withObjectManager:objectManager cacheManager:cacheManager];

    [managedObject setTask:relMoTask];

    // Calling code will handle saving these changes to cacheContext.
}

#pragma mark Direct access

- (void) setSurvey: (SBBSurveyReference*) survey_ settingInverse: (BOOL) setInverse
{

    _survey = survey_;

}

- (void) setSurvey: (SBBSurveyReference*) survey_
{
    [self setSurvey: survey_ settingInverse: YES];
}

- (SBBSurveyReference*) survey
{
    return _survey;
}

- (void) setSurveyResponse: (SBBSurveyResponseReference*) surveyResponse_ settingInverse: (BOOL) setInverse
{

    _surveyResponse = surveyResponse_;

}

- (void) setSurveyResponse: (SBBSurveyResponseReference*) surveyResponse_
{
    [self setSurveyResponse: surveyResponse_ settingInverse: YES];
}

- (SBBSurveyResponseReference*) surveyResponse
{
    return _surveyResponse;
}

- (void) setTask: (SBBTaskReference*) task_ settingInverse: (BOOL) setInverse
{

    _task = task_;

}

- (void) setTask: (SBBTaskReference*) task_
{
    [self setTask: task_ settingInverse: YES];
}

- (SBBTaskReference*) task
{
    return _task;
}

@synthesize survey = _survey;@synthesize surveyResponse = _surveyResponse;@synthesize task = _task;

@end
