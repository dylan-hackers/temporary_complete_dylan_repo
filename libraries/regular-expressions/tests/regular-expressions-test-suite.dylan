Module: regular-expressions-test-suite
Author: Carl Gay

define function re/position (pattern, string, #rest args)
  let (#rest marks) = apply(regex-position, pattern, string, args);
  marks
end function re/position;

define test atom-test ()
  check-no-errors("atom-0", re/position("", ""));
  check-equal("atom-1", re/position("a", "a"),      #[0, 1]);
  check-equal("atom-2", re/position("[a]", "a"),    #[0, 1]);
  check-equal("atom-3", re/position("(a)b", "ab"),  #[0, 2, 0, 1]);
  check-equal("atom-4", re/position("\\w", "a"),    #[0, 1]);
  check-equal("atom-5", re/position(".", "a"),      #[0, 1]);
  check-equal("atom-6", re/position("a{0}", "a"),   #[0, 0]);
  check-equal("atom-7", re/position("a{2}", "aa"),  #[0, 2]);
  check-equal("atom-8", re/position("a{1,}", "aa"), #[0, 2]);
  check-equal("atom-9", re/position("a{1,8}", "aaa"), #[0, 3]);
  check-equal("atom-A", re/position("a{,}", ""),   #[0, 0]);
  check-equal("atom-A1", re/position("a{,}", "aaaaaa"),   #[0, 6]);
  check-condition("atom-B", <invalid-regex>, re/position("a{m,n}", ""));
  check-condition("atom-C", <invalid-regex>, re/position("a{m,}", ""));
  check-condition("atom-D", <invalid-regex>, re/position("a{,n}", ""));
  check-condition("atom-E", <invalid-regex>, re/position("a{m}", ""));
  check-condition("atom-F", <invalid-regex>, re/position("a{,", ""));
  check-condition("atom-G", <invalid-regex>, re/position("[a", ""));
  check-condition("atom-H", <invalid-regex>, re/position("\\", ""));
  check-equal("atom-tan", "\<44>\<79>\<6c>\<61>\<6e>", "Dylan");
end;

define function check-matches
    (pattern, input-string, #rest groups-and-flags) => ()
  let string? = rcurry(instance?, <string>);
  let groups = choose(string?, groups-and-flags);
  let flags = choose(complement(string?), groups-and-flags);
  let regex = apply(compile-regex, pattern, flags);
  let match = regex-search(regex, input-string);
  if (empty?(groups))
    check-false(sprintf("Regex '%s' matches '%s'", pattern, input-string),
                match);
  else
    for (group in groups, i from 0)
      check-equal(sprintf("Regex '%s' group %d is '%s'", pattern, i, group),
                  group,
                  if (match)
                    match-group(match, i)
                  else
                    "{no such group}"
                  end);
    end;
  end;
end function check-matches;

// These are to cover the basics, as I add new features to the code or
// read through the pcrepattern docs.  The PCRE tests should cover a lot
// of the more esoteric cases, I hope.
//
define test ad-hoc-regex-test ()
  //args: check-matches(regex, string, group1, group2, ..., flag1: x, flag2: y, ...)
  check-matches("", "abc", "");
  check-matches("a()b", "ab", "ab", "");
  check-matches("a(?#blah)b", "ab", "ab"); // comments shouldn't create a group
  check-matches(".", "x", "x");
  check-matches(".", "\n", "\n", dot-matches-all: #t);
  check-matches("[a-]", "-", "-");
end test ad-hoc-regex-test;

// All these regexes should signal <invalid-regex> on compilation.
//
define test invalid-regex-test ()
  let patterns = #(
    "(?P<name>x)(?P<name>y)",         // can't use same name twice
    "(?@abc)",                        // invalid extended character '@'
    "(a)\\2"                          // invalid back reference
    );
  for (pattern in patterns)
    check-condition(sprintf("Compiling '%s' gets an error", pattern),
                    <invalid-regex>,
                    compile-regex(pattern));
  end;
end test invalid-regex-test;

define test pcre-testoutput1 ()
  run-pcre-checks(make-pcre-locator("pcre-testoutput1.txt"));
end;

define suite pcre-test-suite ()
  test pcre-testoutput1;
end;

define test regressions-test ()
  run-pcre-checks(make-pcre-locator("regression-tests.txt"));
end;

define suite regular-expressions-test-suite ()
  test atom-test;
  test ad-hoc-regex-test;
  test invalid-regex-test;
  test regressions-test;
  // It's sometimes useful to use -ignore-suite to skip this one because it's so noisy.
  suite pcre-test-suite;
end;
