Module:    macos-interface
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "AppleEvents.h"; do not edit.

// unnamed enum:
define inline-only constant $keyDirectObject           = FOUR_CHAR_CODE('-', '-', '-', '-');
define inline-only constant $keyErrorNumber            = FOUR_CHAR_CODE('e', 'r', 'r', 'n');
define inline-only constant $keyErrorString            = FOUR_CHAR_CODE('e', 'r', 'r', 's');
define inline-only constant $keyProcessSerialNumber    = FOUR_CHAR_CODE('p', 's', 'n', ' ');
define inline-only constant $keyPreDispatch            = FOUR_CHAR_CODE('p', 'h', 'a', 'c');
define inline-only constant $keySelectProc             = FOUR_CHAR_CODE('s', 'e', 'l', 'h');
define inline-only constant $keyAERecorderCount        = FOUR_CHAR_CODE('r', 'e', 'c', 'r');
define inline-only constant $keyAEVersion              = FOUR_CHAR_CODE('v', 'e', 'r', 's');

// unnamed enum:
define inline-only constant $kCoreEventClass           = FOUR_CHAR_CODE('a', 'e', 'v', 't');

// unnamed enum:
define inline-only constant $kAEOpenApplication        = FOUR_CHAR_CODE('o', 'a', 'p', 'p');
define inline-only constant $kAEOpenDocuments          = FOUR_CHAR_CODE('o', 'd', 'o', 'c');
define inline-only constant $kAEPrintDocuments         = FOUR_CHAR_CODE('p', 'd', 'o', 'c');
define inline-only constant $kAEQuitApplication        = FOUR_CHAR_CODE('q', 'u', 'i', 't');
define inline-only constant $kAEAnswer                 = FOUR_CHAR_CODE('a', 'n', 's', 'r');
define inline-only constant $kAEApplicationDied        = FOUR_CHAR_CODE('o', 'b', 'i', 't');

// unnamed enum:
define inline-only constant $kAEStartRecording         = FOUR_CHAR_CODE('r', 'e', 'c', 'a');
define inline-only constant $kAEStopRecording          = FOUR_CHAR_CODE('r', 'e', 'c', 'c');
define inline-only constant $kAENotifyStartRecording   = FOUR_CHAR_CODE('r', 'e', 'c', '1');
define inline-only constant $kAENotifyStopRecording    = FOUR_CHAR_CODE('r', 'e', 'c', '0');
define inline-only constant $kAENotifyRecording        = FOUR_CHAR_CODE('r', 'e', 'c', 'r');

define inline constant <AESendOptions> = <OptionBits>;
define C-pointer-type <AESendOptions*> => <AESendOptions>;
define C-pointer-type <AESendOptions**> => <AESendOptions*>;
// unnamed enum:
define inline-only constant $kAENeverInteract          = #x00000010;
define inline-only constant $kAECanInteract            = #x00000020;
define inline-only constant $kAEAlwaysInteract         = #x00000030;
define inline-only constant $kAECanSwitchLayer         = #x00000040;
define inline-only constant $kAEDontRecord             = #x00001000;
define inline-only constant $kAEDontExecute            = #x00002000;
define inline-only constant $kAEProcessNonReplyEvents  = #x00008000;

define inline constant <AESendMode> = <SInt32>;
define C-pointer-type <AESendMode*> => <AESendMode>;
define C-pointer-type <AESendMode**> => <AESendMode*>;
// unnamed enum:
define inline-only constant $kAENoReply                = #x00000001;
define inline-only constant $kAEQueueReply             = #x00000002;
define inline-only constant $kAEWaitReply              = #x00000003;
define inline-only constant $kAEDontReconnect          = #x00000080;
define inline-only constant $kAEWantReceipt            = #x00000200;

// unnamed enum:
define inline-only constant $kAEDefaultTimeout         = -1;
define inline-only constant $kNoTimeOut                = -2;

define inline constant <AESendPriority> = <SInt16>;
define C-pointer-type <AESendPriority*> => <AESendPriority>;
define C-pointer-type <AESendPriority**> => <AESendPriority*>;
// unnamed enum:
define inline-only constant $kAENormalPriority         = #x00000000;
define inline-only constant $kAEHighPriority           = #x00000001;

define inline constant <AEEventSource> = <SInt8>;
define C-pointer-type <AEEventSource*> => <AEEventSource>;
define C-pointer-type <AEEventSource**> => <AEEventSource*>;
// unnamed enum:
define inline-only constant $kAEUnknownSource          = 0;
define inline-only constant $kAEDirectCall             = 1;
define inline-only constant $kAESameProcess            = 2;
define inline-only constant $kAELocalProcess           = 3;
define inline-only constant $kAERemoteProcess          = 4;

define constant <AEEventHandlerProcPtr> = <C-function-pointer>;
define constant <AEIdleProcPtr> = <C-function-pointer>;
define constant <AEFilterProcPtr> = <C-function-pointer>;
define constant <AEEventHandlerUPP> = <UniversalProcPtr>;
define constant <AEIdleUPP> = <UniversalProcPtr>;
define constant <AEFilterUPP> = <UniversalProcPtr>;
// unnamed enum:
define inline-only constant $uppAEEventHandlerProcInfo = #x00000FE0;

// unnamed enum:
define inline-only constant $uppAEIdleProcInfo         = #x00000FD0;

// unnamed enum:
define inline-only constant $uppAEFilterProcInfo       = #x00003FD0;


define inline-only C-function AESend
  parameter theAppleEvent ::  /* const */ <AppleEvent*>;
  parameter reply      :: <AppleEvent*>;
  parameter sendMode   :: <AESendMode>;
  parameter sendPriority :: <AESendPriority>;
  parameter timeOutInTicks :: <C-both-long>;
  parameter idleProc   :: <AEIdleUPP>;
  parameter filterProc :: <AEFilterUPP>;
  result value :: <OSErr>;
  c-name: "AESend";
  c-modifiers: "pascal";
end;

define inline-only C-function AEProcessAppleEvent
  parameter theEventRecord ::  /* const */ <EventRecord*>;
  result value :: <OSErr>;
  c-name: "AEProcessAppleEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function AEResetTimer
  parameter reply      ::  /* const */ <AppleEvent*>;
  result value :: <OSErr>;
  c-name: "AEResetTimer";
  c-modifiers: "pascal";
end;
define inline constant <AEInteractAllowed> = <SInt8>;
define C-pointer-type <AEInteractAllowed*> => <AEInteractAllowed>;
define C-pointer-type <AEInteractAllowed**> => <AEInteractAllowed*>;
// unnamed enum:
define inline-only constant $kAEInteractWithSelf       = 0;
define inline-only constant $kAEInteractWithLocal      = 1;
define inline-only constant $kAEInteractWithAll        = 2;


define inline-only C-function AEGetInteractionAllowed
  parameter level      :: <AEInteractAllowed*>;
  result value :: <OSErr>;
  c-name: "AEGetInteractionAllowed";
  c-modifiers: "pascal";
end;

define inline-only C-function AESetInteractionAllowed
  parameter level      :: <AEInteractAllowed>;
  result value :: <OSErr>;
  c-name: "AESetInteractionAllowed";
  c-modifiers: "pascal";
end;

define inline-only C-function AEInteractWithUser
  parameter timeOutInTicks :: <C-both-long>;
  parameter nmReqPtr   :: <NMRecPtr>;
  parameter idleProc   :: <AEIdleUPP>;
  result value :: <OSErr>;
  c-name: "AEInteractWithUser";
  c-modifiers: "pascal";
end;

define inline-only C-function AEInstallEventHandler
  parameter theAEEventClass :: <AEEventClass>;
  parameter theAEEventID :: <AEEventID>;
  parameter handler    :: <AEEventHandlerUPP>;
  parameter handlerRefcon :: <C-both-long>;
  parameter isSysHandler :: <MacBoolean>;
  result value :: <OSErr>;
  c-name: "AEInstallEventHandler";
  c-modifiers: "pascal";
end;

define inline-only C-function AERemoveEventHandler
  parameter theAEEventClass :: <AEEventClass>;
  parameter theAEEventID :: <AEEventID>;
  parameter handler    :: <AEEventHandlerUPP>;
  parameter isSysHandler :: <MacBoolean>;
  result value :: <OSErr>;
  c-name: "AERemoveEventHandler";
  c-modifiers: "pascal";
end;

define inline-only C-function AEGetEventHandler
  parameter theAEEventClass :: <AEEventClass>;
  parameter theAEEventID :: <AEEventID>;
  parameter handler    :: <AEEventHandlerUPP*>;
  parameter handlerRefcon :: <C-both-long*>;
  parameter isSysHandler :: <MacBoolean>;
  result value :: <OSErr>;
  c-name: "AEGetEventHandler";
  c-modifiers: "pascal";
end;

define inline-only C-function AESuspendTheCurrentEvent
  parameter theAppleEvent ::  /* const */ <AppleEvent*>;
  result value :: <OSErr>;
  c-name: "AESuspendTheCurrentEvent";
  c-modifiers: "pascal";
end;
// unnamed enum:
define inline-only constant $kAEDoNotIgnoreHandler     = #x00000000;
define inline-only constant $kAEIgnoreAppPhacHandler   = #x00000001;
define inline-only constant $kAEIgnoreAppEventHandler  = #x00000002;
define inline-only constant $kAEIgnoreSysPhacHandler   = #x00000004;
define inline-only constant $kAEIgnoreSysEventHandler  = #x00000008;
define inline-only constant $kAEIngoreBuiltInEventHandler = #x00000010;
define inline-only constant $kAEDontDisposeOnResume    = as(<C-both-long>,as(<machine-word>, #x80000000));

// unnamed enum:
define inline-only constant $kAENoDispatch             = 0;
define inline-only constant $kAEUseStandardDispatch    = as(<C-both-long>,$FFFFFFFF);


define inline-only C-function AEResumeTheCurrentEvent
  parameter theAppleEvent ::  /* const */ <AppleEvent*>;
  parameter reply      ::  /* const */ <AppleEvent*>;
  parameter dispatcher :: <AEEventHandlerUPP>;
  parameter handlerRefcon :: <C-both-long>;
  result value :: <OSErr>;
  c-name: "AEResumeTheCurrentEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function AEGetTheCurrentEvent
  parameter theAppleEvent :: <AppleEvent*>;
  result value :: <OSErr>;
  c-name: "AEGetTheCurrentEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function AESetTheCurrentEvent
  parameter theAppleEvent ::  /* const */ <AppleEvent*>;
  result value :: <OSErr>;
  c-name: "AESetTheCurrentEvent";
  c-modifiers: "pascal";
end;

define inline-only C-function AEInstallSpecialHandler
  parameter functionClass :: <AEKeyword>;
  parameter handler    :: <UniversalProcPtr>;
  parameter isSysHandler :: <MacBoolean>;
  result value :: <OSErr>;
  c-name: "AEInstallSpecialHandler";
  c-modifiers: "pascal";
end;

define inline-only C-function AERemoveSpecialHandler
  parameter functionClass :: <AEKeyword>;
  parameter handler    :: <UniversalProcPtr>;
  parameter isSysHandler :: <MacBoolean>;
  result value :: <OSErr>;
  c-name: "AERemoveSpecialHandler";
  c-modifiers: "pascal";
end;

define inline-only C-function AEGetSpecialHandler
  parameter functionClass :: <AEKeyword>;
  parameter handler    :: <UniversalProcPtr*>;
  parameter isSysHandler :: <MacBoolean>;
  result value :: <OSErr>;
  c-name: "AEGetSpecialHandler";
  c-modifiers: "pascal";
end;

define inline-only C-function AEManagerInfo
  parameter keyWord    :: <AEKeyword>;
  parameter result     :: <C-both-long*>;
  result value :: <OSErr>;
  c-name: "AEManagerInfo";
  c-modifiers: "pascal";
end;

