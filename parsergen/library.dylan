module: dylan-user

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

define library parsergen
  use common-dylan;
  use dylan;
  use io;
  use system;
  use string-extensions;
  use regular-expressions;
end library parsergen;

define module lisp-read
  use common-dylan;
  use dylan-extensions;
  use streams;
  use print;
  use standard-io;
  export
    <token>, <identifier>, <string-literal>, <character-literal>,
    <keyword>, <macro-thingy>, <lparen>, $lparen,
    <rparen>, $rparen, <list-start>, $list-start,
    lex, peek-lex, lisp-read;
end module lisp-read;

define module parsergen
  use common-dylan;
  use dylan-extensions;
  use streams;
  use print;
  use format;
  use standard-io;
  use file-system;
  use regular-expressions;
  use lisp-read, import: { lisp-read };
end module parsergen;