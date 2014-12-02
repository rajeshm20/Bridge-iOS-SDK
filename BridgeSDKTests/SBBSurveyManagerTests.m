//
//  SBBSurveyManagerTests.m
//  BridgeSDK
//
//  Created by Erin Mounts on 10/13/14.
//  Copyright (c) 2014 Sage Bionetworks. All rights reserved.
//

#import "SBBBridgeAPITestCase.h"
#import "NSDate+SBBAdditions.h"

@interface SBBSurveyManagerTests : SBBBridgeAPITestCase

@property (nonatomic, strong) NSDictionary *sampleSurveyJSON;

@end

@implementation SBBSurveyManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
  
  NSString *sampleSurveyJsonString = @"{\n"
    "\"guid\":\"55d9973d-1092-42b0-81e2-bbfb86f483c0\",\n"
    "\"createdOn\":\"2014-10-09T23:30:44.747Z\",\n"
    "\"modifiedOn\":\"2014-10-09T23:30:44.747Z\",\n"
    "\"version\":1,\n"
    "\"name\":\"General Blood Pressure Survey\",\n"
    "\"identifier\":\"bloodpressure\",\n"
    "\"published\":false,\n"
    "\"questions\":[\n"
                 "{\n"
                   "\"guid\":\"e872f85a-c157-457b-890f-9e28eeed6efa\",\n"
                   "\"identifier\":\"high_bp\",\n"
                   "\"prompt\":\"Do you have high blood pressure?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                      "\n"
                     "],\n"
                     "\"dataType\":\"boolean\",\n"
                     "\"type\":\"BooleanConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"checkbox\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"c374b293-a060-47c9-bd99-2738837967a8\",\n"
                   "\"identifier\":\"last_checkup\",\n"
                   "\"prompt\":\"When did you last have a medical check-up?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                      "\n"
                     "],\n"
                     "\"dataType\":\"date\",\n"
                     "\"allowFuture\":false,\n"
                     "\"type\":\"DateConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"datepicker\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"854aed00-3d2c-41c2-9b36-17b72287819b\",\n"
                   "\"identifier\":\"last_reading\",\n"
                   "\"prompt\":\"When is your next medical check-up scheduled?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                      "\n"
                     "],\n"
                     "\"dataType\":\"datetime\",\n"
                     "\"allowFuture\":true,\n"
                     "\"type\":\"DateTimeConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"datetimepicker\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"e27a4728-32e7-4066-985a-bee71e2580c3\",\n"
                   "\"identifier\":\"deleuterium_dosage\",\n"
                   "\"prompt\":\"What dosage (in grams) do you take of deleuterium each day?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                      "\n"
                     "],\n"
                     "\"dataType\":\"decimal\",\n"
                     "\"minValue\":0.0,\n"
                     "\"maxValue\":10.0,\n"
                     "\"step\":0.1,\n"
                     "\"type\":\"DecimalConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"slider\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"21987fd2-4846-48a4-aa80-27c3371186c0\",\n"
                   "\"identifier\":\"bp_x_day\",\n"
                   "\"prompt\":\"How many times a day do you take your blood pressure?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                              "{\n"
                                "\"operator\":\"le\",\n"
                                "\"value\":2,\n"
                                "\"goto\":\"name\",\n"
                                "\"type\":\"SurveyRule\"\n"
                              "},\n"
                              "{\n"
                                "\"operator\":\"de\",\n"
                                "\"goto\":\"name\",\n"
                                "\"type\":\"SurveyRule\"\n"
                              "}\n"
                              "],\n"
                     "\"dataType\":\"integer\",\n"
                     "\"minValue\":0,\n"
                     "\"maxValue\":4,\n"
                     "\"step\":null,\n"
                     "\"type\":\"IntegerConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"numberfield\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"db8d54db-c00e-4203-af71-2701253aa9e9\",\n"
                   "\"identifier\":\"time_for_appt\",\n"
                   "\"prompt\":\"How log does your appointment take, on average?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                      "\n"
                     "],\n"
                     "\"dataType\":\"duration\",\n"
                     "\"type\":\"DurationConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"timepicker\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"f841bb48-3d22-4049-ae1f-921c38cd4ebb\",\n"
                   "\"identifier\":\"deleuterium_x_day\",\n"
                   "\"prompt\":\"What times of the day do you take deleuterium?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                      "\n"
                     "],\n"
                     "\"dataType\":\"time\",\n"
                     "\"type\":\"TimeConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"timepicker\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"
                   "\"guid\":\"1992b80e-912c-4b05-b29b-5c35f02688b4\",\n"
                   "\"identifier\":\"feeling\",\n"
                   "\"prompt\":\"How do you feel today?\",\n"
                   "\"constraints\":{\n"
                     "\"rules\":[\n"
                        "\n"
                     "],\n"
                     "\"dataType\":\"integer\",\n"
                     "\"enumeration\":[\n"
                                    "{\n"
                                      "\"label\":\"Terrible\",\n"
                                      "\"value\":1,\n"
                                      "\"type\":\"SurveyQuestionOption\"\n"
                                    "},\n"
                                    "{\n"   
                                      "\"label\":\"Poor\",\n"
                                      "\"value\":2,\n"
                                      "\"type\":\"SurveyQuestionOption\"\n"
                                    "},\n"
                                    "{\n"   
                                      "\"label\":\"OK\",\n"
                                      "\"value\":3,\n"
                                      "\"type\":\"SurveyQuestionOption\"\n"
                                    "},\n"
                                    "{\n"   
                                      "\"label\":\"Good\",\n"
                                      "\"value\":4,\n"
                                      "\"type\":\"SurveyQuestionOption\"\n"
                                    "},\n"
                                    "{\n"   
                                      "\"label\":\"Great\",\n"
                                      "\"value\":5,\n"
                                      "\"type\":\"SurveyQuestionOption\"\n"
                                    "}\n"
                                    "],\n"
                     "\"allowOther\":false,\n"
                     "\"allowMultiple\":true,\n"
                     "\"type\":\"MultiValueConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"list\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "},\n"
                 "{\n"   
                   "\"guid\":\"12fee175-6213-4c0b-89b5-5cac34f7783f\",\n"
                   "\"identifier\":\"name\",\n"
                   "\"prompt\":\"Please enter an emergency phone number (###-###-####)?\",\n"
                   "\"constraints\":{\n"   
                     "\"rules\":[\n"   
                      "\n"
                     "],\n"
                     "\"dataType\":\"string\",\n"
                     "\"minLength\":2,\n"
                     "\"maxLength\":255,\n"
                     "\"pattern\":\"\\\\d{3}-\\\\d{3}-\\\\{d}4\",\n"
                     "\"type\":\"StringConstraints\"\n"
                   "},\n"
                   "\"uiHint\":\"textfield\",\n"
                   "\"type\":\"SurveyQuestion\"\n"
                 "}\n"
                 "],\n"
    "\"type\":\"Survey\"\n"
  "}";
  NSData *jsonData = [sampleSurveyJsonString dataUsingEncoding:NSUTF8StringEncoding];
  _sampleSurveyJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
  _sampleSurveyJSON = nil;
}

- (void)testGetSurveyByRef {
  [self.mockNetworkManager setJson:_sampleSurveyJSON andResponseCode:200 forEndpoint:@"/api/v1/surveys/55d9973d-1092-42b0-81e2-bbfb86f483c0/2014-10-09T23:30:44.747Z" andMethod:@"GET"];
  SBBObjectManager *oMan = [SBBObjectManager objectManager];
  SBBSurveyManager *sMan = [SBBSurveyManager managerWithAuthManager:SBBComponent(SBBAuthManager) networkManager:self.mockNetworkManager objectManager:oMan];
  [sMan getSurveyByRef:@"/api/v1/surveys/55d9973d-1092-42b0-81e2-bbfb86f483c0/2014-10-09T23:30:44.747Z" completion:^(id survey, NSError *error) {
    XCTAssert([survey isKindOfClass:[SBBSurvey class]], @"Converted incoming json to SBBSurvey");
    SBBSurveyQuestion *question0 = ((SBBSurvey *)survey).questions[0];
    XCTAssert([question0 isKindOfClass:[SBBSurveyQuestion class]], @"Questions converted to SBBSurveyQuestion");
    XCTAssert([question0.constraints isKindOfClass:[SBBSurveyConstraints class]], @"Constraints converted to SBBSurveyConstraints");
  }];
}

- (void)testGetSurveyByGuidCreatedOn {
  NSString *endpoint = @"/api/v1/surveys/55d9973d-1092-42b0-81e2-bbfb86f483c0/2014-10-09T23:30:44.747Z";
  NSArray *pathComponents = [endpoint componentsSeparatedByString:@"/"];
  NSString *guid = pathComponents[pathComponents.count - 2];
  NSDate *createdOn = [NSDate dateWithISO8601String:pathComponents[pathComponents.count - 1]];
  [self.mockNetworkManager setJson:_sampleSurveyJSON andResponseCode:200 forEndpoint:endpoint andMethod:@"GET"];
  SBBObjectManager *oMan = [SBBObjectManager objectManager];
  SBBSurveyManager *sMan = [SBBSurveyManager managerWithAuthManager:SBBComponent(SBBAuthManager) networkManager:self.mockNetworkManager objectManager:oMan];
  [sMan getSurveyByGuid:guid createdOn:createdOn completion:^(id survey, NSError *error) {
    XCTAssert([survey isKindOfClass:[SBBSurvey class]], @"Converted incoming json to SBBSurvey");
    SBBSurveyQuestion *question0 = ((SBBSurvey *)survey).questions[0];
    XCTAssert([question0 isKindOfClass:[SBBSurveyQuestion class]], @"Questions converted to SBBSurveyQuestion");
    XCTAssert([question0.constraints isKindOfClass:[SBBSurveyConstraints class]], @"Constraints converted to SBBSurveyConstraints");
  }];
}

- (NSArray *)someAnswers {
  NSMutableArray *answers = [NSMutableArray array];
  SBBSurveyAnswer *a1 = [SBBSurveyAnswer new];
  a1.questionGuid = @"e872f85a-c157-457b-890f-9e28eeed6efa";
  a1.answer = @"true";
  a1.answeredOn = [NSDate date];
  a1.client = @"test";
  a1.declined = @NO;
  [answers addObject:a1];
  SBBSurveyAnswer *a2 = [a1 copy];
  a2.questionGuid = @"c374b293-a060-47c9-bd99-2738837967a8";
  a2.answer = [[NSDate dateWithTimeIntervalSinceNow:-5000000.0] ISO8601String];
  [answers addObject:a2];
  
  return answers;
}

- (void)testSubmitAnswersToSurveyByRef {
    NSDictionary *guidHolder =
    @{
      @"type": @"GuidHolder",
      @"guid": @"ThisIsn'tReallyAGuid"
      };
    NSString *endpoint = @"/api/v1/surveys/55d9973d-1092-42b0-81e2-bbfb86f483c0/2014-10-09T23:30:44.747Z";
    [self.mockNetworkManager setJson:guidHolder andResponseCode:200 forEndpoint:endpoint andMethod:@"POST"];
    SBBObjectManager *oMan = [SBBObjectManager objectManager];
    SBBSurveyManager *sMan = [SBBSurveyManager managerWithAuthManager:SBBComponent(SBBAuthManager) networkManager:self.mockNetworkManager objectManager:oMan];
    NSArray *answers = [self someAnswers];
    [sMan submitAnswers:answers toSurveyByRef:endpoint completion:^(id guidHolder, NSError *error) {
        XCTAssert([guidHolder isKindOfClass:[SBBGuidHolder class]], @"GuidHolder converted to SBBGuidHolder");
    }];
}

- (void)testSubmitAnswersToSurveyByRefWithResponseGuid {
    NSDictionary *guidHolder =
    @{
      @"type": @"GuidHolder",
      @"guid": @"ThisIsn'tReallyAGuid"
      };
    NSString *surveyRef = @"/api/v1/surveys/55d9973d-1092-42b0-81e2-bbfb86f483c0/2014-10-09T23:30:44.747Z";
    NSString *responseGuid = guidHolder[@"guid"];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", surveyRef, responseGuid];
    [self.mockNetworkManager setJson:guidHolder andResponseCode:200 forEndpoint:endpoint andMethod:@"POST"];
    SBBObjectManager *oMan = [SBBObjectManager objectManager];
    SBBSurveyManager *sMan = [SBBSurveyManager managerWithAuthManager:SBBComponent(SBBAuthManager) networkManager:self.mockNetworkManager objectManager:oMan];
    NSArray *answers = [self someAnswers];
    [sMan submitAnswers:answers toSurveyByRef:surveyRef withResponseGuid:responseGuid completion:^(id guidHolder, NSError *error) {
        XCTAssert([guidHolder isKindOfClass:[SBBGuidHolder class]], @"GuidHolder converted to SBBGuidHolder");
        XCTAssert([responseGuid isEqualToString:((SBBGuidHolder *)guidHolder).guid], @"Response guid is equal to what was specified");
    }];
}

- (void)testSubmitAnswersToSurveyByGuidCreatedOn {
    NSDictionary *guidHolder =
    @{
      @"type": @"GuidHolder",
      @"guid": @"ThisIsn'tReallyAGuid"
      };
    NSString *endpoint = @"/api/v1/surveys/55d9973d-1092-42b0-81e2-bbfb86f483c0/2014-10-09T23:30:44.747Z";
    NSArray *pathComponents = [endpoint componentsSeparatedByString:@"/"];
    NSString *guid = pathComponents[pathComponents.count - 2];
    NSDate *createdOn = [NSDate dateWithISO8601String:pathComponents[pathComponents.count - 1]];
    [self.mockNetworkManager setJson:guidHolder andResponseCode:200 forEndpoint:endpoint andMethod:@"POST"];
    SBBObjectManager *oMan = [SBBObjectManager objectManager];
    SBBSurveyManager *sMan = [SBBSurveyManager managerWithAuthManager:SBBComponent(SBBAuthManager) networkManager:self.mockNetworkManager objectManager:oMan];
    [sMan submitAnswers:[self someAnswers] toSurveyByGuid:guid createdOn:createdOn completion:^(id guidHolder, NSError *error) {
        XCTAssert([guidHolder isKindOfClass:[SBBGuidHolder class]], @"GuidHolder converted to SBBGuidHolder");
   }];
}

- (void)testSubmitAnswersToSurveyByGuidCreatedOnWithResponseGuid {
    NSDictionary *guidHolder =
    @{
      @"type": @"GuidHolder",
      @"guid": @"ThisIsn'tReallyAGuid"
      };
    NSString *guid = @"55d9973d-1092-42b0-81e2-bbfb86f483c0";
    NSString *createdOnString = @"2014-10-09T23:30:44.747Z";
    NSString *responseGuid = guidHolder[@"guid"];
    NSString *endpoint = [NSString stringWithFormat:@"/api/v1/surveys/%@/%@/%@", guid, createdOnString, responseGuid];
    NSDate *createdOn = [NSDate dateWithISO8601String:createdOnString];
    [self.mockNetworkManager setJson:guidHolder andResponseCode:200 forEndpoint:endpoint andMethod:@"POST"];
    SBBObjectManager *oMan = [SBBObjectManager objectManager];
    SBBSurveyManager *sMan = [SBBSurveyManager managerWithAuthManager:SBBComponent(SBBAuthManager) networkManager:self.mockNetworkManager objectManager:oMan];
    [sMan submitAnswers:[self someAnswers] toSurveyByGuid:guid createdOn:createdOn withResponseGuid:responseGuid completion:^(id guidHolder, NSError *error) {
        XCTAssert([guidHolder isKindOfClass:[SBBGuidHolder class]], @"GuidHolder converted to SBBGuidHolder");
        XCTAssert([responseGuid isEqualToString:((SBBGuidHolder *)guidHolder).guid], @"Response guid is equal to what was specified");
    }];
}

- (void)testGetSurveyResponse {
  
}

- (void)testAddAnswersToSurveyResponse {
  
}

- (void)testDeleteSurveyResponse {
  
}

@end
