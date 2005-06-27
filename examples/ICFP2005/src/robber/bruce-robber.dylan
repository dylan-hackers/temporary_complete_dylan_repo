module: bruce-robber


define class <bruce-robber> (<robber>)
  slot goal-bank :: <integer> = 0;
end class <bruce-robber>;

define function next-bank(n)
  let banks = *world-skeleton*.world-banks;
  if (n + 1 = banks.size) 0 else n + 1; end
end;


define constant *cop-probability* = 100000000;

define function count-greater-than(v :: <int-vector>, min :: <integer>)
 => (count :: <integer>, total-prob :: <integer>);
  let count = 0;
  let prob = 0;
  for (i in v)
    if (i > min)
      count := count + 1;
    end;
    prob := prob + i;
  end;
  values(count, prob);
end count-greater-than;


define method choose-move(robber :: <bruce-robber>, world :: <world>)
  *num-evals* := 0;
  let node-lookup = world.world-skeleton.world-nodes-by-id;
  let num-nodes = node-lookup.size;

  let cop-foot-prob = make(<int-vector>, size: num-nodes, fill: 0);
  let cop-car-prob = make(<int-vector>, size: num-nodes, fill: 0);
  let cop-total-prob = make(<int-vector>, size: num-nodes, fill: 0);

  // set up tables, knowing where cops are right now
  for (cop :: <player> in world.world-cops)
    let node-id = cop.player-location.node-id;
    if (cop.player-type = "cop-foot")
      cop-foot-prob[node-id] := cop-foot-prob[node-id] + *cop-probability*;
    else
      cop-car-prob[node-id] := cop-car-prob[node-id] + *cop-probability*;
    end;
  end for;

  for (i from 1 to 3)
    let new-cop-foot-prob = make(<int-vector>, size: num-nodes, fill: 0);
    let new-cop-car-prob = make(<int-vector>, size: num-nodes, fill: 0);

    let hq-node =
      block (return)
        for (node :: <node> in node-lookup)
          if (node.node-tag = "hq")
            return(node);
          end;
        end;
      end;

    local method spread-probs(probs :: <int-vector>,
                              new-probs :: <int-vector>,
                              move-selector) => ();
            for (i from 0 below num-nodes)
              let prob = probs[i];
              if (prob > 0)
                let node = node-lookup[i];
                if (node == hq-node)
                  let prob = truncate/(prob, node.moves-by-foot.size + node.moves-by-car.size);
                  let foot-moves :: <stretchy-object-vector> = node.moves-by-foot;
                  let car-moves :: <stretchy-object-vector> = node.moves-by-car;
                  for (move :: <node> in foot-moves)
                    let target-id = move.node-id;
                    new-cop-foot-prob[target-id] := new-cop-foot-prob[target-id] + prob;
                  end;
                  for (move :: <node> in car-moves)
                    let target-id = move.node-id;
                    new-cop-car-prob[target-id] := new-cop-car-prob[target-id] + prob;
                  end;
                else
                  let moves :: <stretchy-object-vector> = node.move-selector;
                  let prob = truncate/(prob, moves.size);
                  for (move :: <node> in moves)
                    let target-id = move.node-id;
                    new-probs[target-id] := new-probs[target-id] + prob;
                  end for;
                end if; //hq
              end if; //prob nonzero
            end for; // all nodes
          end method spread-probs;

    spread-probs(cop-foot-prob, new-cop-foot-prob, moves-by-foot);
    spread-probs(cop-car-prob, new-cop-car-prob, moves-by-car);

    cop-foot-prob := new-cop-foot-prob;
    cop-car-prob := new-cop-car-prob;

    let (foot-places, foot-prob) = count-greater-than(cop-foot-prob, 0);
    let (car-places, car-prob) = count-greater-than(cop-car-prob, 0);
    dbg("round %d, places cops could be, foot: %d (%d), car: %d (%d)\n",
        i,
        foot-places, foot-prob,
        car-places, car-prob);

  end for; // iterating cop probabilities
  
  dbg("\n\nby foot probability function: ");
  for (i in cop-foot-prob)
    dbg("%d  ", i);
  end;
  dbg("\n\nby car probability function: ");
  for (i in cop-car-prob)
    dbg("%d  ", i);
  end;
  dbg("\n\n");

  for (i from 0 below num-nodes)
    cop-total-prob[i] := cop-foot-prob[i] + cop-car-prob[i];
  end;



////////////////////////////////// temp move chosing
  let fw-world = future-world-from-world(world);
  let (score, move) = robber-move(fw-world, 1);

  dbg("choosing move with score %d\n", score);
  make(<move>, target: move, transport: "robber");
end method choose-move;


        
define method choose-random-move(robber :: <bruce-robber>, world :: <world>)
  let possible-locations = generate-moves(robber.agent-player);
  possible-locations[random(possible-locations.size)];
end method choose-random-move;

//////////////////////////////////////////////////////////////////////////////////

define function robber-move(world :: <future-world>, depth :: <integer>)
 => (score :: <integer>, best-move :: <node>);
  dbg("robber-move depth=%d\n", depth);
  block (return)
    if (depth == 0)
      dbg("robber-move will return after evaluate\n");
      return(evaluate(world), world.fw-robber.player-location);
    end;


    let best-score :: <integer> = -999999999;
    let best-move = #f;

    let possible-moves = generate-moves(world.fw-robber);
    for (move :: <move> in possible-moves)
      let node = move.target;
      let new-world = future-world(world, robber: next-move(world.fw-robber, node));
      let score = cop-move(new-world, depth - 1);
      if (score > best-score)
        best-score := score;
        best-move := node;
      end;
    end;
    dbg("robber-move returning after cop-moves\n");
    return(best-score, best-move)
  end block;
end robber-move;


define function cop-move(world :: <future-world>, depth :: <integer>)
 => (score :: <integer>, best-move :: <node>);
  dbg("cop-move depth=%d\n", depth);
  block (return)
    dbg("entering cop-move\n");
    if (depth == 0)
      dbg("cop-move will return after evaluate\n");
      return(evaluate(world), world.fw-robber.player-location);
    end;

    let best-score :: <integer> = 999999999;
    let best-move = #f;
    let old-cops = world.fw-cops;
    let num-cops :: <integer> = old-cops.size;
    let cops = make(<vector>, size: num-cops);

    local method generate(cop-num :: <integer>)
            let this-cop :: <player> = old-cops[cop-num];
            let possible-moves = generate-moves(this-cop);
            dbg("cop #%d with %d moves\n", cop-num, possible-moves.size);
            for (move :: <move> in possible-moves)
              let node = move.target;
              cops[cop-num] := next-move(this-cop, node);
                
              if (cop-num = 0)
                let new-world = future-world(world, cops: cops);
                let score = robber-move(new-world, depth - 1);
                if (score < best-score)
                  best-score := score;
                  best-move := node;
                end;
              else
                generate(cop-num - 1);
              end;
            end for;
          end method generate;

    generate(num-cops - 1);

    dbg("cop-move returning after robber-moves\n");
    return(best-score, best-move)
  end block;
end cop-move;



//////////////////////////////////////////////////////////////////////////////////

define class <future-world> (<object>)
  constant slot fw-number         :: <integer>, required-init-keyword: number:;
  constant slot fw-loot           :: <integer>, required-init-keyword: loot:;
  constant slot fw-banks          :: <vec>, required-init-keyword: banks:;
  //constant slot fw-evidences      :: <vec>, required-init-keyword: evidences:;
  //constant slot fw-smell-distance :: <integer>, required-init-keyword: smell:;
  constant slot fw-cops           :: <vec>, required-init-keyword: cops:;
  constant slot fw-robber         :: <player>, required-init-keyword: robber:;
  constant slot fw-skeleton       :: <world-skeleton>, required-init-keyword: skeleton:;
end class;

lock-down <future-world> end;

// a lighter-weight version of world, for planning

define inline method future-world
    (world :: <future-world>,
     #key cops = world.fw-cops,
     loot = world.fw-loot,
     robber = world.fw-robber,
     banks = world.fw-banks)
  => (world :: <future-world>);
  make(<future-world>,
       number: world.fw-number + 1,
       loot: loot,
       banks: banks,
       //evidences: evidences,
       //smell: smell,
       cops: cops,
       robber: robber,
       skeleton: world.fw-skeleton);
end method;


define function future-world-from-world(world :: <world>)
 => (fw :: <future-world>);
  make(<future-world>,
       number: world.world-number,
       loot: world.world-loot,
       banks: world.world-banks,
       //evidences: evidences,
       //smell: smell,
       cops: world.world-cops,
       robber: world.world-robber,
       skeleton: world.world-skeleton);
end future-world-from-world;

define constant *dead* :: <integer> = -1000000;
define variable *num-evals* :: <integer> = 0;

define method evaluate(world :: <future-world>)
  => (score :: <integer>);
  *num-evals* := *num-evals* + 1;
  dbg("start evaluate #%d\n", *num-evals*);
  block (return)
    let my-pos = world.fw-robber.player-location;

    let min-dist = 9999;
    for (cop :: <player> in world.fw-cops)
      let dist = distance(cop, my-pos);
      dbg("  dist = %d\n", dist);
      if (dist < 2)
        return(*dead*)
      end;
      if (dist < min-dist)
        min-dist := dist;
      end;
    end;

    return(min-dist);
  end;
end evaluate;

