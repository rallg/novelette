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
[2023/09/21 v0.15 LuaLaTeX document class (printed non-color popular fiction).]
\def\class@ver{15} % Above version = v0.\class@ver. Also update other files.
% If 10<=\class@ver<20, this is ALPHA TEST.
% If 20<=\class@ver<40, this is BETA TEST.
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
%   The only class option is "cover". This converts a pre-processed CMYK
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
\def\nvt@fatal@error#1{%
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
  \nvt@fatal@error{Requires lualatex compiler.^^J%
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
\newif\ifmsdoc % Always false. Compatibility with some packages.
\newif\if@ok % Local scratch boolean. Typically used for and/or series.
\newif\ifnocle@rtoend % True omits blank verso at end. Normally false.
\newlength\temp@l % Local scratch length.
\newif\ifmargin@lert % True if margin settings are funky.
\def\misc@lert{} % Messages may be added.
\newcounter{nvt@count} \setcounter{nvt@count}{0} % Scratch counter.
\newif\ifdev@test \newlength\feeler@wd % Developer only.
\newlength\printable@ht % Printable height (header+main+footer).
\newlength\le@ding % Standard baseline skip. Calculated, not a setting.
\newlength\normalindent % Standard paragraph indent.
\newif\ifhe@der % True when layout has header.
\newif\iff@@ter % True when layout has footer.
\newlength\book@w \newlength\book@h % No defaults. Fatal error if not set.
\newlength\covertrim@w \newlength\covertrim@h \newlength\type@size
\newlength\m@top \newlength\m@out \newlength\m@bot \newlength\m@ins
\newsavebox\image@box \def\ftype@figure{1} % Mystery TeX code.
\newlength\image@width \newlength\image@height % Measured in TeX pt.
\newlength\lines@high % Integer multiple of \le@ding >= \image@height.
\newif\ifre@l % True for real image, false for fake image.
\newif\ifimage@warn % True if image warning issued.
\newif\ifhfimage@lert % True if image used in header|footer.
\newif\ifwarn@lert % True if \warnalert{on}.
\newlength\X@ht % X height of main font.
\newlength\x@ht % x height of main font.
\newlength\chars@ht % Max height of Latin-1 characters.
\newlength\chars@dp % Max depth of Latin-1 characters (positive value).
\newlength\line@gap % Gap between \chars@dp and following \chars@ht.
\newlength\nvt@slop % Leftover height at main text bottom, due to estimations.
\newcounter{nvt@fnmnum} \setcounter{nvt@fnmnum}{1} % Footnote marker number.
\newif\ifzm@rk % Footnote without marker.
\newif\ifcolors@ % Always false. Compatibility.
\newif\ifsent@colormessage % When true, prevents color warning duplicates.
\newif\ifhead@foot % True inside header and footer.
\newif\iffront@matter \newif\ifmain@matter
\newif\if@opening % True within opening environment.
\newif\ifdisplay@page % True within display environment.
%%


%% Error detection. Intended to prevent final mode when error:
\newif\ifb@d % True if error detected.
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
\newif\ifnvt@cover
\DeclareOption{cover}{
  \global\nvt@covertrue
  \global\pdfimageresolution=300 % Default for cover image.
}
\ProcessOptions
\ifdefined\preamble@file % When compiling only a subfile.
  \ifnvt@cover
    \nvt@fatal@error{Cannot request cover from within subfile.
      Cover may only be processed as main document.}
  \fi
\fi
%%


%% Novelette uses these in a slightly different way than in other classes:
\protect\def\title#1{\gdef\nvt@title{#1}}
\title{Untitled Document}
\@onlypreamble\title
\protect\def\author#1{\gdef\nvt@author{#1}}
\author{Anonymous Author}
\@onlypreamble\author
%% \subtitle is for convenience. Not in PDF metadata.
\long\gdef\subtitle#1{\gdef\@subtitle{#1}\gdef\thesubtitle{#1}}
\@onlypreamble\subtitle
%%
% Only set application or producer if necessary. Otherwise, use defaults.
\newcommand\application[1]{\gdef\nvt@application{#1}}
\application{Novelette}
\@onlypreamble\application
\newcommand\producer[1]{\gdef\nvt@producer{#1}}
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
\RequirePackage[nomessages]{fp}
\FPmessagesfalse
%%


%% The booksize is finished size of interior pages. Known as "trim size".
%% This setting is mandatory, whether processing interior or cover.
\newcommand\booksize[1]{ % w=length,h=length. Must be h>=w.
  \StrDel{#1,}{ }[\temp@s]
  \StrBehind{\temp@s}{w=}[\temp@n]
  \StrBefore{\temp@n}{,}[\temp@n]
  \check@length{\temp@n}
  \if@ok
    \global\deflength\book@w{\temp@n}
    \StrBehind{\temp@s}{h=}[\temp@n]
    \StrBefore{\temp@n}{,}[\temp@n]
    \check@length{\temp@n}
    \if@ok\global\deflength\book@h{\temp@n}\fi
  \fi
  \if@ok
    \ifthenelse{\dimtest{\book@h}{<}{\book@w}}{\@okfalse}{}
  \fi
  \if@ok
    \gdef\book@size{#1}
  \else
    \nvt@fatal@@error{Bad \string\booksize{w=W,h=H}.^^J%
      W and H must have units in|mm. Also, H>=W.^^J%
      You must set both of them. No default values.}
  \fi
}
%%


%% Intent sets PDF/X Output Intent.
\def\@intent{SWOP} % Default.
\newcommand\intent[1]{
  \@oktrue
  \StrSubstitute{#1}{FOGRA39L}{FOGRA39}[\temp@s]
  \IfSubStr{:none:SWOP:FOGRA39:JC200103:custom}{:\temp@s:}{
    \xdef\@intent{\temp@s}
  }{
    \@error{Bad value for \string\intent{choice}.^^J%
      Choose one: none SWOP FOGRA39 JC200103 custom.^^J%
      Docs explain what the choices mean. Default SWOP.^^J%
      Do not use custom without expertise.^^J%
      If choice none, PDF will not declare PDF/X conformance.^J%
      Others declare PDF/X conformance with chosen Output Intent.}
  }
}
%%


%%
\RequirePackage{novelette-settings}
\ifnvt@cover
  \RequirePackage{novelette-cover}
\else
  \RequirePackage{novelette-interior}
\fi
%%


%% No user-added packages. Reason: Likely to destroy other things.
\LetLtxMacro\nvt@get@package\RequirePackage\relax
\NewDocumentCommand\out@of@luck{O{}m}{%
  \nvt@fatal@error{Novelette does not allow additional packages.^^J%
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
