Module:    gtk-widgets
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "gtkcheckbutton.h"; do not edit.

define C-pointer-type <GtkCheckButton*> => <GtkCheckButton>;
define C-pointer-type <GtkCheckButton**> => <GtkCheckButton*>;
define C-pointer-type <GtkCheckButtonClass*> => <GtkCheckButtonClass>;
define C-pointer-type <GtkCheckButtonClass**> => <GtkCheckButtonClass*>;

define C-struct <_GtkCheckButton>
  sealed inline-only slot toggle-button-value :: <GtkToggleButton>;
  pointer-type-name: <_GtkCheckButton*>;
  c-name: "struct _GtkCheckButton";
end;

define C-struct <_GtkCheckButtonClass>
  sealed inline-only slot parent-class-value :: <GtkToggleButtonClass>;
  sealed inline-only slot indicator-size-value :: <guint16>;
  sealed inline-only slot indicator-spacing-value :: <guint16>;
  sealed inline-only slot draw-indicator-value :: <C-function-pointer>;
  pointer-type-name: <_GtkCheckButtonClass*>;
  c-name: "struct _GtkCheckButtonClass";
end;

define inline-only C-function gtk-check-button-get-type
  result value :: <GtkType>;
  c-name: "gtk_check_button_get_type";
end;

define inline-only C-function gtk-check-button-new
  result value :: <GtkWidget*>;
  c-name: "gtk_check_button_new";
end;

define inline-only C-function gtk-check-button-new-with-label
  parameter label1     ::  /* const */ <gchar*>;
  result value :: <GtkWidget*>;
  c-name: "gtk_check_button_new_with_label";
end;

define inline constant <GtkCheckButton> = <_GtkCheckButton>;
define inline constant <GtkCheckButtonClass> = <_GtkCheckButtonClass>;
define sealed domain make (singleton(<_GtkCheckButton*>));
define sealed domain initialize (<_GtkCheckButton*>);
define sealed domain make (singleton(<_GtkCheckButtonClass*>));
define sealed domain initialize (<_GtkCheckButtonClass*>);
