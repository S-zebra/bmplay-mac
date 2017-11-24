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

}

//@property(readonly,nonatomic,nullable) HSTREAM *stereamHandle;
@property(nonatomic,nullable) NSString  *fullPath;
@property(nonatomic,nullable) NSString  *fileName;
@property(nonatomic,nullable) NSString  *songName;
@property(nonatomic,nullable) NSString  *copyrightInfo;
@property(nonatomic,nullable) BASS_MIDI_FONTINFO *SoundFontInfo;
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
-(void)LoadSoundFont:(NSString *_Nonnull)Path;
-(BOOL)SetSoundFont;
//-(void)GetSoundFontInfo;
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
