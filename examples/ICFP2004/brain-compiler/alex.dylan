module: assembler


define brain alex-gatherer

  [start:]
    Flip 4, (get-out-of-home, mark-around);

  [drop-and-get-out-of-home:]
    Drop, (get-out-of-home);

  // The following set of macros makes the ant get out of home.
  // After that it moves on to search-food.
  [get-out-of-home:]
    Sense Home, (move-forward-in-home, search-food);

  [move-forward-in-home:]
    Move get-out-of-home => turn-left-or-right-in-home;

  [turn-left-or-right-in-home:]
    Flip 1, (turn-left-in-home, turn-right-in-home);

  [turn-left-in-home:]
    Turn Left, (move-forward-in-home);

  [turn-right-in-home:]
    Turn Right, (move-forward-in-home);


  // The following set of macros makes the ant search for food,
  // while avoiding home cells.
  [search-food:]
    Sense Home, (get-out-of-home, search-food-out-of-home);

  [search-food-out-of-home:]
    Sense Food, (pick-up-food, search-food-in-empty);

  [pick-up-food:]
    PickUp deliver-food => search-food-in-empty;

  [search-food-in-empty:]
    Sense Ahead Food, (move-forward-in-empty, try-left-or-right);

  [try-left-or-right:]
    Flip 1, (try-left, try-right);

  [try-left:]
    Sense LeftAhead Food, (move-left-in-empty, try-forward);

  [try-right:]
    Sense RightAhead Food, (move-right-in-empty, try-forward);

  [try-forward:]
    Mark 0;
    Move search-food => try-else;

  [try-else:]
    Flip 1, (move-left-or-right-twice-in-empty, move-left-or-right-or-forward-in-empty);

  [move-left-or-right-twice-in-empty:]
    Flip 1, (move-left-twice-in-empty, move-right-twice-in-empty);

  [move-left-twice-in-empty:]
    Turn Left;
    Turn Left;
    Mark 0;
    Move search-food => move-at-random-in-empty;

  [move-right-twice-in-empty:]
    Turn Right;
    Turn Right;
    Mark 0;
    Move search-food => move-at-random-in-empty;

  [move-left-or-right-or-forward-in-empty:]
    Flip 2, (move-forward-in-empty, move-left-or-right-in-empty);

  [move-forward-in-empty:]
    Mark 0;
    Move search-food => move-at-random-in-empty;

  [move-left-or-right-in-empty:]
    Flip 1, (move-left-in-empty, move-right-in-empty);

  [move-left-in-empty:]
    Turn Left;
    Mark 0;
    Move search-food => move-at-random-in-empty;

  [move-right-in-empty:]
    Turn Right;
    Mark 0;
    Move search-food => move-at-random-in-empty;

  [move-at-random-in-empty:]
    Flip 5, (move-back, move-other-five);

  [move-back:]
    Turn Left;
    Turn Left;
    Turn Left;
    Mark 0;
    Move search-food => move-at-random-in-empty;

  [move-other-five:]
    Flip 4, (try-forward, try-else);


  // The following set of macros makes it possible to deliver food,
  // using the trail of marks left using marker 0.
  [deliver-food:]
    Sense Home, (drop-and-get-out-of-home, deliver-back);

  [deliver-back:]
    Turn Left;
    Turn Left;
    Turn Left, (deliver-forward);

  [deliver-forward:]
    Sense Ahead (Marker 0), (deliver-move-forward, deliver-try-left-1);

  [deliver-move-forward:]
    Move deliver-food => deliver-at-random;

  [deliver-try-left-1:]
    Sense Ahead (Marker 0), (deliver-move-forward, deliver-try-left-2);

  [deliver-try-left-2:]
    Sense Ahead (Marker 0), (deliver-move-forward, deliver-try-left-3);

  [deliver-try-left-3:]
    Sense Ahead (Marker 0), (deliver-move-forward, deliver-try-left-4);

  [deliver-try-left-4:]
    Sense Ahead (Marker 0), (deliver-move-forward, deliver-try-left-5);

  [deliver-try-left-5:]
    Sense Ahead (Marker 0), (deliver-move-forward, deliver-at-random);

  // We lost our trail. Try randomly or use mark-up of ant hill kind. :-)
  [deliver-at-random:]
    Flip 5, (deliver-move-forward, deliver-try-other-five);

  [deliver-try-other-five:]
    Flip 4, (deliver-move-backward, deliver-try-other-four);

  [deliver-move-backward:]
    Turn Left;
    Turn Left;
    Turn Left, (deliver-move-forward);

  [deliver-try-other-four:]
    Flip 1, (deliver-move-left-or-right, deliver-move-left-or-right-twice);

  [deliver-move-left-or-right:]
    Flip 1, (deliver-move-left, deliver-move-right);

  [deliver-move-left:]
    Turn Left, (deliver-move-forward);

  [deliver-move-right:]
    Turn Right, (deliver-move-forward);   

  [deliver-move-left-or-right-twice:]
    Flip 1, (deliver-move-left-twice, deliver-move-right-twice);

  [deliver-move-left-twice:]
    Turn Left;
    Turn Left, (deliver-move-forward);

  [deliver-move-right-twice:]
    Turn Right;
    Turn Right, (deliver-move-forward);


  // Perform marking algorithm.
  [mark-around:]
    Drop, (deliver-at-random);

end;


alex-gatherer().dump-brain;
