module: dylan-user

define module conditions
   use common;
   
   export
      <syntax-warning>, <syntax-error>, <design-error>, error-code,
      <need-locations>, specifier-for-locations;
   
   export
      illegal-character-in-id, leading-colon-in-id, leading-colon-in-title,
      duplicate-section-in-topic, illegal-section-in-topic, q-and-qq-in-spec,
      qv-or-vi-in-title, no-context-topic-in-block, target-not-found-in-link,
      duplicate-id-in-topics, id-matches-topic-title, ambiguous-title-in-link,
      conflicting-locations-in-tree, bad-syntax-in-toc-file,
      skipped-level-in-toc-file, unparsable-expression-in-code,
      unsupported-syntax-in-code, nonspecific-syntax-error,
      nonspecific-syntax-warning, nonspecific-design-error
      ;
end module;
