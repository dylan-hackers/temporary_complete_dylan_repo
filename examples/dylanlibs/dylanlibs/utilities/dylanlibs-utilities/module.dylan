Module:    dylan-user
Synopsis:  Various utilities that don't fit into other libraries
Author:    Chris Double
Copyright: Copyright (c) 2001, Chris Double.  All rights reserved.

define module dylanlibs-utilities
  use functional-dylan;

  // Add binding exports here.
  export
    formatted-string-to-float,
    float-to-formatted-string,
    \with-abort-handler,
    \with-restart-block-handler;
end module dylanlibs-utilities;
