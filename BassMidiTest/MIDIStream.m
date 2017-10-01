//
//  MIDIStream.m
//  BassMidiTest
//
//  Created by kazu on 2017/04/25.
//  Copyright © 2017年 kazu. All rights reserved.
//

#import "MIDIStream.h"
#import "bass.h"
#import "bassmidi.h"

@implementation MIDIStream

unsigned int streamHandle;
unsigned int streamFlags=BASS_MIDI_DECAYEND;
int numTracks;
HSOUNDFONT sfHandle=0;
BASS_MIDI_FONT f;

float sfVol=1.0;
float maxCpu=70;
float maxPp=100;
float data[512];

+(id)initMyClass{
  return [[self alloc] init];
}

+(unsigned int)HiWord:(unsigned int)Dword{
  return Dword&4294901760;
}
+(unsigned int)LoWord:(unsigned int)Dword{
  return Dword&65535;
}
-(BOOL)hasStream{
  return streamHandle!=0;
}
-(unsigned int)GetMyHandle{
  return streamHandle;
}
-(void)setFlag:(unsigned int)flag{
  streamFlags=streamFlags|flag;
  [self applyFlag];
}
-(void)cancelFlag:(unsigned int)flag{
  streamFlags=streamFlags&~(flag);
  [self applyFlag];
}
-(void)applyFlag{
  if([self hasStream]){
    BASS_ChannelFlags(streamHandle, streamFlags, streamFlags);
  }
}

-(BOOL)Load:(NSString*)FilePath{
  float d;
  int tks=0;
  
  //release old resource
  if(streamHandle!=0){
    BASS_StreamFree(streamHandle);
  }
  
  
  streamHandle=BASS_MIDI_StreamCreateFile(false,[FilePath UTF8String], 0, 0, streamFlags, 1);

  //Get the song name
  BASS_MIDI_MARK mk;
  BASS_MIDI_StreamGetMark(streamHandle, BASS_MIDI_MARK_TRACK, 0, &mk);
  songName=[NSString stringWithFormat:@"%s", mk.text];
  
  //If already soundfont is set
  if(sfHandle!=0){
    BASS_MIDI_StreamSetFonts(streamHandle, &f, 1);
    [self SetVolume:sfVol];
  }

  [self SetMaxPp:maxPp];
  [self SetMaxCpuLoad:maxCpu];
  
  
  while(BASS_ChannelGetAttribute(streamHandle, BASS_ATTRIB_MIDI_TRACK_VOL+tks, &d)){
    tks++;
  }
  numTracks=tks;

  return streamHandle!=0;
}

-(BOOL)Play{
  //NSLog(@"Position: %llu",BASS_ChannelGetPosition(streamHandle,BASS_POS_MIDI_TICK));
  return BASS_ChannelPlay(streamHandle, false);
}

-(void)StopAndRewind{
    BASS_ChannelStop(streamHandle);
    BASS_ChannelSetPosition(streamHandle, 0,BASS_POS_MIDI_TICK);
}

-(void)Pause{
  BASS_ChannelPause(streamHandle);
}

-(unsigned int)GetLevel{
  return BASS_ChannelGetLevel(streamHandle);
}
-(void)ReleaseCurrentSoundFont{
  if(sfHandle!=0){
    BASS_MIDI_FontFree(sfHandle);
  }
}

-(BOOL)SetSoundFont:(HSOUNDFONT *)sf{
  sfHandle=*sf;
  f.font=*sf;
  f.preset=-1;
  f.bank=0;
  [self SetVolume:sfVol];
  if(streamHandle!=0){
   return BASS_MIDI_StreamSetFonts(streamHandle, &f, 1);
  }else{
    return 1;
  }
}

-(NSInteger)GetCurrentPosition{
  return BASS_ChannelGetPosition(streamHandle,BASS_POS_MIDI_TICK)/120;
}
-(NSInteger)SetCurrentPosition:(int)val{
  return BASS_ChannelSetPosition(streamHandle, val*120, BASS_POS_MIDI_TICK|BASS_MIDI_DECAYSEEK);
}
-(NSInteger)GetStreamLength{
  return BASS_ChannelGetLength(streamHandle, BASS_POS_MIDI_TICK)/120;
}
-(NSInteger)GetCurrentCpuLoad{
  return BASS_GetCPU();
}
-(NSInteger)GetCurrentPolyphony{
  float cv = 0.0;
  BASS_ChannelGetAttribute(streamHandle, BASS_ATTRIB_MIDI_VOICES_ACTIVE, &cv);
  return (NSInteger)cv;
}
-(void)SetVolume:(float)vol{
  sfVol=vol;
  NSLog(@"Volume is set to: %lf",vol);
  //for(int i=0;i<numTracks;i++){
    //BASS_ChannelSetAttribute((DWORD)streamHandle, BASS_ATTRIB_MIDI_TRACK_VOL+i, vol);
  //}
  BASS_MIDI_FontSetVolume(sfHandle, sfVol);
}
-(void)SetMaxCpuLoad:(float)cpuLoad{
  maxCpu=cpuLoad;
  BASS_ChannelSetAttribute(streamHandle, BASS_ATTRIB_MIDI_CPU, maxCpu);
  NSLog(@"CPU Load is set to: %lf - %d",(float)cpuLoad,BASS_ErrorGetCode());
}
-(void)SetMaxPp:(float)polyphony{
  maxPp=polyphony;
  BASS_ChannelSetAttribute(streamHandle, BASS_ATTRIB_MIDI_VOICES, maxPp);
}
-(int)UpdateData{
  int n=BASS_ChannelGetData(streamHandle,&data , BASS_DATA_FLOAT);
  NSLog(@"BASS_UpdateData length: %d Error: %d",n,BASS_ErrorGetCode());
  return n;
}
-(float)GetUpdatedData:(int)address{
  return data[address];
}

@synthesize fullPath,fileName,songName,copyrightInfo;
@end
  
