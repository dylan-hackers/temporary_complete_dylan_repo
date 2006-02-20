Module:    dylan-user
Author:    Carl Gay
Copyright: This code is in the public domain.

define library wiki
  use common-dylan,
    import: { common-dylan, threads };
  use io,
    import: { streams, format };
  use system,
    import: { file-system, locators };
  use koala,
    import: { dsp };
  use dylan-basics;
  use regular-expressions;
  use xml-rpc-common;
  use strings;
  //use meta;
  export wiki;
end;

define module wiki
  use common-dylan,
    exclude: { split, format-to-string };
  use locators;
  use streams;
  use format;
  use file-system;
  use threads;
  use dylan-basics;
  //use meta;
  use dsp;
  use regular-expressions,
    import: { regexp-position };
  use xml-rpc-common,
    import: { base64-encode, base64-decode };
  use strings, import: { index-of, case-insensitive-equal? };
end;

