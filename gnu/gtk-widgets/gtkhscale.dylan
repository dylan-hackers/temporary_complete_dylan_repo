Module:    gtk-widgets
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "gtkhscale.h"; do not edit.

define C-pointer-type <GtkHScale*> => <GtkHScale>;
define C-pointer-type <GtkHScale**> => <GtkHScale*>;
define C-pointer-type <GtkHScaleClass*> => <GtkHScaleClass>;
define C-pointer-type <GtkHScaleClass**> => <GtkHScaleClass*>;

define C-struct <_GtkHScale>
  sealed inline-only slot scale-value    :: <GtkScale>;
  pointer-type-name: <_GtkHScale*>;
  c-name: "struct _GtkHScale";
end;

define C-struct <_GtkHScaleClass>
  sealed inline-only slot parent-class-value :: <GtkScaleClass>;
  pointer-type-name: <_GtkHScaleClass*>;
  c-name: "struct _GtkHScaleClass";
end;

define inline-only C-function gtk-hscale-get-type
  result value :: <GtkType>;
  c-name: "gtk_hscale_get_type";
end;

define inline-only C-function gtk-hscale-new
  parameter adjustment1 :: <GtkAdjustment*>;
  result value :: <GtkWidget*>;
  c-name: "gtk_hscale_new";
end;

define inline constant <GtkHScale> = <_GtkHScale>;
define inline constant <GtkHScaleClass> = <_GtkHScaleClass>;
define sealed domain make (singleton(<_GtkHScale*>));
define sealed domain initialize (<_GtkHScale*>);
define sealed domain make (singleton(<_GtkHScaleClass*>));
define sealed domain initialize (<_GtkHScaleClass*>);
