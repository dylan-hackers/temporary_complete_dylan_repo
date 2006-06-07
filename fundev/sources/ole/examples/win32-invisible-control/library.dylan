Module:    Dylan-User
Synopsis:  Example of an invisible-at-runtime OLE Control.
Author:    David N. Gray
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library win32-invisible-control
  use functional-dylan;
  use Win32-common;
  use Win32-kernel;
  use Win32-GDI;
  use Win32-user;
  use OLE-control-framework;
end library;

define module win32-invisible-control
  use functional-dylan;
  use Win32-common;
  use Win32-kernel;
  use Win32-GDI;
  use Win32-user;
  use OLE-control-framework;
end module;