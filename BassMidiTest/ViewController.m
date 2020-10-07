//
//  ViewController.m
//  BassMidiTest
//
//  Created by kazu on 2017/04/23.
//  Copyright © 2017 s-zebra. All rights reserved.
//

#import "ViewController.h"
#import "bass.h"
#import "bassmix.h"
#import "MIDIStream.h"
#import <CoreMIDI/CoreMIDI.h>
#import <CoreMIDI/MIDIServices.h>
#import <CoreMIDI/MIDISetup.h>

@implementation ViewController
MIDIClientRef midiClient;
MIDIPortRef midiPortInput;
MIDIStream *myStream;
NSTimer *_timer;
NSOpenPanel *openWindow;
NSArray *typeMidi,*typeSF2;
bool exporting = false;
NSInteger PreviousCPULimit;

- (void)viewDidLoad {
  [super viewDidLoad];

  typeMidi=[NSArray arrayWithObjects:@"mid",@"midi" ,nil];
  typeSF2=[NSArray arrayWithObjects:@"sf2",@"sfz", nil];
  openWindow=[NSOpenPanel new];

  BOOL res=BASS_Init(-1, 44100, 0, NULL, NULL);
  BASS_SetConfig(BASS_CONFIG_UPDATETHREADS, 2);
  NSLog(@"Bass Init: %s",res?"OK":"NG");
  PreviousCPULimit = [CpuMaxSlider intValue];
  // Do any additional setup after loading the view.
}

-(IBAction)MidiFileOpenBtnClicked:(id)sender{
  [openWindow setAllowedFileTypes: typeMidi];

  NSURL *filePath;
  NSString *fpString;
  if ([openWindow runModal] == NSModalResponseOK) {
    filePath = [openWindow URL];
    fpString=[filePath.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];

    if(![myStream hasStream]){
      myStream=[MIDIStream new];
    }
    [myStream Load:fpString];

    if([myStream hasStream]){
      // On Success
      [MidiFilePathLbl setStringValue:[NSString stringWithFormat:@"%@ - %@",myStream.songName,[filePath lastPathComponent]]];
    }else{
      //On Error
      [MidiFilePathLbl setStringValue:[@"Error: " stringByAppendingString:[NSString stringWithFormat: @"%d",BASS_ErrorGetCode()]]];
      NSLog(@"Bass error code: %d",BASS_ErrorGetCode());
    }
    [SongPositionSlider setMaxValue:[myStream GetStreamLength]];
    [PBExport setMaxValue:[myStream GetStreamLengthBytes]];
  }
}

-(IBAction)SfReplaceBtnClicked:(id)sender{
  [openWindow setAllowedFileTypes:typeSF2];
  NSURL *Url;
  NSString *Path;
  BASS_MIDI_FONTINFO *fi;
  if([openWindow runModal]==NSModalResponseOK){
    Url=openWindow.URL;
    Path=[[Url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    if(myStream==nil){
      myStream=[MIDIStream new];
    }
    [myStream LoadSoundFont:Path];
    fi=myStream.SoundFontInfo;

    if (BASS_ErrorGetCode()==0){
      [SfNameLbl setStringValue:[NSString stringWithCString: fi->name encoding:NSUTF8StringEncoding]];
      NSLog(@"SoundFont OK,　name: %s, loaded %d",fi->name,fi->samload);
    }else{
      NSLog(@"SoundFont Error: %d",BASS_ErrorGetCode());
    }
  }
}

-(IBAction)PpMaxSliderSlided:(id)sender{
  int a=(int)[PpMaxSlider integerValue];
  [PpMaxLbl setStringValue:[NSString stringWithFormat:@"%d",a]];
  [PpCurBar setMaxValue:(double)a];
  [myStream SetMaxPp:a];
}

-(void)ApplyCpuMaxLoad:(NSInteger)value{
  [CpuMaxSlider setFloatValue:value];
  if(value == 101){
    [CpuMaxLbl setStringValue:@"--"];
    [myStream SetMaxCpuLoad:0];
  }else{
    [CpuMaxLbl setStringValue:[NSString stringWithFormat:@"%ld", value]];
    [myStream SetMaxCpuLoad:value];
  }
}
-(IBAction)CpuMaxSliderSlided:(id)sender{
  NSInteger sliderValue = [CpuMaxSlider intValue];
  [self ApplyCpuMaxLoad:sliderValue];
  PreviousCPULimit = sliderValue;
}

-(IBAction)PlayPauseBtnToggled:(id)sender{
  if([PlayPauseBtn state]==NSOnState){
    NSLog(@"Play: %d",[myStream Play]);
    NSLog(@"Started playing: %d",BASS_ErrorGetCode());
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.064 target:self selector:@selector(time:) userInfo:nil repeats:YES];
  }else{
    [myStream Pause];
  }
}

-(IBAction)SongPositionSliderSlided:(id)sender{
  [myStream SetCurrentPosition:(int)[SongPositionSlider integerValue]];
}

-(IBAction)VolSliderChanged:(id)sender{
  float val=[VolSlider doubleValue];
  [CurVolLbl setStringValue:[NSString stringWithFormat:@"%d",(int)val]];
  val/=100;
  [myStream SetVolume:val];
}

-(IBAction)time:(NSTimer*)timer{
  long curpp;
  unsigned int lev=[myStream GetLevel];
  curpp=(long)[myStream GetCurrentPolyphony];
  float curcpu = [myStream GetCurrentCpuLoad];
  [PBExport setDoubleValue:[myStream GetCurrentPositionBytes]];
  [SongPositionSlider setDoubleValue:[myStream GetCurrentPosition]];

  [Level_L setDoubleValue:(double)abs(LoWord(lev))];
  [Level_R setDoubleValue:(double)abs(HiWord(lev))];
  [PpCurLbl setStringValue:[NSString stringWithFormat:@"%ld",curpp]];
  [CpuCurLbl setStringValue:[NSString stringWithFormat:@"%d", (int)curcpu]];
  [PpCurBar setDoubleValue:(double)curpp];
  [CpuCurBar setDoubleValue:(double)curcpu];
  NSLog(@"Byte Position: %ld, Length: %ld", [myStream GetCurrentPositionBytes], [myStream GetStreamLengthBytes]);
  NSLog(@"Position: %ld, Length: %ld", [myStream GetCurrentPosition], [myStream GetStreamLength]);
  if((exporting && [myStream GetLastError] == BASS_ERROR_ENDED) ||
     ([myStream GetCurrentPositionBytes] == [myStream GetStreamLengthBytes])){
    [self StopBtnClicked:nil];
  }
}

-(IBAction)StopBtnClicked:(id)sender{
  [PlayPauseBtn setState:NSOffState];
  [myStream StopAndRewind];
  [_timer invalidate];

  [SongPositionSlider setDoubleValue:0.0];
  [PpCurLbl setStringValue:[NSString stringWithFormat:@"%d",0]];
  [CpuCurLbl setStringValue:[NSString stringWithFormat:@"%d",0]];
  [PpCurBar setDoubleValue:0.0];
  [CpuCurBar setDoubleValue:0.0];
  [Level_L setDoubleValue:0.0];
  [Level_R setDoubleValue:0.0];
  [PositionLabel setStringValue:@"Position"];
  [SongPositionSlider setHidden:false];
  [PBExport setHidden:true];
  [ExportButton setEnabled:true];
  [PlayPauseBtn setEnabled:true];
  [StopButton setEnabled:true];
  [MIDIFileOpenButton setEnabled:true];
  [SFReplaceButton setEnabled:true];
  exporting = false;
  [self ApplyCpuMaxLoad:PreviousCPULimit];
}
-(IBAction)FXCheckChanged:(id)sender{
  if([FXCheckBox state]==NSOnState){
    NSLog(@"FX On");
    [myStream cancelFlag:BASS_MIDI_NOFX];
  }else if([FXCheckBox state]==NSOffState){
    [myStream setFlag:BASS_MIDI_NOFX];
    NSLog(@"FX Off");
  }
}
-(void)ExportTimerTicked:(NSTimer*)timer {
  [self time:_timer];
  NSInteger ErrCode = [myStream GetLastError];
  if (ErrCode != noErr) {
    NSAlert* dialog = [NSAlert new];
    [dialog setMessageText:@"Export Failed"];
    [dialog setInformativeText:[NSString stringWithFormat:@"Error %ld has occurred.", (long)ErrCode]];
    [dialog setAlertStyle:NSAlertStyleCritical];
    [dialog runModal];
  }
}
-(IBAction)ExportBtnClicked:(id)sender{
  NSSavePanel* savePanel = [NSSavePanel new];
  [savePanel setAllowedFileTypes:[NSArray arrayWithObjects: @"wav", nil]];
  if([savePanel runModal] != NSModalResponseOK){
    return;
  }
  [ExportButton setEnabled:false];
  [PlayPauseBtn setEnabled:false];
  [StopButton setEnabled:false];
  [MIDIFileOpenButton setEnabled:false];
  [SFReplaceButton setEnabled:false];
  [self ApplyCpuMaxLoad:101];
  [myStream SetMaxPp:[PpMaxSlider intValue]];
  [myStream performSelectorInBackground:@selector(Export:) withObject:[savePanel URL]];
  exporting = true;
  [SongPositionSlider setHidden:true];
  [PBExport setHidden:false];
  [PositionLabel setStringValue:@"Progress"];
  _timer = [NSTimer scheduledTimerWithTimeInterval:0.064 target:self
                                          selector:@selector(time:)
                                          userInfo:nil repeats:true];
}
- (IBAction)PpExtendChanged:(id)sender {
  if([PpExtendCheck state] == NSOnState){
    [PpMaxSlider setMaxValue:50000];
  }else{
    [PpMaxSlider setMaxValue:1000];
    [self PpMaxSliderSlided:nil];
  }
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];

  // Update the view, if already loaded.
}
@end
