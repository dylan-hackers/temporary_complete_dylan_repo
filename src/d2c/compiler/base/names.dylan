module: names
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/names.dylan,v 1.2 1995/03/23 22:01:21 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

define abstract class <name> (<object>)
end;

define class <basic-name> (<name>)
  slot name-symbol :: <symbol>,
    required-init-keyword: symbol:;
  slot name-module :: <module>,
    required-init-keyword: module:;
end;

define method print-object (name :: <basic-name>, stream :: <stream>) => ();
  pprint-fields(name, stream,
		symbol: name.name-symbol,
		module: name.name-module);
end;

define method id-name (token :: <identifier-token>) => res :: <basic-name>;
  make(<basic-name>, symbol: token.token-symbol, module: token.token-module);
end;

define class <type-cell-name> (<name>)
  slot type-cell-name-base :: <basic-name>,
    required-init-keyword: base:;
end;

define method print-object (name :: <type-cell-name>, stream :: <stream>)
    => ();
  pprint-fields(name, stream, base: name.type-cell-name-base);
end;

define class <method-name> (<name>)
  slot method-name-generic-function :: <basic-name>,
    required-init-keyword: generic-function:;
  slot method-name-signature :: <signature>,
    required-init-keyword: signature:;
end;

define method print-object (name :: <method-name>, stream :: <stream>) => ();
  pprint-fields(name, stream,
		generic-function: name.method-name-generic-function,
		signature: name.method-name-signature);
end;
