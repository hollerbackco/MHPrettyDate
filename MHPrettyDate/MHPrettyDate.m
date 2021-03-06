//
//  MHPrettyDate.m
//  MHPrettyDate
//
//  Created by Bobby Williams on 9/8/12.
//  Copyright (c) 2012 Bobby Williams. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "MHPrettyDate.h"

@interface MHPrettyDate()

@property (strong, nonatomic)   NSDate*            today;
@property (readonly, nonatomic) NSDate*            yesterday;
@property (readonly, nonatomic) NSDate*            tomorrow;
@property (readonly, nonatomic) NSDate*            weekAgo;
@property (readonly, nonatomic) NSCalendar*        calendar;
//@property (strong, nonatomic)   NSDateFormatter*   dateFormatter;
@property (assign)              MHPrettyDateFormat dateFormat;

+(MHPrettyDate*) sharedInstance;
-(NSDate* )      normalizeDate:(NSDate*) date;
-(BOOL)          isSameDay:(NSDate*) date as:(NSDate*) secondDate;

+(NSString*)     formattedStringForDate:(NSDate*) date withFormat:(MHPrettyDateFormat) dateFormat;

@end
    
@implementation MHPrettyDate

@synthesize calendar       = _calendar;
@synthesize yesterday      = _yesterday;
@synthesize tomorrow       = _tomorrow;
@synthesize weekAgo        = _weekAgo;

#pragma mark - get singleton
//
// singleton factory
//
+ (MHPrettyDate*)sharedInstance
{
    static          dispatch_once_t p           = 0;
    __strong static MHPrettyDate*   _singleton  = nil;
    
    dispatch_once(&p,
    ^{
        _singleton = [[self alloc] init];
    });
    return _singleton;
}

- (void)clearCache
{
    _tomorrow = nil;
    _today = nil;
    _yesterday = nil;
    _weekAgo = nil;
}

#pragma mark - worker methods

// this is a worker method
-(NSDate* ) normalizeDate:(NSDate*) date
{
    NSDateComponents* dateComponents = [self.calendar
                                        components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
                                        NSWeekdayCalendarUnit
                                        fromDate:  date];
    NSDate* returnDate = [self.calendar dateFromComponents:dateComponents];
    return returnDate;
}

-(NSDate* ) normalizeTime:(NSDate*) date
{
   NSDateComponents* dateComponents = [self.calendar
                                         components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
                                                     NSHourCalendarUnit | NSMinuteCalendarUnit
                                           fromDate: date];
   NSDate* returnDate = [self.calendar dateFromComponents:dateComponents];
   return returnDate;
}

 
-(NSComparisonResult) compareTimeFromNow:(NSDate*) compareDate
{
   NSDate *normalNow  = [self normalizeTime:[NSDate date]];
   NSDate *normalTest = [self normalizeTime:compareDate];
   
   return [normalNow compare:normalTest];
}

-(NSInteger) minutesFromNow:(NSDate*) compareDate
{
   return ([compareDate timeIntervalSinceNow] / 60);
}

-(NSInteger) hoursFromNow:(NSDate*) compareDate
{
   return ([compareDate timeIntervalSinceNow] / (60 * 60));
}

-(NSInteger) daysFromNow:(NSDate*) compareDate
{
   return ([compareDate timeIntervalSinceNow] / ((60 * 60) * 24));
}

-(BOOL) isSameDay:(NSDate*) date as:(NSDate*) secondDate
{
    NSDate* date1 = [self normalizeDate:date];
    NSDate* date2 = [self normalizeDate:secondDate];
    
    return [date1 isEqualToDate:date2];
}

+(NSString*) makePrettyDate:(NSDate*) date withFormat:(MHPrettyDateFormat) dateFormat
{
   NSString* dateString;
   
   switch (dateFormat)
   {
      case MHPrettyDateFormatWithTime:
      case MHPrettyDateFormatNoTime:
      case MHPrettyDateFormatTodayTimeOnly:
         dateString = [MHPrettyDate formattedStringForDate:date withFormat:dateFormat];
         break;
         
      case MHPrettyDateLongRelativeTime:
      case MHPrettyDateShortRelativeTime:
         dateString = [MHPrettyDate formattedStringForTime:date withFormat:dateFormat];
         break;
         
      default:
         dateString = @"Unsupported date format";
         break;
   }
   
   return dateString;
};

+(NSString*) formattedStringForTime:(NSDate*) date withFormat:(MHPrettyDateFormat) dateFormat
{
   NSString *dateString;
   
   // handle future date cases
   if ([MHPrettyDate isFutureTime: date])
   {
      if ((dateFormat == MHPrettyDateLongRelativeTime) || [MHPrettyDate isToday:date])
      {
         dateString = [MHPrettyDate formattedStringForDate:date withFormat:MHPrettyDateFormatWithTime];
      }
      else
      {
         dateString = [MHPrettyDate formattedStringForDate:date withFormat:MHPrettyDateFormatNoTime];
      }
   }
   else if ([MHPrettyDate isWithin24Hours:date])
   {
      MHPrettyDate *prettyDate = [MHPrettyDate sharedInstance];
      if ([MHPrettyDate isWithinHour: date])
      {
         // if within 60 minutes print minutes
         NSInteger minutes = [prettyDate minutesFromNow: date] * -1;
         NSString  *post;
         
         if (minutes == 0)
         {
            dateString = @"Now";
         }
         else
         {
            if (minutes == 1) post = (dateFormat == MHPrettyDateLongRelativeTime) ? @" minute ago" : @"m";
            else post = (dateFormat == MHPrettyDateLongRelativeTime) ? @" minutes ago" : @"m";
            dateString = [NSString stringWithFormat: @"%d%@", minutes, post];
         }
      }
      else
      {
         // else print hours
         NSInteger hours = [prettyDate hoursFromNow: date] * -1;
         NSString  *post;
         
         if (hours == 1) post = (dateFormat == MHPrettyDateLongRelativeTime) ? @" hour ago" : @"h";
         else post = (dateFormat == MHPrettyDateLongRelativeTime) ? @" hours ago" : @"h";
         dateString = [NSString stringWithFormat: @"%d%@", hours, post];
      }
   }
   else if ([MHPrettyDate isYesterday:date])
   {
      dateString = (dateFormat == MHPrettyDateLongRelativeTime) ? @"1 day ago" : @"1d";
   }
   else
   {
      MHPrettyDate *prettyDate = [MHPrettyDate sharedInstance];
      NSInteger days = [prettyDate daysFromNow: date] * -1;
      NSString  *post;
      
      post = (dateFormat == MHPrettyDateLongRelativeTime) ? @" days ago" : @"d";
      dateString = [NSString stringWithFormat: @"%d%@", days, post];
   }
   
   return dateString;
}

// TODO: this method needs to be refactored and localized
+(NSString*) formattedStringForDate:(NSDate*) date withFormat:(MHPrettyDateFormat) dateFormat
{
    NSString*        dateString;
    NSDateFormatter* formatter   = [[MHPrettyDate sharedInstance] dateFormatter];
    //
    // TODO: this needs to be localized
    //
    if ([MHPrettyDate willMakePretty:date])
    {
        if ([MHPrettyDate isTomorrow:date])
        {
            dateString = @"'Tomorrow'";
        }
        else if ([MHPrettyDate isToday:date])
        {
            dateString = @"'Today'";
        }
        else if ([MHPrettyDate isYesterday:date])
        {
            dateString = @"'Yesterday'";
        }
        else
        {
            dateString = @"EEEE";
        }
        
        // special case for MHPrettyDateFormatWithTime
        if (dateFormat == MHPrettyDateFormatWithTime)
        {
            // today show only time
            if ([MHPrettyDate isToday:date])
            {
               dateString = @"h:mm a";
            }
            else
            {
               // otherwise show date string and time
               dateString = [NSString stringWithFormat:@"%@ h:mm a", dateString];
            }
        }
        
        // special case for MHPrettyDateFormatTodayTimeOnly
        if (dateFormat == MHPrettyDateFormatTodayTimeOnly)
        {
            // today show only time
            if ([MHPrettyDate isToday:date])
            {
                dateString = @"h:mm a";
            }
        }
    }
    else
    {
        if (dateFormat == MHPrettyDateFormatWithTime)
        {
            dateString = @"MM/dd/yy h:mm a"; // bjw bugbugbug need to localize
        }
        else
        {
            //dateString = [NSDateFormatter dateFormatFromTemplate:@"MMddyy" options:0 locale:[NSLocale currentLocale]];
            dateString = @"MM/dd/yy";
        }
    }
    
    [formatter setDateFormat: dateString];
    
    return [formatter stringFromDate:date];
}


#pragma mark - accessors

// TODO: these methods can be refactored

- (void)sanitize
{
    if (_today) {
        if (![self isSameDay:_today as:[NSDate date]]) {
            [self clearCache];
        }
    }
}

//
// today is read/write (write is for testing only)
//

-(NSDate*) today
{
    [self sanitize];
    if (!_today)
    {
        _today = [self normalizeDate:[NSDate date]];
    }
    return _today;
}

// yesterday is today minus 1 day
-(NSDate*) yesterday
{
    [self sanitize];
    if (!_yesterday)
    {
        NSDateComponents* comps = [[NSDateComponents alloc] init];
        [comps setDay: -1];
        _yesterday = [self.calendar dateByAddingComponents:comps toDate:self.today options:0];
    }
    return _yesterday;
}

// yesterday is today minus 1 day
-(NSDate*) weekAgo
{
    [self sanitize];
    if (!_weekAgo)
    {
        NSDateComponents* comps = [[NSDateComponents alloc] init];
        [comps setDay: -6];
        _weekAgo = [self.calendar dateByAddingComponents:comps toDate:self.today options:0];
    }
    return _weekAgo;
}

// tomorrow is today plus 1 day
-(NSDate*) tomorrow
{
    [self sanitize];
    if (!_tomorrow)
    {
        NSDateComponents* comps = [[NSDateComponents alloc] init];
        [comps setDay: 1];
        _tomorrow = [self.calendar dateByAddingComponents:comps toDate:self.today options:0];
    }
    return _tomorrow;
}

// calendar
-(NSCalendar*) calendar
{
    if (!_calendar)
    {
       _calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    }
    return _calendar;
}

// nsdateformattter
-(NSDateFormatter*) dateFormatter
{
    if (!_dateFormatter)
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yy"];
        _dateFormatter = dateFormat;
    }
    return _dateFormatter;
}

#pragma mark - public methods

+(NSString*) prettyDateFromDate:(NSDate*) date withFormat:(MHPrettyDateFormat) dateFormat
{
    return [MHPrettyDate makePrettyDate:date withFormat:dateFormat];
}

+(BOOL) willMakePretty:(NSDate *)date
{
   return ([MHPrettyDate isTomorrow:date] || [MHPrettyDate isWithinWeek:date]);
}

#pragma mark - date relative
+(BOOL) isToday:(NSDate*) date
{
    MHPrettyDate* prettyDate = [MHPrettyDate sharedInstance];
    return [prettyDate isSameDay:date as:prettyDate.today];
};

+(BOOL) isTomorrow:(NSDate*) date
{
    MHPrettyDate* prettyDate = [MHPrettyDate sharedInstance];
    return [prettyDate isSameDay:date as:prettyDate.tomorrow];
};

+(BOOL) isYesterday:(NSDate*) date
{
    MHPrettyDate* prettyDate = [MHPrettyDate sharedInstance];
    return [prettyDate isSameDay:date as:prettyDate.yesterday];
};

+(BOOL) isFutureDate:(NSDate *) date
{
   MHPrettyDate* prettyDate  = [MHPrettyDate sharedInstance];
   NSDate*       compareDate = [prettyDate normalizeDate:date];
   
   return ([prettyDate.today compare:compareDate] == NSOrderedAscending);
}

+(BOOL) isPastDate:(NSDate *) date
{
   MHPrettyDate* prettyDate  = [MHPrettyDate sharedInstance];
   NSDate*       compareDate = [prettyDate normalizeDate:date];
   
   return ([prettyDate.today compare:compareDate] == NSOrderedDescending);
}

+(BOOL) isWithinWeek:(NSDate*) date;
{
    MHPrettyDate* prettyDate   = [MHPrettyDate sharedInstance];
    NSDate*       today        = prettyDate.today;
    NSDate*       weekAgo      = prettyDate.weekAgo;
    NSDate*       testDate     = [prettyDate normalizeDate:date];
    BOOL          isWithinWeek = NO;

    if ([prettyDate isSameDay:testDate as:weekAgo] || [prettyDate isSameDay:testDate as:today])
    {
        isWithinWeek = YES;
    }
    else
    {
        NSDate* earlierDate = [testDate earlierDate: today];
        NSDate* laterDate   = [testDate laterDate:   weekAgo];
        
        isWithinWeek = ([testDate isEqualToDate:earlierDate] && [testDate isEqualToDate:laterDate]);
    }
    
    return isWithinWeek;
}

#pragma mark - time relative

+(BOOL) isNow:(NSDate*) date
{
   MHPrettyDate* prettyDate   = [MHPrettyDate sharedInstance];
   return ([prettyDate compareTimeFromNow:date] == NSOrderedSame);
}

+(BOOL) isFutureTime:(NSDate*) date
{
   MHPrettyDate* prettyDate   = [MHPrettyDate sharedInstance];
   return ([prettyDate compareTimeFromNow:date] == NSOrderedAscending);
}

+(BOOL) isPastTime:(NSDate*) date
{
   MHPrettyDate* prettyDate   = [MHPrettyDate sharedInstance];
   return ([prettyDate compareTimeFromNow:date] == NSOrderedDescending);
}

+(BOOL) isWithin24Hours:(NSDate*) date
{
   MHPrettyDate* prettyDate   = [MHPrettyDate sharedInstance];
   return ([prettyDate daysFromNow:date] == 0);
}

+(BOOL) isWithinHour:(NSDate*) date
{
   MHPrettyDate* prettyDate   = [MHPrettyDate sharedInstance];
   return ([prettyDate hoursFromNow:date] == 0);
}


#pragma mark -
@end
