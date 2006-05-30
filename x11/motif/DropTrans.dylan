Module:    Motif
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "DropTrans.h"; do not edit.

//	RCSfile: DropTrans.h,v 
//	Revision: 1.19 
//	Date: 93/03/03 16:26:22 
define inline-only constant $XmTRANSFER-FAILURE         =    0;
define inline-only constant $XmTRANSFER-SUCCESS         =    1;
define C-variable xmDropTransferObjectClass :: <WidgetClass>
  c-name: "xmDropTransferObjectClass";
end;
define C-subtype <XmDropTransferObjectClass> ( <C-void*> ) end;
define C-subtype <XmDropTransferObject> ( <C-void*> ) end;

define inline-only function XmIsDropTransfer (w);
   XtIsSubclass(w, xmDropTransferObjectClass())
end;

define C-struct <XmDropTransferEntryRec>
  sealed inline-only slot client-data-value :: <XtPointer>;
  sealed inline-only slot target-value   :: <C-Atom>;
  pointer-type-name: <XmDropTransferEntryRec*>;
  c-name: "struct _XmDropTransferEntryRec";
end C-struct <XmDropTransferEntryRec>;
define inline constant <XmDropTransferEntry> = <XmDropTransferEntryRec*>;

define inline-only C-function XmDropTransferStart
  parameter refWidget  :: <Widget>;
  parameter args       :: <ArgList>;
  parameter argCount   :: <C-Cardinal>;
  result value :: <Widget>;
  c-name: "XmDropTransferStart";
end;

define inline-only C-function XmDropTransferAdd
  parameter widget     :: <Widget>;
  parameter transfers  :: <XmDropTransferEntry>;
  parameter num-transfers :: <C-Cardinal>;
  c-name: "XmDropTransferAdd";
end;

define sealed domain make (singleton(<XmDropTransferEntryRec*>));
define sealed domain initialize (<XmDropTransferEntryRec*>);