Module:       deuce-test-suite
Synopsis:     Test suite for the Deuce editor
Author:       Scott McKay
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define suite deuce-test-suite ()
  suite line-suite;
  suite bp-suite;
  suite interval-suite;
  suite section-suite;
  suite deletion-suite;
  suite buffer-suite;
  suite insertion-suite;
  suite motion-suite;
  suite search-suite;
end suite deuce-test-suite;

perform-suite(deuce-test-suite);

