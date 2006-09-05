Module:    macos-interface
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "Finder.h"; do not edit.

// unnamed enum:
define inline-only constant $kCustomIconResource       = -16455;

// unnamed enum:
define inline-only constant $kContainerFolderAliasType = FOUR_CHAR_CODE('f', 'd', 'r', 'p');
define inline-only constant $kContainerTrashAliasType  = FOUR_CHAR_CODE('t', 'r', 's', 'h');
define inline-only constant $kContainerHardDiskAliasType = FOUR_CHAR_CODE('h', 'd', 's', 'k');
define inline-only constant $kContainerFloppyAliasType = FOUR_CHAR_CODE('f', 'l', 'p', 'y');
define inline-only constant $kContainerServerAliasType = FOUR_CHAR_CODE('s', 'r', 'v', 'r');
define inline-only constant $kApplicationAliasType     = FOUR_CHAR_CODE('a', 'd', 'r', 'p');
define inline-only constant $kContainerAliasType       = FOUR_CHAR_CODE('d', 'r', 'o', 'p');
define inline-only constant $kSystemFolderAliasType    = FOUR_CHAR_CODE('f', 'a', 's', 'y');
define inline-only constant $kAppleMenuFolderAliasType = FOUR_CHAR_CODE('f', 'a', 'a', 'm');
define inline-only constant $kStartupFolderAliasType   = FOUR_CHAR_CODE('f', 'a', 's', 't');
define inline-only constant $kPrintMonitorDocsFolderAliasType = FOUR_CHAR_CODE('f', 'a', 'p', 'n');
define inline-only constant $kPreferencesFolderAliasType = FOUR_CHAR_CODE('f', 'a', 'p', 'f');
define inline-only constant $kControlPanelFolderAliasType = FOUR_CHAR_CODE('f', 'a', 'c', 't');
define inline-only constant $kExtensionFolderAliasType = FOUR_CHAR_CODE('f', 'a', 'e', 'x');
define inline-only constant $kExportedFolderAliasType  = FOUR_CHAR_CODE('f', 'a', 'e', 't');
define inline-only constant $kDropFolderAliasType      = FOUR_CHAR_CODE('f', 'a', 'd', 'r');
define inline-only constant $kSharedFolderAliasType    = FOUR_CHAR_CODE('f', 'a', 's', 'h');
define inline-only constant $kMountedFolderAliasType   = FOUR_CHAR_CODE('f', 'a', 'm', 'n');

// unnamed enum:
define inline-only constant $kIsOnDesk                 = #x0001;
define inline-only constant $kColor                    = #x000E;
define inline-only constant $kIsShared                 = #x0040;
define inline-only constant $kHasBeenInited            = #x0100;
define inline-only constant $kHasCustomIcon            = #x0400;
define inline-only constant $kIsStationery             = #x0800;
define inline-only constant $kNameLocked               = #x1000;
define inline-only constant $kHasBundle                = #x2000;
define inline-only constant $kIsInvisible              = #x4000;
define inline-only constant $kIsAlias                  = #x8000;

// unnamed enum:
define inline-only constant $kIsStationary             = $kIsStationery;

// unnamed enum:
define inline-only constant $fOnDesk                   = 1;
define inline-only constant $fHasBundle                = 8192;
define inline-only constant $fTrash                    = -3;
define inline-only constant $fDesktop                  = -2;
define inline-only constant $fDisk                     = 0;


define C-struct <FInfo>
  sealed inline-only slot fdType-value   :: <OSType>;
  sealed inline-only slot fdCreator-value :: <OSType>;
  sealed inline-only slot fdFlags-value  :: <C-unsigned-short>;
  sealed inline-only slot fdLocation-value :: <Point>;
  sealed inline-only slot fdFldr-value   :: <C-short>;
  pack: 2;
  c-name: "struct FInfo";
end;
define C-pointer-type <FInfo*> => <FInfo>;
define C-pointer-type <FInfo**> => <FInfo*>;

define C-struct <FXInfo>
  sealed inline-only slot fdIconID-value :: <C-short>;
  sealed inline-only array slot fdUnused-array :: <C-short>,
    length: 3,
    address-getter: fdUnused-value;
  sealed inline-only slot fdScript-value :: <SInt8>;
  sealed inline-only slot fdXFlags-value :: <SInt8>;
  sealed inline-only slot fdComment-value :: <C-short>;
  sealed inline-only slot fdPutAway-value :: <C-both-long>;
  pack: 2;
  c-name: "struct FXInfo";
end;
define C-pointer-type <FXInfo*> => <FXInfo>;
define C-pointer-type <FXInfo**> => <FXInfo*>;

define C-struct <DInfo>
  sealed inline-only slot frRect-value   :: <Rect>;
  sealed inline-only slot frFlags-value  :: <C-unsigned-short>;
  sealed inline-only slot frLocation-value :: <Point>;
  sealed inline-only slot frView-value   :: <C-short>;
  pack: 2;
  c-name: "struct DInfo";
end;
define C-pointer-type <DInfo*> => <DInfo>;
define C-pointer-type <DInfo**> => <DInfo*>;

define C-struct <DXInfo>
  sealed inline-only slot frScroll-value :: <Point>;
  sealed inline-only slot frOpenChain-value :: <C-both-long>;
  sealed inline-only slot frScript-value :: <SInt8>;
  sealed inline-only slot frXFlags-value :: <SInt8>;
  sealed inline-only slot frComment-value :: <C-short>;
  sealed inline-only slot frPutAway-value :: <C-both-long>;
  pack: 2;
  c-name: "struct DXInfo";
end;
define C-pointer-type <DXInfo*> => <DXInfo>;
define C-pointer-type <DXInfo**> => <DXInfo*>;
// unnamed enum:
define inline-only constant $initDev                   = 0;
define inline-only constant $hitDev                    = 1;
define inline-only constant $closeDev                  = 2;
define inline-only constant $nulDev                    = 3;
define inline-only constant $updateDev                 = 4;
define inline-only constant $activDev                  = 5;
define inline-only constant $deactivDev                = 6;
define inline-only constant $keyEvtDev                 = 7;
define inline-only constant $macDev                    = 8;
define inline-only constant $undoDev                   = 9;
define inline-only constant $cutDev                    = 10;
define inline-only constant $copyDev                   = 11;
define inline-only constant $pasteDev                  = 12;
define inline-only constant $clearDev                  = 13;
define inline-only constant $cursorDev                 = 14;

// unnamed enum:
define inline-only constant $cdevGenErr                = -1;
define inline-only constant $cdevMemErr                = 0;
define inline-only constant $cdevResErr                = 1;
define inline-only constant $cdevUnset                 = 3;

define constant <ControlPanelDefProcPtr> = <C-function-pointer>;
define constant <ControlPanelDefUPP> = <UniversalProcPtr>;
// unnamed enum:
define inline-only constant $uppControlPanelDefProcInfo = #x000FEAB0;

