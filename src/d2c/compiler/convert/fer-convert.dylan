module: fer-convert
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/convert/fer-convert.dylan,v 1.51 1996/02/09 20:39:44 ram Exp $
copyright: Copyright (c) 1994  Carnegie Mellon University
	   All rights reserved.

define constant <var-or-vars>
  = type-union(<abstract-variable>, <list>);


// Result stuff.

define constant <result-designator>
  = one-of(#"nothing", #"assignment", #"let", #"expr", #"leaf");

define constant <result-datum>
  = type-union(<var-or-vars>, <symbol>, <false>);

define constant <result> = false-or(<fer-expression>);


define generic deliver-result (builder :: <fer-builder>, policy :: <policy>,
			       source :: <source-location>, 
			       want :: <result-designator>,
			       datum :: <result-datum>,
			       result :: <result>)
    => res :: <result>;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"nothing",
			      datum :: <result-datum>,
			      result :: <result>)
    => res :: <result>;
  #f;
end;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"nothing",
			      datum :: <result-datum>,
			      result :: <operation>)
    => res :: <result>;
  build-assignment(builder, policy, source, #(), result);
  #f;
end;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"assignment",
			      datum :: <result-datum>,
			      result :: <result>)
    => res :: <result>;
  build-assignment
    (builder, policy, source, datum,
     result | make-literal-constant(builder, make(<literal-false>)));

  #f;
end;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"let",
			      datum :: <result-datum>,
			      result :: <result>)
    => res :: <result>;
  build-let
    (builder, policy, source, datum,
     result | make-literal-constant(builder, make(<literal-false>)));

  #f;
end;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"expr",
			      datum :: <result-datum>,
			      result :: <result>)
    => res :: <result>;
  result | make-literal-constant(builder, make(<literal-false>));
end;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"leaf",
			      datum :: <result-datum>,
			      result :: <result>)
    => res :: <result>;
  result | make-literal-constant(builder, make(<literal-false>));
end;

define method deliver-result (builder :: <fer-builder>, policy :: <policy>,
			      source :: <source-location>, 
			      want == #"leaf",
			      datum :: <result-datum>,
			      result :: <operation>)
    => res :: <result>;
  let temp = make-local-var(builder, datum, object-ctype());
  build-assignment(builder, policy, source, temp, result);
  temp;
end;



// fer-convert

define constant source = make(<source-location>);

define generic fer-convert (builder :: <fer-builder>,
			    form :: <constituent>,
			    lexenv :: <lexenv>,
			    want :: <result-designator>,
			    datum :: <result-datum>)
    => res :: <result>;


define method fer-convert-body (builder :: <fer-builder>,
				body :: <simple-object-vector>,
				lexenv :: <lexenv>,
				want :: <result-designator>,
				datum :: <result-datum>)
    => res :: <result>;
  if (empty?(body))
    deliver-result(builder, lexenv.lexenv-policy, source, want, datum, #f);
  else
    for (i from 0 below body.size - 1)
      fer-convert(builder, body[i], lexenv, #"nothing", #f);
    end;
    fer-convert(builder, body[body.size - 1], lexenv, want, datum);
  end;
end;

define method fer-convert (builder :: <fer-builder>, form :: <constituent>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let expansion = expand(form, lexenv);
  if (expansion)
    fer-convert-body(builder, expansion, lexenv, want, datum);
  else
    error("Can't fer-convert %=", form);
  end;
end;

define method fer-convert (builder :: <fer-builder>, form :: <let>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let bindings = form.let-bindings;
  let paramlist = bindings.bindings-parameter-list;
  let params = paramlist.paramlist-required-vars;
  let rest = paramlist.paramlist-rest;
  let rest-temp
    = if (rest)
	if (rest.param-type)
	  compiler-error-location(form, "let #rest variables can't have types");
	end;
	make-local-var(builder, rest.param-name.token-symbol, object-ctype());
      end;
  let nfixed = params.size;
  let types = make(<vector>, size: nfixed);
  let type-temps = make(<vector>, size: nfixed);
  let temps = make(<list>, size: nfixed);

  // Make temps for all the values and evaluate any types that arn't constant.
  for (param in params, index from 0, temp-ptr = temps then temp-ptr.tail)
    let type
      = if (param.param-type)
	  let ct-type = ct-eval(param.param-type, lexenv);
	  if (ct-type)
	    ct-type;
	  else
	    let type-local
	      = make-local-var(builder, #"type", specifier-type(#"<type>"));
	    fer-convert(builder, param.param-type,
			make(<lexenv>, inside: lexenv),
			#"assignment", type-local);
	    let type-temp
	      = make-lexical-var(builder, #"type", source,
				 specifier-type(#"<type>"));
	    build-let(builder, lexenv.lexenv-policy, source,
		      type-temp, type-local);
	    type-temps[index] := type-temp;
	    object-ctype();
	  end;
	else
	  object-ctype();
	end;
    types[index] := type;
    temp-ptr.head
      := make-local-var(builder, param.param-name.token-symbol, type);
  end;

  // Evaluate the expression, getting the results in the temps
  if (rest)
    let cluster = make-values-cluster(builder, #"temps", wild-ctype());
    fer-convert(builder, bindings.bindings-expression,
		make(<lexenv>, inside: lexenv), #"assignment", cluster);
    build-assignment
      (builder, lexenv.lexenv-policy, source,
       concatenate(temps, list(rest-temp)),
       make-operation(builder, <fer-primitive>,
		      list(cluster,
			   make-literal-constant(builder,
						 as(<ct-value>, temps.size))),
		      name: #"canonicalize-results"));
  else
    fer-convert(builder, bindings.bindings-expression,
		make(<lexenv>, inside: lexenv), #"assignment", temps);
  end;

  // Copy the temps into real lexical vars and update the lexenv with em.
  for (param in params, type in types, type-temp in type-temps, temp in temps)
    let name = param.param-name;
    let var = make-lexical-var(builder, name.token-symbol, source, type);
    add-binding(lexenv, name, var, type-var: type-temp);
    build-let(builder, lexenv.lexenv-policy, source, var,
	      if (type-temp)
		make-check-type-operation
		  (builder, lexenv.lexenv-policy, source,
		   temp, type-temp);
	      else
		temp;
	      end);
  end;
  if (rest)
    let name = rest.param-name;
    let var = make-lexical-var(builder, name.token-symbol, source,
			       object-ctype());
    add-binding(lexenv, name, var);
    build-let(builder, lexenv.lexenv-policy, source, var, rest-temp);
  end;

  // Supply #f as the result.
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 make-literal-constant(builder, make(<literal-false>)));
end;

define method fer-convert (builder :: <fer-builder>, form :: <let-handler>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  // First, build the call to push-handler.
  let policy = lexenv.lexenv-policy;
  let func = ref-dylan-defn(builder, policy, source, #"push-handler");
  let args = make(<stretchy-vector>);
  add!(args,
       fer-convert(builder, form.handler-type,
		   make(<lexenv>, inside: lexenv), #"leaf", #"type"));
  add!(args,
       fer-convert(builder, form.handler-expression,
		   make(<lexenv>, inside: lexenv), #"leaf", #"handler"));
  for (prop in form.handler-plist)
    let lit = prop.prop-keyword.token-literal;
    add!(args, make-literal-constant(builder, lit));
    add!(args,
	 fer-convert(builder, prop.prop-value,
		     make(<lexenv>, inside: lexenv), #"leaf",
		     lit.literal-value));
  end;
  build-assignment(builder, policy, source, #(),
		   make-unknown-call(builder, func, #f, as(<list>, args)));

  // Record the fact that we've added another handler.
  lexenv.lexenv-handlers := lexenv.lexenv-handlers + 1;

  // Supply #f as the result.
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 make-literal-constant(builder, make(<literal-false>)));
end;


define method fer-convert (builder :: <fer-builder>, form :: <local>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let specializer-lexenv = make(<lexenv>, inside: lexenv);
  let vars
    = map(method (meth)
	    let name = meth.method-name;
	    let var = make-lexical-var(builder, name.token-symbol, source,
				       function-ctype());
	    add-binding(lexenv, name, var);
	    var;
	  end,
	  form.local-methods);
  for (var in vars, meth in form.local-methods)
    build-let(builder, lexenv.lexenv-policy, source, var,
	      fer-convert-method(builder, meth, #f, #f, #"local",
				 specializer-lexenv, lexenv));
  end;

  // Supply #f as the result.
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 make-literal-constant(builder, make(<literal-false>)));
end;

define method fer-convert (builder :: <fer-builder>, form :: <literal-ref>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 make-literal-constant(builder, form.litref-literal));
end;

define constant $arg-names
  = #[#"arg0", #"arg1", #"arg2", #"arg3", #"arg4", #"arg5", #"arg6", #"arg7",
	#"arg8", #"arg9"];

define method fer-convert (builder :: <fer-builder>, form :: <funcall>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let expansion = expand(form, lexenv);
  if (expansion)
    fer-convert-body(builder, expansion, lexenv, want, datum);
  else
    let func = fer-convert(builder, form.funcall-function,
			   make(<lexenv>, inside: lexenv),
			   #"leaf", #"function");
    let ops = make(<list>, size: form.funcall-arguments.size);
    for (arg in form.funcall-arguments,
	 op-ptr = ops then op-ptr.tail,
	 index from 0)
      let name = if (index < $arg-names.size)
		   $arg-names[index];
		 else
		   as(<symbol>, format-to-string("arg%d", index));
		 end;
      op-ptr.head := fer-convert(builder, arg, make(<lexenv>, inside: lexenv),
				 #"leaf", name);
    end;
    deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		   make-unknown-call(builder, func, #f, ops));
  end;
end;

define method fer-convert (builder :: <fer-builder>, form :: <dot>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let expansion = expand(form, lexenv);
  if (expansion)
    fer-convert-body(builder, expansion, lexenv, want, datum);
  else
    let arg-leaf = fer-convert(builder, form.dot-operand,
			       make(<lexenv>, inside: lexenv),
			       #"leaf", #"argument");
    let fun-leaf = fer-convert(builder, make(<varref>, id: form.dot-name),
			       make(<lexenv>, inside: lexenv),
			       #"leaf", #"function");
    deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		   make-unknown-call(builder, fun-leaf, #f, list(arg-leaf)));
  end;
end;

define method fer-convert (builder :: <fer-builder>, form :: <varref>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let id = form.varref-id;
  let binding = find-binding(lexenv, id);
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 if (binding)
		   binding.binding-var;
		 else
		   let name = id-name(id);
		   let var = find-variable(name);
		   let defn = var & var.variable-definition;
		   if (defn)
		     fer-convert-defn-ref(builder, lexenv.lexenv-policy,
					  source, defn);
		   else
		     compiler-warning-location(form, "Undefined variable: %s",
		     			       name);
		     make-error-operation
		       (builder, lexenv.lexenv-policy, source,
			"Undefined variable: %s",
			make-literal-constant
			  (builder,
			   as(<ct-value>, format-to-string("%s", name))));
		   end;
		 end);
end;

define method fer-convert (builder :: <fer-builder>, form :: <assignment>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let expansion = expand(form, lexenv);
  if (expansion)
    fer-convert-body(builder, expansion, lexenv, want, datum);
  else
    let place = form.assignment-place;
    unless (instance?(place, <varref>))
      error("Assignment to complex place didn't get expanded away?");
    end;
    let id = place.varref-id;
    let binding = find-binding(lexenv, id);
    if (binding)
      let temp = fer-convert(builder, form.assignment-value,
			     make(<lexenv>, inside: lexenv),
			     #"leaf", #"new-value");
      let checked
	= if (binding.binding-type-var)
	    let checked
	      = make-local-var(builder, #"checked-new-value", object-ctype());
	    build-assignment(builder, lexenv.lexenv-policy, source, checked,
			     make-check-type-operation
			       (builder, lexenv.lexenv-policy, source,
				temp, binding.binding-type-var));
	    checked;
	  else
	    temp;
	  end;
      build-assignment(builder, lexenv.lexenv-policy, source,
		       binding.binding-var, checked);
      deliver-result(builder, lexenv.lexenv-policy, source,
		     want, datum, checked);
    else
      let name = id-name(id);
      let var = find-variable(name);
      let defn = var & var.variable-definition;
      if (~defn)
	compiler-warning-location(place, "Undefined variable: %s", name);
	deliver-result
	  (builder, lexenv.lexenv-policy, source, want, datum,
	   make-error-operation
	     (builder, lexenv.lexenv-policy, source,
	      "Undefined variable: %s",
	      make-literal-constant
		(builder,
		 as(<ct-value>, format-to-string("%s", name)))));
      elseif (~instance?(defn, <variable-definition>))
	compiler-warning-location(
	  place, "Attept to assign constant module variable: %s",
	  name);
	deliver-result
	  (builder, lexenv.lexenv-policy, source, want, datum,
	   make-error-operation
	     (builder, lexenv.lexenv-policy, source,
	      "Can't assign constant module variable: %s",
	      make-literal-constant
		(builder,
		 as(<ct-value>, format-to-string("%s", name)))));
      else
	let temp = fer-convert(builder, form.assignment-value,
			       make(<lexenv>, inside: lexenv),
			       #"leaf", #"new-value");
	let checked
	  = if (defn.var-defn-type-defn)
	      let checked = make-local-var(builder, #"checked-new-value",
					   object-ctype());
	      build-assignment
		(builder, lexenv.lexenv-policy, source, checked,
		 make-check-type-operation
		   (builder, lexenv.lexenv-policy, source, temp,
		    fer-convert-defn-ref(builder, lexenv.lexenv-policy, source,
					 defn.var-defn-type-defn)));
	      checked;
	    else
	      temp;
	    end;
	fer-convert-defn-set(builder, lexenv.lexenv-policy, source,
			     defn, checked);
	deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		       checked);
      end;
    end;
  end;
end;

define method fer-convert (builder :: <fer-builder>, form :: <begin>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let lexenv = make(<body-lexenv>, inside: lexenv);
  let result = fer-convert-body(builder, form.begin-body, lexenv, want, datum);
  finalize-body(builder, lexenv);
  result;
end;

define method finalize-body (builder :: <fer-builder>, lexenv :: <body-lexenv>)
    => ();
  unless (zero?(lexenv.lexenv-handlers))
    let policy = lexenv.lexenv-policy;
    let pop-handler = ref-dylan-defn(builder, policy, source, #"pop-handler");
    for (i from 0 below lexenv.lexenv-handlers)
      build-assignment(builder, policy, source, #(),
		       make-unknown-call(builder, pop-handler, #f, #()));
    end;
  end;
end;

define method fer-convert (builder :: <fer-builder>, form :: <bind-exit>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let nlx-info = make(<nlx-info>);
  let name = form.exit-name;
  let state-type = specifier-type(#"<raw-pointer>");
  let saved-state-var = make-local-var(builder, #"saved-state", state-type);
  let policy = lexenv.lexenv-policy;
  let body-region
    = build-function-body(builder, policy, source, #t,
			  format-to-string("Block Body for %s",
					   name.token-symbol),
			  list(saved-state-var), wild-ctype(), #f);
  let body-sig = make(<signature>, specializers: list(state-type));
  let body-literal
    = make-function-literal(builder, #f, #f, #"local", body-sig, body-region);
  let catcher-var
    = make-lexical-var(builder, symcat(name.token-symbol, "-catcher"),
		       source, object-ctype());
  build-let(builder, policy, source, catcher-var,
	    make-operation(builder, <make-catcher>, list(saved-state-var),
			   nlx-info: nlx-info));
  let lexenv = make(<lexenv>, inside: lexenv);
  let exit = make-lexical-var(builder, name.token-symbol, source,
			      function-ctype());
  add-binding(lexenv, name, exit);
  build-let(builder, policy, source, exit,
	    make-exit-function(builder, nlx-info, catcher-var));
  let cluster = make-values-cluster(builder, #"results", wild-ctype());
  fer-convert-body(builder, form.exit-body, lexenv, #"assignment", cluster);
  build-assignment
    (builder, policy, source, #(),
     make-operation(builder, <disable-catcher>, list(catcher-var),
		    nlx-info: nlx-info));
  build-return(builder, policy, source, body-region, cluster);
  end-body(builder);
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 make-operation(builder, <catch>, list(body-literal),
				nlx-info: nlx-info));
end;

define method fer-convert (builder :: <fer-builder>, form :: <if>,
			   lexenv :: <lexenv>,
			   want :: one-of(#"leaf", #"expr"),
			   datum :: <result-datum>)
    => res :: <result>;
  let leaf = make-local-var(builder, datum, object-ctype());
  fer-convert(builder, form, lexenv, #"assignment", leaf);
  leaf;
end;

define method fer-convert (builder :: <fer-builder>, form :: <if>,
			   lexenv :: <lexenv>,
			   want :: one-of(#"nothing", #"assignment"),
			   datum :: <result-datum>)
    => res :: <result>;
  build-if-body(builder, lexenv.lexenv-policy, source,
		fer-convert(builder, form.if-condition,
			    make(<lexenv>, inside: lexenv),
			    #"leaf", #"condition"));
  fer-convert-body(builder, form.if-consequent, make(<lexenv>, inside: lexenv),
		   want, datum);
  build-else(builder, lexenv.lexenv-policy, source);
  fer-convert-body(builder, form.if-alternate, make(<lexenv>, inside: lexenv),
		   want, datum);
  end-body(builder);
  #f;
end;

define method fer-convert (builder :: <fer-builder>, form :: <method-ref>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let temp = make-local-var(builder, #"method", function-ctype());
  build-assignment(builder, lexenv.lexenv-policy, source, temp,
		   fer-convert-method(builder, form.method-ref-method, #f, #f,
				      #"local", lexenv, lexenv));
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum, temp);
end;

define method fer-convert (builder :: <fer-builder>, form :: <mv-call>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let operands = form.mv-call-operands;
  let func = fer-convert(builder, operands[0], make(<lexenv>, inside: lexenv),
			 #"leaf", #"function");
  let clusters = #();
  for (index from 1 below operands.size)
    let name = as(<symbol>, format-to-string("cluster%d", index - 1));
    let var = make-values-cluster(builder, name, wild-ctype());
    clusters := pair(var, clusters);
    fer-convert(builder, operands[index], make(<lexenv>, inside: lexenv),
		#"assignment", var);
  end;
  let cluster
    = if (clusters.tail == #())
	clusters.head;
      else
	let temp = make-values-cluster(builder, #"composite", wild-ctype());
	build-assignment(builder, lexenv.lexenv-policy, source, temp,
			 make-operation(builder, <fer-primitive>,
					reverse!(clusters),
					name: #"merge-clusters"));
	temp;
      end;
  deliver-result(builder, lexenv.lexenv-policy, source, want, datum,
		 make-operation(builder, <fer-mv-call>,
				list(func, cluster),
				use-generic-entry: #f));
end;

define method fer-convert (builder :: <fer-builder>, form :: <primitive>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let name = form.primitive-name.token-symbol;
  let info = primitive-info-or-lose(name);
  let operands = form.primitive-operands;
  let ops = make(<list>, size: operands.size);
  local
    method repeat (op-ptr :: <list>, index :: <integer>, types :: <list>)
      if (op-ptr == #())
	unless (types == #() | types.head == #"rest")
	  compiler-error-location(
	    form, "Too few arguments to %%primitive %s", name);
	end;
      elseif (types == #())
	compiler-error-location(
	  form, "Too many arguments to %%primitive %s", name);
      else
	let (type, remaining-types)
	  = if (types.head == #"rest")
	      values(types.tail.head, types);
	    else
	      values(types.head, types.tail);
	    end;
	let name = if (index < $arg-names.size)
		     $arg-names[index];
		   else
		     as(<symbol>, format-to-string("arg%d", index));
		   end;
	let arg = operands[index];
	let lexenv = make(<lexenv>, inside: lexenv);
	let var = if (type == #"cluster")
		    make-values-cluster(builder, name, wild-ctype());
		  else
		    make-local-var(builder, name, type);
		  end;
	fer-convert(builder, arg, lexenv, #"assignment", var);
	op-ptr.head := var;
	repeat(op-ptr.tail, index + 1, remaining-types);
      end;
    end;
  repeat(ops, 0, info.priminfo-arg-types);
  deliver-result
    (builder, lexenv.lexenv-policy, source, want, datum,
     make-operation(builder, <fer-primitive>, ops, name: name));
end;

define method fer-convert (builder :: <fer-builder>, form :: <uwp>,
			   lexenv :: <lexenv>, want :: <result-designator>,
			   datum :: <result-datum>)
    => res :: <result>;
  let policy = lexenv.lexenv-policy;
  let cleanup-builder = make-builder(builder);
  let cleanup-region
    = build-function-body(cleanup-builder, policy, source, #t,
			  "Unwind-Protect Cleanup", #(),
			  make-values-ctype(#(), #f), #f);
  let cleanup-literal
    = make-function-literal(cleanup-builder, #f, #f, #"local",
			    make(<signature>, specializers: #(),
				 returns: make-values-ctype(#(), #f)),
			    cleanup-region);

  build-unwind-protect-body(builder, policy, source, cleanup-literal);
  build-assignment
    (builder, policy, source, #(),
     make-unknown-call
       (builder,
	ref-dylan-defn(builder, policy, source, #"push-unwind-protect"),
	#f,
	list(cleanup-literal)));
  let res = fer-convert-body(builder, form.uwp-body,
			     make(<lexenv>, inside: lexenv),
			     want, datum);
  build-assignment
    (builder, policy, source, #(),
     make-unknown-call
       (builder,
	ref-dylan-defn(builder, policy, source, #"pop-unwind-protect"),
	#f, #()));
  build-assignment(builder, policy, source, #(),
		   make-unknown-call(builder, cleanup-literal, #f, #()));
  end-body(builder);

  fer-convert-body(cleanup-builder, form.uwp-cleanup,
		   make(<lexenv>, inside: lexenv),
		   #"nothing", #f);
  build-return(cleanup-builder, policy, source, cleanup-region, #());
  end-body(cleanup-builder);

  res;
end;


// Method conversion.

define method fer-convert-method
    (builder :: <fer-builder>, meth :: <method-parse>,
     name :: false-or(<string>), ctv :: false-or(<ct-function>),
     visibility :: <function-visibility>, specializer-lexenv :: <lexenv>,
     lexenv :: <lexenv>)
    => res :: <leaf>;
  let lexenv = make(<body-lexenv>, inside: lexenv);

  local
    method param-type-and-var (param)
      if (param.param-type)
	let type = ct-eval(param.param-type, specializer-lexenv);
	if (type)
	  values(type, #f);
	else
	  let temp = make-local-var(builder, #"type",
				    specifier-type(#"<type>"));
	  fer-convert(builder, param.param-type,
		      make(<lexenv>, inside: specializer-lexenv),
		      #"assignment", temp);
	  let var = make-lexical-var(builder, #"type", source,
				     specifier-type(#"<type>"));
	  build-let(builder, specializer-lexenv.lexenv-policy, source,
		    var, temp);
	  values(object-ctype(), var);
	end;
      else
	values(object-ctype(), #f);
      end;
    end;

  let paramlist = meth.method-param-list;
  let vars = make(<stretchy-vector>);
  let body-builder = make-builder(builder);

  let specializers = make(<stretchy-vector>);
  let specializer-leaves = make(<stretchy-vector>);
  let non-const-arg-types? = #f;
  for (param in paramlist.paramlist-required-vars)
    let (type, type-var) = param-type-and-var(param);
    add!(specializers, type);
    let name = param.param-name;
    let var = make-lexical-var(builder, name.token-symbol, source, type);
    add-binding(lexenv, name, var, type-var: type-var);
    add!(vars, var);
    if (type-var)
      non-const-arg-types? := #t;
      add!(specializer-leaves, type-var);
    else
      add!(specializer-leaves, make-literal-constant(builder, type));
    end;
  end;
  let next = paramlist.paramlist-next;
  let next-info-var
    = next & make-lexical-var(builder, #"next-method-info", source,
			      specifier-type(#"<list>"));
  let rest = paramlist.paramlist-rest;
  let rest-var
    = if (rest)
	if (rest.param-type)
	  compiler-error-location(meth, "#rest parameters can't have a type");
	end;
	let name = rest.param-name;
	let var = make-lexical-var(builder, name.token-symbol, source,
				   // ### should this be <object>?
				   specifier-type(#"<simple-object-vector>"));
	add-binding(lexenv, name, var);
	var;
      elseif (next & paramlist.paramlist-keys)
	make-lexical-var(builder, #"rest", source,
			 specifier-type(#"<simple-object-vector>"));
      end;
  if (next)
    let var = make-lexical-var(builder, next.token-symbol, source,
			       object-ctype());
    let cookie-args = make(<stretchy-vector>);
    if (rest-var)
      add!(cookie-args,
	   ref-dylan-defn(builder, lexenv.lexenv-policy, source,
			  #"%make-next-method-cookie"));
    end;
    add!(cookie-args, next-info-var);
    for (var in vars)
      add!(cookie-args, var);
    end;
    if (rest-var)
      add!(cookie-args, rest-var);
    end;
    build-let
      (body-builder, lexenv.lexenv-policy, source, var,
       make-unknown-call
	 (builder,
	  ref-dylan-defn(builder, lexenv.lexenv-policy, source,
			 if (rest-var)
			   #"apply";
			 else
			   #"%make-next-method-cookie";
			 end),
	  #f, as(<list>, cookie-args)));
    add!(vars, next-info-var);
    add-binding(lexenv, next, var);
  end;
  if (rest-var)
    add!(vars, rest-var);
  end;
  let keyword-infos
    = if (paramlist.paramlist-keys)
	let infos = make(<stretchy-vector>);
	for (param in paramlist.paramlist-keys)
	  let name = param.param-name;
	  let (type, type-var) = param-type-and-var(param);
	  let var = make-lexical-var(builder, name.token-symbol, source, type);
	  let default = if (param.param-default)
			  ct-eval(param.param-default, lexenv);
			else
			  make(<literal-false>);
			end;
	  if (default)
	    add!(infos,
		 make(<key-info>, key-name: param.param-keyword,
		      default: default, type: type,
		      required: ~cinstance?(default, type)));
	    add!(vars, var);
	  else
	    let temp = make-local-var(builder, name.token-symbol, type);
	    let pre-default
	      = make-lexical-var(builder, name.token-symbol, source, type);
	    let info = make(<key-info>, key-name: param.param-keyword,
			    type: type, default: #f);
	    add!(infos, info);
	    add!(vars, pre-default);
	    let supplied?-var
	      = make-lexical-var(builder,
				 as(<symbol>,
				    format-to-string("%s-supplied?",
						     name.token-symbol)),
				 source,
				 specifier-type(#"<boolean>"));
	    let rep = pick-representation(type, #"speed");
	    if (rep.representation-has-bottom-value?)
	      build-let(body-builder, lexenv.lexenv-policy,
			source, supplied?-var,
			make-operation
			  (builder, <fer-primitive>, list(pre-default),
			   name: #"initialized?"));
	    else
	      add!(vars, supplied?-var);
	    end;
	    build-if-body(body-builder, lexenv.lexenv-policy,
			  source, supplied?-var);
	    build-assignment(body-builder, lexenv.lexenv-policy,
			     source, temp, pre-default);
	    build-else(body-builder, lexenv.lexenv-policy,
		       source);
	    fer-convert(body-builder, param.param-default,
			make(<lexenv>, inside: lexenv),
			#"assignment", temp);
	    end-body(body-builder);
	    build-let(body-builder, lexenv.lexenv-policy, source,
		      var, temp);
	  end;
	  if (type-var)
	    let checked = make-lexical-var(builder, name.token-symbol, source,
					   object-ctype());
	    build-assignment
	      (body-builder, lexenv.lexenv-policy, source, checked,
	       make-check-type-operation
		 (builder, lexenv.lexenv-policy, source, var, type-var));
	    add-binding(lexenv, name, checked, type-var: type-var);
	  else
	    add-binding(lexenv, name, var);
	  end;
	end;
	as(<list>, infos);
      end;
  
  let returns = meth.method-returns;
  let fixed-results = make(<stretchy-vector>);
  let checked-fixed-results = make(<stretchy-vector>);
  let result-types = make(<stretchy-vector>);
  let result-type-leaves = make(<stretchy-vector>);
  let non-const-result-types? = #f;
  let result-check-builder = make-builder(builder);
  for (param in returns.paramlist-required-vars)
    let (type, type-var) = param-type-and-var(param);
    add!(result-types, type);
    let var = make-local-var(builder, param.param-name.token-symbol, type);
    if (type-var)
      non-const-result-types? := #t;
      add!(result-type-leaves, type-var);
      let temp = make-local-var(result-check-builder,
				param.param-name.token-symbol,
				type);
      add!(fixed-results, temp);
      build-assignment
	(result-check-builder, specializer-lexenv.lexenv-policy, source, var,
	 make-check-type-operation
	   (result-check-builder, specializer-lexenv.lexenv-policy, source,
	    temp, type-var));
    else
      add!(result-type-leaves, make-literal-constant(builder, type));
      add!(fixed-results, var);
    end;
    add!(checked-fixed-results, var);
  end;

  let (rest-type, rest-type-leaf, need-to-check-rest?)
    = if (returns.paramlist-rest)
	let (type, type-var) = param-type-and-var(returns.paramlist-rest);

	if (type-var)
	  non-const-result-types? := #t;
	  values(type, type-var, #t);
	else
	  values(type,
		 make-literal-constant(builder, type),
		 ~(type == object-ctype()));
	end;
      end;

  let name = if (name)
	       name;
	     elseif (meth.method-name)
	       as(<string>, meth.method-name.token-symbol);
	     else
	       "Anonymous Method";
	     end;
  let vars = as(<list>, vars);
  let result-type = make-values-ctype(as(<list>, result-types), rest-type);
  let lambda?
    = visibility == #"local" | non-const-arg-types? | non-const-result-types?;
  let function-region
    = build-function-body(builder, lexenv.lexenv-policy, source, lambda?,
			  name, vars, result-type, ~lambda?);

  build-region(builder, builder-result(body-builder));

  if (rest-type)
    let rest-symbol = returns.paramlist-rest.param-name.token-symbol;
    if (empty?(fixed-results) & ~need-to-check-rest?)
      let cluster
	= make-values-cluster(builder, rest-symbol, wild-ctype());
      fer-convert-body(builder, meth.method-body, lexenv,
		       #"assignment", cluster);
      finalize-body(builder, lexenv);
      build-return(builder, lexenv.lexenv-policy, source, function-region,
		   cluster);
    else
      let cluster = make-values-cluster(builder, #"results", wild-ctype());
      fer-convert-body(builder, meth.method-body, lexenv,
		       #"assignment", cluster);
      finalize-body(builder, lexenv);

      let rest-result
	= make-local-var(builder, rest-symbol, object-ctype());
      build-assignment
	(builder, lexenv.lexenv-policy, source,
	 concatenate(as(<list>, fixed-results), list(rest-result)),
	 make-operation(builder, <fer-primitive>,
			list(cluster,
			     make-literal-constant
			       (builder,
				as(<ct-value>, fixed-results.size))),
			name: #"canonicalize-results"));

      build-region(builder, builder-result(result-check-builder));
      if (need-to-check-rest?)
	// ### Need to check the type of the rest results.
	#f;
      end;

      let checked-cluster
	= make-values-cluster(builder, #"results", wild-ctype());

      let args = make(<stretchy-vector>);
      add!(args,
	   ref-dylan-defn(builder, lexenv.lexenv-policy, source, #"values"));
      for (fixed in checked-fixed-results)
	add!(args, fixed);
      end;
      add!(args, rest-result);
      build-assignment
	(builder, lexenv.lexenv-policy, source, checked-cluster,
	 make-unknown-call
	   (builder,
	    ref-dylan-defn(builder, lexenv.lexenv-policy, source, #"apply"),
	    #f,
	    as(<list>, args)));
      build-return(builder, lexenv.lexenv-policy, source,
		   function-region, checked-cluster);
    end;
  else
    fer-convert-body(builder, meth.method-body, lexenv,
		     #"assignment", as(<list>, fixed-results));
    finalize-body(builder, lexenv);
    build-region(builder, builder-result(result-check-builder));
    build-return(builder, lexenv.lexenv-policy, source,
		 function-region, as(<list>, checked-fixed-results));
  end;

  end-body(builder);

  let signature
    = make(<signature>,
	   specializers: as(<list>, specializers),
	   next: next & #t,
	   rest-type: rest & object-ctype(),
	   keys: keyword-infos & as(<list>, keyword-infos),
	   all-keys: paramlist.paramlist-all-keys?,
	   returns: make-values-ctype(as(<list>, result-types),
	   			      rest-type));

  if (non-const-arg-types? | non-const-result-types?)
    assert(ctv == #f);
    local
      method build-call (name, args)
	let temp = make-local-var(builder, name, object-ctype());
	build-assignment
	  (builder, lexenv.lexenv-policy, source, temp,
	   make-unknown-call
	     (builder,
	      ref-dylan-defn(builder, lexenv.lexenv-policy, source, name), #f,
	      as(<list>, args)));
	temp;
      end;
    build-call(#"%make-method",
	       list(build-call(#"list", specializer-leaves),
		    build-call(#"list", result-type-leaves),
		    rest-type-leaf
		      | make-literal-constant(builder, make(<literal-false>)),
		    make-function-literal(builder, #f, #f, #"local", signature,
					  function-region)));
  else
    make-function-literal(builder, ctv, #t, visibility, signature,
			  function-region);
  end;
end;


// Definition reference conversion.

define generic fer-convert-defn-ref
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     defn :: <definition>)
    => res :: <leaf>;


define method fer-convert-defn-ref
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     defn :: <abstract-constant-definition>)
    => res :: <leaf>;
  let value = ct-value(defn);
  if (instance?(value, <eql-ct-value>))
    make-literal-constant(builder, value);
  elseif (value)
    make-definition-constant(builder, defn);
  else
    let type = defn.defn-type | object-ctype();
    let temp = make-local-var(builder, #"temp", type);
    build-assignment(builder, policy, source, temp,
		     make-operation(builder, <module-var-ref>, #(),
				    derived-type: type,
				    var: defn));
    temp;
  end;
end method;

define method fer-convert-defn-ref
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     defn :: <variable-definition>)
 => res :: <leaf>;
  let type = defn.defn-type | object-ctype();
  let temp = make-local-var(builder, #"temp", type);
  build-assignment(builder, policy, source, temp,
		   make-operation(builder, <module-var-ref>, #(),
				  derived-type: type,
				  var: defn));
  temp;
end method;


define generic fer-convert-defn-set
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     defn :: <definition>, new-value :: <leaf>)
    => ();

define method fer-convert-defn-set
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     defn :: <definition>, new-value :: <leaf>)
    => ();
  build-assignment(builder, policy, source, #(),
		   make-operation(builder, <module-var-set>, list(new-value),
				  var: defn));
end;



// Random utilities.

define method ref-dylan-defn
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     name :: <symbol>)
    => res :: <leaf>;
  let defn = dylan-defn(name);
  unless (defn)
    error("%s undefined?", name);
  end;
  fer-convert-defn-ref(builder, policy, source, defn)
end;

define method make-check-type-operation
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     value-leaf :: <leaf>, type-leaf :: <leaf>)
    => res :: <operation>;
  make-unknown-call
    (builder,
     ref-dylan-defn(builder, policy, source, #"check-type"),
     #f,
     list(value-leaf, type-leaf));
end method;

define method make-error-operation
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     msg :: <byte-string>, #rest args)
    => res :: <operation>;
  make-unknown-call
    (builder,
     ref-dylan-defn(builder, $Default-Policy, make(<source-location>),
		     #"error"),
     #f,
     pair(make-literal-constant(builder, as(<ct-value>, msg)),
	  as(<list>, args)));
end method;

define method make-error-operation
    (builder :: <fer-builder>, policy :: <policy>, source :: <source-location>,
     symbol :: <symbol>, #rest args)
    => res :: <operation>;
  make-unknown-call
    (builder,
     ref-dylan-defn(builder, $Default-Policy, make(<source-location>),
		     symbol),
     #f,
     as(<list>, args));
end method;

