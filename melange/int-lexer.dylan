documented: #t
module:  int-lexer
author:  Robert Stockton (rgs@cs.cmu.edu)
synopsis: Provides a rough approximation of the lexical conventions of the
          Dylan language, or at least the protions which concern the
          "define interface" form.
copyright: Copyright (C) 1994, Carnegie Mellon University
	   All rights reserved.
	   This code was produced by the Gwydion Project at Carnegie Mellon
	   University.  If you are interested in using this code, contact
	   "Scott.Fahlman@cs.cmu.edu" (Internet).
rcs-header: $Header: 

//======================================================================
//
// Copyright (c) 1994  Carnegie Mellon University
// All rights reserved.
//======================================================================

//======================================================================
// Module int-lexer performs lexical analysis for Dylan "define interface"
// clauses.  This will likely disappear when it comes time to merge Melange
// into Gwydion's Dylan compiler.  This file is derived from c-lexer.dylan.
//
// The module exports two major classes -- <tokenizer> and <token> -- along
// with assorted operations, subclasses, and constants.
//
//   <tokenizer>
//      Given some input source, produces a stream of tokens.  Tokenizers 
//      maintain local state.  At present this consists of the current
//      position in the input stream.
//
//   Tokenizers support the following operations:
//     make(<tokenizer>, #key source) -- source may either be a file name or
//       a stream. 
//     get-token(tokenizer) -- returns the next token
//     unget-token(tokenizer, token) -- returns a previously "gotten" token
//       to the beginning of the sequence of available tokens.
//
//    <token>
//      Represents a single input token generated by a tokenizer.
//      Encapsulates: the position in the original source; the character
//      string which generated the token; and the typed "value" of the token.
//      There are numerous subclasses of <token> representing specific
//      reserved words or semantic types (e.g. <semicolon-token> or
//      <string-literal-token>). 
//
//    All tokens support the following operations:
//      value(token) -- returns the abstract "value" of the token.  The
//        type depends upon class of the specific token.
//      string-value(token) -- returns the sequence of characters from which
//        the token's value was derived
//      generator(token) -- returns the tokenizer which generated the
//        token. 
//      parse-error(token, format, args) -- invokes the standard "error" with
//        file and location information prepended to the format string.
//======================================================================

define module int-lexer
  use dylan;
  use extensions;
  use self-organizing-list;
  use string-conversions;
  use regular-expressions;
  use character-type;
  use streams;
  export
    <tokenizer>, get-token, unget-token, <token>, value, string-value,
    generator, parse-error, position, <error-token>, <identifier-token>,
    <integer-token>, <eof-token>, <true-eof-token>, <keyword-token>,
    <symbol-literal-token>, <string-literal-token>, <comma-token>,
    <semicolon-token>, <lbrace-token>, <rbrace-token>, <arrow-token>,
    <define-token>, <interface-token>, <end-token>, <include-token>,
    <object-file-token>, <define-macro-token>, <undefine-token>,
    <name-mapper-token>, <import-token>, <prefix-token>, <exclude-token>,
    <rename-token>, <mapping-token>, <equate-token>, <superclass-token>,
    <all-token>, <function-token>, <map-result-token>, <equate-result-token>,
    <ignore-result-token>, <map-argument-token>, <equate-argument-token>,
    <input-argument-token>, <output-argument-token>,
    <input-output-argument-token>, <struct-token>, <union-token>,
    <constant-token>, <variable-token>, <getter-token>, <setter-token>,
    <read-only-token>, <seal-token>, <seal-functions-token>, <boolean-token>,
    <sealed-token>, <open-token>, <inline-token>, <value-token>,
    <literal-token>, <mindy-inc-token>;
end module int-lexer;

//------------------------------------------------------------------------
// Definitions specific to <tokenizer>s
//------------------------------------------------------------------------

// The public view of tokenizers is described above.  
//
define primary class <tokenizer> (<object>)
  slot file-name :: false-or(<string>),
    init-value: #f, init-keyword: #"source-file";
  slot contents :: <string>, required-init-keyword: #"source-string";
  slot position :: <integer>, init-keyword: #"start", init-value: 0;
  slot unget-stack :: <deque>, init-function: curry(make, <deque>);
end class <tokenizer>;

// Exported operations -- described in module header

define generic get-token
    (tokenizer :: <tokenizer>, #key) => (result :: <token>);
define generic unget-token
    (tokenizer :: <tokenizer>, token :: <token>) => (result :: <false>);

//======================================================================
// Class definitions for and operations upon <token>s
//======================================================================
// Tokens types follow this hierarchy:
//   <token>
//     <simple-token> -- value is the token itself
//       <reserved-word-token>
//         ... -- lots of different tokens, distinguished via the
//                "reserved-words" table.
//       <punctuation-token>
//         ... -- lots of different tokens, distinguished via the
//                "reserved-words" table.
//       <true-eof-token> -- "<eof-token>" is an alias for "<token>", so that
//                           the parser can stip in the middle....
//       <error-token>
//     <name-token> -- value the token string taken as a symbol.
//       <identifier-token>
//     <literal-token>
//        <integer-token> -- value is an integer
//        <string-literal-token> -- value is the token string, minus
//                                  bracketing '"'s and character escapes
//        <character-token> -- value is a single character
//        <keyword-token> -- value is a "symbolic constant"
//        <symbol-literal-token> -- value is a "symbolic constant"
//        <boolean-token> -- value is a boolean
//          <true-token>, <false-token>
//======================================================================

define abstract primary class <token> (<object>)
  slot string-value :: <string>, required-init-keyword: #"string";
  slot generator, required-init-keyword: #"generator";
  slot position, init-value: #f, init-keyword: #"position";
end;

// The parser generator wires in "<eof-token>" as the only permissible
// stopping point.  Since we want to be able to stop in the middle of a file,
// we define it to be identical to "<token>".  If you really want the "end of
// file", use "<true-eof-token>".
define constant <eof-token> = <token>;

define sealed generic string-value (token :: <token>) => (result :: <string>);
define sealed generic value (token :: <token>) => (result :: <object>);
define sealed generic parse-error
    (token :: <token>, format :: <string>, #rest args)
 => ();				// never returns

// Literal tokens (and those not otherwise modified) evaluate to themselves.
//
define method value (token :: <token>) => (result :: <token>);
  token;
end method value;

define abstract class <simple-token> (<token>) end class;
define abstract class <reserved-word-token> (<simple-token>) end class;
define abstract class <punctuation-token> (<simple-token>) end class;
define class <true-eof-token> (<simple-token>) end class;
define class <error-token> (<simple-token>) end class;

define abstract class <name-token> (<token>) end class;
define class <identifier-token> (<name-token>) end class;

// Name values are interned as symbols so that they will be case insensitive.
//
define method value (token :: <name-token>) => (result :: <symbol>);
  as(<symbol>, token.string-value);
end method value;

define class <keyword-token> (<token>) end class;

// Keyword values are interned as symbols (without the terminating colon) so
// that they will be case insensitive.
//
define method value (token :: <keyword-token>) => (result :: <symbol>);
  as(<symbol>, copy-sequence(token.string-value,
			     end: token.string-value.size - 1))
end method value;

define abstract class <literal-token> (<token>) end class;
define class <integer-token> (<literal-token>) end class;
define class <character-token> (<literal-token>) end class;
define class <string-literal-token> (<literal-token>) end class;
define class <symbol-literal-token> (<literal-token>) end class;
define abstract class <boolean-token> (<punctuation-token>) end class;
define class <true-token> (<boolean-token>) end class;
define class <false-token> (<boolean-token>) end class;

// Boolean tokens may be #t or #f.  Figure out which.
//
define method value (token :: <boolean-token>) => (result :: <boolean>);
  ~instance?(token, <false-token>);
end method value;

// Symbol literals are interned as symbols after the various quotation stuff
// is stripped off.
//
define method value
    (token :: <symbol-literal-token>) => (result :: <symbol>);
  as(<symbol>, copy-sequence(token.string-value,
			     start: 2, end: token.string-value.size - 1))
end method value;

// Integer tokens can be in one of three different radices.  Figure out which
// and then compute an integer value.
//
define method value (token :: <integer-token>) => (result :: <integer>);
  let string = token.string-value;
  case
    string.first ~= '#' =>
      string-to-integer(string);
    string.second == 'o', string.second == 'O' =>
      string-to-integer(copy-sequence(string, start: 2), base: 8);
    otherwise =>
      string-to-integer(copy-sequence(string, start: 2), base: 16);
  end case;
end method value;

// non-alphanumeric characters.  This routine translates the second character
// of such a sequence into the appropriate "escaped character".
//
define method escaped-character (char :: <character>) => (esc :: <character>);
  select (char)
    'a' => as(<character>, 7);
    'b' => as(<character>, 8);
    't' => as(<character>, 9);
    'n' => as(<character>, 10);
    'v' => as(<character>, 11);
    'f' => as(<character>, 12);
    'r' => as(<character>, 13);
    otherwise => char;
  end select;
end method escaped-character;

// Character tokens evaluate to characters.  We must handle two character
// "escape sequences" as well as simple literals.
//
define method value (token :: <character-token>) => (result :: <character>);
  let string = token.string-value;
  if (string[1] == '\\')
    escaped-character(string[2]);
  else
    string[1];
  end if;
end method value;
  
// String literals evaluate to strings (without the bracketing quotation
// marks).  Handling is complicated by the possibility that there will be
// "character escape"s in the string.
//
define method value (token :: <string-literal-token>) => (result :: <string>);
  let string = token.string-value;
  let new = make(<stretchy-vector>);

  local method process-char (position :: <integer>) => ();
	  let char = string[position];
	  if (char == '\\')
	    add!(new, escaped-character(string[position + 1]));
	    process-char(position + 2);
	  elseif (char ~= '"')
	    add!(new, char);
	    process-char(position + 1);
          // else we're done, so fall through
	  end if;
	end method process-char;
  process-char(1);
  as(<string>, new);
end method value;

// A whole bunch of reserved words

define class <define-token> (<reserved-word-token>) end class;
define class <interface-token> (<reserved-word-token>) end class;
define class <end-token> (<reserved-word-token>) end class;
define class <include-token> (<reserved-word-token>) end class;
define class <object-file-token> (<reserved-word-token>) end class;
define class <mindy-inc-token> (<reserved-word-token>) end class;
define class <define-macro-token> (<reserved-word-token>) end class;
define class <undefine-token> (<reserved-word-token>) end class;
define class <name-mapper-token> (<reserved-word-token>) end class;
define class <import-token> (<reserved-word-token>) end class;
define class <prefix-token> (<reserved-word-token>) end class;
define class <exclude-token> (<reserved-word-token>) end class;
define class <rename-token> (<reserved-word-token>) end class;
define class <mapping-token> (<reserved-word-token>) end class;
define class <equate-token> (<reserved-word-token>) end class;
define class <superclass-token> (<reserved-word-token>) end class;
define class <all-token> (<reserved-word-token>) end class;
define class <function-token> (<reserved-word-token>) end class;
define class <map-result-token> (<reserved-word-token>) end class;
define class <equate-result-token> (<reserved-word-token>) end class;
define class <ignore-result-token> (<reserved-word-token>) end class;
define class <map-argument-token> (<reserved-word-token>) end class;
define class <equate-argument-token> (<reserved-word-token>) end class;
define class <input-argument-token> (<reserved-word-token>) end class;
define class <output-argument-token> (<reserved-word-token>) end class;
define class <input-output-argument-token> (<reserved-word-token>) end class;
define class <struct-token> (<reserved-word-token>) end class;
define class <union-token> (<reserved-word-token>) end class;
define class <constant-token> (<reserved-word-token>) end class;
define class <variable-token> (<reserved-word-token>) end class;
define class <getter-token> (<reserved-word-token>) end class;
define class <setter-token> (<reserved-word-token>) end class;
define class <read-only-token> (<reserved-word-token>) end class;
define class <seal-token> (<reserved-word-token>) end class;
define class <seal-functions-token> (<reserved-word-token>) end class;
define class <sealed-token> (<reserved-word-token>) end class;
define class <open-token> (<reserved-word-token>) end class;
define class <inline-token> (<reserved-word-token>) end class;
define class <value-token> (<reserved-word-token>) end class;

// A whole bunch of punctuation

define class <semicolon-token> (<punctuation-token>) end class;
define class <comma-token> (<punctuation-token>) end class;
define class <lbrace-token> (<punctuation-token>) end class;
define class <rbrace-token> (<punctuation-token>) end class;
define class <arrow-token> (<punctuation-token>) end class;

// When we have a specific token that triggered an error, this routine can
// used saved character positions to precisely identify the location.
//
define method parse-error (token :: <token>, format :: <string>, #rest args)
 => ();	// never returns
  let source-string = token.generator.contents;
  let line-num = 1;
  let last-CR = -1;

  for (i from 0 below token.position | 0)
    if (source-string[i] == '\n')
      line-num := line-num + 1;
      last-CR := i;
    end if;
  end for;

  let char-num = (token.position | 0) - last-CR;
  apply(error, concatenate("%s:line %d: ", format),
	token.generator.file-name | "<unknown-file>", line-num, args);
end method parse-error;

//========================================================================
// "Simple" operations on tokenizers
//========================================================================

// Stores a previously analyzed token for later return
//
define method unget-token (state :: <tokenizer>, token :: <token>)
  => (result :: <false>);
  push(state.unget-stack, token);
  #f;
end method unget-token;

//======================================================================
// A bunch of specialized routines which together support "get-token"
//======================================================================

// Internal error messages generated by the lexer.  We have to go through some
// messy stuff to get to the "current" file name.
// 
define method lex-error (generator :: <tokenizer>, format :: <string>,
			 #rest args)
 => ();	// never returns
  apply(error, concatenate("%s:char %d: ", format),
	"<unknown-file>", generator.position | -1, args);
end method lex-error;

// Each pair of elements in this vector specifies a literal constant
// corresponding to a C reserved word and the token class it belongs to.
define constant reserved-words
  = vector("define", <define-token>,
	   "interface", <interface-token>,
	   "end", <end-token>,
	   "#include", <include-token>,
	   "object-file:", <object-file-token>,
	   "mindy-include-file:", <mindy-inc-token>,
	   "define:", <define-macro-token>,
	   "undefine:", <undefine-token>,
	   "name-mapper:", <name-mapper-token>,
	   "import:", <import-token>,
	   "prefix:", <prefix-token>,
	   "exclude:", <exclude-token>,
	   "rename:", <rename-token>,
	   "map:", <mapping-token>,
	   "equate:", <equate-token>,
	   "superclasses:", <superclass-token>,
	   "all", <all-token>,
           "function", <function-token>,
           "map-result:", <map-result-token>,
           "equate-result:", <equate-result-token>,
           "ignore-result:", <ignore-result-token>,
           "map-argument:", <map-argument-token>,
           "equate-argument:", <equate-argument-token>,
           "input-argument:", <input-argument-token>,
           "output-argument:", <output-argument-token>,
           "input-output-argument:", <input-output-argument-token>,
	   "struct", <struct-token>,
	   "union", <union-token>,
	   "constant", <constant-token>,
	   "variable", <variable-token>,
	   "getter:", <getter-token>,
	   "setter:", <setter-token>,
	   "read-only:", <read-only-token>,
	   "seal:", <seal-token>,
	   "seal-functions:", <seal-functions-token>,
	   "sealed", <sealed-token>,
	   "open", <open-token>,
	   "inline", <inline-token>,
	   "value:", <value-token>,
	   "#t", <true-token>,
	   "#f", <false-token>,
	   ",", <comma-token>,
	   ";", <semicolon-token>,
	   "{", <lbrace-token>,
	   "}", <rbrace-token>,
	   "=>", <arrow-token>);

// This table maps reserved words (as "symbol" literals) to the corresponding
// token class.  It is initialized from the "reserved-words" vector defined
// above
//
define constant reserved-word-table =
  make(<object-table>, size: truncate/(reserved-words.size, 2));

// Do the actual initialization of reserved-word-table at load time.
//
for (index from 0 below reserved-words.size by 2)
  reserved-word-table[as(<symbol>, reserved-words[index])]
    := reserved-words[index + 1]; 
end for;

// Looks for special classes of tokens and acts appropriately.  This includes
// reserved words, keywods, symbolic literals, and punctuation.  These are
// identified by entries in reserved-word-table.
//
define method lex-identifier
    (tokenizer :: <tokenizer>, position :: <integer>, string :: <string>)
 => (token :: <token>);
  let symbol = as(<symbol>, string);
  if (string.first == '#')
    let token-class = element(reserved-word-table, symbol, default: #f);
    if (string.last == ':' | token-class == #f)
      lex-error(tokenizer, "Bad keyword.");
    end if;
    make(token-class, position: position, string: string,
	 generator: tokenizer);
  else
    let default
      = if (string.last == ':') <keyword-token> else <identifier-token> end;
    let token-class = element(reserved-word-table, symbol, default: default);
    make(token-class, position: position, string: string,
	 generator: tokenizer);
  end if;
end method lex-identifier;

// This is complicated by the need to insure that we *don't* match octal and
// hexedecimal integer literals.
//
define constant match-ID
  = make-regexp-positioner("^(#[^xXoO]|[!&*<=>|^$%@_a-zA-Z])("
			     "[-!&*<=>|^$%@_+~?/a-zA-Z0-9]*"
			     "|[0-9][-!&*<=>|^$%@_+~?/a-zA-Z0-9]*"
			     "[a-zA-Z][a-zA=Z]"
			     "[-!&*<=>|^$%@_+~?/a-zA-Z0-9]*):?");

// Attempts to match "words" (i.e. identifiers or reserved words) or
// keywords.  Returns a token if the match is succesful and #f otherwise.
//
define method try-identifier
    (state :: <tokenizer>, position :: <integer>)
 => (result :: union(<token>, <false>));
  let contents :: <string> = state.contents;

  let (start-index, end-index)
    = match-ID(contents, start: position);
  if (start-index == #f)
    #f;
  else
    state.position := end-index;
    let string-value = copy-sequence(contents,
				     start: position, end: end-index);
    lex-identifier(state, position, string-value);
  end if;
end method try-identifier;

define constant match-punctuation
  = make-regexp-positioner("^(=>|[,;{}])", byte-characters-only: #t);

// Attempts to match "punctuation".  Returns a token if the match is succesful
// and #f otherwise.
//
define method try-punctuation (state :: <tokenizer>, position :: <integer>)
 => result :: union(<token>, <false>);
  let contents :: <string> = state.contents;

  if (punctuation?(contents[position]))
    let (start-index, end-index)
      = match-punctuation(contents, start: position);
    if (start-index ~= #f)
      state.position := end-index;
      let string-value = copy-sequence(contents,
				       start: position, end: end-index);
      lex-identifier(state, position, string-value);
    end if;
  end if;
end method try-punctuation;

define method is-prefix?
    (short :: <string>, long :: <string>, #key start = 0)
 => (result :: <boolean>);
  if (size(short) > size(long) - start)
    #f;
  else
    block (return)
      for (short-char in short,
	   index from start)
	if (short-char ~= long[index]) return(#f) end if;
      end for;
      #t;
    end block;
  end if;
end method is-prefix?;

define constant match-comment-component
  = make-regexp-positioner("\\*/|(/\\*|//)",
			   byte-characters-only: #t);

// Skip over whitespace characters (including newlines) and comments.
//
define method skip-whitespace (contents :: <string>, position :: <integer>)
 => (position :: <integer>);
  let sz = contents.size;

  local
    method find-comment-end (index :: <integer>) => (end-index :: <integer>);
      let (first, last, nested?) =
	match-comment-component(contents, start: index);
      if (nested?)
	find-comment-end(skip-comment(first));
      else
	last;
      end if;
    end method find-comment-end,
    method skip-comment (index :: <integer>) => (end-index :: <integer>);
      // The string literal looks odd, but things that look like comments
      // can really confuse the emacs mode....
      if (is-prefix?("/" "/", contents, start: index))
	for (j from index + 2 below sz,
	     until contents[j] == '\n')
	finally
	  j
	end for;
      elseif (is-prefix?("/*", contents, start: index))
	find-comment-end(index + 2);
      else
	index;
      end if;
    end method skip-comment;
  for (i from position below sz,
       until (~whitespace?(contents[i])))
  finally
    let comment-end = skip-comment(i);
    if (comment-end == i)
      // no comment -- we're done
      i;
    else
      skip-whitespace(contents, comment-end);
    end if;
  end for;
end method skip-whitespace;

// This matcher is used to match various literals.  Marks will be generated as
// follows:
//   [0, 1] and [2, 3] -- start and end of the entire match
//   [3, 4] -- start and end of character literal contents
//   [5, 6] -- start and end of string literal contents
//   [7, 8] -- start and end of integer literal
//
define constant match-literal
  = make-regexp-positioner("^('(\\\\?.)'|"
			     "(#?\"([^\"]|\\\\\")*\")|"
			     "(([1-9][0-9]*)|(#[xX][0-9a-fA-F]+)|(#[oO][0-7]*)))",
			   byte-characters-only: #t);

// Returns a <token> object and updates state to reflect the token's
// consumption. 
//
define method get-token
    (state :: <tokenizer>, #key position: init-position)
 => (token :: <token>);
  block (return)
    let pos = init-position | state.position;

    // If we have old tokens, just pop them from the stack and return them
    if (~state.unget-stack.empty?)
      return(pop(state.unget-stack));
    end if;

    let contents = state.contents;
    local method string-value(start-index, end-index)
	    copy-sequence(contents, start: start-index, end: end-index);
	  end method string-value;

    // Get rid of whitespace, whether it be spaces, newlines, or comments
    let pos = skip-whitespace(contents, pos);
    if (pos = contents.size)
      state.position := pos;
      return(make(<true-eof-token>, position: pos, generator: state,
		  string: ""));
    end if;

    // Do the appropriate matching, and return an <error-token> if we don't
    // find a match.
    let token? =
      try-identifier(state, pos) | try-punctuation(state, pos);
    if (token?) return(token?) end if;

    let (start-index, end-index, dummy1, dummy2, char-start, char-end,
	 string-start, string-end, string-contents-start, string-contents-end,
	 int-start, int-end)
      = match-literal(contents, start: pos);

    if (start-index)
      // At most one of the specialized start indices will be non-false.  Look
      // for that one and build the appropriate token.
      state.position := end-index;
      let token-type = case
			 char-start =>
			   <character-token>;
			 string-start & contents[string-start] == '#' =>
			   <symbol-literal-token>;
			 string-start =>
			   <string-literal-token>;
			 int-start =>
			   <integer-token>;
		       end case;
      return(make(token-type, position: pos,
		  string: string-value(pos, end-index), generator: state));
    end if;

    // None of our searches matched, so we haven't the foggiest what this is.
    break();
    lex-error(state, "Major botch in get-token.");
  end block;
end method get-token;
