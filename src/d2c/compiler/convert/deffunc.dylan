module: define-functions
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/convert/deffunc.dylan,v 1.62 1996/03/17 00:56:29 wlott Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.



// Parse tree stuff and macro expanders.

// <define-generic-parse> -- internal.
//
// Special subclass of <definition-parse> that ``define generic'' expands
// into.
// 
define class <define-generic-parse> (<definition-parse>)
  //
  // The name being defined.
  constant slot defgeneric-name :: <identifier-token>,
    required-init-keyword: name:;
  //
  // The parameters.
  constant slot defgeneric-parameters :: <parameter-list>,
    required-init-keyword: parameters:;
  //
  // The results.
  constant slot defgeneric-results :: <variable-list>,
    required-init-keyword: results:;
  //
  // The options, a vector of <property> objects.
  constant slot defgeneric-options :: <simple-object-vector>,
    required-init-keyword: options:;
end class <define-generic-parse>;

define-procedural-expander
  (#"make-define-generic",
   method (name-frag :: <fragment>, params-frag :: <fragment>,
	   results-frag :: <fragment>, options-frag :: <fragment>)
       => result :: <fragment>;
     make-parsed-fragment
       (make(<define-generic-parse>,
	     name: extract-name(name-frag),
	     parameters: parse-parameter-list(make(<fragment-tokenizer>,
						   fragment: params-frag)),
	     results: parse-variable-list(make(<fragment-tokenizer>,
					       fragment: results-frag)),
	     options: parse-property-list(make(<fragment-tokenizer>,
					       fragment: options-frag))));
   end method);



define class <define-sealed-domain-parse> (<definition-parse>)
  //
  // The name of the generic function.
  constant slot sealed-domain-name :: <identifier-token>,
    required-init-keyword: name:;
  //
  // The type expressions, each an <expression-parse>;
  constant slot sealed-domain-type-exprs :: <simple-object-vector>,
    required-init-keyword: type-exprs:;
end class <define-sealed-domain-parse>;

define-procedural-expander
  (#"make-define-sealed-domain",
   method (name-frag :: <fragment>, types-frag :: <fragment>)
       => result :: <fragment>;
     make-parsed-fragment
       (make(<define-sealed-domain-parse>,
	     name: extract-name(name-frag),
	     type-exprs: map(expression-from-fragment,
			     split-fragment-at-commas(types-frag))));
   end method);



// <define-method-parse> -- internal.
// 
define class <define-method-parse> (<definition-parse>)
  //
  // The method guts.  Includes the name, parameters, results, and body.
  constant slot defmethod-method :: <method-parse>,
    required-init-keyword: method:;
  //
  // Extra options, a vector of <property> objects.
  constant slot defmethod-options :: <simple-object-vector>,
    required-init-keyword: options:;
end class <define-method-parse>;

define-procedural-expander
  (#"make-define-method",
   method (name-frag :: <fragment>, method-frag :: <fragment>,
	   options-frag :: <fragment>)
       => result :: <fragment>;
     let method-parse
       = for (method-expr = expression-from-fragment(method-frag)
		then macro-expand(method-expr),
	      while: instance?(method-expr, <macro-call-parse>))
	 finally
	   unless (instance?(method-expr, <method-ref-parse>))
	     error("bug in define method macro: guts didn't show up as "
		     "a method-ref");
	   end unless;
	   method-expr.method-ref-method;
	 end for;
     method-parse.method-name := extract-name(name-frag);
     make-parsed-fragment
       (make(<define-method-parse>,
	     method: method-parse,
	     options: parse-property-list(make(<fragment-tokenizer>,
					       fragment: options-frag))));
   end method);


// <explicitly-define-generic-tlf> -- internal.
//
// Top-level-form for explicitly defined generic functions.
//
define class <explicitly-define-generic-tlf> (<define-generic-tlf>)
  //
  // Make the definition required.
  required keyword defn:;
  //
  // The original parse.
  constant slot generic-tlf-parse :: <define-generic-parse>,
    required-init-keyword: parse:;
end;

define method print-message
    (tlf :: <explicitly-define-generic-tlf>, stream :: <stream>) => ();
  format(stream, "Define Generic %s", tlf.tlf-defn.defn-name);
end;

define class <implicitly-define-generic-tlf> (<define-generic-tlf>)
  //
  // Make the definition required.
  required keyword defn:;
end;

define method print-message
    (tlf :: <implicitly-define-generic-tlf>, stream :: <stream>) => ();
  format(stream, "{Implicit} Define Generic %s", tlf.tlf-defn.defn-name);
end;


define class <define-sealed-domain-tlf> (<top-level-form>)
  //
  // The <define-sealed-domain-parse> for the ``define sealed domain''
  constant slot sealed-domain-parse :: <define-sealed-domain-parse>,
    required-init-keyword: parse:;
  //
  // The <name> for the generic function being sealed.
  constant slot sealed-domain-name :: <name>,
    required-init-keyword: name:;
  //
  // The library doing the seal.
  constant slot sealed-domain-library :: <library>,
    required-init-keyword: library:;
  //
  // The generic defn for this sealed domain.  Filled in at finalization time.
  slot sealed-domain-defn :: false-or(<generic-definition>),
    init-value: #f;
  //
  // The types, once we have evaluated them.  #f until then.
  slot sealed-domain-types :: false-or(<simple-object-vector>),
    init-value: #f;
end;

define method print-message
    (tlf :: <define-sealed-domain-tlf>, stream :: <stream>) => ();
  let parse = tlf.sealed-domain-parse;
  format(stream, "Define Sealed Domain %s (", parse.sealed-domain-name);
  for (type in parse.sealed-domain-type-exprs,
       first? = #t then #f)
    unless (first?)
      write(", ", stream);
    end;
    print-type-expr(type, stream);
  end;
  write(')', stream);
end;


define class <real-define-method-tlf> (<define-method-tlf>)
  //
  // The <method-parse> for the guts of the method being defined.
  constant slot method-tlf-parse :: <method-parse>,
    required-init-keyword: parse:;
  //
  // The name being defined.  Note: this isn't the name of the method, it is
  // the name of the generic function.
  slot method-tlf-base-name :: <name>, required-init-keyword: base-name:;
  //
  // The library doing the defining.
  slot method-tlf-library :: <library>, required-init-keyword: library:;
  //
  // True if the define method is sealed, false if open.
  slot method-tlf-sealed? :: <boolean>, required-init-keyword: sealed:;
  //
  // True if the define method was declared inline, #f if not.
  slot method-tlf-inline? :: <boolean>, required-init-keyword: inline:;
  //
  // True if we can drop calls to this function when the results isn't used
  // because there are no side effects.
  slot method-tlf-flushable? :: <boolean>,
    init-value: #f, init-keyword: flushable:;
  //
  // True if we can move calls to this function around with impunity because
  // the result depends on nothing but the value of the arguments.
  slot method-tlf-movable? :: <boolean>,
    init-value: #f, init-keyword: movable:;
end;



// Print-type-expr
//
// Utility used to print common type expression parses.
// 
define generic print-type-expr
    (expr :: <expression-parse>, stream :: <stream>) => ();

define method print-type-expr
    (expr :: <expression-parse>, stream :: <stream>) => ();
  write("???", stream);
end method print-type-expr;

define method print-type-expr
    (expr :: <varref-parse>, stream :: <stream>) => ();
  write(as(<string>, expr.varref-id.token-symbol), stream);
end method print-type-expr;

define method print-type-expr
    (expr :: <funcall-parse>, stream :: <stream>) => ();
  print-type-expr(expr.funcall-function, stream);
  write('(', stream);
  for (arg in expr.funcall-arguments, first? = #t then #f)
    unless (first?)
      write(", ", stream);
    end unless;
    print-type-expr(arg, stream);
  end for;
  write(')', stream);
end method print-type-expr;

define method print-type-expr
    (expr :: <dot-parse>, stream :: <stream>) => ();
  print-type-expr(expr.dot-operand, stream);
  format(stream, ".%s", as(<string>, expr.dot-name.token-symbol));
end method print-type-expr;


// process-top-level-form

define method process-top-level-form (form :: <define-generic-parse>) => ();
  let name = form.defgeneric-name.token-symbol;
  let (sealed-frag, movable-frag, flushable-frag)
    = extract-properties(form.defgeneric-options,
			 #"sealed", #"movable", #"flushable");
  let sealed? = ~sealed-frag | extract-boolean(sealed-frag);
  let movable? = movable-frag & extract-boolean(movable-frag);
  let flushable? = flushable-frag & extract-boolean(flushable-frag);
  let defn = make(<generic-definition>,
		  name: make(<basic-name>,
			     symbol: name,
			     module: *Current-Module*),
		  source-location: form.source-location,
		  library: *Current-Library*,
		  sealed: sealed?,
		  movable: movable?,
		  flushable: flushable? | movable?);
  note-variable-definition(defn);
  let tlf = make(<explicitly-define-generic-tlf>,
	         defn: defn,
		 source-location: defn.source-location,
		 parse: form);
  defn.function-defn-signature := curry(compute-define-generic-signature, tlf);
  add!(*Top-Level-Forms*, tlf);
end;

define method compute-define-generic-signature
    (tlf :: <explicitly-define-generic-tlf>) => res :: <signature>;
  let parse = tlf.generic-tlf-parse;
  let (signature, anything-non-constant?)
    = compute-signature(parse.defgeneric-parameters, parse.defgeneric-results);
  let defn = tlf.tlf-defn;
  if (anything-non-constant?)
    defn.function-defn-hairy? := #t;
    if (defn.function-defn-ct-value)
      error("noticed that a function was hairy after creating a ct-value.");
    end;
  elseif (defn.generic-defn-sealed?)
    // Fill in the slot so that add-seal's call to function-defn-signature
    // doesn't cause us to recurse forever.
    defn.function-defn-signature := signature;
    add-seal(defn, defn.defn-library, signature.specializers, tlf);
  end;
  signature;
end;



define method process-top-level-form
    (form :: <define-sealed-domain-parse>) => ();
  add!(*Top-Level-Forms*,
       make(<define-sealed-domain-tlf>,
	    parse: form,
	    name: make(<basic-name>,
		       symbol: form.sealed-domain-name.token-symbol,
		       module: *Current-Module*),
	    source-location: form.source-location,
	    library: *Current-Library*));
end;

define method process-top-level-form (form :: <define-method-parse>) => ();
  let parse = form.defmethod-method;
  let name = parse.method-name.token-symbol;
  let (sealed?-frag, inline?-frag, movable?-frag, flushable?-frag)
    = extract-properties(form.defmethod-options,
			 #"sealed", #"inline", #"movable", #"flushable");
  let base-name = make(<basic-name>, symbol: name, module: *Current-Module*);
  let params = parse.method-parameters;
  implicitly-define-generic(*Current-Library*, base-name,
			    params.varlist-fixed.size,
			    params.varlist-rest & ~params.paramlist-keys,
			    params.paramlist-keys & #t);
  let sealed? = sealed?-frag & extract-boolean(sealed?-frag);
  let inline? = inline?-frag & extract-boolean(inline?-frag);
  let movable? = movable?-frag & extract-boolean(movable?-frag);
  let flushable? = flushable?-frag & extract-boolean(flushable?-frag);
  let tlf = make(<real-define-method-tlf>,
		 base-name: base-name,
		 library: *Current-Library*,
		 source-location: form.source-location,
		 sealed: sealed?,
		 inline: inline?,
		 movable: movable?,
		 flushable: flushable? | movable?,
		 parse: parse);
  add!(*Top-Level-Forms*, tlf);
end;

define method implicitly-define-generic
    (library :: <library>, name :: <basic-name>, num-required :: <integer>,
     variable-args? :: <boolean>, keyword-args? :: <boolean>)
    => ();
  let var = find-variable(name);
  unless (var & var.variable-definition)
    let defn = make(<implicit-generic-definition>,
		    name: name, library: library);
    defn.function-defn-signature
      := method ()
	   let specs = make(<list>, size: num-required,
			    fill: object-ctype());
	   let sig = make(<signature>,
			  specializers: specs,
			  rest-type: variable-args? & object-ctype(),
			  keys: keyword-args? & #(),
			  all-keys: #f,
			  returns: wild-ctype());
	   defn.function-defn-signature := sig;
	   add-seal(defn, library, specs, #f);
	   sig;
	 end;
    note-variable-definition(defn);
    add!(*Top-Level-Forms*, make(<implicitly-define-generic-tlf>, defn: defn));
  end;
end;


// finalize-top-level-form

define method finalize-top-level-form
    (tlf :: <explicitly-define-generic-tlf>) => ();
  // Force the processing of the signature and ct-value.
  tlf.tlf-defn.ct-value;
end;

define method finalize-top-level-form (tlf :: <implicitly-define-generic-tlf>)
    => ();
  let defn = tlf.tlf-defn;
  let name = defn.defn-name;
  let var = find-variable(name);
  if (var & var.variable-definition == defn)
    // The implicit defn is still around.  Force the processing of the
    // signature and ct-value.
    defn.ct-value;
  else
    // There is an explicit definition for this variable.  So remove this
    // top level form.
    remove!(*Top-Level-Forms*, tlf);
  end;
end;

define method finalize-top-level-form
    (tlf :: <define-sealed-domain-tlf>) => ();
  let var = find-variable(tlf.sealed-domain-name);
  let defn = var & var.variable-definition;
  unless (instance?(defn, <generic-definition>))
    compiler-error-location
      (tlf, "%s doesn't name a define generic, so can't be sealed.",
       tlf.sealed-domain-name);
  end;
  tlf.sealed-domain-defn := defn;
  local method eval-type (type-expr :: <expression-parse>)
	    => type :: <ctype>;
	  let type = ct-eval(type-expr, #f) | make(<unknown-ctype>);
	  unless (instance?(type, <ctype>))
	    compiler-error-location
	      (tlf,
	       "Parameter in define sealed domain of %s isn't a type:\n  %s",
	       tlf.sealed-domain-name,
	       type);
	  end;
	  type;
	end method eval-type;
  let types = map(eval-type, tlf.sealed-domain-parse.sealed-domain-type-exprs);
  tlf.sealed-domain-types := types;
  add-seal(defn, tlf.sealed-domain-library, types, tlf);
end;

define method finalize-top-level-form (tlf :: <real-define-method-tlf>)
    => ();
  let name = tlf.method-tlf-base-name;
  let (signature, anything-non-constant?)
    = compute-signature(tlf.method-tlf-parse.method-parameters,
			tlf.method-tlf-parse.method-returns);
  let defn = make(<method-definition>,
		  base-name: name,
		  source-location: tlf.source-location,
		  library: tlf.method-tlf-library,
		  signature: signature,
		  hairy: anything-non-constant?,
		  movable: tlf.method-tlf-movable?,
		  flushable: tlf.method-tlf-flushable?,
		  inline-function:
		    if (tlf.method-tlf-inline? & ~anything-non-constant?)
		      rcurry(expand-inline-function, tlf.method-tlf-parse);
		    end);
  tlf.tlf-defn := defn;
  let gf = defn.method-defn-of;
  if (gf)
    ct-add-method(gf, defn);
  end;
  if (tlf.method-tlf-sealed?)
    if (gf)
      add-seal(gf, tlf.method-tlf-library, signature.specializers, tlf);
    else
      compiler-error-location(tlf, "%s doesn't name a generic function", name);
    end;
  end;
end;

define method compute-signature
    (parameters :: <parameter-list>, returns :: <variable-list>)
    => (signature :: <signature>, anything-non-constant? :: <boolean>);
  let anything-non-constant? = #f;
  local
    method maybe-eval-type (param)
      let type = param.param-type;
      if (type)
	let ctype = ct-eval(type, #f);
	select (ctype by instance?)
	  <false> =>
	    anything-non-constant? := #t;
	    make(<unknown-ctype>);
	  <ctype> =>
	    ctype;
	  otherwise =>
	    // ### Should just be a warning.
	    error("%= isn't a type.", ctype);
	end;
      else
	object-ctype();
      end;
    end,
    method make-key-info (param)
      let type = maybe-eval-type(param);
      let default = if (param.param-default)
		      ct-eval(param.param-default, #f);
		    else
		      as(<ct-value>, #f);
		    end;
      let required? = ~(instance?(type, <unknown-ctype>)
			  | default == #f
			  | cinstance?(default, type));
      make(<key-info>, key-name: param.param-keyword, type: type,
	   default: default, required: required?);
    end;
  values(make(<signature>,
	      specializers: map-as(<list>, maybe-eval-type,
				   parameters.varlist-fixed),
	      next: parameters.paramlist-next & #t,
	      rest-type: parameters.varlist-rest & object-ctype(),
	      keys: (parameters.paramlist-keys
		       & map-as(<list>, make-key-info,
				parameters.paramlist-keys)),
	      all-keys: parameters.paramlist-all-keys?,

	      returns:
	        make-values-ctype(map-as(<list>, maybe-eval-type,
			                 returns.varlist-fixed),
				  returns.varlist-rest & object-ctype())),
	 anything-non-constant?);
end;


// CT-value

define method ct-value (defn :: <generic-definition>)
    => res :: false-or(<ct-function>);
  let ctv = defn.function-defn-ct-value;
  if (ctv == #"not-computed-yet")
    // We extract the sig first, because doing so may change the -hairy? flag.
    let sig = defn.function-defn-signature;
    defn.function-defn-ct-value
      := unless (defn.function-defn-hairy?)
	   make(<ct-generic-function>,
		name: format-to-string("%s", defn.defn-name),
		signature: sig,
		definition: defn,
		sealed?: defn.generic-defn-sealed?);
	 end;
  else
    ctv;
  end;
end;

define method ct-value (defn :: <abstract-method-definition>)
    => res :: false-or(<ct-function>);
  let ctv = defn.function-defn-ct-value;
  if (ctv == #"not-computed-yet")
    defn.function-defn-ct-value
      := unless (defn.function-defn-hairy?)
	   make(<ct-method>,
		name: format-to-string("%s", defn.defn-name),
		signature: defn.function-defn-signature,
		definition: defn,
		hidden: instance?(defn, <method-definition>));
	 end;
  else
    ctv;
  end;
end;

define method ct-value (defn :: <accessor-method-definition>)
    => res :: false-or(<ct-function>);
  let ctv = defn.function-defn-ct-value;
  if (ctv == #"not-computed-yet")
    defn.function-defn-ct-value
      := unless (defn.function-defn-hairy?)
	   make(<ct-accessor-method>,
		name: format-to-string("%s", defn.defn-name),
		signature: defn.function-defn-signature,
		definition: defn,
		hidden: #t,
		slot-info: defn.accessor-method-defn-slot-info);
	 end;
  else
    ctv;
  end;
end;


// Compilation of inline functions.

define method expand-inline-function
    (defn :: <abstract-method-definition>, meth :: <method-parse>)
    => res :: false-or(<function-literal>);
  unless (defn.function-defn-hairy?)
    let name = format-to-string("%s", defn.defn-name);
    let component = make(<fer-component>);
    let builder = make-builder(component);
    let lexenv = make(<lexenv>);
    let leaf = fer-convert-method(builder, meth, name, #f, #"local",
				  lexenv, lexenv);
    optimize-component(component, simplify-only: #t);
    leaf;
  end unless;
end method expand-inline-function;


// Compile-top-level-form

define method convert-top-level-form
    (builder :: <fer-builder>, tlf :: <explicitly-define-generic-tlf>) => ();
  convert-generic-definition(builder, tlf.tlf-defn);
end;

define method convert-top-level-form
    (builder :: <fer-builder>, tlf :: <implicitly-define-generic-tlf>) => ();
  let defn = tlf.tlf-defn;
  let name = defn.defn-name;
  let var = find-variable(name);
  if (var & var.variable-definition == defn)
    convert-generic-definition(builder, tlf.tlf-defn);
  end;
end;

define method convert-generic-definition
    (builder :: <fer-builder>, defn :: <generic-definition>) => ();
  if (defn.function-defn-hairy?)
    let policy = $Default-Policy;
    let source = make(<source-location>);
    let args = make(<stretchy-vector>);
    // ### compute the args.
    let temp = make-local-var(builder, #"gf", object-ctype());
    build-assignment
      (builder, policy, source, temp,
       make-unknown-call
	 (builder, ref-dylan-defn(builder, policy, source, #"%make-gf"), #f,
	  as(<list>, args)));
    build-defn-set(builder, policy, source, defn, temp);
  elseif (defn.generic-defn-discriminator)
    make-discriminator(builder, defn);
  end;
end;  

define method convert-top-level-form
    (builder :: <fer-builder>, tlf :: <define-sealed-domain-tlf>) => ();
end;

define method convert-top-level-form
    (builder :: <fer-builder>, tlf :: <real-define-method-tlf>) => ();
  let defn = tlf.tlf-defn;
  let lexenv = make(<lexenv>);
  let leaf = fer-convert-method(builder, tlf.method-tlf-parse,
				format-to-string("%s", defn.defn-name),
				ct-value(defn), #"global", lexenv, lexenv);
  if (defn.function-defn-hairy? 
	| defn.method-defn-of == #f
	| defn.method-defn-of.function-defn-hairy?)
    // We don't use method-defn-of, because that is #f if there is a definition
    // but it isn't a define generic.
    let gf-name = tlf.method-tlf-base-name;
    let gf-var = find-variable(gf-name);
    let gf-defn = gf-var & gf-var.variable-definition;
    if (gf-defn)
      let policy = $Default-Policy;
      let source = make(<source-location>);
      let gf-leaf = build-defn-ref(builder, policy, source, gf-defn);
      build-assignment
	(builder, policy, source, #(),
	 make-unknown-call
	   (builder,
	    ref-dylan-defn(builder, policy, source, #"add-method"), #f,
	    list(gf-leaf, leaf)));
    else
      compiler-error-location
        (tlf,
	 "In %s:\n  no definition for %=, and can't implicitly define it.",
	 tlf, gf-name);
    end;
  end;
end;



// Generic function discriminator functions.

define method generic-defn-discriminator (gf :: <generic-definition>)
    => res :: false-or(<ct-function>);
  if (gf.%generic-defn-discriminator == #"not-computed-yet")
    gf.%generic-defn-discriminator
      := if (discriminator-possible?(gf) & gf.generic-defn-methods.size > 1)
	   let sig = gf.function-defn-signature;
	   make(<ct-function>,
		name: format-to-string("Discriminator for %s", gf.defn-name),
		signature:
		  if (sig.key-infos)
		    make(<signature>,
			 specializers: sig.specializers,
			 rest-type: sig.rest-type | object-ctype(),
			 keys: #(), all-keys: #t,
			 returns: sig.returns);
		  else
		    make(<signature>,
			 specializers: sig.specializers,
			 rest-type: sig.rest-type,
			 returns: sig.returns);
		  end);
	 else
	   #f;
	 end;
  else
    gf.%generic-defn-discriminator;
  end;
end;

define method discriminator-possible? (gf :: <generic-definition>)
    => res :: <boolean>;
  if (gf.generic-defn-sealed? & ~gf.function-defn-hairy?)
    block (return)
      for (meth in gf.generic-defn-methods)
	if (meth.function-defn-hairy?)
	  return(#f);
	end;
	for (method-spec in meth.function-defn-signature.specializers,
	     gf-spec in gf.function-defn-signature.specializers)
	  unless (method-spec == gf-spec
		    | (instance?(method-spec, <cclass>)
			 & method-spec.sealed?
			 & every?(method (subclass :: <cclass>)
				    subclass.abstract? | subclass.unique-id;
				  end,
				  method-spec.subclasses)))
	    return(#f);
	  end;
	end for;
      end for;
      #t;
    end block;
  end if;
end method discriminator-possible?;

define method make-discriminator
    (builder :: <fer-builder>, gf :: <generic-definition>) => ();
  let policy = $Default-Policy;
  let source = make(<source-location>);
  let discriminator = gf.generic-defn-discriminator;
  let name = discriminator.ct-function-name;
  let sig = discriminator.ct-function-signature;

  let vars = make(<stretchy-vector>);
  for (specializer in sig.specializers,
       index from 0)
    let var = make-local-var(builder,
			     as(<symbol>, format-to-string("arg%d", index)),
			     specializer);
    add!(vars, var);
  end;
  let nspecs = vars.size;

  assert(~sig.next?);
  let rest-var
    = if (sig.rest-type)
	let var = make-local-var(builder, #"rest",
				 specifier-type(#"<simple-object-vector>"));
	add!(vars, var);
	var;
      else
	#f;
      end;
  assert(sig.key-infos == #f | sig.key-infos == #());

  let region = build-function-body(builder, policy, source, #f, name,
				   as(<list>, vars), sig.returns, #t);
  let results = make-values-cluster(builder, #"results", sig.returns);
  build-discriminator-tree
    (builder, policy, source, as(<list>, vars), rest-var, results,
     as(<list>, make(<range>, from: 0, below: nspecs)),
     sort-methods-set(gf.generic-defn-methods,
		      make(<vector>, size: nspecs, fill: #f),
		      empty-ctype()),
     gf);
  build-return(builder, policy, source, region, results);
  end-body(builder);
  
  make-function-literal(builder, discriminator, #f, #"global", sig, region);
end;

define method build-discriminator-tree
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     arg-vars :: <list>, rest-var :: false-or(<abstract-variable>),
     results :: <abstract-variable>, remaining-discriminations :: <list>,
     method-set :: <method-set>, gf :: <generic-definition>)
    => ();
  if (empty?(method-set.all-methods))
    build-assignment
      (builder, policy, source, results,
       make-error-operation
	 (builder, policy, source, #"no-applicable-methods-error"));
  elseif (empty?(remaining-discriminations))
    let ordered = method-set.ordered-methods;
    let ordered-ctvs = map(ct-value, ordered.tail);
    assert(every?(identity, ordered-ctvs));
    let ambig-ctvs = map(ct-value, method-set.ambiguous-methods);
    assert(every?(identity, ambig-ctvs));
    if (~empty?(ordered))
      let func-leaf = build-defn-ref(builder, policy, source, ordered.head);
      let ambig-lit = unless (empty?(ambig-ctvs))
			make(<literal-pair>,
			     head: make(<literal-list>,
					contents: ambig-ctvs,
					sharable: #t),
			     tail: make(<literal-empty-list>),
			     sharable: #t);
		      end;
      let next-leaf
	= make-literal-constant(builder,
				make(<literal-list>,
				     contents: ordered-ctvs,
				     tail: ambig-lit,
				     sharable: #t));
      if (rest-var)
	let sig = gf.function-defn-signature;
	if (sig.key-infos)
	  let valid-keys
	    = as(<ct-value>,
		 if (sig.all-keys?)
		   #"all";
		 else
		   block (return)
		     map(curry(as, <ct-value>),
			 reduce(method (keys :: <simple-object-vector>,
					meth :: <method-definition>)
				    => res :: <simple-object-vector>;
				  let sig = meth.function-defn-signature;
				  if (sig.all-keys?)
				    return(#"all");
				  end if;
				  union(keys, map(key-name, sig.key-infos));
				end method,
				#[],
				method-set.all-methods));
		   end block;
		 end if);
	  build-assignment
	    (builder, policy, source, #(),
	     make-unknown-call
	       (builder,
		ref-dylan-defn(builder, policy, source, #"verify-keywords"),
		#f,
		list(rest-var, make-literal-constant(builder, valid-keys))));
	end if;

	let apply-leaf = ref-dylan-defn(builder, policy, source, #"apply");
	let values-leaf = ref-dylan-defn(builder, policy, source, #"values");
	let cluster = make-values-cluster(builder, #"args", wild-ctype());
	build-assignment
	  (builder, policy, source, cluster,
	   make-unknown-call(builder, apply-leaf, #f,
			     pair(values-leaf, arg-vars)));
	build-assignment
	  (builder, policy, source, results,
	   make-operation(builder, <mv-call>,
			  list(func-leaf, next-leaf, cluster),
			  use-generic-entry: #t));
      else
	build-assignment(builder, policy, source, results,
			 make-unknown-call(builder, func-leaf, next-leaf,
					   arg-vars));
      end;
    elseif (~empty?(ambig-ctvs))
      build-assignment
	(builder, policy, source, results,
	 make-error-operation
	   (builder, policy, source, #"ambiguous-method-error",
	    make-literal-constant(builder,
				  make(<literal-list>,
				       contents: ambig-ctvs,
				       sharable: #t))));
    else
      error("Where did all the methods go?");
    end;
  else
    //
    // Figure out which of the remaining positions would be the best one to
    // specialize on.
    let discriminate-on
      = if (remaining-discriminations.tail == #())
	  remaining-discriminations.head;
	else
	  let discriminate-on = #f;
	  let max-distinct-specializers = 0;
	  for (posn in remaining-discriminations)
	    let distinct-specializers
	      = count-distinct-specializers(method-set.all-methods, posn);
	    if (distinct-specializers > max-distinct-specializers)
	      max-distinct-specializers := distinct-specializers;
	      discriminate-on := posn;
	    end;
	  end;
	  discriminate-on;
	end;
    let remaining-discriminations
      = remove(remaining-discriminations, discriminate-on);
    //
    // Divide up the methods based on that one argument.
    let ranges = discriminate-on-one-arg(discriminate-on, method-set, gf);
    //
    // Extract the unique id for this argument.
    let class-temp = make-local-var(builder, #"class", object-ctype());
    let obj-class-leaf
      = ref-dylan-defn(builder, policy, source, #"%object-class");
    build-assignment(builder, policy, source, class-temp,
		     make-unknown-call(builder, obj-class-leaf, #f,
				       list(arg-vars[discriminate-on])));
    let id-temp = make-local-var(builder, #"id", object-ctype());
    let unique-id-leaf
      = ref-dylan-defn(builder, policy, source, #"unique-id");
    build-assignment(builder, policy, source, id-temp,
		     make-unknown-call(builder, unique-id-leaf, #f,
				       list(class-temp)));
    let less-then = ref-dylan-defn(builder, policy, source, #"<");
    //
    // Recursivly build an if tree based on that division of the methods.
    local
      method split-range (min, max)
	if (min == max)
	  let method-set = ranges[min].third;
	  let arg = arg-vars[discriminate-on];
	  let temp = copy-variable(builder, arg);
	  build-assignment
	    (builder, policy, source, temp,
	     make-operation(builder, <truly-the>, list(arg),
			    guaranteed-type: method-set.restriction-type));
	  arg-vars[discriminate-on] := temp;
	  build-discriminator-tree
	    (builder, policy, source, arg-vars, rest-var, results,
	     remaining-discriminations, method-set, gf);
	  arg-vars[discriminate-on] := arg;
	else
	  let half-way-point = ash(min + max, -1);
	  let cond-temp = make-local-var(builder, #"cond", object-ctype());
	  let ctv = as(<ct-value>, ranges[half-way-point].second + 1);
	  let bound = make-literal-constant(builder, ctv);
	  build-assignment(builder, policy, source, cond-temp,
			   make-unknown-call(builder, less-then, #f,
					     list(id-temp, bound)));
	  build-if-body(builder, policy, source, cond-temp);
	  split-range(min, half-way-point);
	  build-else(builder, policy, source);
	  split-range(half-way-point + 1, max);
	  end-body(builder);
	end;
      end;
    split-range(0, ranges.size - 1);
  end;
end;


define method count-distinct-specializers
    (methods :: <list>, arg-posn :: <integer>)
    => count :: <integer>;
  let distinct-specializers = #();
  for (meth in methods)
    let specializer = meth.function-defn-signature.specializers[arg-posn];
    unless (member?(specializer, distinct-specializers))
      distinct-specializers := pair(specializer, distinct-specializers);
    end;
  end;
  distinct-specializers.size;
end;


define class <method-set> (<object>)
  slot arg-classes :: <simple-object-vector>,
    required-init-keyword: arg-classes:;
  slot ordered-methods :: <list>,
    required-init-keyword: ordered:;
  slot ambiguous-methods :: <list>,
    required-init-keyword: ambiguous:;
  slot all-methods :: <list>,
    required-init-keyword: all:;
  slot restriction-type :: <ctype>,
    required-init-keyword: restriction-type:;
end;

// = on <method-set>s
// 
// Two method sets are ``the same'' if they have the same methods, the same
// ordered methods (in the same order), and the same ambigous methods.
// 
define method \= (set1 :: <method-set>, set2 :: <method-set>)
    => res :: <boolean>;
  set1.ordered-methods = set2.ordered-methods
    & same-unordered?(set1.all-methods, set2.all-methods)
    & same-unordered?(set1.ambiguous-methods, set2.ambiguous-methods);
end;

// same-unordered?
//
// Return #t if the two lists have the same elements in any order.
// We assume that there are no duplicates in either list.
// 
define method same-unordered? (list1 :: <list>, list2 :: <list>)
    => res :: <boolean>;
  list1.size == list2.size
    & block (return)
	for (elem in list1)
	  unless (member?(elem, list2))
	    return(#f);
	  end;
	end;
	#t;
      end;
end;

define method discriminate-on-one-arg
    (discriminate-on :: <integer>, method-set :: <method-set>,
     gf :: <generic-definition>)
    => res :: <simple-object-vector>;
  //
  // For each method, associate it with all the direct classes for which that
  // method will be applicable.  Applicable is an object table mapping class
  // objects to sets of methods.  Actually, it maps to pairs where the head
  // is the class again and the tail is the set because portable dylan doesn't
  // include keyed-by.
  let applicable = make(<object-table>);
  let always-applicable = #();
  let gf-spec = gf.function-defn-signature.specializers[discriminate-on];
  for (meth in method-set.all-methods)
    let specializer
      = meth.function-defn-signature.specializers[discriminate-on];
    let direct-classes = find-direct-classes(specializer);
    if (direct-classes)
      for (direct-class in direct-classes)
	let entry = element(applicable, direct-class, default: #f);
	if (entry)
	  entry.tail := pair(meth, entry.tail);
	else
	  applicable[direct-class] := list(direct-class, meth);
	end;
      end;
    elseif (specializer == gf-spec)
      always-applicable := pair(meth, always-applicable);
    end;
  end;
  //
  // Grovel over the direct-class -> applicable-methods mapping producing
  // an equivalent mapping that has direct classes with consecutive unique
  // ids and equivalent method sets merged.
  //
  // Each entry in ranges is a vector of [min, max, method-set].  If max is
  // #f then that means unbounded.  We maintain the invariant that there are
  // no holes.
  //
  let ranges
    = begin
	let arg-classes = copy-sequence(method-set.arg-classes);
	arg-classes[discriminate-on] := gf-spec;
	let method-set = sort-methods-set(always-applicable, arg-classes,
					  gf-spec);
	let possible-direct-classes = find-direct-classes(gf-spec);
	if (possible-direct-classes)
	  for (direct-class in possible-direct-classes.tail,
	       min-id = possible-direct-classes.head.unique-id
		 then min(min-id, direct-class.unique-id),
	       max-id = possible-direct-classes.head.unique-id
		 then max(max-id, direct-class.unique-id))
	  finally
	    list(vector(min-id, max-id, method-set));
	  end;
	else
	  list(vector(0, #f, method-set));
	end;
      end;
  for (entry in applicable)
    let direct-class = entry.head;
    let arg-classes = copy-sequence(method-set.arg-classes);
    arg-classes[discriminate-on] := direct-class;
    let method-set
      = sort-methods-set(concatenate(entry.tail, always-applicable),
			 arg-classes, direct-class.direct-type);
    let this-id = direct-class.unique-id;
    for (remaining = ranges then remaining.tail,
	 prev = #f then remaining,
	 while: begin
		  let range :: <simple-object-vector> = remaining.head;
		  let max = range.second;
		  max & max < this-id;
		end)
    finally
      let range :: <simple-object-vector> = remaining.head;
      let other-set = range.third;
      if (method-set = other-set)
	other-set.restriction-type
	  := ctype-union(other-set.restriction-type,
			 method-set.restriction-type);
      else
	let min = range.first;
	let max = range.second;
	let new = if (this-id == max)
		    if (remaining.tail == #())
		      list(vector(this-id, this-id, method-set));
		    else
		      let next-range :: <simple-object-vector>
			= remaining.tail.head;
		      let next-set = next-range.third;
		      if (method-set = next-set)
			method-set.restriction-type
			  := ctype-union(method-set.restriction-type,
					 next-set.restriction-type);
			pair(vector(this-id, next-range.second, method-set),
			     remaining.tail.tail);
		      else
			pair(vector(this-id, this-id, method-set),
			     remaining.tail);
		      end;
		    end;
		  else
		    pair(vector(this-id, this-id, method-set),
			 pair(vector(this-id + 1, max, other-set),
			      remaining.tail));
		  end;
	if (this-id == min)
	  if (prev)
	    let prev-range :: <simple-object-vector> = prev.head;
	    let prev-set = prev-range.third;
	    if (method-set = prev-set)
	      prev-set.restriction-type
		:= ctype-union(prev-set.restriction-type,
			       method-set.restriction-type);
	      prev-range.second := new.head.second;
	      prev.tail := new.tail;
	    else
	      prev.tail := new;
	    end;
	  else
	    ranges := new;
	  end;
	else
	  range.second := this-id - 1;
	  remaining.tail := new;
	end;
      end;
    end;
  end;
  //
  // Convert ranges into a vector and return it.
  as(<simple-object-vector>, ranges);
end;
    

define method sort-methods-set
    (methods :: <list>, arg-classes :: <simple-object-vector>,
     restriction-type :: <ctype>)
    => res :: <method-set>;
  let (ordered, ambiguous) = sort-methods(methods, arg-classes);
  make(<method-set>, arg-classes: arg-classes, ordered: ordered,
       ambiguous: ambiguous, all: methods, restriction-type: restriction-type);
end;


// Dump stuff.

define method dump-od
    (tlf :: <real-define-method-tlf>, state :: <dump-state>) => ();
  let defn = tlf.tlf-defn;
  let gf = defn.method-defn-of;
  if (gf & name-inherited-or-exported?(defn.defn-name))
    dump-od(defn, state);
    if (tlf.method-tlf-sealed? & defn.defn-library ~== gf.defn-library)
      dump-simple-object(#"sealed-domain", state,
			 gf,
			 defn.defn-library,
			 defn.function-defn-signature.specializers);
    end if;
  end if;
end method dump-od;

define method dump-od
    (tlf :: <define-sealed-domain-tlf>, state :: <dump-state>) => ();
  if (tlf.sealed-domain-defn.defn-library ~== tlf.sealed-domain-library)
    assert(name-inherited-or-exported?(tlf.sealed-domain-name));
    dump-simple-object(#"sealed-domain", state,
		       tlf.sealed-domain-defn,
		       tlf.sealed-domain-library,
		       tlf.sealed-domain-types);
  end if;
end method dump-od;

add-od-loader(*compiler-dispatcher*, #"sealed-domain",
	      method (state :: <load-state>) => res :: <false>;
		let gf = load-object-dispatch(state);
		let library = load-object-dispatch(state);
		let types = load-object-dispatch(state);
		assert-end-object(state);
		add-seal(gf, library, types, #f);
	      end method);

