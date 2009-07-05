module: dylan-user

define module dylan-translator
   use common;
   use conditions;
   use dylan-parser,
      rename: { source-location => token-src-loc, local-name => token-local-name,
                import-name => token-import-name, definitions => token-definitions,
                source-text => token-text, <class-slot> => <parsed-class-slot>,
                <rest-value> => <parsed-rest-value> };
   use markup-parser, import: { <markup-content-token> };
   use dylan-rep;
   use markup-rep;
   
   export apis-from-dylan;
end module;