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

- (void)viewDidLoad {
  [super viewDidLoad];
  typeMidi=[NSArray arrayWithObjects:@"mid",@"midi" ,nil];
  typeSF2=[NSArray arrayWithObjects:@"sf2",@"sfz", nil];
  openWindow=[NSOpenPanel new];
  BOOL res=BASS_Init(-1, 44100, 0, NULL, NULL);
  //BASS_SetConfig(BASS_CONFIG_BUFFER, 2);
  //BASS_SetConfig(BASS_CONFIG_MIXER_BUFFER, 1);
  NSLog(@"Bass Init: %s",res?"OK":"NG");
  // Do any additional setup after loading the view.
}

-(IBAction)MidiFileOpenBtnClicked:(id)sender{
  [openWindow setAllowedFileTypes: typeMidi];
  
  NSURL *filePath;
  NSString *fpString;
  if([openWindow runModal]==NSModalResponseOK){
    filePath =[openWindow URL];
    fpString=[[filePath.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];

    if(![myStream hasStream]){
     myStream=MIDIStream.new;
    }
    [myStream Load:fpString];

 
    if(myStream.hasStream){
      //On Success
      [MidiFilePathLbl setStringValue:[NSString stringWithFormat:@"%@ - %@",[myStream songName],[filePath lastPathComponent]]];
    }else{
      //On Error
      [MidiFilePathLbl setStringValue:[@"Error: " stringByAppendingString:[NSString stringWithFormat: @"%d",BASS_ErrorGetCode()]]];
      NSLog(@"Bass error code: %d",BASS_ErrorGetCode());
    }
    [SongPositionSlider setMaxValue:[myStream GetStreamLength]];
  }
}

-(IBAction)SfReplaceBtnClicked:(id)sender{
  [openWindow setAllowedFileTypes:typeSF2];
  NSURL *Url;
  NSString *Path;
  HSOUNDFONT sf;
  BASS_MIDI_FONTINFO fi;
  if([openWindow runModal]==NSModalResponseOK){
    Url=openWindow.URL;
    Path=[[Url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
    
    //Should be extern
    sf=BASS_MIDI_FontInit([Path UTF8String], 0);
    BASS_MIDI_FontGetInfo(sf, &fi);
    BASS_MIDI_FontLoad(sf, -1, -1);
    //to here...
    
    [myStream ReleaseCurrentSoundFont];
    [myStream SetSoundFont:&sf];
    if (sf>0){
      [SfNameLbl setStringValue:[NSString stringWithCString: fi.name encoding:NSUTF8StringEncoding]];
      NSLog(@"SoundFont OK,　name: %s, loaded %d",fi.name,fi.samload);
    }else{
      NSLog(@"SoundFont Error: %d",BASS_ErrorGetCode());
    }
  }
}
-(IBAction)PpMaxSliderSlided:(id)sender{
  int a=[PpMaxSlider integerValue];
  [PpMaxLbl setStringValue:[NSString stringWithFormat:@"%d",a]];
  [PpCurBar setMaxValue:(double)a];
  [myStream SetMaxPp:a];
}
-(IBAction)CpuMaxSliderSlided:(id)sender{
  int a=[CpuMaxSlider doubleValue];
  if(a==101){
    [CpuMaxLbl setStringValue:@"--"];
    [myStream SetMaxCpuLoad:0];
  }else{
    [CpuMaxLbl setStringValue:[NSString stringWithFormat:@"%d",a]];
    [myStream SetMaxCpuLoad:a];
  }
}
-(IBAction)PlayPauseBtnToggled:(id)sender{
  if([PlayPauseBtn state]==NSOnState){
    NSLog(@"Play: %d",[myStream Play]);
    NSLog(@"Started playing: %d",BASS_ErrorGetCode());
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(time:) userInfo:nil repeats:YES];
  }else{
    [myStream Pause];
  }
}
-(IBAction)SongPositionSliderSlided:(id)sender{
  [myStream SetCurrentPosition:[SongPositionSlider integerValue]];
}
-(IBAction)VolSliderChanged:(id)sender{
  float val=[VolSlider doubleValue];
  [CurVolLbl setStringValue:[NSString stringWithFormat:@"%d",(int)val]];
  val/=100;
  [myStream SetVolume:val];
}
-(IBAction)time:(NSTimer*)timer{
  long curpp,curcpu;
  unsigned int lev=[myStream GetLevel];
  double leftlev,rightlev;
  curpp=(long)[myStream GetCurrentPolyphony];
  curcpu=(long)[myStream GetCurrentCpuLoad];
  NSInteger *pos=[myStream GetCurrentPosition];
  //NSLog(@"%d - %d/%ld",BASS_ErrorGetCode(),pos,(long)[myStream GetStreamLength]);
  [SongPositionSlider setIntValue:pos];
  
  [Level_L setDoubleValue:(double)abs(LoWord(lev))];
  [Level_R setDoubleValue:(double)abs(HiWord(lev))];
  [PpCurLbl setStringValue:[NSString stringWithFormat:@"%ld",curpp]];
  [CpuCurLbl setStringValue:[NSString stringWithFormat:@"%ld",curcpu]];
  [PpCurBar setDoubleValue:(double)curpp];
  [CpuCurBar setDoubleValue:(double)curcpu];
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
}
- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];

  // Update the view, if already loaded.
}


@end
