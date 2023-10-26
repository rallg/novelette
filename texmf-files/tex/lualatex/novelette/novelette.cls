%% This is file `novelette.cls', lualatex `novelette' document class.
%% Copyright 2023 Robert Allgeyer.
%%
%% This file may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, version 1.3c.
%% License URL: https://www.latex-project.org/lppl/lppl-1-3c.txt
%% A copy of this license is distributed with LaTeX 2008+.
%%
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{novelette}%
[2023/10/26 v0.21 LuaLaTeX document class (printed non-color popular fiction).]
\def\class@ver{21} % Above version = v0.\class@ver. Also update other files.
% If 10<=\class@ver<30, this is ALPHA TEST.
% If 30<=\class@ver<40, this is BETA TEST.
%%


%% PURPOSE
% Novelette is limited to printed (paper, not Ebook) popular fiction, written
% in a Western European language. Monochrome black ink interiors, and CMYK
% color covers, are supported. Interior images must be monochrome png.
% No vector artwork. Print-on-demand is expected, but not exclusive.
%   The available commands are very limited, to only what you need for books
% such as detctive novels, romance, and the like. No frills. Although bug
% reports are encouraged, feature requests are not. If you cannot do what
% you need to do, then try a different document class.
%   Novelette must be compiled using LuaLaTeX, not pdftex or XeTeX.
% Command: lualatex yourdocument   Or: luahbtex --fmt=lualatex yourdocument
%   You may decompose your book into a main document with subfiles, such as
% chapters. Then, you may compile an individual subfile. Great for editing.
% The complete book is created by compiling the main document, which calls
% its subfiles (rather than by merging various PDF subfiles).
%   Novelette supports three modes: draft, shade, final. Default draft.
% Shade mode is draft, with gray zones placed on pages, for alignment purposes.
% In draft|shade mode, you may do some things (such as fake or off-spec images)
% that are disallowed in final mode. Also, a draft|shade mode file, or any
% individual subfile, will contain modified PDF metadata, which distinguishes
% it from the data that will appear in the final document.
%   In final mode, you may compile the document for PDF/X-1a:2001 conformance.
% This is the default. But if an error is detected, the document will
% automatically revert to draft mode, and will not be labeled with conformance.
%   Settings such as font size, lines per page, page size, and anything else,
% are not set by a document class option. Instead, you may modify the default
% values, by using Novelette-specific commands in Preamble.
%   The only class option is `cover'. This converts a pre-processed CMYK
% cover image to PDF/X-1a:2001 conformance, without attached icc profile.
% Some print services require this format; others do not. When processing
% a cover, only a single page is produced, with no text. Just the image.
% Cover ignores the mode setting. If processed without error, it is final.
%   Novelette does not use most standard LaTeX commands, and does not allow
% you to load additional packages. This is because the internal calculations
% require very specific macros, and no others. So, be sure to read the
% documentation.
%%


%% Traps some novelette-specific fatal errors:
\def\fatal@error#1{%
  \immediate\write\@unused{}%
  \set@display@protect%
  \typeout{! Class novelette Fatal Error: #1^^J^^J%
    See the novelette class documentation for explanation.^^J%
    This is a fatal error. No PDF produced. Compiler exits.}%
  \batchmode \read-1 \ciaobaby
}
%%


%% Preliminary requirements:
\RequirePackage{iftex}
\RequirePackage{luatex85} % Compatibility.
\RequirePackage{pdftexcmds} % Compatibility.
\ifluatex
  \pdfvariable suppressoptionalinfo 511 % Writes only ID to PDF Catalog.
\else
  \fatal@error{Requires lualatex compiler.^^J%
  Command:\space\space lualatex yourdocument^^J%
  Or this:\space\space luahbtex --fmt=lualatex yourdocument}
\fi
\RequirePackage{luatexbase}
\nofiles % Does not use aux.
\pdfimageresolution=600 % Default pixels/inch for monochrome bitmap images.
\pdfcompresslevel=0
\pdfobjcompresslevel=0
\pdfminorversion=3 % Required for optional PDF/X-1a:2001 conformance.
\gdef\thepdfminorversion{\pdfminorversion}
\setlength\overfullrule{6pt} % Except in final mode.
\newif\ifmsdoc % Always false. Compatibility with some old packages.
\newif\ifcolors@ % Always false. Compatibility.
\newif\if@ok % Local scratch boolean. Typically used for and/or series.
\newif\ifnocle@rtoend % True omits blank verso at end. Normally false.
\newlength\temp@l % Local scratch length.
\newcounter{temp@count} % Scratch counter. %%%%%
\long\def\memo#1{\ignorespaces} % Alternative to % comment, different effect.
\long\def\misc@lert{} % Messages may be added, for log summary.
%%


%% Error detection. Intended to prevent final mode when error:
\newif\ifb@d % True if error detected. %%%%% Thanks.
\def\@XN{You may continue. A PDF may or may not be produced.^^J%
  If PDF produced, it is relegated to draft or shade mode.^^J%
  Better to respond x to exit now, then fix the problem}
\def\@RXN{No more help. If in doubt, respond x to exit now.}
\def\@error#1{\ClassError{novelette}{^^J#1^^J\@XN}{\@RXN}\global\b@dtrue}
% Thanks to Marcel Krüger for this, at tex.stackexchange.com, q. 675718:
\directlua{
  local error_seen = false
  local true_cmd = token.create'use_i:nn'
  local false_cmd = token.create'use_ii:nn'
  local id = luatexbase.new_luafunction'iferrorsissued'
  token.set_lua('iferrorsissued', id)
  lua.get_functions_table()[id] = function()
    token.put_next(error_seen and true_cmd or false_cmd)
  end
  luatexbase.add_to_callback('show_error_hook', function()
    error_seen = true
    texio.write('.')
    tex.show_context()
  end, 'track_errors')
}
%%


%% Utility: Check if string can be used to set a length (number with units).
\def\check@length#1{
  \@okfalse
  \IfEndWith{#1}{in}{\@oktrue}{}
  \IfEndWith{#1}{mm}{\@oktrue}{}
  \IfEndWith{#1}{cm}{\@oktrue}{}
  \IfEndWith{#1}{pt}{\@oktrue}{}
  \IfEndWith{#1}{bp}{\@oktrue}{}
  \ifdefined\forceindent\IfEndWith{#1}{em}{\@oktrue}{}\fi % AtBeginDocument.
  \StrGobbleRight{#1}{2}[\temp@cl]
  \IfDecimal{\temp@cl}{}{\@okfalse}
}
%%


%% Class Option:
\newif\ifcover@rt
\DeclareOption{cover}{
  \global\cover@rttrue
  \global\pdfimageresolution=300 % Default for cover image.
}
\ProcessOptions
\ifdefined\preamble@file % When compiling only a subfile.
  \ifcover@rt
    \fatal@error{Cannot request cover from within subfile.
      Cover may only be processed as main document.}
  \fi
\fi
%%


%% METADATA
\title{Untitled Document}
\author{Anonymous Author}
% \subtitle is for convenience. Not in PDF metadata.
\long\gdef\subtitle#1{\gdef\@subtitle{#1}\gdef\thesubtitle{#1}}
\subtitle{}
\@onlypreamble\subtitle
% Only set application or producer if necessary. Otherwise, use defaults.
\newcommand\application[1]{\gdef\applic@tion{#1}}
\application{Novelette}
\@onlypreamble\application
\newcommand\producer[1]{\gdef\pr@ducer{#1}}
\producer{Novelette}
\@onlypreamble\producer
%%


%%
\RequirePackage{novelette-unglued} % Re-sets various LaTeX values.
\RequirePackage{xparse}
\RequirePackage{letltxmacro}
\RequirePackage{etoolbox}
\RequirePackage{xifthen}
\RequirePackage{xstring}
\def\IfNadaTF#1#2#3{%
  \ifthenelse{\equal{#1}{}\OR\equal{#1}{ }}{#2}{#3}%
}
%%


%% Utility: Harness other commands.
\def\comp@re#1#2#3{% Where #1 is a numerical comparison expression.
  \ifthenelse{\fpeval{#1}=1}{#2}{#3}
}
\def\@accept#1{% Where #1 is a numerical comparison expression.
  \ifthenelse{\fpeval{#1}=1}{\@oktrue}{}
}
\def\@reject#1{% Where #1 is a numerical comparison expression.
  \ifthenelse{\fpeval{#1}=1}{\@okfalse}{}
}
\def\reject@nonempty#1{\ifthenelse{\equal{#1}{}}{}{\@okfalse}}
%%


%% Unicode character. Four hex digits, uppercase A-F, no following space.
%% Examples: c\uni{0061}t -> cat  d\uni{006F}g -> dog
%\def\uni#1{{\addfontfeature{Ligatures=ResetAll}\char"#1}\obeyspaces}
%%


%%
\RequirePackage{novelette-settings}
\ifcover@rt
  \RequirePackage{novelette-cover}
\else
  \RequirePackage{novelette-interior}
\fi
%%


%% No user-added packages. Reason: Likely to destroy other things.
\LetLtxMacro\get@package\RequirePackage\relax
\NewDocumentCommand\out@of@luck{O{}m}{%
  \fatal@error{Novelette does not allow additional packages.^^J%
    You cannot use \string\usepackage, or \string\RequirePackage.^^J%
    If the package is a font, do not load its package. Instead, use^^J%
    the Novelette font settings to directly load the fonts by name.^^J%
    Novelette pre-loads only what is necessary. No frills allowed.^^J%
    Reason: Layout calculations are very tight, and are likely to be^^J%
    disturbed by added packages. Besides, you should not need them.}
}
\LetLtxMacro\RequirePackage\out@of@luck\relax
\LetLtxMacro\usepackage\out@of@luck\relax
%%



%%
%% End of file `novelette.cls'.
