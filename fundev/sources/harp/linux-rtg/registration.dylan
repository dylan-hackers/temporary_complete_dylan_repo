module:    linux-rtg
Synopsis:  Support for registering top-level items for the Linux runtime generator
Author:    Nosa Omo
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define macro unix-runtime-primitive-definer
  { define ?adjectives:* unix-runtime-primitive ?:name 
      ?body:*
    end }
    => {
         define sideways method "genop--" ## ?name
           (?=be :: <native-unix-back-end>) => ()
           with-harp (?=be)
             ?body
           end with-harp;
         end method;
       }
end macro;


define macro unix-API-runtime-primitive-definer
  { define ?adjectives:* unix-API-runtime-primitive ?:name 
        (?linux-name:expression)
      ?body:*
    end }
    => { define ?adjectives call-in runtime-function-aux "primitive-" ## ?name
             (c-mangle, ?linux-name, ?adjectives)
           ?body
         end }
end macro;
