module: cback
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/cback/primemit.dylan,v 1.21 1996/01/12 00:58:31 wlott Exp $
copyright: Copyright (c) 1995  Carnegie Mellon University
	   All rights reserved.


define method default-primitive-emitter
    (results :: false-or(<definition-site-variable>),
     operation :: <primitive>, file :: <file-state>)
    => ();
  let stream = make(<byte-string-output-stream>);

  let use-deliver-result?
    = if (results)
	if (results.definer-next)
	  write('[', stream);
	  for (var = results then var.definer-next,
	       first? = #t then #f,
	       while: var)
	    unless (first?)
	      write(", ", stream);
	    end;
	    write(c-name-and-rep(var, file), stream);
	  end;
	  write("] = ", stream);
	  #f;
	elseif (instance?(results.var-info, <values-cluster-info>))
	  let (bottom-name, top-name) = produce-cluster(results, file);
	  format(stream, "%s = ", top-name);
	  #f;
	else
	  #t;
	end;
      else
	#f;
      end;

  let info = operation.info;
  format(stream, "### %%primitive %s (", info.primitive-name);
  block (return)
    for (dep = operation.depends-on then dep.dependent-next,
	 types = info.primitive-arg-types then types.tail,
	 first? = #t then #f,
	 while: dep)
      let type = types.head;
      if (type == #"rest")
	let rest-type = types.tail.head;
	let rep = pick-representation(rest-type, #"speed");
	for (dep = dep then dep.dependent-next,
	     first? = first? then #f,
	     while: dep)
	  unless (first?)
	    write(", ", stream);
	  end;
	  write(ref-leaf(rep, dep.source-exp, file), stream);
	end;
	return();
      else
	unless (first?)
	  write(", ", stream);
	end;
	if (type == #"cluster")
	  let (bottom-name, top-name)
	    = consume-cluster(dep.source-exp, file);
	  format(stream, "%s...%s", bottom-name, top-name);
	else
	  let rep = pick-representation(type, #"speed");
	  write(ref-leaf(rep, dep.source-exp, file), stream);
	end;
      end;
    end;
  end;
  write(')', stream);
  let expr = stream.string-output-stream-string;

  if (use-deliver-result?)
    let (name, rep) = c-name-and-rep(results, file);
    deliver-result(results, expr, rep, #f, file);
  else
    format(file.file-guts-stream, "%s;\n", expr);
  end;
end;


define method extract-operands
    (operation :: <operation>, file :: <file-state>,
     #rest representations)
    => (#rest str :: <string>);
  let results = make(<stretchy-vector>);
  block (return)
    for (op = operation.depends-on then op.dependent-next,
	 index from 0)
      if (index == representations.size)
	if (op)
	  error("Too many operands for %s", operation);
	else
	  return();
	end;
      else
	let rep = representations[index];
	if (rep == #"rest")
	  if (index + 2 == representations.size)
	    let rep = representations[index + 1];
	    for (op = op then op.dependent-next)
	      add!(results, ref-leaf(rep, op.source-exp, file));
	    end;
	    return();
	  end;
	elseif (op)
	  add!(results, ref-leaf(rep, op.source-exp, file));
	else
	  error("Not enough operands for %s", operation);
	end;
      end;
    end;
  end;
  apply(values, results);
end;



// Argument primitives.

define-primitive-emitter
  (#"extract-args",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let nargs = extract-operands(operation, file, *long-rep*);
     let expr = stringify("((void *)(orig_sp - ", nargs, "))");
     deliver-result(results, expr, *ptr-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extract-arg",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (args, index) = extract-operands(operation, file,
					  *ptr-rep*, *long-rep*);
     let expr = stringify("(((descriptor_t *)", args, ")[", index, "])");
     deliver-result(results, expr, *general-rep*, #t, file);
   end);

define-primitive-emitter
  (#"make-rest-arg",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (args, nfixed, nargs)
       = extract-operands(operation, file,
			  *ptr-rep*, *long-rep*, *long-rep*);
     let cur-top = cluster-names(file.file-cur-stack-depth);
     let mra-defn = dylan-defn(#"make-rest-arg");
     let mra-info = find-main-entry-info(mra-defn, file);
     let expr
       = stringify(main-entry-name(mra-info, file), '(', cur-top,
		   ", (descriptor_t *)", args, " + ", nfixed, ", ",
		   nargs, " - ", nfixed, ')');
     deliver-result(defines, expr, *heap-rep*, #t, file);
   end);

define-primitive-emitter
  (#"pop-args",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let stream = file.file-guts-stream;
     let args = extract-operands(operation, file, *ptr-rep*);
     spew-pending-defines(file);
     assert(zero?(file.file-cur-stack-depth));
     if (results)
       format(stream, "cluster_0_top = orig_sp;\n");
     end;
     format(stream, "orig_sp = %s;\n", args);
     deliver-cluster(results, "orig_sp", "cluster_0_top", 0, file);
   end);


// Value primitives.

define-primitive-emitter
  (#"canonicalize-results",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let stream = file.file-guts-stream;
     let cluster = operation.depends-on.source-exp;
     let nfixed-leaf = operation.depends-on.dependent-next.source-exp;
     let nfixed = if (instance?(nfixed-leaf, <literal-constant>))
		    as(<integer>, nfixed-leaf.value.literal-value);
		  else
		    error("nfixed arg to %%%%primitive canonicalize-results "
			    "isn't constant?");
		  end;
     let (bottom-name, top-name) = consume-cluster(cluster, file);
     format(stream, "%s = pad_cluster(%s, %s, %d);\n",
	    top-name, bottom-name, top-name, nfixed);
     let results = make(<vector>, size: nfixed + 1);
     for (index from 0 below nfixed)
       results[index] := pair(stringify(bottom-name, '[', index, ']'),
			      *general-rep*);
     end;
     let mra-defn = dylan-defn(#"make-rest-arg");
     let mra-info = find-main-entry-info(mra-defn, file);
     results[nfixed]
       := pair(stringify(main-entry-name(mra-info, file), '(', top-name, ", ",
			 bottom-name, " + ", nfixed, ", ",
			 top-name, " - ", bottom-name, " - ", nfixed, ')'),
	       *heap-rep*);
     deliver-results(defines, results, #t, file);
   end);

define-primitive-emitter
  (#"merge-clusters",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     local
       method repeat (dep :: false-or(<dependency>))
	   => (bottom-name, top-name, values-count);
	 if (dep)
	   let (next-bottom, next-top, values-count)
	     = repeat(dep.dependent-next);
	   let cluster = dep.source-exp;
	   let (my-bottom, my-top) = consume-cluster(cluster, file);
	   unless (next-bottom == #f | my-top = next-bottom)
	     error("Merging two clusters that arn't adjacent?");
	   end;
	   values(my-bottom, next-top | my-top,
		  values-count + cluster.derived-type.min-values);
	 else
	   values(#f, #f, 0);
	 end;
       end;
     let (bottom-name, top-name, values-count)
       = repeat(operation.depends-on);
     if (bottom-name)
       deliver-cluster(defines, bottom-name, top-name, values-count,
		       file);
     else
       deliver-results(defines, #[], #f, file);
     end;
   end);

define-primitive-emitter
  (#"values-sequence",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let vec = extract-operands(operation, file, *heap-rep*);
     let (cur-sp, new-sp)
       = cluster-names(file.file-cur-stack-depth);
     format(file.file-guts-stream,
	    "%s = values_sequence(%s, %s);\n", new-sp, cur-sp, vec);
     deliver-cluster(defines, cur-sp, new-sp, 0, file);
   end);

define-primitive-emitter
  (#"values",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let results = make(<stretchy-vector>);
     for (dep = operation.depends-on then dep.dependent-next,
	  while: dep)
       let expr = ref-leaf(*general-rep*, dep.source-exp, file);
       add!(results, pair(expr, *general-rep*));
     end;
     deliver-results(defines, results, #f, file);
   end);


// Allocation primitives.

define-primitive-emitter
  (#"allocate",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let bytes = extract-operands(operation, file, *long-rep*);
     deliver-result(defines, stringify("allocate(", bytes, ')'),
		    *heap-rep*, #f, file);
   end);

define-primitive-emitter
  (#"make-data-word-instance",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let cclass = operation.derived-type;
     let target-rep = pick-representation(cclass, #"speed");
     let source-rep
       = pick-representation(cclass.all-slot-infos[1].slot-type, #"speed");
     unless (source-rep == target-rep
	       | (representation-data-word-member(source-rep)
		    = representation-data-word-member(target-rep)))
       error("The instance and slot representations don't match in a "
	       "data-word reference?");
     end;
     let source = extract-operands(operation, file, source-rep);
     deliver-result(defines, source, target-rep, #f, file);
   end);


// Foreign code interface primitives.

define-primitive-emitter
  (#"call-out",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let stream = make(<byte-string-output-stream>);

     let func-dep = operation.depends-on;
     let func = func-dep.source-exp;
     unless (instance?(func, <literal-constant>)
	       & instance?(func.value, <literal-string>))
       error("function in call-out isn't a constant string?");
     end;
     format(stream, "%s(", func.value.literal-value);

     let res-dep = func-dep.dependent-next;
     let result-rep = rep-for-c-type(res-dep.source-exp);

     local
       method repeat (dep :: false-or(<dependency>), first? :: <boolean>)
	 if (dep)
	   unless (first?)
	     write(", ", stream);
	   end;
	   let rep = rep-for-c-type(dep.source-exp);
	   let next = dep.dependent-next;
	   format(stream, "(%s)%s",
		  rep.representation-c-type,
		  ref-leaf(rep, next.source-exp, file));
	   repeat(next.dependent-next, #f);
	 end;
       end;
     repeat(res-dep.dependent-next, #t);

     write(')', stream);

     spew-pending-defines(file);
     if (result-rep)
       deliver-result(defines, string-output-stream-string(stream),
		      result-rep, #t, file);
     else
       format(file.file-guts-stream, "%s;\n",
	      string-output-stream-string(stream));
       deliver-results(defines, #[], #f, file);
     end;
   end);

define-primitive-emitter
  (#"c-include",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let include = operation.depends-on.source-exp;
     unless (instance?(include, <literal-constant>)
	       & instance?(include.value, <literal-string>))
       error("file name in c-include isn't a constant string?");
     end;
     maybe-emit-include(include.value.literal-value, file);
     deliver-results(defines, #[], #f, file);
   end);

define-primitive-emitter
  (#"c-decl",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let decl = operation.depends-on.source-exp;
     unless (instance?(decl, <literal-constant>)
	       & instance?(decl.value, <literal-string>))
       error("decl in c-decl isn't a constant string?");
     end;
     format(file.file-body-stream, "%s\n",
	    decl.value.literal-value);
     deliver-results(defines, #[], #f, file);
   end);

define-primitive-emitter
  (#"c-expr",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let stream = make(<byte-string-output-stream>);

     let res-dep = operation.depends-on;
     let result-rep = rep-for-c-type(res-dep.source-exp);

     let expr = res-dep.dependent-next.source-exp;
     unless (instance?(expr, <literal-constant>)
	       & instance?(expr.value, <literal-string>))
       error("expr in c-expr isn't a constant string?");
     end;

     spew-pending-defines(file);
     if (result-rep)
       deliver-result(defines, expr.value.literal-value,
		      result-rep, #t, file);
     else
       format(file.file-guts-stream, "%s;\n",
	      expr.value.literal-value);
       deliver-results(defines, #[], #f, file);
     end;
   end);


define method rep-for-c-type (leaf :: <leaf>)
    => rep :: false-or(<representation>);
  unless (instance?(leaf, <literal-constant>))
    error("Type spec in call-out isn't a constant?");
  end;
  let ct-value = leaf.value;
  unless (instance?(ct-value, <literal-symbol>))
    error("Type spec in call-out isn't a symbol?");
  end;
  let c-type = ct-value.literal-value;
  select (c-type)
    #"long" => *long-rep*;
    #"int" => *int-rep*;
    #"unsigned-int" => *uint-rep*;
    #"short" => *short-rep*;
    #"unsigned-short" => *ushort-rep*;
    #"char" => *byte-rep*;
    #"unsigned-char" => *ubyte-rep*;
    #"ptr" => *ptr-rep*;
    #"float" => *float-rep*;
    #"double" => *double-rep*;
    #"long-double" => *long-double-rep*;
    #"void" => #f;
  end;
end;

define-primitive-emitter
  (#"c-string",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let leaf = operation.depends-on.source-exp;
     unless (instance?(leaf, <literal-constant>))
       error("argument to c-string isn't a constant?");
     end;
     let lit = leaf.value;
     unless (instance?(lit, <literal-string>))
       error("argument to c-string isn't a string?");
     end;
     let stream = make(<byte-string-output-stream>);
     write('"', stream);
     for (char in lit.literal-value)
       let code = as(<integer>, char);
       if (char < ' ')
	 select (char)
	   '\b' => write("\\b", stream);
	   '\t' => write("\\t", stream);
	   '\n' => write("\\n", stream);
	   '\r' => write("\\r", stream);
	   otherwise =>
	     format(stream, "\\0%d%d",
		    ash(code, -3),
		    logand(code, 7));
	 end;
       elseif (char == '"' | char == '\\')
	 format(stream, "\\%c", char);
       elseif (code < 127)
	 write(char, stream);
       elseif (code < 256)
	 format(stream, "\\%d%d%d",
		ash(code, -6),
		logand(ash(code, -3), 7),
		logand(code, 7));
       else
	 error("%= can't be represented in a C string.");
       end;
     end;
     write('"', stream);
     deliver-result(defines, string-output-stream-string(stream), *ptr-rep*,
		    #f, file);
   end);


// Predicate primitives

define-primitive-emitter
  (#"as-boolean",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let expr = extract-operands(operation, file, *boolean-rep*);
     deliver-result(defines, expr, *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"not",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let arg = operation.depends-on.source-exp;
     let expr
       = if (csubtype?(arg.derived-type, specifier-type(#"<boolean>")))
	   stringify('!', ref-leaf(*boolean-rep*, arg, file));
	 else
	   stringify('(', ref-leaf(*heap-rep*, arg, file), " == obj_False)");
	 end;
     deliver-result(defines, expr, *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"==",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *heap-rep*, *heap-rep*);
     deliver-result(defines, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"initialized?",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let expr = stringify('(', extract-operands(operation, file, *heap-rep*),
			  " != NULL)");
     deliver-result(defines, expr, *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"initial-symbols",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     extract-operands(operation, file);
     deliver-result(defines, "initial_symbols", *heap-rep*, #f, file);
   end);
   


// NLX primitives.

define-primitive-emitter
  (#"current-sp",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let sp = cluster-names(file.file-cur-stack-depth);
     deliver-result(defines, sp, *ptr-rep*, #t, file);
   end);

define-primitive-emitter
  (#"unwind-stack",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let sp = cluster-names(file.file-cur-stack-depth);
     format(file.file-guts-stream, "%s = %s;\n",
	    sp, extract-operands(operation, file, *ptr-rep*));
     deliver-results(defines, #[], #f, file);
   end);

define-primitive-emitter
  (#"throw",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let state-expr
       = ref-leaf(*ptr-rep*, operation.depends-on.source-exp, file);
     let cluster = operation.depends-on.dependent-next.source-exp;
     let (bottom-name, top-name) = consume-cluster(cluster, file);
     spew-pending-defines(file);
     format(file.file-guts-stream,
	    "throw(%s, %s);\n", state-expr, top-name);
   end);


// Fixnum primitives.

define-primitive-emitter
  (#"fixnum-=",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"fixnum-<",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " < ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-+",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " + ", y, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-*",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " * ", y, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum--",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " - ", y, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-negative",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-rep*);
     deliver-result(defines, stringify("(- ", x, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-divide",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     spew-pending-defines(file);
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-results(defines,
		     vector(pair(stringify('(', x, " / ", y, ')'), *long-rep*),
			    pair(stringify('(', x, " % ", y, ')'),
				 *long-rep*)),
		     #f, file);
   end);

define-primitive-emitter
  (#"fixnum-logior",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " | ", y, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-logxor",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " ^ ", y, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-logand",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " & ", y, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-lognot",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-rep*);
     deliver-result(defines, stringify("(~ ", x, ')'), *long-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"fixnum-shift-left",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " << ", y, ')'),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"fixnum-shift-right",
   method (defines :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-rep*, *long-rep*);
     deliver-result(defines, stringify('(', x, " >> ", y, ')'),
		    *long-rep*, #f, file);
   end);


// Single float primitives.

define-primitive-emitter
  (#"fixed-as-single",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-rep*);
     deliver-result(results, stringify("((float)", x, ')'),
		    *float-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-as-single",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("((float)", x, ')'),
		    *float-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-as-single",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("((float)", x, ')'),
		    *float-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-<",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " < ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-<=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file, *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " <= ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file, *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-==",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     // ### This isn't right -- should really be doing a bitwise comparison.
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-~=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " != ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-+",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " + ", y, ')'), *float-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-*",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " * ", y, ')'), *float-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single--",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " - ", y, ')'), *float-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-/",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *float-rep*, *float-rep*);
     deliver-result(results, stringify('(', x, " / ", y, ')'), *float-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-abs",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("fabsf(", x, ')'), *float-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"single-negative",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("(-", x, ')'), *float-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-floor",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("((long)floor(", x, "))"),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-ceiling",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("((long)ceil(", x, "))"),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-round",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("((long)rint(", x, "))"),
		    *long-rep*, #f, file);
   end);


// Double float primitives.

define-primitive-emitter
  (#"fixed-as-double",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-rep*);
     deliver-result(results, stringify("((double)", x, ')'),
		    *double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-as-double",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("((double)", x, ')'),
		    *double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-as-double",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("((double)", x, ')'),
		    *double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-<",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results, stringify('(', x, " < ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-<=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results,
		    stringify('(', x, " <= ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-==",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     // ### This isn't right -- should really be doing a bitwise comparison.
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-~=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results,
		    stringify('(', x, " != ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-+",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results, stringify('(', x, " + ", y, ')'), *double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-*",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results, stringify('(', x, " * ", y, ')'), *double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double--",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results, stringify('(', x, " - ", y, ')'), *double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-/",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *double-rep*, *double-rep*);
     deliver-result(results, stringify('(', x, " / ", y, ')'), *double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-abs",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("fabsf(", x, ')'), *double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-negative",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("(-", x, ')'), *double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"double-floor",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("((long)floor(", x, "))"),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-ceiling",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("((long)ceil(", x, "))"),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-round",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("((long)rint(", x, "))"),
		    *long-rep*, #f, file);
   end);


// Extended float primitives.

define-primitive-emitter
  (#"fixed-as-extended",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-rep*);
     deliver-result(results, stringify("((long double)", x, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"single-as-extended",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *float-rep*);
     deliver-result(results, stringify("((long double)", x, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"double-as-extended",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *double-rep*);
     deliver-result(results, stringify("((long double)", x, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-<",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results, stringify('(', x, " < ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"extended-<=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results,
		    stringify('(', x, " <= ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"extended-=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-==",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     // ### This isn't right -- should really be doing a bitwise comparison.
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-~=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results,
		    stringify('(', x, " != ", y, ')'), *boolean-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"extended-+",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results, stringify('(', x, " + ", y, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-*",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results, stringify('(', x, " * ", y, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended--",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results, stringify('(', x, " - ", y, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-/",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file,
				   *long-double-rep*, *long-double-rep*);
     deliver-result(results, stringify('(', x, " / ", y, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-abs",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("fabsf(", x, ')'),
		    *long-double-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-negative",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("(-", x, ')'), *long-double-rep*,
		    #f, file);
   end);

define-primitive-emitter
  (#"extended-floor",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("((long)floor(", x, "))"),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-ceiling",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("((long)ceil(", x, "))"),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"extended-round",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-double-rep*);
     deliver-result(results, stringify("((long)rint(", x, "))"),
		    *long-rep*, #f, file);
   end);


// raw pointer operations.

define-primitive-emitter
  (#"make-raw-pointer",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *long-rep*);
     deliver-result(results, stringify("((void *)", x, ')'),
		    *ptr-rep*, #f, file);
   end);

define-primitive-emitter
  (#"raw-pointer-address",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let x = extract-operands(operation, file, *ptr-rep*);
     deliver-result(results, stringify("((long)", x, ')'),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"pointer-+",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file, *ptr-rep*, *long-rep*);
     deliver-result(results,
		    stringify("((void *)((char *)", x, " + ", y, "))"),
		    *ptr-rep*, #f, file);
   end);

define-primitive-emitter
  (#"pointer--",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file, *ptr-rep*, *ptr-rep*);
     deliver-result(results,
		    stringify("((char *)", x, " - (char *)", y, ')'),
		    *long-rep*, #f, file);
   end);

define-primitive-emitter
  (#"pointer-<",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file, *ptr-rep*, *ptr-rep*);
     deliver-result(results,
		    stringify("((char *)", x, " < (char *)", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"pointer-=",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let (x, y) = extract-operands(operation, file, *ptr-rep*, *ptr-rep*);
     deliver-result(results, stringify('(', x, " == ", y, ')'),
		    *boolean-rep*, #f, file);
   end);

define-primitive-emitter
  (#"pointer-deref",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let type-dep = operation.depends-on;
     let rep = rep-for-c-type(type-dep.source-exp);
     let ptr-dep = type-dep.dependent-next;
     let ptr = ref-leaf(*ptr-rep*, ptr-dep.source-exp, file);
     let offset-dep = ptr-dep.dependent-next;
     let offset = ref-leaf(*long-rep*, offset-dep.source-exp, file);

     spew-pending-defines(file);
     
     deliver-result(results,
		    stringify("(*(", rep.representation-c-type, " *)((char *)",
			      ptr, " + ", offset, " ))"),
		    rep, #f, file);
   end);

define-primitive-emitter
  (#"pointer-deref-setter",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let new-dep = operation.depends-on;
     let type-dep = new-dep.dependent-next;
     let rep = rep-for-c-type(type-dep.source-exp);
     let new = ref-leaf(rep, new-dep.source-exp, file);
     let ptr-dep = type-dep.dependent-next;
     let ptr = ref-leaf(*ptr-rep*, ptr-dep.source-exp, file);
     let offset-dep = ptr-dep.dependent-next;
     let offset = ref-leaf(*long-rep*, offset-dep.source-exp, file);

     spew-pending-defines(file);
     format(file.file-guts-stream, "*(%s *)((char *)%s + %s) = %s;\n",
	    rep.representation-c-type, ptr, offset, new);
     
     deliver-results(results, #[], #f, file);
   end);

define-primitive-emitter
  (#"vector-elements",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let vec = operation.depends-on.source-exp;
     let vec-expr = extract-operands(operation, file, *heap-rep*);
     deliver-result(results,
		    stringify("((void *)((char *)", vec-expr, " + ",
			      dylan-slot-offset(vec.derived-type, #"%element"),
			      "))"),
		    *ptr-rep*, #f, file);
   end);

define-primitive-emitter
  (#"object-address",
   method (results :: false-or(<definition-site-variable>),
	   operation :: <primitive>,
	   file :: <file-state>)
       => ();
     let object = extract-operands(operation, file, *heap-rep*);
     deliver-result(results,
		    stringify("((void *)", object, ')'),
		    *ptr-rep*, #f, file);
   end);
