Module:   employee-explorer
Synopsis: An employee tree explorer
Author:   Keith Playford
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant $database-name :: <string> = "northwind";
define constant $user-name :: <string> = "";
define constant $user-password :: <string>  = "";

define method main () => ()
  do-with-open-database
    ($database-name, $user-name, $user-password,
       method () start-frame(make(<explorer-frame>)) end);
end method main;

begin
  main();
end;
