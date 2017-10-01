//
//  MIDIStream.h
//  BassMidiTest
//
//  Created by kazu on 2017/04/25.
//  Copyright © 2017年 kazu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bassmidi.h"

@interface MIDIStream : NSObject{
 //   HSTREAM *streamHandle;
    NSString *fullPath;
    NSString *fileName;
    NSString *songName;
    NSString *copyrightInfo;
  //unsigned int *handle;
}

//@property(readonly,nonatomic,nullable) HSTREAM *stereamHandle;
@property(readonly,nonatomic,nullable) NSString  *fullPath;
@property(readonly,nonatomic,nullable) NSString  *fileName;
@property(readonly,nonatomic,nullable) NSString  *songName;
@property(readonly,nonatomic,nullable) NSString  *copyrightInfo;
//@property(readonly,nonatomic,nullable) unsigned  int *handle;
+(id _Nullable )initMyClass;
+(unsigned int)HiWord:(unsigned int)Dword;
+(unsigned int)LoWord:(unsigned int)Dword;
-(BOOL)hasStream;
-(unsigned int)GetMyHandle;
-(void)setFlag:(unsigned int)flag;
-(void)cancelFlag:(unsigned int)flag;
-(BOOL)Load: (NSString*_Nonnull)FilePath;
-(BOOL)Play;
-(void)StopAndRewind;
-(void)Pause;
-(unsigned int)GetLevel;
-(void)ReleaseCurrentSoundFont;
-(BOOL)SetSoundFont:(HSOUNDFONT*_Nonnull)sf;
-(NSInteger)GetCurrentPosition;
-(NSInteger)GetStreamLength;
-(NSInteger)SetCurrentPosition:(int)val;
-(NSInteger)GetCurrentCpuLoad;
-(NSInteger)GetCurrentPolyphony;
-(void)SetVolume:(float)vol;
-(void)SetMaxCpuLoad:(float)cpuLoad;
-(void)SetMaxPp:(float)polyphony;
-(int)UpdateData;
-(float)GetUpdatedData:(int)address;
@end
