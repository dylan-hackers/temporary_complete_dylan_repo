Module:    dylan-user
Synopsis:  This library is basically a wrapper of the debugger-manager,
           but containing specialized behaviour relevant to a
           multi-threaded user interface.
Author:    Paul Howard
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define library target-application
  use functional-dylan;

  use release-info;

  use access-path;
  use debugger-manager;

  export target-application;
end library target-application;

define module target-application
  create
      <target-application>,
      target-application-state,
      run-target-application,
      stop-target-application,
      continue-target-application,
      kill-target-application,
      \with-debugger-transaction,
      perform-debugger-transaction,
      perform-requiring-debugger-transaction,
      application-continuation-pending,
      application-shut-down-lock;
end module target-application;

define module target-application-internals
  use functional-dylan;
  use threads;

  use release-info;

  use access-path,
    rename: { thread-name => ap-thread-name};
  use debugger-manager,
    rename: { kill-application => dm-kill-application,
	      thread-name => dm-thread-name };

  use target-application;
end module target-application-internals;
