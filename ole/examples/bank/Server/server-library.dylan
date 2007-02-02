Module: dylan-user
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library bank-server
  use functional-dylan;
  use duim;
  use ole-automation;
  use bank-interface;
  use sql-odbc;
end library bank-server;

define module bank-server
  use functional-dylan;
  use simple-format;
  use duim;
  use ole-automation;
  use bank-interface;
  use sql-odbc, rename: {command-function => sql-command-function};
end module bank-server;