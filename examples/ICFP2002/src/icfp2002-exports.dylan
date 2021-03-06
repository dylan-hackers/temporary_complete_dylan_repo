module: dylan-user
synopsis: Dylan Hackers entry in the Fifth Annual (2002) ICFP Programming Contest
copyright: this program may be freely used by anyone, for any purpose

define library icfp2002
  use common-dylan;
  use io;
  use collection-extensions;
  use string-extensions;
  use table-extensions;
//  use time; // gabor does not have this present at the moment
  use garbage-collection;
  use network;
end library;

define module utils
  use common-dylan;
  use streams, export: all;
  use format-out;
  use standard-io;
  use extensions, import: {report-condition};
  use print;
  use table-extensions;

  export
    *debug*, debug, always-print, force-format, choose-one,
    report-and-flush-error,
    <cons>, cons, car, cdr;
end module utils;

define module board
  use common-dylan;
  use utils;
  use format-out;
  use print, import: {print-object};
  use table-extensions;
  use extensions, import: {functional-==}; // from runtime
  
  export
    <state>, board, robots, packages, bases, bases-setter, packages-at, robot-at,
    <board>,
    path-length-cache,
    path-cache,
    <coordinate>, <point>, x, y, point,
    send-board,
    width, height, passable?, deadly?,
    <terrain>, <wall>, <water>, <base>, <space>,
    <package>, id, weight, location, dest, at-destination?, free-packages, carrier,
    <robot>, id, capacity, capacity-setter, inventory, capacity-left, money, score,
    current-inventory,
    terrain-at-point,
    copy-package,
    add-robot,
    remove-robot-by-id,
    copy-robot,
    find-robot,
    robot-exists?,
    find-package,
    add-package,
    remove-package-by-id;
end module board;


define module path
  use common-dylan;
  use utils;
  use table-extensions;
  use board;

  // For debugging only. Sorry.
  //  use format-out;
  //  use standard-io;
  //  use streams, export: all;

  export
    <point-list>,
    distance-cost,
    find-path,
    path-length,
    <path-cost>;
end module path;

define module tour
  use common-dylan;
  use utils;
  use board;
  use print;
  use subseq;
  use path;

  // While debugging, export basically everything....
  export
    <no-path-error>,
    no-path-error,
    path-start,
    path-finish,
//    <disjoint-set>,
//    value,
//    set-rank,
//    parent,
//    make-set,
//    find-set,
//    link-set,
//    set-union!,
//    all-edges,
//    min-span-tree,
    find-tour;
end module tour;

define module command
  use common-dylan;
  use utils;
  use print;
  use board;

  export
    $north,
    $south,
    $east,
    $west,
    process-command,
    <direction>,
    <command>, bid, robot-id,
    <move>, direction,
    <pick>, package-ids,
    <drop>,
    <transport>, transport-location;
end module command;

define module messages
  use common-dylan;
  use utils;
  use character-type, import: {digit?};
  use board;
  use print;
  use command;

  export
    //    <message-error>,
    //    message-error,
    //    add-error,
    // send routines
    send-player,  // This sends the "Player" message to the server to
    //initialize.
    send-command,
    // receive routines
    receive-server-packages,
    receive-server-command-reply,
    receive-initial-setup; // Reads initial board plus self robot, with robot
  // positions. Does it all.
  // receive-initial-setup calls:
  //    receive-integer,
  //    receive-string,
  //    receive-board-layout,  // Reads initial board layout, w/o robot positions.
  //    receive-client-configuration, // Reads our initial status.
  //    receive-robot-location,
  //    receive-initial-robot-positions; // Updates board with robot positions.
end module messages;

define module client
  use common-dylan;
  use utils;
  use board;
  use command;
  use path;
  use table-extensions;

  // For debugging only. Sorry.
  use format-out;
  use standard-io;

  export
    <robot-agent>,
    agent-id,
    <dumbot>, <dumber-bot>,
    <dumber-bot>,
    <pushbot>,
    <thomas>,
    <gabot>,
    generate-next-move;
end module client;

/*
define module server
  use board;
  use utils;
  
end module server;
*/

define module icfp2002
  use common-dylan, exclude: {string-to-integer}, export: all;
  use format-out;
  use format;
  use subseq;
  use utils;
  use string-conversions, import: {string-to-integer};
  use subseq, import: {subsequence}; // for test-tour-finding
  use table-extensions; // likewise
  // use time;
  use garbage-collection;
  use network;
  use messages;
  use board;
  use client;
  use command;

  // For testing only. Sorry.
  use path;
  use tour;
end module;
