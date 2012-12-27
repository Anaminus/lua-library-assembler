Lua Library Assembler
=====================

Attempts to consolidate the many files of a Lua library into a single Lua file.

This works by replacing the Lua library searcher function in package.loaders
with a proxy function. This pretty much does the same thing as the former,
except it also reads the contents of a found file, which gets added to the
assembled file.

This module sets up the searcher function, and returns a function that, when
called, allows the assembled content to be written to a file. The name of the
file is the name of the first required library, with ".lua" as the extension.
The first required library is considered as the root library, which is what
would be loaded were the assembled file to be required.

However, two optional arguments may be specified. The first is the name of the
root library to use. The second argument specifies the exact file name to
output to (".lua" is not appended).

So, the general prodecure for assembling a library is to require the
assembler, require the library you wish to assemble, then call the assembler.

    require 'AssembleLibrary'

    -- do stuff normally
    require 'library'
    -- etc

    require 'AssembleLibrary' ()

Note that a root library with a compound name may not work well with the name
of the assembled file, so it's a good idea to specify the file name directly
in such a case:

    require 'AssembleLibrary' ('library.sublib.subfunc', "library.lua")

If a library happens to load dependencies only when needed, then you will have
to use it in whatever way necessary to make sure they are loaded. If the
library comes with a unit test, that should do the job.
