Module: dylan-user
Author:    Keith Dennison
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define module scepter-dump-back-end
  use date;
  use generic-arithmetic-functional-dylan;
  use format;
  use streams;
  use file-system;
  use scepter-back-end;
  use scepter-front-end;
  use scepter-ast;
end module;