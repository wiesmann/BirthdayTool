/*
 *  BirthDayTool.m
 *  BirthdayTool
 *
 *  Created by Matthias Wiesmann on 11.03.05.
 *  Copyright 2005 Matthias Wiesmann. All rights reserved.
 *
 */

#include <sysexits.h>
#include "BirthdayTool.h"

NSString * ics_date_format = @"%Y%m%d" ;
NSString * birthday_title_format_key = @"birthday_title" ; 
NSString * calendar_title_format_key = @"calendar_title" ; 
NSString * birthday_text_format_key =  @"birthday_text" ; 
NSString * date_format_key = @"birth_date" ; 

NSString * default_birthday_title_format = @"Birthday of %@ %@" ;
NSString * default_calendar_title_format = @"Birthdays in %@ %@'s Address Book" ; 
NSString * default_birthday_text_format = @"Birth date: %@" ; 
NSString * default_date_format = @"%A %d %B %Y" ; 

NSString * usage_format = @"usage: %@ [-o outfile] [%@ birthday-title] [%@ calendar-title] [%@ birthday-text] [%@ date-format]\nCurrent patterns: %@" ; 

@implementation BirthDayTool


+ (NSMutableDictionary *) defaultDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 10] ; 
    [dict setObject: default_birthday_title_format forKey: birthday_title_format_key] ; 
    [dict setObject: default_calendar_title_format forKey: calendar_title_format_key] ; 
    [dict setObject: default_birthday_text_format forKey: birthday_text_format_key] ; 
    [dict setObject: default_date_format forKey: date_format_key] ;    
    return dict ; 
} // defaultDictionary


+ (void) printUsage: (NSString *) program_name withDictionary: (NSDictionary *) dict {
    NSString * usage_text = [NSString stringWithFormat: usage_format,program_name,birthday_title_format_key,calendar_title_format_key,birthday_text_format_key,date_format_key,dict] ; 
    printf("%s\n", [usage_text UTF8String]) ; 
} // printUsage


- (id) init: (NSDictionary *) dict {
    dictionary = dict ; 
    [dictionary retain] ; 
    out_file = stdout ; 
    return self ; 
} // 

- (void) setStream: (FILE *) stream {
    out_file = stream ; 
} // setStream

- (void) export {
    ABAddressBook *ABook = [ABAddressBook sharedAddressBook];
    NSArray *everyone = [ABook people] ;
    ABPerson *me = [ABook me] ; 
    unsigned int i ; 
    fprintf(out_file,"BEGIN:VCALENDAR\nVERSION:2.0\n");
    NSString * description = [NSString stringWithFormat: [dictionary objectForKey: calendar_title_format_key], [me valueForProperty: kABFirstNameProperty], [me valueForProperty: kABLastNameProperty]] ; 
    fprintf(out_file,"X-WR-CALDESC:%s\n",[description UTF8String]); 
    for(i=0;i<[everyone count];i++) {
	ABPerson * person = [everyone objectAtIndex: i] ; 
	[self export: person] ; 
    } // for
    fprintf(out_file,"END:VCALENDAR");
} // export 

- (void) export: (ABPerson*) person {
    NSDate *birthday = [person valueForProperty: kABBirthdayProperty] ;
    if (birthday) {
	[self export: person born: birthday] ; 
    } // birthday present 
} // export person

- (void) export: (ABPerson*) person born: (NSDate *) birthday {
    NSDate *end_day = [NSDate alloc] ;
    [end_day initWithTimeInterval:  60*60*24 sinceDate:birthday] ;
    NSString * first_name = [person valueForProperty: kABFirstNameProperty] ; 
    if (first_name==nil) first_name = @"" ; 
    NSString * last_name = [person valueForProperty: kABLastNameProperty] ; 
    if (last_name==nil) last_name = @"" ; 
    NSString * start_date = [birthday descriptionWithCalendarFormat: ics_date_format timeZone:nil locale:nil] ; 
    NSString * end_date = [end_day descriptionWithCalendarFormat: ics_date_format timeZone:nil locale:nil] ; 
    ABMultiValue *emails = [person valueForProperty: kABEmailProperty] ;
    NSString * email = [emails valueAtIndex: [emails indexForIdentifier: [emails primaryIdentifier]]] ; 
    if (email==nil) email = @"" ; 
    NSString * homepage = [person valueForProperty: kABHomePageProperty] ;
    NSString * pretty_birth_date = [birthday descriptionWithCalendarFormat: [dictionary objectForKey: date_format_key] timeZone: nil locale: nil] ;
    NSString * main_text = [NSString stringWithFormat: [dictionary objectForKey: birthday_text_format_key], pretty_birth_date] ; 
    NSString * description = [NSString stringWithFormat: [dictionary objectForKey: birthday_title_format_key], first_name, last_name] ; 
    fprintf(out_file,"BEGIN:VEVENT\nRRULE:FREQ=YEARLY;INTERVAL=1\n");
    fprintf(out_file,"DTSTART;VALUE=DATE:%s\n",[start_date UTF8String]); 
    fprintf(out_file,"DTEND;VALUE=DATE:%s\n",[end_date UTF8String]); 
    fprintf(out_file,"SUMMARY:%s\n",[description UTF8String]);
    fprintf(out_file,"ATTENDEE;CN=\"%s %s\":%s\n",[first_name UTF8String],[last_name UTF8String],[email UTF8String] );
    if (homepage) {
	fprintf(out_file,"URL;VALUE=URI:%s\n",[[homepage stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding] UTF8String]);
    } // homepage
    fprintf(out_file,"DESCRIPTION:%s\n",[main_text UTF8String]) ; 
    fprintf(out_file,"END:VEVENT\n");
    [end_day autorelease] ; 
} // export

@end

void print_usage(NSString *program_name) {
 
} // print_usage

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* dictionary = [BirthDayTool defaultDictionary] ; 
    NSString *program = [NSString stringWithUTF8String:argv[0]] ; 
    FILE *out_file = stdout; 
    int close_file = 0 ; 
    int i = 1 ; 
    while(i<argc) {
	if (strcmp(argv[i],"-help")==0) {
	    print_usage(program) ;
	    exit(0) ; 
	} else if (strcmp(argv[i],"-o")==0) {
	    if (i+1<argc) {
		const char* file_name = argv[i+1] ; 
		out_file = fopen(file_name,"w");
		if (! out_file) {
		    char buffer[256] ; 
		    snprintf(buffer,sizeof(buffer),"cannot open \"%s\"",file_name);
		    perror(buffer);
		    exit(EX_IOERR);
		} // open file failed 
		close_file = 1 ; 
		i+=2 ; 
	    } else {
		print_usage(program) ;
		exit(EX_USAGE) ; 
	    } // missing filename 
	} else  {
	    NSString *key = [NSString stringWithUTF8String:argv[i]]  ;
	    if (i+1>=argc) {
		[BirthDayTool printUsage: program withDictionary: dictionary] ; 
		exit(EX_USAGE) ; 
	    } // if
	    NSString *value = [NSString stringWithUTF8String:argv[i+1]] ; 
	    [dictionary setObject: value forKey: key] ; 
	    i+=2 ; 
	} // else 
    } //
    BirthDayTool *tool = [[BirthDayTool alloc] init: dictionary] ; 
    [tool setStream: out_file] ; 
    [tool export] ; 
    if (close_file) { fclose(out_file) ; } 
    [pool release];
    return 0;
} // main 
