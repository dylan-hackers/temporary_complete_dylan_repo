Module:    gtk-widgets
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "gtkscrollbar.h"; do not edit.

define C-pointer-type <GtkScrollbar*> => <GtkScrollbar>;
define C-pointer-type <GtkScrollbar**> => <GtkScrollbar*>;
define C-pointer-type <GtkScrollbarClass*> => <GtkScrollbarClass>;
define C-pointer-type <GtkScrollbarClass**> => <GtkScrollbarClass*>;

define C-struct <_GtkScrollbar>
  sealed inline-only slot range-value    :: <GtkRange>;
  pointer-type-name: <_GtkScrollbar*>;
  c-name: "struct _GtkScrollbar";
end;

define C-struct <_GtkScrollbarClass>
  sealed inline-only slot parent-class-value :: <GtkRangeClass>;
  pointer-type-name: <_GtkScrollbarClass*>;
  c-name: "struct _GtkScrollbarClass";
end;

define inline-only C-function gtk-scrollbar-get-type
  result value :: <GtkType>;
  c-name: "gtk_scrollbar_get_type";
end;

define inline constant <GtkScrollbar> = <_GtkScrollbar>;
define inline constant <GtkScrollbarClass> = <_GtkScrollbarClass>;
define sealed domain make (singleton(<_GtkScrollbar*>));
define sealed domain initialize (<_GtkScrollbar*>);
define sealed domain make (singleton(<_GtkScrollbarClass*>));
define sealed domain initialize (<_GtkScrollbarClass*>);
