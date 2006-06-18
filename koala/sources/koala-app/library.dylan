Module:   dylan-user
Synopsis: Koala HTTP Server Application
Author:   Carl Gay

define library koala-app
  use dylan;
  use system, import: { operating-system };
  use koala;
end;


define module koala-app
  use dylan;
  use operating-system, import: { application-arguments };
  use koala, import: { start-server };
end;
