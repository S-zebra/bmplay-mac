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
#import <AudioToolbox/ExtendedAudioFile.h>

@implementation MIDIStream

HSTREAM streamHandle;
//デフォルトフラグ
unsigned int streamFlags=BASS_MIDI_DECAYEND|BASS_SAMPLE_FLOAT;
int numTracks;
HSOUNDFONT sfHandle=0;
BASS_MIDI_FONT SoundFonts[1];
BASS_MIDI_FONTINFO SFInfo;

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
    BASS_ChannelFlags(streamHandle, streamFlags, INT_MAX);
  }
}

-(BOOL)Load:(NSString*)FilePath{
  float d;
  int tks=0;

  //release old resource
  if(streamHandle!=0){
    BASS_StreamFree(streamHandle);
  }
  streamHandle=BASS_MIDI_StreamCreateFile(false, [[FilePath stringByRemovingPercentEncoding] UTF8String], 0, 0, streamFlags, 1);
  NSLog(@"%@ Result: %d", [FilePath stringByRemovingPercentEncoding], BASS_ErrorGetCode());
  NSLog(@"Pointer: %X", streamHandle);

  //Get the song name
  BASS_MIDI_MARK mk;
  BASS_MIDI_StreamGetMark(streamHandle, BASS_MIDI_MARK_TRACK, 0, &mk);
  if(mk.text==NULL||strlen(mk.text)==0){
    self.songName=@"(NO TITLE)";
  }else{
    self.songName=[NSString stringWithFormat:@"%s", mk.text];
    char* s;
    for(s = &mk.text[0]; *s != '\0'; s++){
      NSLog(@"0x%x", *s);
    }

  }

  //If the stream already has a soundfont
  if(sfHandle!=0){
    [self SetSoundFont];
  }

  [self SetMaxPp:maxPp];
  [self SetMaxCpuLoad:maxCpu];

  while(BASS_ChannelGetAttribute(streamHandle, BASS_ATTRIB_MIDI_TRACK_VOL+tks, &d)){
    tks++;
  }
  numTracks=tks;
  NSLog(@"%d tracks", numTracks);
  return streamHandle!=0;
}

-(BOOL)Play{
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

-(void)LoadSoundFont:(NSString*)Path{
  NSLog(@"%s", [Path UTF8String]);
  if (sfHandle != 0) {
    BASS_MIDI_FontFree(sfHandle);
  }
  sfHandle=BASS_MIDI_FontInit([Path UTF8String], 0);
  BASS_MIDI_FontGetInfo(sfHandle, &SFInfo);
  _SoundFontInfo=&SFInfo;
  [self SetSoundFont];
}

-(BOOL)SetSoundFont{
  if(sfHandle!=0){
    SoundFonts[0].font=sfHandle;
    SoundFonts[0].preset=-1;
    SoundFonts[0].bank=0;
    [self SetVolume:sfVol];
    if(streamHandle!=0){
      BASS_MIDI_FontLoad(sfHandle, -1, -1);
      return BASS_MIDI_StreamSetFonts(streamHandle, &SoundFonts, 1);
    }else{
      return 1;
    }
  }else{
    NSLog(@"SoundFont is not loaded, or error.");
    return false;
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
  BASS_MIDI_FontSetVolume(sfHandle, sfVol);
}
-(void)SetMaxCpuLoad:(float)cpuLoad{
  maxCpu=cpuLoad;
  BASS_ChannelSetAttribute(streamHandle, BASS_ATTRIB_MIDI_CPU, maxCpu);
  NSLog(@"CPU Load is set to: %lf - %d", (float)cpuLoad, BASS_ErrorGetCode());
}
-(void)SetMaxPp:(float)polyphony{
  maxPp=polyphony;
  BASS_ChannelSetAttribute(streamHandle, BASS_ATTRIB_MIDI_VOICES, maxPp);
}
-(void)Export:(NSString*)file{
  [self SetCurrentPosition: 0];

  AudioStreamBasicDescription format;
  format.mFormatID = kAudioFormatLinearPCM;
  format.mSampleRate = 44100;
  format.mBitsPerChannel = 32;
  format.mFormatFlags = kAudioFormatFlagIsFloat;
  format.mChannelsPerFrame = 2;
  format.mBytesPerFrame = 8;
  format.mFramesPerPacket = 4;
  format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket;

  ExtAudioFileRef outRef = NULL;
  OSStatus ref = ExtAudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:file],
                                           kAudioFileWAVEType, &format, NULL, 0, &outRef);
  SInt64 wroteBytes = 0;
//  ExtAudioFileSetProperty(outRef, ExtAudioFilePropertyID inPropertyID, <#UInt32 inPropertyDataSize#>, <#const void * _Nonnull inPropertyData#>)
  while(BASS_ErrorGetCode() == BASS_OK){
    uint32 availableBytes = BASS_ChannelGetData(streamHandle, NULL, BASS_DATA_FLOAT);
    uint8_t *data = (uint8_t *)malloc(availableBytes);

    free(data);
  }
}

@synthesize fullPath,fileName,songName,copyrightInfo;
@end
