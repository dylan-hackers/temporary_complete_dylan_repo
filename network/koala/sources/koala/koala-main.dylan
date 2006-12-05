Module:    httpi
Synopsis:  Library initialization code
Author:    Carl Gay
Copyright: Copyright (c) 2001-2004 Carl L. Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND

//// Testing

define constant $debugging-koala :: <boolean> = #f;

define function test-koala
    () => ()
  // Nothing yet...
end;


//// Initialization

define function init-koala ()
  when ($debugging-koala)
    test-koala();
  end;

  //init-server();
end;

begin
  init-koala();
end;
