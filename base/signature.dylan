Module: signature
Description: Method/GF signatures and operations on them
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/signature.dylan,v 1.7 1995/10/13 15:08:00 ram Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

// A <signature> represents what we know at compile-time about the
// argument/return-value protocol of a GF or method.
// 
define class <signature> (<object>)

  // List of <ctype>s representing the specializers for required arguments.
  slot specializers :: <list>, required-init-keyword: specializers:;

  // True if there was a #next.
  slot next? :: <boolean>,
    init-value: #f, init-keyword: next:;

  // If no #rest args, #f, otherwise the rest arg type.
  slot rest-type :: false-or(<ctype>),
    init-value: #f, init-keyword: rest-type:;

  // List of <key-info>s describing the specified keyword args.  #f if #key was
  // not specified.
  slot key-infos :: false-or(<list>),
    init-value: #f, init-keyword: keys:;
  slot all-keys? :: <boolean>,
    init-value: #f, init-keyword: all-keys:;

  // <values-ctype> representing the result types.
  slot returns :: <values-ctype>, init-keyword: returns:,
    init-function: wild-ctype;

end;

define method print-object (sig :: <signature>, stream :: <stream>) => ();
  pprint-fields(sig, stream,
		specializers: sig.specializers,
		sig.rest-type & (rest-type:), sig.rest-type,
		sig.key-infos & (key-infos:), sig.key-infos,
		sig.all-keys? & (all-keys:), #t,
		returns:, sig.returns);
end;

add-make-dumper(#"function-signature", *compiler-dispatcher*, <signature>,
  list(specializers, specializers:, #f,
       next?, next:, #f,
       rest-type, rest-type:, #f,
       key-infos, keys:, #f,
       returns, returns:, #f)
);


define class <key-info> (<object>)

  // name of this keyword arg.
  slot key-name :: <symbol>, required-init-keyword: key-name:;

  // type restriction.
  slot key-type :: <ctype>, required-init-keyword: type:;

  // true if a required keyword.
  // ??? if this means anything, it means the non-strictly-Dylan
  // concept of keywords that are effictively required, e.g. due to an
  // error-default.  Or a required-init-keyword on a make method?
  slot required? :: <boolean>,
    init-value: #f, init-keyword: required:;

  // The default, if it is a compile-time constant.  Otherwise, #f.
  slot key-default :: union(<false>, <ct-value>),
    init-value: #f, init-keyword: default:;
end;

define method print-object (key :: <key-info>, stream :: <stream>) => ();
  pprint-fields(key, stream,
		name: key.key-name,
		type: key.key-type,
		required: key.required?,
		default: key.key-default);
end;

define method key-needs-supplied?-var (key-info :: <key-info>)
    => res :: <boolean>;
  if (key-info.key-default)
    #f;
  else
    let rep = pick-representation(key-info.key-type, #"speed");
    ~rep.representation-has-bottom-value?;
  end;
end;

add-make-dumper(#"function-key-info", *compiler-dispatcher*, <key-info>,
  list(key-name, key-name:, #f,
       key-type, type:, #f,
       required?, required:, #f,
       key-default, default:, #f)
);
