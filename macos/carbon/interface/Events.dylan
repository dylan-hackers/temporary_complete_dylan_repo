Module:    carbon-interface
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "Events.h"; do not edit.

define inline constant <EventKind> = <UInt16>;
define C-pointer-type <EventKind*> => <EventKind>;
define C-pointer-type <EventKind**> => <EventKind*>;
define inline constant <EventMask> = <UInt16>;
define C-pointer-type <EventMask*> => <EventMask>;
define C-pointer-type <EventMask**> => <EventMask*>;
// unnamed enum:
define inline-only constant $nullEvent                 = 0;
define inline-only constant $mouseDown                 = 1;
define inline-only constant $mouseUp                   = 2;
define inline-only constant $keyDown                   = 3;
define inline-only constant $keyUp                     = 4;
define inline-only constant $autoKey                   = 5;
define inline-only constant $updateEvt                 = 6;
define inline-only constant $diskEvt                   = 7;
define inline-only constant $activateEvt               = 8;
define inline-only constant $osEvt                     = 15;
define inline-only constant $kHighLevelEvent           = 23;

// unnamed enum:
define inline-only constant $mDownMask                 = ash(1,$mouseDown);
define inline-only constant $mUpMask                   = ash(1,$mouseUp);
define inline-only constant $keyDownMask               = ash(1,$keyDown);
define inline-only constant $keyUpMask                 = ash(1,$keyUp);
define inline-only constant $autoKeyMask               = ash(1,$autoKey);
define inline-only constant $updateMask                = ash(1,$updateEvt);
define inline-only constant $diskMask                  = ash(1,$diskEvt);
define inline-only constant $activMask                 = ash(1,$activateEvt);
define inline-only constant $highLevelEventMask        = #x0400;
define inline-only constant $osMask                    = ash(1,$osEvt);
define inline-only constant $everyEvent                = #xFFFF;

// unnamed enum:
define inline-only constant $charCodeMask              = #x000000FF;
define inline-only constant $keyCodeMask               = #x0000FF00;
define inline-only constant $adbAddrMask               = #x00FF0000;
define inline-only constant $osEvtMessageMask          = c-type-cast(<C-both-long>,as(<machine-word>, #xFF000000));

// unnamed enum:
define inline-only constant $mouseMovedMessage         = #x00FA;
define inline-only constant $suspendResumeMessage      = #x0001;

// unnamed enum:
define inline-only constant $resumeFlag                = 1;
define inline-only constant $convertClipboardFlag      = 2;

define inline constant <EventModifiers> = <UInt16>;
define C-pointer-type <EventModifiers*> => <EventModifiers>;
define C-pointer-type <EventModifiers**> => <EventModifiers*>;
// unnamed enum:
define inline-only constant $activeFlagBit             = 0;
define inline-only constant $btnStateBit               = 7;
define inline-only constant $cmdKeyBit                 = 8;
define inline-only constant $shiftKeyBit               = 9;
define inline-only constant $alphaLockBit              = 10;
define inline-only constant $optionKeyBit              = 11;
define inline-only constant $controlKeyBit             = 12;
define inline-only constant $rightShiftKeyBit          = 13;
define inline-only constant $rightOptionKeyBit         = 14;
define inline-only constant $rightControlKeyBit        = 15;

// unnamed enum:
define inline-only constant $activeFlag                = ash(1,$activeFlagBit);
define inline-only constant $btnState                  = ash(1,$btnStateBit);
define inline-only constant $cmdKey                    = ash(1,$cmdKeyBit);
define inline-only constant $shiftKey                  = ash(1,$shiftKeyBit);
define inline-only constant $alphaLock                 = ash(1,$alphaLockBit);
define inline-only constant $optionKey                 = ash(1,$optionKeyBit);
define inline-only constant $controlKey                = ash(1,$controlKeyBit);
define inline-only constant $rightShiftKey             = ash(1,$rightShiftKeyBit);
define inline-only constant $rightOptionKey            = ash(1,$rightOptionKeyBit);
define inline-only constant $rightControlKey           = ash(1,$rightControlKeyBit);

// unnamed enum:
define inline-only constant $kNullCharCode             = 0;
define inline-only constant $kHomeCharCode             = 1;
define inline-only constant $kEnterCharCode            = 3;
define inline-only constant $kEndCharCode              = 4;
define inline-only constant $kHelpCharCode             = 5;
define inline-only constant $kBellCharCode             = 7;
define inline-only constant $kBackspaceCharCode        = 8;
define inline-only constant $kTabCharCode              = 9;
define inline-only constant $kLineFeedCharCode         = 10;
define inline-only constant $kVerticalTabCharCode      = 11;
define inline-only constant $kPageUpCharCode           = 11;
define inline-only constant $kFormFeedCharCode         = 12;
define inline-only constant $kPageDownCharCode         = 12;
define inline-only constant $kReturnCharCode           = 13;
define inline-only constant $kFunctionKeyCharCode      = 16;
define inline-only constant $kEscapeCharCode           = 27;
define inline-only constant $kClearCharCode            = 27;
define inline-only constant $kLeftArrowCharCode        = 28;
define inline-only constant $kRightArrowCharCode       = 29;
define inline-only constant $kUpArrowCharCode          = 30;
define inline-only constant $kDownArrowCharCode        = 31;
define inline-only constant $kDeleteCharCode           = 127;
define inline-only constant $kNonBreakingSpaceCharCode = 202;


define C-struct <EventRecord>
  sealed inline-only slot what-value     :: <EventKind>;
  sealed inline-only slot message-value  :: <UInt32>;
  sealed inline-only slot when-value     :: <UInt32>;
  sealed inline-only slot where-value    :: <Point>;
  sealed inline-only slot modifiers-value :: <EventModifiers>;
  pack: 2;
  c-name: "struct EventRecord";
end;
define C-pointer-type <EventRecord*> => <EventRecord>;
define C-pointer-type <EventRecord**> => <EventRecord*>;
define constant <FKEYProcPtr> = <C-function-pointer>;
define constant <FKEYUPP> = <UniversalProcPtr>;
// unnamed enum:
define inline-only constant $uppFKEYProcInfo           = #x00000000;


define inline-only C-function GetMouse
  parameter mouseLoc   :: <Point*>;
  c-name: "GetMouse";
  c-modifiers: "pascal";
end;

define inline-only C-function Button
  result value :: <MacBoolean>;
  c-name: "Button";
  c-modifiers: "pascal";
end;

define inline-only C-function StillDown
  result value :: <MacBoolean>;
  c-name: "StillDown";
  c-modifiers: "pascal";
end;

define inline-only C-function WaitMouseUp
  result value :: <MacBoolean>;
  c-name: "WaitMouseUp";
  c-modifiers: "pascal";
end;

define inline-only C-function TickCount
  result value :: <UInt32>;
  c-name: "TickCount";
  c-modifiers: "pascal";
end;

define inline-only C-function KeyTranslate
  parameter transData  ::  /* const */ <C-void*>;
  parameter keycode    :: <UInt16>;
  parameter state      :: <UInt32*>;
  result value :: <UInt32>;
  c-name: "KeyTranslate";
  c-modifiers: "pascal";
end;

define inline-only C-function GetCaretTime
  result value :: <UInt32>;
  c-name: "GetCaretTime";
  c-modifiers: "pascal";
end;

define inline-only C-function GetKeys
  parameter theKeys    :: <KeyMap>;
  c-name: "GetKeys";
  c-modifiers: "pascal";
end;
// unnamed enum:
define inline-only constant $networkEvt                = 10;
define inline-only constant $driverEvt                 = 11;
define inline-only constant $app1Evt                   = 12;
define inline-only constant $app2Evt                   = 13;
define inline-only constant $app3Evt                   = 14;
define inline-only constant $app4Evt                   = 15;
define inline-only constant $networkMask               = #x0400;
define inline-only constant $driverMask                = #x0800;
define inline-only constant $app1Mask                  = #x1000;
define inline-only constant $app2Mask                  = #x2000;
define inline-only constant $app3Mask                  = #x4000;
define inline-only constant $app4Mask                  = #x8000;


define C-struct <EvQEl>
  sealed inline-only slot qLink-value    :: <QElemPtr>;
  sealed inline-only slot qType-value    :: <SInt16>;
  sealed inline-only slot evtQWhat-value :: <EventKind>;
  sealed inline-only slot evtQMessage-value :: <UInt32>;
  sealed inline-only slot evtQWhen-value :: <UInt32>;
  sealed inline-only slot evtQWhere-value :: <Point>;
  sealed inline-only slot evtQModifiers-value :: <EventModifiers>;
  pack: 2;
  c-name: "struct EvQEl";
end;
define C-pointer-type <EvQEl*> => <EvQEl>;
define C-pointer-type <EvQEl**> => <EvQEl*>;
define C-pointer-type <EvQElPtr> => <EvQEl>;
define constant <GetNextEventFilterProcPtr> = <C-function-pointer>;
define constant <GetNextEventFilterUPP> = <UniversalProcPtr>;
// unnamed enum:
define inline-only constant $uppGetNextEventFilterProcInfo = #x000000BF;

define inline constant <GNEFilterUPP> = <GetNextEventFilterUPP>;
define C-pointer-type <GNEFilterUPP*> => <GNEFilterUPP>;
define C-pointer-type <GNEFilterUPP**> => <GNEFilterUPP*>;

define inline-only C-function GetEvQHdr
  result value :: <QHdrPtr>;
  c-name: "GetEvQHdr";
  c-modifiers: "pascal";
end;

define inline-only C-function GetDblTime
  result value :: <UInt32>;
  c-name: "GetDblTime";
  c-modifiers: "pascal";
end;

define inline-only C-function SetEventMask
  parameter value      :: <EventMask>;
  c-name: "SetEventMask";
  c-modifiers: "pascal";
end;

define inline-only C-function PPostEvent
  parameter eventCode  :: <EventKind>;
  parameter eventMsg   :: <UInt32>;
  parameter qEl        :: <EvQElPtr*>;
  result value :: <OSErr>;
  c-name: "PPostEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function GetNextEvent
  parameter eventMask  :: <EventMask>;
  parameter theEvent   :: <EventRecord*>;
  result value :: <MacBoolean>;
  c-name: "GetNextEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function EventAvail
  parameter eventMask  :: <EventMask>;
  parameter theEvent   :: <EventRecord*>;
  result value :: <MacBoolean>;
  c-name: "EventAvail";
  c-modifiers: "pascal";
end;

define inline-only C-function PostEvent
  parameter eventNum   :: <EventKind>;
  parameter eventMsg   :: <UInt32>;
  result value :: <OSErr>;
  c-name: "PostEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function OSEventAvail
  parameter mask       :: <EventMask>;
  parameter theEvent   :: <EventRecord*>;
  result value :: <MacBoolean>;
  c-name: "OSEventAvail";
  c-modifiers: "pascal";
end;

define inline-only C-function GetOSEvent
  parameter mask       :: <EventMask>;
  parameter theEvent   :: <EventRecord*>;
  result value :: <MacBoolean>;
  c-name: "GetOSEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function FlushEvents
  parameter whichMask  :: <EventMask>;
  parameter stopMask   :: <EventMask>;
  c-name: "FlushEvents";
  c-modifiers: "pascal";
end;

define inline-only C-function SystemClick
  parameter theEvent   ::  /* const */ <EventRecord*>;
  parameter theWindow  :: <WindowPtr>;
  c-name: "SystemClick";
  c-modifiers: "pascal";
end;

define inline-only C-function SystemTask
  c-name: "SystemTask";
  c-modifiers: "pascal";
end;

define inline-only C-function SystemEvent
  parameter theEvent   ::  /* const */ <EventRecord*>;
  result value :: <MacBoolean>;
  c-name: "SystemEvent";
  c-modifiers: "pascal";
end;

