Module:    gtk-widgets
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// This file is automatically generated from "gtkmenuitem.h"; do not edit.

define C-pointer-type <GtkMenuItem*> => <GtkMenuItem>;
define C-pointer-type <GtkMenuItem**> => <GtkMenuItem*>;
define C-pointer-type <GtkMenuItemClass*> => <GtkMenuItemClass>;
define C-pointer-type <GtkMenuItemClass**> => <GtkMenuItemClass*>;

define C-struct <_GtkMenuItem>
  sealed inline-only slot item-value     :: <GtkItem>;
  sealed inline-only slot submenu-value  :: <GtkWidget*>;
  sealed inline-only slot accelerator-signal-value :: <guint>;
  sealed inline-only slot toggle-size-value :: <guint16>;
  sealed inline-only slot accelerator-width-value :: <guint16>;
  sealed bitfield slot show-toggle-indicator-value ::
	<guint>,
    width: 1;
  sealed bitfield slot show-submenu-indicator-value ::
	<guint>,
    width: 1;
  sealed bitfield slot submenu-placement-value ::
	<guint>,
    width: 1;
  sealed bitfield slot submenu-direction-value ::
	<guint>,
    width: 1;
  sealed bitfield slot right-justify-value :: <guint>,
    width: 1;
  sealed inline-only slot timer-value    :: <guint>;
  pointer-type-name: <_GtkMenuItem*>;
  c-name: "struct _GtkMenuItem";
end;

define C-struct <_GtkMenuItemClass>
  sealed inline-only slot parent-class-value :: <GtkItemClass>;
  sealed inline-only slot toggle-size-value :: <guint>;
  sealed bitfield slot hide-on-activate-value ::
	<guint>,
    width: 1;
  sealed inline-only slot activate-value :: <C-function-pointer>;
  sealed inline-only slot activate-item-value :: <C-function-pointer>;
  pointer-type-name: <_GtkMenuItemClass*>;
  c-name: "struct _GtkMenuItemClass";
end;

define inline-only C-function gtk-menu-item-get-type
  result value :: <GtkType>;
  c-name: "gtk_menu_item_get_type";
end;

define inline-only C-function gtk-menu-item-new
  result value :: <GtkWidget*>;
  c-name: "gtk_menu_item_new";
end;

define inline-only C-function gtk-menu-item-new-with-label
  parameter label1     ::  /* const */ <gchar*>;
  result value :: <GtkWidget*>;
  c-name: "gtk_menu_item_new_with_label";
end;

define inline-only C-function gtk-menu-item-set-submenu
  parameter menu_item1 :: <GtkMenuItem*>;
  parameter submenu2   :: <GtkWidget*>;
  c-name: "gtk_menu_item_set_submenu";
end;

define inline-only C-function gtk-menu-item-remove-submenu
  parameter menu_item1 :: <GtkMenuItem*>;
  c-name: "gtk_menu_item_remove_submenu";
end;

define inline-only C-function gtk-menu-item-set-placement
  parameter menu_item1 :: <GtkMenuItem*>;
  parameter placement2 :: <GtkSubmenuPlacement>;
  c-name: "gtk_menu_item_set_placement";
end;

define inline-only C-function gtk-menu-item-configure
  parameter menu_item1 :: <GtkMenuItem*>;
  parameter show_toggle_indicator2 :: <gint>;
  parameter show_submenu_indicator3 :: <gint>;
  c-name: "gtk_menu_item_configure";
end;

define inline-only C-function gtk-menu-item-select
  parameter menu_item1 :: <GtkMenuItem*>;
  c-name: "gtk_menu_item_select";
end;

define inline-only C-function gtk-menu-item-deselect
  parameter menu_item1 :: <GtkMenuItem*>;
  c-name: "gtk_menu_item_deselect";
end;

define inline-only C-function gtk-menu-item-activate
  parameter menu_item1 :: <GtkMenuItem*>;
  c-name: "gtk_menu_item_activate";
end;

define inline-only C-function gtk-menu-item-right-justify
  parameter menu_item1 :: <GtkMenuItem*>;
  c-name: "gtk_menu_item_right_justify";
end;

define inline constant <GtkMenuItem> = <_GtkMenuItem>;
define inline constant <GtkMenuItemClass> = <_GtkMenuItemClass>;
define sealed domain make (singleton(<_GtkMenuItem*>));
define sealed domain initialize (<_GtkMenuItem*>);
define sealed domain make (singleton(<_GtkMenuItemClass*>));
define sealed domain initialize (<_GtkMenuItemClass*>);
