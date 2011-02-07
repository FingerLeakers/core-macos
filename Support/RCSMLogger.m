/*
 *  RCSMLogger.m
 *  RCSMac
 *
 *
 *  Created by revenge on 2/2/11.
 *  Copyright (C) HT srl 2011. All rights reserved
 *
 */

#import "RCSMLogger.h"


#ifdef ENABLE_LOGGING

static RCSMLogger *sharedLogger = nil;

@implementation RCSMLogger

+ (RCSMLogger *)sharedInstance
{
  @synchronized(self)
    {
      if (sharedLogger == nil)
        {
          //
          // Assignment is not done here
          //
          [[self alloc] init];
        }
    }
  
  return sharedLogger;
}

+ (id)allocWithZone: (NSZone *)aZone
{
  @synchronized(self)
    {
      if (sharedLogger == nil)
        {
          sharedLogger = [super allocWithZone: aZone];
          
          //
          // Assignment and return on first allocation
          //
          return sharedLogger;
        }
      }
  
  // On subsequent allocation attemps return nil
  return nil;
}

- (id)copyWithZone: (NSZone *)aZone
{
  return self;
}

- (id)init
{
  Class myClass = [self class];
  
  @synchronized(myClass)
    {
      if (sharedLogger != nil)
        {
          self = [super init];
          
          if (self != nil)
            {
              sharedLogger = self;
              
              NSDate *date = [[NSDate alloc] init];
              NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
              [dateFormat setDateFormat: @"dd-MM-yyyy"];
              
              NSString *dateString = [dateFormat stringFromDate: date];
              [dateFormat release];
              
              NSMutableString *logName = [NSMutableString stringWithFormat: @"%@.log", dateString];
              mLogName = [[NSString alloc] initWithString: logName];
              
              if ([[NSFileManager defaultManager] fileExistsAtPath: mLogName] == NO)
                {
                  [@"" writeToFile: mLogName
                        atomically: YES
                          encoding: NSUTF8StringEncoding
                             error: nil];
                }
              
              mLogHandle = [NSFileHandle fileHandleForUpdatingAtPath: logName];
              [mLogHandle retain];
              [mLogHandle seekToEndOfFile];
            }
        }
    }
  
  return sharedLogger;
}

- (id)retain
{
  return self;
}

- (unsigned)retainCount
{
  // Denotes an object that cannot be released
  return UINT_MAX;
}

- (void)release
{
  // Do nothing
}

- (id)autorelease
{
  return self;
}

- (void)log: (const char *)aCaller
       line: (int)aLineNumber
      level: (int)aLogLevel
     string: (NSString *)aFormat, ...
{
  va_list argList;
  NSString *logString;
  NSString *entry;
  NSString *level;
  
  va_start(argList, aFormat);
  logString = [[NSString alloc] initWithFormat: aFormat arguments: argList];
  va_end(argList);
  
  NSDate *date = [[NSDate alloc] init];
  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat: @"HH:mm:ss"];
  NSString *dateString = [dateFormat stringFromDate: date];
  [dateFormat release];
  
  switch (aLogLevel)
    {
    case kInfoLevel:
      level = @"[INFO] ";
      break;
    case kWarnLevel:
      level = @"[WARN] ";
      break;
    case kErrLevel:
      level = @"[ERR]  ";
      break;
    case kVerboseLevel:
      level = @"[VERB] ";
      break;
    default:
      level = @"[INFO] ";
      break;
    }
  
  entry = [[NSString alloc] initWithFormat: @"[%@]%@%s:%d - %@",
                                            dateString,
                                            level,
                                            aCaller,
                                            aLineNumber,
                                            logString];
  
  NSMutableData *entryData = [NSMutableData dataWithData:
                              [entry dataUsingEncoding: NSUTF8StringEncoding]];
  char newline = '\n';
  [entryData appendBytes: &newline
                  length: sizeof(newline)];
  [mLogHandle writeData: entryData];
  
  [entry release];
  [date release];
  [logString release];
}

@end

#endif