Module:    gtk-widgets
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "gtktext.h"; do not edit.

define C-pointer-type <GtkTextFont*> => <GtkTextFont>;
define C-pointer-type <GtkTextFont**> => <GtkTextFont*>;
define C-pointer-type <GtkPropertyMark*> => <GtkPropertyMark>;
define C-pointer-type <GtkPropertyMark**> => <GtkPropertyMark*>;
define C-pointer-type <GtkText*> => <GtkText>;
define C-pointer-type <GtkText**> => <GtkText*>;
define C-pointer-type <GtkTextClass*> => <GtkTextClass>;
define C-pointer-type <GtkTextClass**> => <GtkTextClass*>;

define C-struct <_GtkPropertyMark>
  sealed inline-only slot property-value :: <GList*>;
  sealed inline-only slot offset-value   :: <guint>;
  sealed inline-only slot index-value    :: <guint>;
  pointer-type-name: <_GtkPropertyMark*>;
  c-name: "struct _GtkPropertyMark";
end;
define C-union <text%1>
  sealed inline-only slot wc-value       :: <GdkWChar*>;
  sealed inline-only slot ch-value       :: <guchar*>;
end;
define C-union <scratch_buffer%2>
  sealed inline-only slot wc-value       :: <GdkWChar*>;
  sealed inline-only slot ch-value       :: <guchar*>;
end;

define C-struct <_GtkText>
  sealed inline-only slot editable-value :: <GtkEditable>;
  sealed inline-only slot text-area-value :: <GdkWindow*>;
  sealed inline-only slot hadj-value     :: <GtkAdjustment*>;
  sealed inline-only slot vadj-value     :: <GtkAdjustment*>;
  sealed inline-only slot gc-value       :: <GdkGC*>;
  sealed inline-only slot line-wrap-bitmap-value :: <GdkPixmap*>;
  sealed inline-only slot line-arrow-bitmap-value :: <GdkPixmap*>;
  sealed inline-only slot text-value     :: <text%1>;
  sealed inline-only slot text-len-value :: <guint>;
  sealed inline-only slot gap-position-value :: <guint>;
  sealed inline-only slot gap-size-value :: <guint>;
  sealed inline-only slot text-end-value :: <guint>;
  sealed inline-only slot line-start-cache-value :: <GList*>;
  sealed inline-only slot first-line-start-index-value :: <guint>;
  sealed inline-only slot first-cut-pixels-value :: <guint>;
  sealed inline-only slot first-onscreen-hor-pixel-value :: <guint>;
  sealed inline-only slot first-onscreen-ver-pixel-value :: <guint>;
  sealed bitfield slot line-wrap-value   :: <guint>,
    width: 1;
  sealed bitfield slot word-wrap-value   :: <guint>,
    width: 1;
  sealed bitfield slot use-wchar-value   :: <guint>,
    width: 1;
  sealed inline-only slot freeze-count-value :: <guint>;
  sealed inline-only slot text-properties-value :: <GList*>;
  sealed inline-only slot text-properties-end-value :: <GList*>;
  sealed inline-only slot point-value    :: <GtkPropertyMark>;
  sealed inline-only slot scratch-buffer-value :: <scratch_buffer%2>;
  sealed inline-only slot scratch-buffer-len-value :: <guint>;
  sealed inline-only slot last-ver-value-value :: <gint>;
  sealed inline-only slot cursor-pos-x-value :: <gint>;
  sealed inline-only slot cursor-pos-y-value :: <gint>;
  sealed inline-only slot cursor-mark-value :: <GtkPropertyMark>;
  sealed inline-only slot cursor-char-value :: <GdkWChar>;
  sealed inline-only slot cursor-char-offset-value :: <gchar>;
  sealed inline-only slot cursor-virtual-x-value :: <gint>;
  sealed inline-only slot cursor-drawn-level-value :: <gint>;
  sealed inline-only slot current-line-value :: <GList*>;
  sealed inline-only slot tab-stops-value :: <GList*>;
  sealed inline-only slot default-tab-width-value :: <gint>;
  sealed inline-only slot current-font-value :: <GtkTextFont*>;
  sealed inline-only slot timer-value    :: <gint>;
  sealed inline-only slot button-value   :: <guint>;
  sealed inline-only slot bg-gc-value    :: <GdkGC*>;
  pointer-type-name: <_GtkText*>;
  c-name: "struct _GtkText";
end;

define C-struct <_GtkTextClass>
  sealed inline-only slot parent-class-value :: <GtkEditableClass>;
  sealed inline-only slot set-scroll-adjustments-value :: <C-function-pointer>;
  pointer-type-name: <_GtkTextClass*>;
  c-name: "struct _GtkTextClass";
end;

define inline-only C-function gtk-text-get-type
  result value :: <GtkType>;
  c-name: "gtk_text_get_type";
end;

define inline-only C-function gtk-text-new
  parameter hadj1      :: <GtkAdjustment*>;
  parameter vadj2      :: <GtkAdjustment*>;
  result value :: <GtkWidget*>;
  c-name: "gtk_text_new";
end;

define inline-only C-function gtk-text-set-editable
  parameter text1      :: <GtkText*>;
  parameter editable2  :: <gboolean>;
  c-name: "gtk_text_set_editable";
end;

define inline-only C-function gtk-text-set-word-wrap
  parameter text1      :: <GtkText*>;
  parameter word_wrap2 :: <gint>;
  c-name: "gtk_text_set_word_wrap";
end;

define inline-only C-function gtk-text-set-line-wrap
  parameter text1      :: <GtkText*>;
  parameter line_wrap2 :: <gint>;
  c-name: "gtk_text_set_line_wrap";
end;

define inline-only C-function gtk-text-set-adjustments
  parameter text1      :: <GtkText*>;
  parameter hadj2      :: <GtkAdjustment*>;
  parameter vadj3      :: <GtkAdjustment*>;
  c-name: "gtk_text_set_adjustments";
end;

define inline-only C-function gtk-text-set-point
  parameter text1      :: <GtkText*>;
  parameter index2     :: <guint>;
  c-name: "gtk_text_set_point";
end;

define inline-only C-function gtk-text-get-point
  parameter text1      :: <GtkText*>;
  result value :: <guint>;
  c-name: "gtk_text_get_point";
end;

define inline-only C-function gtk-text-get-length
  parameter text1      :: <GtkText*>;
  result value :: <guint>;
  c-name: "gtk_text_get_length";
end;

define inline-only C-function gtk-text-freeze
  parameter text1      :: <GtkText*>;
  c-name: "gtk_text_freeze";
end;

define inline-only C-function gtk-text-thaw
  parameter text1      :: <GtkText*>;
  c-name: "gtk_text_thaw";
end;

define inline-only C-function gtk-text-insert
  parameter text1      :: <GtkText*>;
  parameter font2      :: <GdkFont*>;
  parameter fore3      :: <GdkColor*>;
  parameter back4      :: <GdkColor*>;
  parameter chars5     ::  /* const */ <C-string>;
  parameter length6    :: <gint>;
  c-name: "gtk_text_insert";
end;

define inline-only C-function gtk-text-backward-delete
  parameter text1      :: <GtkText*>;
  parameter nchars2    :: <guint>;
  result value :: <gint>;
  c-name: "gtk_text_backward_delete";
end;

define inline-only C-function gtk-text-forward-delete
  parameter text1      :: <GtkText*>;
  parameter nchars2    :: <guint>;
  result value :: <gint>;
  c-name: "gtk_text_forward_delete";
end;

define inline constant <GtkTextFont> = <_GtkTextFont>;
define inline constant <GtkPropertyMark> = <_GtkPropertyMark>;
define inline constant <GtkText> = <_GtkText>;
define inline constant <GtkTextClass> = <_GtkTextClass>;
define sealed domain make (singleton(<_GtkPropertyMark*>));
define sealed domain initialize (<_GtkPropertyMark*>);
define sealed domain make (singleton(<_GtkText*>));
define sealed domain initialize (<_GtkText*>);
define sealed domain make (singleton(<_GtkTextClass*>));
define sealed domain initialize (<_GtkTextClass*>);
