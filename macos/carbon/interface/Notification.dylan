Module:    carbon-interface
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "Notification.h"; do not edit.

define C-pointer-type <NMRec*> => <NMRec>;
define C-pointer-type <NMRec**> => <NMRec*>;
define C-pointer-type <NMRecPtr> => <NMRec>;
define constant <NMProcPtr> = <C-function-pointer>;
define constant <NMUPP> = <UniversalProcPtr>;

define C-struct <NMRec>
  sealed inline-only slot qLink-value    :: <QElemPtr>;
  sealed inline-only slot qType-value    :: <C-short>;
  sealed inline-only slot nmFlags-value  :: <C-short>;
  sealed inline-only slot nmPrivate-value :: <C-both-long>;
  sealed inline-only slot nmReserved     :: <C-short>;
  sealed inline-only slot nmMark-value   :: <C-short>;
  sealed inline-only slot nmIcon-value   :: <Handle>;
  sealed inline-only slot nmSound-value  :: <Handle>;
  sealed inline-only slot nmStr-value    :: <StringPtr>;
  sealed inline-only slot nmResp-value   :: <NMUPP>;
  sealed inline-only slot nmRefCon-value :: <C-both-long>;
  pack: 2;
  c-name: "struct NMRec";
end;
// unnamed enum:
define inline-only constant $uppNMProcInfo             = #x000000C0;


define inline-only C-function NMInstall
  parameter nmReqPtr   :: <NMRecPtr>;
  result value :: <OSErr>;
  c-name: "NMInstall";
  c-modifiers: "pascal";
end;

define inline-only C-function NMRemove
  parameter nmReqPtr   :: <NMRecPtr>;
  result value :: <OSErr>;
  c-name: "NMRemove";
  c-modifiers: "pascal";
end;

