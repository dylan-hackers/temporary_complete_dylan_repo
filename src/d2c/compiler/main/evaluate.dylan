module: main
rcs-header: $Header: /scm/cvs/src/d2c/compiler/main/evaluate.dylan,v 1.1.2.37 2002/08/10 18:31:50 gabor Exp $
copyright: see below

//======================================================================
//
// Copyright (c) 2002  Gwydion Dylan Maintainers
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

// This file contains an interpreter that can give back <ct-values> for
// certain FER constructions.


define variable *interpreter-library* = #f;

define generic evaluate(expression, environment :: <interpreter-environment>)
 => val :: <ct-value>;

define constant $empty-environment 
  = curry(error, "trying to access %= in an empty environment");

define constant <interpreter-environment> :: <type> = <object>;

define method evaluate(expression :: <string>, env :: <interpreter-environment> )
 => (val :: <ct-value>)
  if(~ *interpreter-library*)
    *interpreter-library* := find-library(#"foo", create: #t); // ### FIXME: arbitrary name
    seed-representations();
    inherit-slots();
    inherit-overrides();
    layout-instance-slots();
  end if;
  *Current-Library* := *interpreter-library*;
  *Current-Module*  := find-module(*interpreter-library*, #"dylan-user");
  *top-level-forms* := make(<stretchy-vector>);
  let tokenizer = make(<lexer>, 
                       source: make(<source-buffer>, 
                                    buffer: as(<byte-vector>, expression)),
                       start-line: 0,
                       start-posn: 0);
  parse-source-record(tokenizer);
  for(tlf in *top-level-forms*)
    format(*debug-output*, "got tlf %=", tlf);
    force-output(*debug-output*);
    
    select(tlf by instance?)
      <expression-tlf> =>
        let expression = tlf.tlf-expression;
        format(*debug-output*, ", an expression \n%=\n", expression);
        force-output(*debug-output*);
        let component = make(<fer-component>);
        let builder = make-builder(component);
        let result-type = object-ctype();
        let result-var = make-local-var(builder, #"result", result-type);
        fer-convert(builder, expression,
                    lexenv-for-tlf(tlf), #"assignment", result-var);
        convert-top-level-form(builder, tlf);
        let inits = builder-result(builder);
        
        let name-obj = make(<anonymous-name>, location: tlf.source-location);
        let init-function-region
          = build-function-body(builder, $Default-Policy,
                                tlf.source-location, #f,
                                name-obj, #(), result-type, #t);
        build-region(builder, inits);
        build-return
          (builder, $Default-Policy, tlf.source-location,
           init-function-region, result-var);
        
        end-body(builder);
        
        format(*debug-output*, "\n\nBefore optimization:\n");
        dump-fer(component);
        optimize-component(*current-optimizer*, component);
        format(*debug-output*, "\n\nAfter optimization:\n");
        dump-fer(component);
        force-output(*debug-output*);
        
        let value
          = block ()
              fer-evaluate(init-function-region.body, env)
              exception (ret :: <return-condition>)
              ret.exit-result
            end;
    
        format(*debug-output*, "\n\nevaluated expression: %=\n", value);
        format(*debug-output*, "\n\nBinding of return variable: %=\n", result-var);
        force-output(*debug-output*);
      otherwise =>
        let component = make(<fer-component>);
        let builder = make-builder(component);
        convert-top-level-form(builder, tlf);
        let inits = builder-result(builder);
        let name-obj = make(<anonymous-name>, location: tlf.source-location);
        unless (instance?(inits, <empty-region>))
          let result-type = make-values-ctype(#(), #f);
          let source = make(<source-location>);
          let init-function
            = build-function-body
            (builder, $Default-Policy, source, #f,
             name-obj,
             #(), result-type, #t);
          build-region(builder, inits);
          build-return
            (builder, $Default-Policy, source, init-function, #());
          end-body(builder);
          let sig = make(<signature>, specializers: #(), returns: result-type);
          let ctv = make(<ct-function>, name: name-obj, signature: sig);
          make-function-literal(builder, ctv, #"function", #"global",
                                sig, init-function);
          format(*debug-output*, "\n\nBefore optimization:\n");
          dump-fer(component);
          optimize-component(*current-optimizer*, component);
          format(*debug-output*, "\n\nAfter optimization:\n");
          dump-fer(component);
          force-output(*debug-output*);
          
          format(*debug-output*, "\n\nevaluated expression: %=\n",
                 evaluate(init-function.body,
                          env));
          force-output(*debug-output*);
        end;
    end select;
  end for;
  as(<ct-value>, #f);
end method evaluate;




// ######### fer-evaluate #########
//
// accumulate bindings in environment, and take non local exits when we have a result
//
define generic fer-evaluate(region :: <region>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;

define class <exit-condition>(<condition>)
  constant slot exit-block :: <block-region-mixin>, required-init-keyword: block:;
  constant slot exit-environment :: <interpreter-environment>, required-init-keyword: environment:;
end class <exit-condition>;

define method fer-evaluate(block-region :: <block-region>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  block ()
    fer-evaluate(block-region.body, environment)
  exception (exit :: <exit-condition>, test: method(exit :: <exit-condition>)
                                               exit.exit-block == block-region
                                             end method)
    exit.exit-environment;
  end block
end;

define method fer-evaluate(loop :: <loop-region>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  local method repeat(environment :: <interpreter-environment>)
      repeat(fer-evaluate(loop.body, environment))
    end method;
  repeat(environment);
end;

define method fer-evaluate(exit :: <exit>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  signal(make(<exit-condition>, block: exit.block-of, environment: environment));
end;



define method fer-evaluate(simple :: <simple-region>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  fer-gather-assigns-bindings(simple.first-assign, environment);
end;

define class <return-condition>(<exit-condition>)
  constant slot exit-result :: <ct-value>, required-init-keyword: result:;
end class <return-condition>;

/*
define method fer-evaluate(func :: <function-region>, environment :: <interpreter-environment>)
 => environment :: <never-returns>;
  block ()
    fer-evaluate(init-function-region.body, environment)
  exception (return :: <return-condition>, test: method(exit :: <exit-condition>)
    return.exit-result;
  end block
end;
*/

define method fer-evaluate(return :: <return>, environment :: <interpreter-environment>)
 => environment :: <never-returns>;
  signal(make(<return-condition>, block: return.block-of,
				  result: evaluate(return.depends-on.source-exp, environment),
				  environment: environment));
end;

define method fer-evaluate(compound :: <compound-region>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  let regions = compound.regions;
  fer-evaluate-regions(regions.head, regions.tail, environment)
end;

define method fer-evaluate(the-if :: <if-region>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  let test-value
    = evaluate(the-if.depends-on.source-exp,
                              environment);
  if(test-value == as(<ct-value>, #f))
    fer-evaluate(the-if.else-region, environment);
  else
    fer-evaluate(the-if.then-region, environment);
  end if;
end;

// ########## fer-evaluate-regions ##########
define method fer-evaluate-regions(region :: <region>, more-regions == #(), environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  error("Did not encounter a <return> in control flow... \nregion: %=", region);
end;

define method fer-evaluate-regions(the-if :: <if-region>, more-regions == #(), environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  fer-evaluate(the-if, environment);
  error("Did not encounter a <return> in control flow of any of the <if-region>s legs");
end;

define method fer-evaluate-regions(region :: <region>, more-regions :: <list>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  fer-evaluate-regions(more-regions.head, more-regions.tail, fer-evaluate(region, environment))
end;

define method fer-evaluate-regions(return :: <return>, more-regions == #(), environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  fer-evaluate(return, environment)
end;

define method fer-evaluate-regions(exit :: <exit>, more-regions == #(), environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  fer-evaluate(exit, environment)
end;


// ########## fer-gather-assigns-bindings ##########
// collect the assignment chain with their (of a simple region) newest values into the environment
//
define generic fer-gather-assigns-bindings(assigns :: false-or(<abstract-assignment>), environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;

define method fer-gather-assigns-bindings(no-assign == #f, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  environment
end;

define method fer-gather-assigns-bindings(assign :: <abstract-assignment>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  let extended-env = fer-gather-assign-bindings(assign.defines, assign.depends-on.source-exp, environment);
  fer-gather-assigns-bindings(assign.next-op, extended-env);
end;

// ########## fer-gather-assign-bindings ##########
// collect the bindings chain (of one assignment) with their newest values into the environment
//
define generic fer-gather-assign-bindings(defs :: false-or(<definition-site-variable>), expr :: <expression>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;

define method fer-gather-assign-bindings(defs :: <ssa-variable>, expr :: <expression>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  let var-value = evaluate(expr, environment);
  append-environment(environment, defs, var-value)
end;

define method fer-gather-assign-bindings(defs :: <initial-definition>, expr :: <expression>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  let var-value = evaluate(expr, environment);
  append-environment(environment, defs.definition-of, var-value) // ### we should perhaps take in account that this var may already have been recorded in the env...
end;

define method fer-gather-assign-bindings(no-more-defs == #f, expr :: <expression>, environment :: <interpreter-environment>)
 => environment :: <interpreter-environment>;
  environment
end;

// ########## evaluate-call ##########
// set up fresh environment with prolog bindings bound to input arguments
// and evaluate the function body in that context
//
define generic evaluate-call(func :: <abstract-function-literal>,
                                 operands :: false-or(<dependency>),
                                 callee-environment :: <interpreter-environment>)
 => result :: <ct-value>;

define method evaluate-call(func :: <method-literal>, operands :: false-or(<dependency>), callee-environment :: <interpreter-environment>)
 => result :: <ct-value>;

//  format(*debug-output*, "\n\n\n####### evaluate-call %= %= \n", func, operands);
//  force-output(*debug-output*);
  block ()
    let prologue = func.main-entry.prologue;
  
    let prologue-assignment :: <abstract-assignment> = prologue.dependents.dependent;
    let vars-to-be-bound :: false-or(<definition-site-variable>) = prologue-assignment.defines;

    local method prologue-environment(vars :: false-or(<definition-site-variable>),
                                      operands :: false-or(<dependency>),
                                      #key to-extend :: <interpreter-environment> = $empty-environment)
    	 => prologue-environment :: <interpreter-environment>;
    	  if (vars)
    	    operands | error("too few arguments passed to <method-literal>");
    	    prologue-environment(vars.definer-next, operands.dependent-next,
                                   to-extend: append-environment(to-extend, vars,
                                                                 evaluate(operands.source-exp, callee-environment)));
  	    else
  	      to-extend
  	    end if;
          end method;

    fer-evaluate(func.main-entry.body, prologue-environment(vars-to-be-bound, operands));
    "no <return> encountered".error;
  exception (return :: <return-condition>)
   /*, test: method(exit :: <exit-condition> leaving the right function????? */
    return.exit-result
  end block
end;

define method evaluate(expr :: <literal-constant>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  expr.value;
end;

define method evaluate(expr :: <method-literal>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  expr.ct-function
end;

define method evaluate(expr :: <truly-the>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  evaluate(expr.depends-on.source-exp, environment)
end;

// ######### extract-leaf #########
// is there a way to arrive from <ct-method> to its literal?
// OPEN QUESTION
define method extract-leaf(the :: <truly-the>)
 => leaf :: <leaf>;
  the.depends-on.source-exp.extract-leaf
end;

define method extract-leaf(leaf :: <abstract-function-literal>)
 => leaf :: <leaf>;
  leaf
end;

define method extract-leaf(var :: <definition-site-variable>)
 => leaf :: <leaf>;
  var.definer.depends-on.source-exp.extract-leaf
end;

define method extract-leaf(var :: <multi-definition-variable>)
 => leaf :: <leaf>;
  var.definitions.first.extract-leaf
end;


define method evaluate(expr :: <unknown-call>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  let args = expr.depends-on.dependent-next;
  let leaf :: <abstract-function-literal> = expr.depends-on.source-exp.extract-leaf;
  evaluate-call(leaf, args, environment);
//  main-entry



/**
      let func :: <ct-function> = evaluate(expr.depends-on.source-exp, environment);
      select (func by instance?) // ## really need to select???? TODO
        <ct-method> =>
          main-entry!!!!!
          let defn :: <abstract-method-definition> = func.ct-function-definition;
          let literal :: <function-literal> = defn.method-defn-inline-function;
          evaluate-call(literal, args, environment);
      end select;
      */
end;

define method evaluate(expr :: <known-call>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
      let func :: <method-literal> = expr.depends-on.source-exp;
      let args = expr.depends-on.dependent-next;
      
      evaluate-call(func, args, environment);
end;

define method evaluate(var :: <abstract-variable>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  var.environment
end;

define method evaluate(primitive :: <primitive>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  evaluate-primitive(primitive.primitive-name, primitive.depends-on, environment);
end;

define method evaluate(prologue :: <prologue>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  let prologue-assignment :: <abstract-assignment> = prologue.dependents.dependent;
  let vars-to-be-bound :: false-or(<definition-site-variable>) = prologue-assignment.defines;
  environment(vars-to-be-bound); // we only support one variable for now...###
end;


define method evaluate(slot-ref :: <heap-slot-ref>, environment :: <interpreter-environment>)
 => result :: <ct-value>;
  let slot-info = slot-ref.slot-info;
  let obj = slot-ref.depends-on.dependent-next.source-exp;
  
  slot-info.slot-read-only? | error("cannot evaluate writeable <heap-slot-ref> of %=", obj);
  
  if (slot-info.slot-init-value
      & slot-info.slot-init-value ~== #t)
    slot-info.slot-init-value
  else
    // we need to eval the init function too??? ### side-effects?
    
    let obj-value = evaluate(obj, environment);
    obj-value // for now...
  end;
  
end;


// ########## evaluate-primitive ##########
// perform an appropriate reduction for the primitive call
//
define generic evaluate-primitive(name :: <symbol>, depends-on :: false-or(<dependency>), environment :: <interpreter-environment>)
 => result :: <ct-value>;



define macro primitive-emulator-aux-definer
  {
    define primitive-emulator-aux ?primitive:expression ?:name(?lhs:variable, ?rhs:variable) ?stuff:* end
  }
  =>
  {
    define method evaluate-primitive(name == ?primitive, depends-on :: <dependency>, environment :: <interpreter-environment>)
     => result :: <ct-value>;
      let ?lhs = evaluate(depends-on.source-exp, environment);
      let ?rhs = evaluate(depends-on.dependent-next.source-exp, environment);
      as(<ct-value>, ?name(?stuff))
    end;
  }

  {
    define unary primitive-emulator-aux ?primitive:expression ?:name(?val:variable) ?stuff:* end
  }
  =>
  {
    define method evaluate-primitive(name == ?primitive, depends-on :: <dependency>, environment :: <interpreter-environment>)
     => result :: <ct-value>;
      let ?val = evaluate(depends-on.source-exp, environment);
      as(<ct-value>, ?name(?stuff))
    end;
  }
end macro primitive-emulator-aux-definer;

define macro primitive-emulator-definer
  {
    define primitive-emulator ?:name end
  }
  =>
  {
    define primitive-emulator-aux "fixnum-" ## ?#"name" ?name(lhs, rhs)
      lhs.literal-value, rhs.literal-value
    end
  }

  {
    define primitive-emulator (?:name) end
  }
  =>
  {
    define primitive-emulator-aux ?#"name" ?name(lhs :: <eql-ct-value>, rhs :: <eql-ct-value>)
      lhs.literal-value, rhs.literal-value
    end
  }

  {
    define unary primitive-emulator ?:name => ?func:name end
  }
  =>
  {
    define unary primitive-emulator-aux ?#"name" ?func(val :: <ct-value>)
      val.literal-value
    end
  }
end;

define primitive-emulator \+ end;
define primitive-emulator \- end;
define primitive-emulator \* end;
define primitive-emulator \< end;
define primitive-emulator \= end;
define primitive-emulator logior end;
define primitive-emulator logxor end;
define primitive-emulator logand end;
define primitive-emulator (\==) end;
define unary primitive-emulator not => \~ end;
define unary primitive-emulator fixnum-negative => negative end;

// ########## append-environment ##########
define function append-environment(prev-env :: <interpreter-environment>, new-binding, new-value) => new-env;

//  format(*debug-output*, "append-environment %= %= \n", new-binding, new-value);
//  force-output(*debug-output*);


  method(var)
    if (var == new-binding)
      new-value
    else
      prev-env(var)
    end if;
  end method;
end function;
