module: transformers
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/base/transdef.dylan,v 1.1 1995/05/26 10:54:08 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.

define class <transformer> (<object>)
  //
  // The name of the function this transformer is for.  For printing purposes
  // only.
  slot transformer-name :: <symbol>, required-init-keyword: name:;
  //
  // The type specifiers for the specializers, or #f if unrestricted.
  slot transformer-specializer-specifiers :: false-or(<list>),
    required-init-keyword: specializers:;
  //
  // The ctypes for the specialiers, #f if unrestricted, or #"not-computed-yet"
  // if we haven't computed it yet from the specifiers.
  slot %transformer-specializers
    :: union(<list>, one-of(#f, #"not-computed-yet")),
    init-value: #"not-computed-yet";
  //
  // The actual transformer function.  Takes the component and the call
  // operation, returns a boolean indicating whether or not it did anything.
  slot transformer-function :: <function>,
    required-init-keyword: function:;
end;

define method print-object (trans :: <transformer>, stream :: <stream>) => ();
  pprint-fields(trans, stream, name: trans.transformer-name);
end;


define method define-transformer
    (name :: <symbol>, specializers :: false-or(<list>),
     function :: <function>)
    => ();
  let trans = make(<transformer>, name: name, specializers: specializers,
		   function: function);
  let var = dylan-var(name, create: #t);
  var.variable-transformers := pair(trans, var.variable-transformers);
end;

define method transformer-specializers
    (trans :: <transformer>) => res :: false-or(<list>);
  let res = trans.%transformer-specializers;
  if (res == #"not-computed-yet")
    let specs = trans.transformer-specializer-specifiers;
    trans.%transformer-specializers
      := specs & map(specifier-type, specs);
  else
    res;
  end;
end;
