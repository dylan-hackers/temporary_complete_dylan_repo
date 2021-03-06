module: world

define function dbg(#rest args)
  apply(format, *standard-error*, args);
  force-output(*standard-error*);
end;

define function send(#rest args)
  apply(format, *standard-output*, args);
  force-output(*standard-output*);
end;

define method regexp-match(big :: <string>, regex :: <string>) => (#rest results);
  let (#rest marks) = regexp-position(big, regex);
  let result = make(<stretchy-vector>);

  if(marks[0])
    for(i from 0 below marks.size by 2)
      if(marks[i] & marks[i + 1])
        result := add!(result, copy-sequence(big, 
                                             start: marks[i], 
                                             end: marks[i + 1]))
      else
        result := add!(result, #f)
      end
    end
  end;
  apply(values, result)
end;

define function re (stream, #rest regexen)
  let regex = reduce1(method(x, y) concatenate(x, ws-re, y) end,
                      regexen);
  let line = read-line(stream);
  let (match, #rest substrings) = regexp-match(line, regex);
  unless (match) signal(make(<parse-error>)) end;
  apply(values, substrings)
end;



define function collect (stream, type, keywords, regexps)
 => (res :: <vec>);
  let res = make(<stretchy-vector>);
  block()
    while(#t)
      let (#rest substrings) = apply(re, stream, regexps);
      add!(res,
           apply(make, type,
                 intermingle(keywords, substrings)));
    end while;
  exception (condition :: <parse-error>)
  end;
  as(<vec>, res);
end;

// kudos to Intercal
define function intermingle (#rest sequences)
  apply(concatenate,
        apply(map,
              method(#rest elements) elements end,
              sequences));
end;

define constant <vec> = <simple-object-vector>;
define constant <string> = <byte-string>;

define macro lock-down
  { lock-down ?class-list end } => { ?class-list }
  class-list:
    { } => { }
    { ?:name, ... } =>
    { define sealed domain make(singleton(?name));
      define sealed domain initialize(?name);
      ... }
end lock-down;

define sealed method next-move (player :: <player>, move :: <move>)
 => (player :: <player>)
  make(<player>,
       name: player.player-name,
       location: move.target,
       type: move.transport);
end method;

define sealed method next-move (player :: <player>, node :: <node>)
 => (player :: <player>)
  make(<player>,
       name: player.player-name,
       location: node,
       type: player.player-type);
end method;

define sealed method advance-world
    (world :: <world>,
     #key cops = world.world-cops,
     robber = world.world-robber,
     banks = world.world-banks,
     evidences = world.world-evidences,
     smell = world.world-smell-distance)
 => (world :: <world>)
  //let players = add(cops, robber);
  /*for (p in players)
    dbg("PLAYER: %= ", p);
    if (p)
      dbg("%s", p.player-name);
    end if;
    dbg("\n");
  end for;
  for (p in cops)
    dbg("COP-PLAYER: %= ", p);
    if (p)
      dbg("%s", p.player-name);
    end if;
    dbg("\n");
  end for;*/
  /*for (player in players)
    player := next-move(player, generate-moves(player)[0]);
  end for;*/
  make(<world>,
       number: world.world-number + 1,
       loot: world.world-loot,
       banks: banks,
       evidences: evidences,
       smell: smell,
       cops: cops,
       other-cops: world.world-other-cops,
       my-player: world.world-my-player,
       robber: robber,
       skeleton: world.world-skeleton);
end method;
