Lua Library Assembler
=====================

Attempts to consolidate the many files of a Lua library into a single Lua file.

This works by replacing the Lua library searcher function in package.loaders
with a proxy function. This pretty much does the same thing as the former,
except it also reads the contents of a found file, which gets added to the
assembled file.

This module sets up the searcher function, and returns a function that, when
called with a file name as an argument, allows the assembled content to be
written to the given file. So, the general prodecure for assembling a library
is to require the assembler, require the library you wish to assemble, then
call the assembler with the file to output to. Example:

    require 'AssembleLibrary'

    -- do stuff normally
    require 'library'
    -- etc

    require 'AssembleLibrary' ("library-assembled.lua")

A second argument to the assembler function specifies the root library, which
allows the assembled file to be used as a library itself. If no second
argument is given, the name of the first library that was required will be
used.

If a library happens to load dependencies only when needed, then you will have
to use it in whatever way necessary to make sure they are loaded. If the
library comes with a unit test, that should do the job.
