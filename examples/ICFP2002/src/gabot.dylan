module: client

define constant <path> = <point-list>;


// ## <strategy>
define abstract class <strategy>(<object>)
  slot strategy-robot :: <robot>;
end;

// ## valid?
define generic valid?(s :: <strategy>) => valid :: <boolean>;
// ## safe?
define generic safe?(strategy :: <strategy>, me :: <gabot>, s :: <state>) => safe :: <boolean>;
// ## create-command
define generic create-command(s :: <strategy>) => command :: <command>;


define method safe?(dropping :: <drop-strategy>, me :: <gabot>, s :: <state>)
 => safe :: <boolean>;
// TODO: any other robots around?
  let position = find-robot(s, me.agent-id).location;
      
      let nearest-bot = s.robots.first; /// HACK

  distance-cost(position, dropping.approach) < distance-cost(position, nearest-bot.location)
  & distance-cost(position, dropping.approach) < distance-cost(dropping.approach, nearest-bot.location)
 //;/// TODO: all?(s.robots x path piints out-of-reach?)

// #t;
end method safe?;

// ## <gabot>
define class <gabot> (<dumbot>)
  slot decided :: <strategy>.false-or = #f;
end class <gabot>;


// ## <drop-strategy>
define concrete class <drop-strategy>(<strategy>)
  slot approach :: <point>, required-init-keyword: approach:;
  slot strategy-path :: <path>, required-init-keyword: path:;
end;

define function drop-strategy(drop-path :: <path>)
  make(<drop-strategy>, path: drop-path, approach: drop-path.last);
end;

define method valid?(dropping :: <drop-strategy>) => valid :: <boolean>;
  // did we arrive?
  if (dropping.strategy-path.size < 2)
    debug("arrived!\n");
    #f
  else
  //; TODO: do we still have the package?
    #t;
  end;
end;

// ## create-command{<drop-strategy>}
define method create-command(s :: <strategy>) => command :: <command>;
  let path = s.strategy-path;
  let path = path.head = s.strategy-robot.location
             & path.tail
             | path;
  let path = s.strategy-path := path;
  make(<move>, bid: 1, direction: turn(s.strategy-robot, path));
end;

// ## create-command{<drop-strategy>}
define method create-terminal-command(s :: <strategy>) => command :: <command>;
debug("Dropping in create-terminal-command");
  make(<drop>, package-ids: /* map(id, choose() */ #());
end;




// ## <pick-strategy>
define concrete class <pick-strategy>(<strategy>)
  slot approach :: <point>, required-init-keyword: approach:;
  slot strategy-path :: <path>, required-init-keyword: path:;
end;

define function pick-strategy(pick-path :: <path>)
  make(<drop-strategy>, path: pick-path, approach: pick-path.last);
end;


define generic find-safest(me :: <gabot>, coll :: <sequence>, locator :: <function>, s :: <state>, #key weighting :: <function> = identity)
  => (thing, way :: <path>.false-or);

define method find-safest(me :: <gabot>, coll :: <sequence>, locator :: <function>, s :: <state>, #key weighting :: <function> = identity)
  => (thing, way :: <path>.false-or);

  let position = find-robot(s, me.agent-id).location;

    local find-near-safe-place(best-thing, best-path :: <path>)
         => (better-thing, better-path :: <path>);
         
         let distance = best-path == #()
                        & s.board.height + s.board.width + 1
                        | distance-cost(position, best-path.last);

          block (found)
            for (thing in coll)
              let thing-location = thing.locator;
              let path = find-path(position, thing-location, s.board, cutoff: best-thing & distance);
              debug("find-near-safe-place: thing: %=, path: %=\n", thing, path);
              if (path)
                if (~best-thing
                    | distance-cost(position, thing-location) < distance) // # FISHY TODO we should compare paths
                  let (better-thing, nearer-path)
                    = find-near-safe-place(thing, path);
                  found(better-thing, nearer-path)
                end if;
              end if;
            end for;
            values(best-thing, best-path)
          end block;
        end method;
  
  
  find-near-safe-place(#f, #());
end method find-safest;



// overall strategy:

// if we have an already cooked-up strategy, try to follow that if still safe 
// (possibly find a better strategy instead?)
// look for safe destinations where I can drop packets
// look for safe bases to pick up packets, or safe forgotten packets in the space
// look for vulnerable robots and I am not vulnerable then attack
// try escape from attackers

define method generate-next-move(me :: <gabot>, s :: <state>)
  => c :: <command>;

  let bot = find-robot(s, me.agent-id);

block (return)
  local method follow(strategy :: <strategy>)
          me.decided := strategy;
          strategy.strategy-robot := bot;
          strategy.create-command.return;
        end;

  local method finish(strategy :: <strategy>)
          me.decided := #f;
          strategy.strategy-robot := bot;
          strategy.create-terminal-command.return;
        end;

debug("check\n");
  me.decided
    & (me.decided.valid? | me.decided.finish)
    & safe?(me.decided, me, s)
    & me.decided.follow;
debug("check1\n");
  let (safe-drop, drop-path) = find-safest(me, choose(method(p :: <package>) debug("examining %=\n",p); p.carrier == bot end, s.packages), location, s, weighting: weight);
debug("check11\n");
  safe-drop & drop-path.drop-strategy.follow;
  
//  find-robot(state, agent).inventory
//  reduce(map(weight, packages), 0, \+)
  
debug("check111\n");
  let (safe-pick, pick-path) = find-safest(me, s.bases, identity, s, weighting: weight /* my payload */);
debug("check1111\n");
  safe-pick & pick-path.pick-strategy.follow;
  
/*  ; not yet
  let safe-vulnerable = find-safest(me, s.robots, location, s, weighting: identity);
  safe-vulnerable & safe-vulnerable.kill-strategy.follow;
  */
  
debug("check11111\n");
  next-method()
end block;
end;