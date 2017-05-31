/*
 *  BirthDayTool.h
 *  BirthdayTool
 *
 *  Created by Matthias Wiesmann on 11.03.05.
 *  Copyright 2005 Matthias Wiesmann. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@interface BirthDayTool : NSObject {
    NSDictionary * dictionary  ; 
    FILE *out_file ; 
} 

+ (NSMutableDictionary *) defaultDictionary ; 
+ (void) printUsage: (NSString *) program_name withDictionary: (NSDictionary *) dict ; 

- (id) init: (NSDictionary *) dict ; 
- (void) setStream: (FILE *) stream ; 

- (void) export ;
- (void) export: (ABPerson*) person ; 
- (void) export: (ABPerson*) person born: (NSDate *) birthday; 

@end