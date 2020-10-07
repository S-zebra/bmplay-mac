//
//  ViewController.h
//  BassMidiTest
//
//  Created by kazu on 2017/04/23.
//  Copyright © 2017年 kazu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController{
  IBOutlet NSProgressIndicator *WaitRing;
  IBOutlet NSTextField *MidiFilePathLbl;
  IBOutlet NSButton *MIDIFileOpenButton;
  IBOutlet NSTextField *SfNameLbl;
  IBOutlet NSButton *SFReplaceButton;
  
  IBOutlet NSTextField *PositionLabel;
  IBOutlet NSProgressIndicator *Level_L;
  IBOutlet NSProgressIndicator *Level_R;
  IBOutlet NSTextField *PpCurLbl;
  IBOutlet NSProgressIndicator *PpCurBar;
  IBOutlet NSTextField *PpMaxLbl;
  
  IBOutlet NSTextField *CpuCurLbl;
  IBOutlet NSProgressIndicator *CpuCurBar;
  IBOutlet NSTextField *CpuMaxLbl;
  
  IBOutlet NSButton *ExportButton;
  IBOutlet NSSlider *PpMaxSlider;
  IBOutlet NSSlider *CpuMaxSlider;
  
  IBOutlet NSButton *PlayPauseBtn;
  IBOutlet NSButton *StopButton;
  IBOutlet NSSlider *SongPositionSlider;
  IBOutlet NSTextField *CurVolLbl;
  IBOutlet NSSlider *VolSlider;
  IBOutlet NSButton *FXCheckBox;
  IBOutlet NSTableColumn *EffectsList;
  IBOutlet NSProgressIndicator *PBExport;
  IBOutlet NSButton *PpExtendCheck;
}
-(IBAction)MidiFileOpenBtnClicked;
-(IBAction)SfReplaceBtnClicked;
-(IBAction)PlayPauseBtnToggled;
-(IBAction)StopBtnClicked;
-(IBAction)PpMaxSliderSlided;
-(IBAction)CpuMaxSliderSlided;
-(IBAction)VolSliderChanged;
-(IBAction)SongPositionSliderSlided;
-(IBAction)PpExtendChanged;
-(IBAction)FXCheckChanged;
@end

