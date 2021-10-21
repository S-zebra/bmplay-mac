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
NSInteger lastErrorCode;

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
    unsigned char* s;
    printf("Title dump: ");

    for(s = &mk.text[0]; *s != '\0'; s++){
      printf("%x ", *s);
    }
    puts("");
    self.songName = [NSString stringWithCString:mk.text encoding:NSShiftJISStringEncoding];
  }
  NSLog(@"%@", self.songName);
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
-(NSInteger)GetCurrentPositionBytes{
  return BASS_ChannelGetPosition(streamHandle, BASS_POS_BYTE);
}
-(NSInteger)GetStreamLengthBytes{
  return BASS_ChannelGetLength(streamHandle, BASS_POS_BYTE);
}
-(float)GetCurrentCpuLoad{
  float load = 0.0;
  BASS_ChannelGetAttribute(streamHandle, BASS_ATTRIB_CPU, &load);
  return load;
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
-(NSInteger)GetLastError{
  return lastErrorCode;
}
-(NSInteger)Export:(NSURL*)file{
  [self SetCurrentPosition: 0];

  AudioStreamBasicDescription format;
  format.mFormatID = kAudioFormatLinearPCM;
  format.mSampleRate = 44100;
  format.mBitsPerChannel = 32;
  format.mFormatFlags = kAudioFormatFlagIsFloat | kLinearPCMFormatFlagIsPacked;
  format.mChannelsPerFrame = 2;
  format.mBytesPerFrame = 8;
  format.mFramesPerPacket = 1; // 1 for PCM
  format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket;

  ExtAudioFileRef outRef = NULL;
  lastErrorCode = ExtAudioFileCreateWithURL((__bridge CFURLRef)file, kAudioFileWAVEType, &format,
                                                  NULL, 0, &outRef);
  if (lastErrorCode != noErr){
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:lastErrorCode userInfo:nil];
    NSLog(@"Cannot open output file: %@", [error description]);
    return lastErrorCode;
  }
  SInt64 wroteBytes = 0;
  BASS_ChannelUpdate(streamHandle, 0);
  uint32 availableBytes;
  uint8_t* buffer = NULL;
  int64_t curPos = 0;
  while((lastErrorCode = (NSInteger)BASS_ErrorGetCode()) == 0){
    BASS_ChannelUpdate(streamHandle, 0);
    availableBytes = BASS_ChannelGetData(streamHandle, NULL, BASS_DATA_AVAILABLE);
    printf("%u bytes available\n", availableBytes);
    buffer = (uint8_t *)realloc(buffer, availableBytes); // realloc for NULL is equivalent to malloc
    if(buffer == NULL){
      fprintf(stderr, "Cannot allocate memory for buffer!\n");
      free(buffer);
      ExtAudioFileDispose(outRef);
      lastErrorCode = (NSInteger)errno;
      return lastErrorCode;
    }
    memset(buffer, 0, availableBytes);
    BASS_ChannelGetData(streamHandle, buffer, availableBytes);
    AudioBufferList bufList;
    bufList.mNumberBuffers = 1;
    bufList.mBuffers[0].mNumberChannels = 2;
    bufList.mBuffers[0].mDataByteSize = availableBytes;
    bufList.mBuffers[0].mData = buffer;
    lastErrorCode = ExtAudioFileWrite(outRef, availableBytes / 8, &bufList);
    if(lastErrorCode != noErr) {
      NSError* error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                           code:lastErrorCode userInfo:nil];
      NSLog(@"Write error: %@", [error description]);
      return lastErrorCode;
    }
    curPos = BASS_ChannelGetPosition(streamHandle, BASS_POS_BYTE);
    BASS_ChannelSetPosition(streamHandle, curPos + availableBytes, BASS_POS_BYTE | BASS_POS_DECODETO);
  }
  free(buffer);
  ExtAudioFileDispose(outRef);
  return lastErrorCode;
}

@synthesize fullPath,fileName,songName,copyrightInfo;
@end
