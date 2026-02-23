rldev 2026.2
Fix: GAMEEXE.INI parsing error (Tomoyo After – Steam)
    • Fixed a syntax error during GAMEEXE.INI parsing when recompiling Tomoyo After (Steam) with rlc.
    • The error was triggered by UI keys using an extended numeric path format, e.g.
WAKU.020.000.EXBTN_000_BTN.000 = "s_ped_mw00c"
    • Root cause: iniParser.mly did not support keys with two consecutive numeric segments (.NNN.NNN) followed by a text segment and a final numeric segment.
    • Added a dedicated grammar rule to handle the pattern:
IDENT .NNN .NNN .TEXT .NNN
    • This change mirrors the previous fix made for Clannad Side Stories (Steam) and restores full recompilation compatibility without affecting legacy titles.





rldev 2026.1
=========================

This update fixes multiple issues encountered when compiling and
decompiling RealLive 1.6.x based games using rlc/kprl, including:

- compilation failures when parsing gameexe.ini
- script decompilation errors
- runtime freezes when accessing the in-game Settings menu

These problems were caused by a combination of incomplete RealLive
function definitions and parser limitations.

Background
----------

Affected games make use of modern RealLive UI features introduced
in the 1.6.x era, including:

- extended ITEM definitions in gameexe.ini
- UI scripts calling OBJBACKCHILDMOJI with string-based parameters

Two independent issues were identified.

1) gameexe.ini parsing failure
------------------------------

Some gameexe.ini files contain extended ITEM paths using 5-level
dotted keys, for example:

  FULLSCREEN_MSGBK.000.ITEM.SLIDER_BASE.FILENAME

The original iniParser grammar only supported shorter paths and
failed to parse these entries correctly, causing compilation to stop
or requiring manual removal of valid configuration blocks.

2) Incorrect OBJBACKCHILDMOJI definition
----------------------------------------

The RealLive function OBJBACKCHILDMOJI is used by UI scripts with a
6-argument variant where the 'moji' parameter is passed as a string
literal.

The default reallive.kfn definitions were incomplete and inconsistent:

- the 6-argument overload was missing or incorrectly described
- string literal arguments were not handled correctly
- overload ordering/count did not match actual bytecode usage

As a result:
- script decompilation could fail or truncate output
- recompilation could fail with type errors
- compiled scripts could freeze at runtime (notably in the Settings menu)

Fixes applied
-------------

Parser / Compiler
~~~~~~~~~~~~~~~~~

- iniParser.mly has been extended to correctly parse extended ITEM paths
  in gameexe.ini (support for 5-level dotted keys).
- This removes the need for manual editing of valid gameexe.ini files
  and restores correct handling of fullscreen UI definitions.

RealLive / KFN
~~~~~~~~~~~~~~

- The OBJBACKCHILDMOJI definition in reallive.kfn has been corrected.
- A proper 6-argument overload has been added.
- The 'moji' parameter is now correctly defined as a string literal
  using the 'strC' type.
- Overload order and count have been fixed to match actual bytecode usage.

This restores correct compilation, decompilation and runtime behaviour
for scripts using text-based moji parameters.

Toolchain / Build
~~~~~~~~~~~~~~~~~

- Minor internal refactoring in common/iMap.ml.
- Build warning fixes in common/lz_comp_rl.cpp.
- OMakefile adjustments for improved Cygwin compatibility.

These changes only affect the build process and do not alter the
generated RealLive bytecode format.

Scope
-----

- Fully compatible with existing projects.
- No script (.org) modifications are required.
- No runtime behaviour changes outside of the fixed issues.
- Intended for developers working with RealLive 1.6.x era games.

Conclusion
----------

This update restores full toolchain compatibility with modern
RealLive UI scripts and configuration files, ensuring reliable
round-trip compilation and decompilation without workarounds.


