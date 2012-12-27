Lua Library Assembler
====================

Attempts to gather dependent Lua libraries into a single Lua file.

This works by replacing the Lua library searcher function in package.loaders
with a proxy function. This pretty much does the same thing as the former,
except it also reads the contents of a found file, which gets added to the
assembled file.

AssembleLibrary returns a function that, when called with a file name as an
argument, allows the assembled content to be written to the given file. So,
the general prodecure for assembling a library is to require the assembler,
with an output filename, then require the library you wish to assemble.
Example:

    require 'AssembleLibrary' "library-assembled.lua"
    -- do stuff normally
    require 'library'
    -- etc

If a library happens to load dependencies only when needed, then you will have
to use it in whatever way necessary to make sure they are loaded. If the
library comes with a unit test, that should do the job.
