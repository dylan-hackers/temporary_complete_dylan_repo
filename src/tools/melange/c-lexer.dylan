documented: #t
module:  c-lexer
author:  Robert Stockton (rgs@cs.cmu.edu)
synopsis: Encapsulates the lexical conventions of the C language.  Along with
          c-lexer-cpp.dylan, this file also incorporates most of the
          functionality of CPP.
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
//
//======================================================================

//======================================================================
// Module c-lexer performs lexical analysis and macro preprocessing for C
// header files.  The implementation is divided into two files --
// c-lexer.dylan handles basic lexing, while c-lexer-cpp.dylan contains most
// of the support for macro preprocessing.
//
// The module exports two major classes -- <tokenizer> and <token> -- along
// with assorted operations, subclasses, and constants.
//
//   <tokenizer>
//      Given some input source, produces a stream of tokens.  Tokenizers 
//      maintain local state.  At present this consists of the current
//      position in the input stream and the list of "typedefs" which
//      have been recognized thus far.  (The latter would be unnecessary
//      in a rational language, but C's lexical analysis is context dependent.
//
//   Tokenizers support the following operations:
//     make(<tokenizer>, #key source) -- source may either be a file name or a
//       stream. 
//     get-token(tokenizer) -- returns the next token
//     unget-token(tokenizer, token) -- returns a previously "gotten" token to
//       the beginning of the sequence of available tokens.
//     add-typedef(tokenizer, value) -- given either a token or string value,
//       will register that value in the tokenizer as the name of a valid
//       typedef.
//     cpp-decls(tokenizer) -- if at the "top-level" (i.e. not recursively
//       processing a #include) will contain the names of all "simple" macros
//       defined in the top level token stream.
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

define module c-lexer
  use dylan;
  use extensions, exclude: {<string-table>};
  use self-organizing-list;
  use string-conversions;
  use regular-expressions;
  use substring-search;
  use character-type;
  use streams;
  create cpp-parse;
  export
    default-cpp-table, include-path,
    <tokenizer>, get-token, unget-token, add-typedef, cpp-table, cpp-decls,
    <token>, value, string-value, generator, parse-error,
    <error-token>, <identifier-token>, <integer-token>, <eof-token>,
    <begin-include-token>, <end-include-token>,
    <reserved-word-token>, <struct-token>, <typedef-token>, <name-token>,
    <int-token>, <short-token>, <long-token>,
    <signed-token>, <unsigned-token>, <char-token>, <float-token>,
    <double-token>, <const-token>, <volatile-token>, <void-token>,
    <extern-token>, <static-token>, <auto-token>, <register-token>,
    <type-name-token>, <union-token>, <enum-token>, <elipsis-token>,
    <sizeof-token>, <dec-op-token>, <inc-op-token>, <ptr-op-token>,
    <string-literal-token>, <constant-token>, <mul-assign-token>,
    <div-assign-token>, <mod-assign-token>, <add-assign-token>,
    <sub-assign-token>, <left-assign-token>, <right-assign-token>,
    <and-assign-token>, <xor-assign-token>, <or-assign-token>,
    <semicolon-token>, <comma-token>, <lparen-token>, <rparen-token>,
    <lbracket-token>, <rbracket-token>, <dot-token>,
    <ampersand-token>, <star-token>, <slash-token>, <plus-token>,
    <minus-token>, <tilde-token>, <bang-token>, <percent-token>,
    <lt-token>, <gt-token>, <carat-token>, <bar-token>,
    <question-token>, <colon-token>, <eq-op-token>, <assign-token>,
    <ge-op-token>, <le-op-token>, <ne-op-token>, <and-op-token>, <or-op-token>,
    <left-op-token>, <right-op-token>, <lcurly-token>, <rcurly-token>,
    <type-specifier-token>;
end module c-lexer;

//------------------------------------------------------------------------
// Definitions specific to <tokenizer>s
//------------------------------------------------------------------------


// The public view of tokenizers is described above.  The additional fields
// "cpp-stack" and "include-tokenizer" are used for handling the functionality
// of CPP.  The "parent" keyword for make is used to create tokenizers for
// "#included"ed files.
//
define primary class <tokenizer> (<object>)
  required keyword source:, type: type-union(<string>, <stream>);
  keyword name:, init-value: #f, type: type-union(<false>, <string>);
  keyword parent:, init-value: #f, type: type-union(<false>, <tokenizer>);
  keyword typedefs-from:, init-value: #f,
	type: type-union(<false>, <tokenizer>);
  slot file-name :: <string>;
  slot contents :: <string>;
  slot position :: <integer>, init-value: 0;
  slot unget-stack :: <deque>, init-function: curry(make, <deque>);
  slot cpp-table :: <table>;
  slot cpp-stack :: <list>, init-value: #();
  slot cpp-decls :: type-union(<deque>, <false>);
  slot include-tokenizer, init-value: #f;
  slot typedefs :: <table>;
end class <tokenizer>;

// Exported operations -- described in module header

define generic get-token
    (tokenizer :: <tokenizer>, #key) => (result :: <token>);
define generic unget-token
    (tokenizer :: <tokenizer>, token :: <token>) => (result :: <false>);
define generic add-typedef
    (tokenizer :: <tokenizer>, name :: <object>) => (result :: <false>);

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
//       <eof-token>
//       <error-token>
//       <begin-include-token>
//     <end-include-token> -- value is a sequence of macro names
//     <name-token> -- value is the token string
//       <identifier-token>
//       <type-name-token> -- distinguished via the "typedefs" table
//     <literal-token>
//        <integer-token> -- value is an integer
//        <string-literal-token> -- value is the token string, minus
//                                  bracketing '"'s and character escapes
//        <character-token> -- value is a single character
//        <cpp-token> -- value is the token string minus the initial "#".
//                       This is only used internally.
//======================================================================

define abstract primary class <token> (<object>)
  slot string-value :: <string>, required-init-keyword: #"string";
  slot generator, required-init-keyword: #"generator";
  slot position, init-value: #f, init-keyword: #"position";
end;

define sealed generic string-value (token :: <token>) => (result :: <string>);
define sealed generic value (token :: <token>) => (result :: <object>);
//define sealed generic parse-error
//    (token :: type-union(<token>,<tokenizer>), format :: <string>, #rest args)
// => ();				// never returns
define sealed generic parse-error
    (token :: <object>, format :: <string>, #rest args) => (); // never returns

// Literal tokens (and those not otherwise modified) evaluate to themselves.
//
define method value (token :: <token>) => (result :: <token>);
  token;
end method value;

define abstract class <simple-token> (<token>) end class;
define abstract class <reserved-word-token> (<simple-token>) end class;
define abstract class <punctuation-token> (<simple-token>) end class;
define class <eof-token> (<simple-token>) end class;
define class <error-token> (<simple-token>) end class;
define class <begin-include-token> (<simple-token>) end class;

define class <end-include-token> (<token>)
  slot value :: <deque>, required-init-keyword: #"value";
end class;

define abstract class <name-token> (<token>) end class;
define class <identifier-token> (<name-token>) end class;
define class <type-name-token>  (<name-token>) end class;

// Name tokens evaluate to the string-value.
//
define method value (token :: <name-token>) => (result :: <string>);
  token.string-value;
end method value;

define abstract class <literal-token> (<token>) end class;
define class <integer-token> (<literal-token>) end class;
define class <character-token> (<literal-token>) end class;
define class <string-literal-token> (<literal-token>) end class;
define class <cpp-token> (<literal-token>) end class;

// Integer tokens can be in one of three different radices.  Figure out which
// and then compute an integer value.
//
define method value (token :: <integer-token>) => (result :: <integer>);
  let string = token.string-value;
  // Strip trailing markers from string.
  while (member?(string.last, "uUlL"))
    string := copy-sequence(string, end: string.size - 1);
  end while;

  case
    string.first ~= '0' => string-to-integer(string);
    string.size == 1 => 0;
    string.second.digit? =>
      string-to-integer(copy-sequence(string, start: 1), base: 8);
    otherwise =>
      string-to-integer(copy-sequence(string, start: 2), base: 16);
  end case;
end method value;

// Both string and character literals allow you to use '\\' to get certain
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

// "Cpp" tokens evaluate to the string minus the initial "#".
//
define method value (token :: <cpp-token>) => (result :: <string>);
  copy-sequence(token.string-value, start: 1);
end method value;

// A whole bunch of reserved words

define class <struct-token> (<reserved-word-token>) end class;
define class <typedef-token> (<reserved-word-token>) end class;
define class <type-specifier-token> (<reserved-word-token>) end class;
define class <short-token> (<type-specifier-token>) end class;
define class <long-token> (<type-specifier-token>) end class;
define class <int-token> (<type-specifier-token>) end class;
define class <char-token> (<type-specifier-token>) end class;
define class <signed-token> (<type-specifier-token>) end class;
define class <unsigned-token> (<type-specifier-token>) end class;
define class <float-token> (<type-specifier-token>) end class;
define class <double-token> (<type-specifier-token>) end class;
define class <const-token> (<reserved-word-token>) end class;
define class <volatile-token> (<reserved-word-token>) end class;
define class <void-token> (<type-specifier-token>) end class;
define class <extern-token> (<reserved-word-token>) end class;
define class <static-token> (<reserved-word-token>) end class;
define class <auto-token> (<reserved-word-token>) end class;
define class <register-token> (<reserved-word-token>) end class;
define class <type_name-token> (<reserved-word-token>) end class;
define class <union-token> (<reserved-word-token>) end class;
define class <enum-token> (<reserved-word-token>) end class;
define class <constant-token> (<reserved-word-token>) end class;
define class <mul-assign-token> (<reserved-word-token>) end class;
define class <div-assign-token> (<reserved-word-token>) end class;
define class <mod-assign-token> (<reserved-word-token>) end class;
define class <add-assign-token> (<reserved-word-token>) end class;
define class <sub-assign-token> (<reserved-word-token>) end class;
define class <left-assign-token> (<reserved-word-token>) end class;
define class <right-assign-token> (<reserved-word-token>) end class;
define class <and-assign-token> (<reserved-word-token>) end class;
define class <xor-assign-token> (<reserved-word-token>) end class;
define class <or-assign-token> (<reserved-word-token>) end class;

// A whole bunch of puctuation

define class <elipsis-token> (<punctuation-token>) end class;
define class <sizeof-token> (<punctuation-token>) end class;
define class <dec-op-token> (<punctuation-token>) end class;
define class <inc-op-token> (<punctuation-token>) end class;
define class <ptr-op-token> (<punctuation-token>) end class;
define class <semicolon-token> (<punctuation-token>) end class;
define class <comma-token> (<punctuation-token>) end class;
define class <dot-token> (<punctuation-token>) end class;
define class <lparen-token> (<punctuation-token>) end class;
define class <rparen-token> (<punctuation-token>) end class;
define class <lbracket-token> (<punctuation-token>) end class;
define class <rbracket-token> (<punctuation-token>) end class;
define class <ampersand-token> (<punctuation-token>) end class;
define class <star-token> (<punctuation-token>) end class;
define class <carat-token> (<punctuation-token>) end class;
define class <bar-token> (<punctuation-token>) end class;
define class <percent-token> (<punctuation-token>) end class;
define class <slash-token> (<punctuation-token>) end class;
define class <plus-token> (<punctuation-token>) end class;
define class <minus-token> (<punctuation-token>) end class;
define class <tilde-token> (<punctuation-token>) end class;
define class <bang-token> (<punctuation-token>) end class;
define class <lt-token> (<punctuation-token>) end class;
define class <gt-token> (<punctuation-token>) end class;
define class <question-token> (<punctuation-token>) end class;
define class <colon-token> (<punctuation-token>) end class;
define class <eq-op-token> (<punctuation-token>) end class;
define class <le-op-token> (<punctuation-token>) end class;
define class <ge-op-token> (<punctuation-token>) end class;
define class <ne-op-token> (<punctuation-token>) end class;
define class <and-op-token> (<punctuation-token>) end class;
define class <or-op-token> (<punctuation-token>) end class;
define class <pound-pound-token> (<punctuation-token>) end class;
define class <left-op-token> (<punctuation-token>) end class;
define class <right-op-token> (<punctuation-token>) end class;
define class <assign-token> (<punctuation-token>) end class;
define class <lcurly-token> (<punctuation-token>) end class;
define class <rcurly-token> (<punctuation-token>) end class;

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
	token.generator.file-name, line-num, args);
end method parse-error;

//========================================================================
// "Simple" operations on tokenizers
//========================================================================

// We attempt to optimize hashing of identifiers by using a specialized table
// type.  The given hash functions is very fast and should be sufficient for
// "typical" data.  Note that it will fail catastrophically for null strings,
// but these should never appear in these tables.
//
define class <string-table> (<value-table>) end class;

define method fast-string-hash (string :: <string>)
  values(string.size * 256 + as(<integer>, string.first),
	 $permanent-hash-state);
end method fast-string-hash;

define method table-protocol (table :: <string-table>)
 => (equal :: <function>, hash :: <function>);
  values(\=, fast-string-hash);
end method;

// Tokenizers can be created in a number of ways.  It must be passed a
// "source", but this may be either a file name or a stream.  The "name:"
// keyword can override the file name for the purposes of error reporting.
// We also accept an optional set of preprocessor definitions (and
// un-definitions.) 
//
// If "parent:" is specified then we inherit context sensitivities (i.e.
// typedefs and #defines) from the parent tokenizer.  Note that changes made
// to these tables will be reflected in the parent tokenizer.
// "Typedefs-from:" is similar, except that we only inherit the typedefs
// table.
//
define method initialize (value :: <tokenizer>,
			  #key source, parent, typedefs-from, name,
			       defines = #(), undefines = #())
  // We just read the entire file into a string for the tokenizer to use.
  // This simplifies things since we can use regexp searches to find things,
  // even across line boundaries.
  let source-stream
    = if (instance?(source, <string>))
	value.file-name := name | source;
	make(<file-stream>, name: source, direction: #"input");
      else
	value.file-name := name | "<unknown-file>";
	source;
      end if;
  value.contents := read-as(<byte-string>, source-stream, to-eof?: #t);
  if (parent)
    value.typedefs := (typedefs-from | parent).typedefs;
    value.cpp-table := parent.cpp-table;
    value.cpp-decls := make(<deque>);
  else
    value.cpp-table := shallow-copy(default-cpp-table);
    value.typedefs := if (typedefs-from)
			typedefs-from.typedefs;
		      else
			make(<string-table>);
		      end if;
    value.cpp-decls := make(<deque>);
  end if;

  // We must be able to initialize the cpp-table with user supplied additions
  // (or subtractions).  If the supplied value is a string, we need to create
  // a temporary tokenizer to convert it to a sequence of tokens.  Like all
  // such sequences of "cpp" tokens, this one will be in reverse order.
  for (elem in defines)
    let key = elem.head;
    let cpp-value = elem.tail;
    select (cpp-value by instance?)
      <integer> =>
	value.cpp-table[key] := list(make(<integer-token>,
					  string: cpp-value.integer-to-string,
					  generator: value));
      <string> =>
	if (cpp-value.empty?)
	  // Work around bug/misfeature in streams
	  value.cpp-table[key] := #();
	else
	  let sub-tokenizer
	    = make(<tokenizer>,
		   source: make(<byte-string-input-stream>,
				string: cpp-value));
	  for (list = #() then pair(token, list),
	       token = get-token(sub-tokenizer, expand: #f)
		 then get-token(sub-tokenizer, expand: #f),
	       until: instance?(token, <eof-token>))
	    if (instance?(token, <error-token>))
	      parse-error(value, "Error in cpp defines");
	    end if;
	  finally
	    value.cpp-table[key] := list;
	  end for;
	end if;
    end select;
  end for;
  for (key in undefines)
    if (element(value.cpp-table, key, default: #f))
      remove-key!(value.cpp-table, key);
    else
      cerror("Continue", "No such key in %=: %=", value.cpp-table, key);
    end if;
  end for;
end method initialize;

// Stores a previously analyzed token for later return
//
define method unget-token (state :: <tokenizer>, token :: <token>)
  => (result :: <false>);
  push(state.unget-stack, token);
  #f;
end method unget-token;

// Record the given name as a valid type specifier
//
define method add-typedef (tokenizer :: <tokenizer>, token :: <token>)
 => (result :: <false>);
  tokenizer.typedefs[token.value] := <type-name-token>;
  #f;
end method add-typedef;

define method add-typedef (tokenizer :: <tokenizer>, name :: <string>)
 => (result :: <false>);
  tokenizer.typedefs[name] := <type-name-token>;
  #f;
end method add-typedef;

//======================================================================
// A bunch of specialized routines which together support "get-token"
//======================================================================

// Internal error messages generated by the lexer.  We have to go through some
// messy stuff to get to the "current" file name.
// 
define method parse-error (generator :: <tokenizer>, format :: <string>,
			 #rest args)
 => ();	// never returns
  for (gen = generator then gen.include-tokenizer,
       while: gen.include-tokenizer)
  finally 
    let source-string = gen.contents;
    let line-num = 1;
    let last-CR = -1;
    
    for (i from 0 below gen.position | 0)
      if (source-string[i] == '\n')
	line-num := line-num + 1;
	last-CR := i;
      end if;
    end for;

    let char-num = (gen.position | 0) - last-CR;
    apply(error, concatenate("%s:line %d: ", format),
	  gen.file-name, line-num, args);
  end for;
end method parse-error;

// Each pair of elements in this vector specifies a literal constant
// corresponding to a C reserved word and the token class it belongs to.
define constant reserved-words
  = vector("struct", <struct-token>,
	   "typedef", <typedef-token>,
	   "short", <short-token>,
	   "long", <long-token>,
	   "int", <int-token>,
	   "char", <char-token>,
	   "signed", <signed-token>,
	   "unsigned", <unsigned-token>,
	   "float", <float-token>,
	   "double", <double-token>,
	   "const", <const-token>,
	   "volatile", <volatile-token>,
	   "void", <void-token>,
	   "extern", <extern-token>,
	   "static", <static-token>,
	   "auto", <auto-token>,
	   "register", <register-token>,
	   "union", <union-token>,
	   "enum", <enum-token>,
	   "...", <elipsis-token>,
	   "sizeof", <sizeof-token>,
	   "constant", <constant-token>,
	   "--", <dec-op-token>,
	   "++", <inc-op-token>,
	   "->", <ptr-op-token>,
	   "*=", <mul-assign-token>,
	   "/=", <div-assign-token>,
	   "%=", <mod-assign-token>,
	   "+=", <add-assign-token>,
	   "-=", <sub-assign-token>,
	   "<<=", <left-assign-token>,
	   ">>=", <right-assign-token>,
	   "&=", <and-assign-token>,
	   "^=", <xor-assign-token>,
	   "|=", <or-assign-token>,
	   ">=", <ge-op-token>,
	   "<=", <le-op-token>,
	   "!=", <ne-op-token>,
	   "&&", <and-op-token>,
	   "||", <or-op-token>,
	   "##", <pound-pound-token>,
	   ";", <semicolon-token>,
	   ",", <comma-token>,
	   ".", <dot-token>,
	   "*", <star-token>,
	   "%", <percent-token>,
	   "+", <plus-token>,
	   "-", <minus-token>,
	   "~", <tilde-token>,
	   "!", <bang-token>,
	   "/", <slash-token>,
	   "<", <lt-token>,
	   ">", <gt-token>,
	   "^", <carat-token>,
	   "|", <bar-token>,
	   "&", <ampersand-token>,
	   "?", <question-token>,
	   ":", <colon-token>,
	   "=", <assign-token>,
	   "==", <eq-op-token>,
	   "<<", <left-op-token>,
	   ">>", <right-op-token>,
	   "{", <lcurly-token>,
	   "}", <rcurly-token>,
	   "[", <lbracket-token>,
	   "]", <rbracket-token>,
	   "(", <lparen-token>,
	   ")", <rparen-token>);

// This table maps reserved words (as "symbol" literals) to the corresponding
// token class.  It is initialized from the "reserved-words" vector defined
// above
//
define constant reserved-word-table =
  make(<string-table>, size: truncate/(reserved-words.size, 2));

// Do the actual initialization of reserved-word-table at load time.
//
for (index from 0 below reserved-words.size by 2)
  reserved-word-table[reserved-words[index]] := reserved-words[index + 1];
end for;

// Looks for special classes of tokens and acts appropriately.  This includes
// macro names, typedefs, reserved words, and punctuation.  These are
// identified by entries in cpp-table, tokenizer.typedefs, and reserved-word
// table.
//
define method lex-identifier
    (tokenizer :: <tokenizer>, position :: <integer>, string :: <string>,
     #key expand = #t)
 => (token :: <token>);
  case
    expand & check-cpp-expansion(string, tokenizer) =>
      get-token(tokenizer);
    element(tokenizer.typedefs, string, default: #f) =>
      make(<type-name-token>, string: string, position: position,
	   generator: tokenizer);
    otherwise =>
      let default
	= if (string.first == '#') <cpp-token> else <identifier-token> end if;
      let cls = element(reserved-word-table, string, default: default);
      make(cls, position: position, string: string, generator: tokenizer);
  end case;
end method lex-identifier;

// Attempts to match "words" (i.e. identifiers or reserved words).  Returns a
// token if the match is succesful and #f otherwise.
//
define method try-identifier
    (state :: <tokenizer>, position :: <integer>, #key expand = #t)
 => (result :: type-union(<token>, <false>));
  let contents :: <string> = state.contents;

  let pos = if (contents[position] == '#') position + 1 else position end if;
  if (alpha?(contents[pos]) | contents[pos] == '_')
    for (index from pos + 1 below contents.size,
	 until: ~alphanumeric?(contents[index]) & contents[index] ~= '_')
    finally
      state.position := index;
      let string-value = copy-sequence(contents,
				       start: position, end: index);
      lex-identifier(state, position, string-value, expand: expand);
    end for;
  end if;
end method try-identifier;

define constant match-punctuation
  = make-regexp-positioner("^([-*/%+<>&^|=!]="
			     "|\\+\\+|--|->|\\.\\.\\.|>>=?|<<=?|\\|\\||&&|##"
			     "|[;,().&*+~!/%<>^|?:={}]"
			     "|-|\\[|\\])",
			   byte-characters-only: #t, case-sensitive: #t);

// Attempts to match "punctuation".  Returns a token if the match is succesful
// and #f otherwise.
//
define method try-punctuation (state :: <tokenizer>, position :: <integer>)
 => result :: type-union(<token>, <false>);
  let contents :: <string> = state.contents;

  if (punctuation?(contents[position]))
    let (start-index, end-index)
      = match-punctuation(contents, start: position);
    if (start-index ~= #f)
      state.position := end-index;
      let string-value = copy-sequence(contents,
				       start: position, end: end-index);
      lex-identifier(state, position, string-value, expand: #f);
    end if;
  end if;
end method try-punctuation;

define constant match-comment-end = make-substring-positioner("*/");

// Skip over whitespace characters (including newlines) and comments.
//
define method skip-whitespace (contents :: <string>, position :: <integer>)
 => (position :: <integer>);
  let sz = contents.size;

  local method skip-comments (index :: <integer>)
	 => end-index :: type-union(<integer>, <false>);
	  for (i from index,
	       until: (i >= sz | ~whitespace?(contents[i])))
	  finally
	    if (i < sz - 1 & contents[i] == '/' & contents[i + 1] == '*')
	      let end-index = match-comment-end(contents, start: i + 2);
	      if (~end-index)
		error("Incomplete comment in C header file.");
	      end if;
	      skip-comments(end-index + 2);
	    else
	      i;
	    end if;
	  end for;
	end method skip-comments;
  skip-comments(position);
end method skip-whitespace;

// Skip over whitespace characters (excluding newlines) and comments in
// "#preprocessor" lines.  Handles the "\\\n" special case.
//
define method skip-cpp-whitespace (contents :: <string>, position :: <integer>)
 => (position :: <integer>);
  let sz = contents.size;

  local method skip-comments (index :: <integer>)
	 => end-index :: type-union(<integer>, <false>);
	  for (i from index,
	       until: (i >= sz | (contents[i] ~= ' ' & contents[i] ~= '\t')))
	  finally
	    if (i < sz - 1 & contents[i] == '/' & contents[i + 1] == '*')
	      let end-index = match-comment-end(contents, start: i + 2);
	      if (~end-index)
		error("Incomplete comment in C header file.");
	      end if;
	      skip-comments(end-index + 2);
	    elseif ((i < sz - 1)
		      & contents[i] == '\\' & contents[i + 1] == '\n')
	      skip-comments(i + 2);
	    else
	      i;
	    end if;
	  end for;
	end method skip-comments;
  skip-comments(position);
end method skip-cpp-whitespace;

// This matcher is used to match various literals.  Marks will be generated as
// follows:
//   [0, 1] and [2, 3] -- start and end of the entire match
//   [3, 4] -- start and end of character literal contents
//   [5, 6] -- start and end of string literal contents
//   [7, 8] -- start and end of integer literal
//
define constant match-literal
  = make-regexp-positioner("^('(\\\\?.)'|"
			     "\"([^\"]|\\\\\")*\"|"
			     "((([1-9][0-9]*)|(0[xX][0-9a-fA-F]+)|(0[0-7]*))[lLuU]*))",
			   byte-characters-only: #t, case-sensitive: #t);

// Returns a <token> object and updates state to reflect the token's
// consumption. 
//
define method get-token
    (state :: <tokenizer>,
     #key cpp-line, position: init-position, expand = ~cpp-line)
 => (token :: <token>);
  block (return)
    let pos = init-position | state.position;

    // If we are recursively including another file, defer to the tokenizer
    // for that file.
    if (state.include-tokenizer)
      let token = get-token(state.include-tokenizer, expand: expand,
			    cpp-line: cpp-line, position: init-position);
      if (instance?(token, <eof-token>))
	let macros = state.include-tokenizer.cpp-decls;
	let old-file = state.include-tokenizer.file-name;
	state.include-tokenizer := #f;
	return(make(<end-include-token>, position: pos, generator: state,
		    string: old-file, value: macros));
      else
	return(token);
      end if;
    end if;

    // If we have old tokens, just pop them from the stack and return them
    if (~state.unget-stack.empty?)
      let stack = state.unget-stack;
      let token = pop(stack);
      if (~stack.empty? & instance?(stack.first, <pound-pound-token>))
	// The pound-pound construct is nasty.  We must concatenate two tokens
	// and then get a new token from the resulting string.  If this isn't
	// a single token, we just ignore the rest -- "the results are
	// undefined".
	pop(stack);		// Get rid of the pound-pound-token
	let new-string = concatenate(token.string-value,
				     get-token(state).string-value);
	let sub-tokenizer
	  = make(<tokenizer>,
		 source: make(<byte-string-input-stream>, string: new-string));
	return(get-token(sub-tokenizer));
      elseif (instance?(token, <identifier-token>)
		& element(state.typedefs, token.value, default: #f))
	// This is our last chance to deal with recently declared typedefs, so
	// we check one more time.
	return(make(<type-name-token>, position: token.position,
		    generator: token.generator, string: token.string-value));
      else
	return(token);
      end if;
    end if;

    let contents = state.contents;
    local method string-value(start-index, end-index)
	    copy-sequence(contents, start: start-index, end: end-index);
	  end method string-value;

    // There are different whitespace conventions for normal input and for
    // preprocessor directives.
    let pos = if (cpp-line)
		     skip-cpp-whitespace(contents, pos);
		   else
		     skip-whitespace(contents, pos);
		   end if;
    if (pos = contents.size | (cpp-line & contents[pos] == '\n'))
      state.position := pos;
      return(make(<eof-token>, position: pos, generator: state,
		  string: ""));
    end if;

    // Deal with preprocessor lines.  Since these may change the state, we
    // will simply re-call "get-token" after invoking the appropriate
    // processing.  We don't look for preprocessor lines in the middle of
    // other preprocessor lines.
    if (~cpp-line & try-cpp(state, pos))
      return(get-token(state));
    end if;

    // Do the appropriate matching, and return an <error-token> if we don't
    // find a match.
    let token? =
      try-identifier(state, pos, expand: expand) | try-punctuation(state, pos);
    if (token?) return(token?) end if;

    let (start-index, end-index, dummy1, dummy2, char-start, char-end,
	 string-start, string-end, int-start, int-end)
      = match-literal(contents, start: pos);

    if (start-index)
      // At most one of the specialized start indices will be non-false.  Look
      // for that one and build the appropriate token.
      state.position := end-index;
      let token-type = case
			 char-start => <character-token>;
			 string-start => <string-literal-token>;
			 int-start => <integer-token>;
		       end case;
      return(make(token-type, position: pos,
		  string: string-value(pos, end-index), generator: state));
    end if;

    // None of our searches matched, so we haven't the foggiest what this is.
    break();
    parse-error(state, "Major botch in get-token.");
  end block;
end method get-token;
