Module:    build-system
Synopsis:  A build-system for Dylan PC Applications in Dylan
Author:    Nosa Omo, Peter S. Housel
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define settings <build-system-settings> (<functional-developer-user-settings>)
  key-name "Build-System";
  slot build-script :: <string>
    = as(<string>,
         merge-locators(as(<file-locator>,
                           concatenate(as(<string>, $platform-name),
                                       "-build.jam")),
                        $system-lib));
end settings <build-system-settings>;

define constant $build-system-settings = make(<build-system-settings>);

define function default-build-script
    () => (script :: <file-locator>)
  as(<file-locator>, $build-system-settings.build-script)
end function default-build-script;

define function default-build-script-setter
    (script :: <file-locator>) => (script :: <file-locator>)
  $build-system-settings.build-script := as(<string>, script);
  script
end function default-build-script-setter;



define method change-directory (directory :: <directory-locator>)
  if (~file-exists?(directory))
    error("Invalid Directory %s", directory);
  else
    working-directory() := directory;
  end if;
end method;

define macro with-build-directory
  { with-build-directory (?directory:expression) ?:body end }
    => {
        let directory = ?directory;
	let previous-directory = if (directory) working-directory(); end;
	block()
	  if (directory) change-directory(directory); end;
	  ?body
	cleanup
	  if (previous-directory) change-directory(previous-directory) end if;
	end block;
       }
end macro;



// Toplevel internal function that can be invoked by Dylan Clients

define method build-system
    (build-targets :: <sequence>,
     #key directory :: <directory-locator> = working-directory(),
          progress-callback :: <function> = ignore,
	  build-script = default-build-script(),
	  project-build-info,
          force?,
	  configure? = #t)
 => (build-successful? :: <boolean>)
  if (configure?)
    configure-build-system();
  end;

  block (return)
    let jam
      = make-jam-state(build-script, progress-callback: progress-callback);
    with-build-directory (directory)
      jam-read-mkf(jam, as(<file-locator>, "dylanmakefile.mkf"));
      jam-target-build(jam, build-targets,
                       progress-callback: progress-callback,
                       force?: force?);
    end;
  exception (e :: <error>)
    progress-callback(condition-to-string(e), error?: #t);
    return(#f);
  exception (w :: <warning>)
    progress-callback(condition-to-string(w), warning?: #t);
  end block;
end method;
