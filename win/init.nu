#!/usr/bin/env nu
# windows init.nu in addition to top level init.nu

# print "Initialized PFiles Vars"
# let $PFilesX64Dir = "C:\\PFiles_x64\\choco"
# let $PFilesX86Dir = "C:\\PFiles_x86\\choco"

$env.PFilesX64Dir = "C:\\PFiles_x64\\choco"
$env.PFilesX86Dir = "C:\\PFiles_x86\\choco"

# print $"($PFilesX64Dir)"
# print $"($PFilesX86Dir)"