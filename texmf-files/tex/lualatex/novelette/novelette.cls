%% This is file `novelette.cls', lualatex `novelette' document class.
%% Copyright 2024 Robert Allgeyer.
%%
%% This file may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, version 1.3c.
%% License URL: https://www.latex-project.org/lppl/lppl-1-3c.txt
%% A copy of this license is distributed with LaTeX 2008+.
%%
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{novelette}%
[2024/01/11 v0.31 LuaLaTeX document class (printed non-color popular fiction).]
\def\class@ver{31} % Above version = v0.\class@ver. Also update other files.
% If 30<=\class@ver<40, this is BETA TEST.
%%


%% PURPOSE
% Novelette is limited to printed (paper, not Ebook) popular fiction, written
% in a Western European language. Monochrome black ink interiors, and CMYK
% color covers, are supported. Interior images must be monochrome png.
% No vector artwork. Print-on-demand is expected, but not exclusive.
%   The available commands are very limited, to only what you need for books
% such as detective novels, romance, and the like. No frills. Although bug
% reports are encouraged, feature requests are not. If you cannot do what
% you need to do, then try a different document class.
%   Novelette must be compiled using LuaLaTeX, not pdftex or XeTeX.
% Command: lualatex yourdocument   Or: luahbtex --fmt=lualatex yourdocument
%   You may decompose your book into a main document with subfiles, such as
% chapters. Then, you may compile an individual subfile. Great for editing.
% The complete book is created by compiling the main document, which calls
% its subfiles (rather than by merging various PDF subfiles).
%   Novelette supports four modes: draft, shade, typo, final. Default draft.
% For alignment, shade mode is draft mode with gray zones showing layout areas.
% The typo mode is draft mode, with poorly-typeset words or lines highlighted.
% Modes typo1, typo2, typo3 are typo mode, with different highlight color sets.
%   In draft|shade|typo modes, you may do some things that are disallowed in
% final mode. In particular, off-spec images are allowed. To ensure that
% a non-final PDF is not mistaken for final, its PDF metadata is altered.
%   In final mode, you may compile the document for PDF/X-1a:2001 conformance.
% This is the default. But if an error is detected, the document will
% automatically revert to draft mode, and will not be labeled with conformance.
%   Settings such as font size, lines per page, page size, and anything else,
% are not set by a document class option. Instead, you may modify the default
% values, by using Novelette-specific commands in Preamble.
%   Novelette does not use most standard LaTeX commands, and does not allow
% you to load additional packages. This is because the internal calculations
% require very specific macros, and no others. So, be sure to read the
% documentation.
%%



\newif\ifb@d % True if ordinary error detected.
\gdef\ClassError#1#2#3{%
   \global\b@dtrue%
   \GenericError{(#1) \space\@spaces\@spaces\@spaces}%
   {Novelette Error: #2}%
   {See the Novelette HTML documentation for explanation.}%
   {#3}%
}
%%
\gdef\PackageError#1#2#3{%
   \global\b@dtrue%
   \GenericError{(#1)\@spaces\@spaces\@spaces\@spaces}%
   {Package #1 Error: #2}%
   {See the #1 package documentation for explanation.}%
   {#3}%
}
%%
\def\fatal@err#1{%
  \immediate\write\@unused{}%
  \set@display@protect%
  \typeout{! Class novelette Fatal Error:^^J#1^^J%
    \space\space See the novelette class documentation for explanation.^^J%
    \space\space This is a fatal error. No PDF produced. Compiler exits.}%
  \batchmode \read-1 \ciaobaby
}
%%
% Many errors are caused by bad settings. It is often possible to continue
% past these errors, because Novelette will attempt to use a suitable default
% setting. The result may be a good PDF file. But since something was wrong,
% it will be produced in draft mode, even if you requested final mode.
\def\@RXN{Best: Respond x <return> to exit now.^^J%
  If you continue, the PDF (if any) will not be in final mode.}
\def\nvt@err#1#2{\ClassError{novelette}{^^J#1}{#2^^J\@RXN}}
% Thanks to Marcel Krüger for this, at tex.stackexchange.com, q. 675718:
\def\track@errors{%
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
}
%%

%% LuaLaTeX only:
\RequirePackage{iftex}
\ifluatex\else
\fatal@err{Requires lualatex compiler.^^J%
  Command line: \space lualatex YourDocument^^J%
  Or: \space luahbtex --fmt=lualatex YourDocument}
\fi
\RequirePackage{luatexbase}
\def\h@ck{} % For possible future use.
\def\hack#1{\gdef\h@ck{#1}}
\def\twe@k{} % For possible future use.
\def\tweak#1{\gdef\twe@k{#1}}
\def\prev@lerts{} % Accumulates \@lert{message}.
\def\@lert#1{%
  \edef\temp@lert{\prev@lerts}%
  \edef\this@lert{! #1}%
  \xdef\prev@lerts{\prev@lerts^^J\this@lert}%
}
%%

%% Preliminary settings:
\nofiles % Does not use aux.
\pdfvariable imageresolution 600 % Default for monochrome interior images.
\pdfvariable suppressoptionalinfo 511 % Writes only ID to PDF Catalog.
\pdfvariable compresslevel 0
\pdfvariable objcompresslevel 0
\pdfvariable minorversion 3 % Required for optional PDF/X-1a:2001 conformance.
\setlength\overfullrule{6pt} % Except in final mode.
\newif\ifmsdoc % Always false. Compatibility with some old packages.
\newif\if@ok % Local scratch boolean. Typically used for and/or series.
\newif\ifall@ok % Local scratch boolean, for combined and/or series.
\newif\ifnocle@rtoend % True omits blank verso at end. Normally false.
\newlength\temp@l % Local scratch length.
\newcounter{temp@count} % Scratch counter.
\newcounter{bookmatter}\setcounter{bookmatter}{2} % 1=front, 2=main/back.
\newsavebox\image@box
\newif\ifcover@rt % Always false for interior.
%%


%% Metadata.
\title{Untitled Document} \def\title@tail{}
\author{Anonymous Author} \def\author@tail{}
% \subtitle is for convenience. Not in PDF metadata.
\long\gdef\subtitle#1{\gdef\@subtitle{#1}\gdef\thesubtitle{#1}}
\subtitle{} \gdef\subtitle@tail{}
\@onlypreamble\title \@onlypreamble\author \@onlypreamble\subtitle
\def\applic@tion{Novelette} \def\pr@ducer{Novelette}
\directlua{require('novelette-pdftc')} % Minimal pdftexcmds.
\def\nvt@filesize#1{%
  \directlua{novelette.pdftc.filesize('\luaescapestring{#1}')}%
}
\long\def\nvt@mdfivesum#1{%
  \directlua{novelette.pdftc.mdfivesum('\luaescapestring{#1}', 'byte')}%
}%
%%


%% Some packages:
\RequirePackage{novelette-relaxed} % Re-sets various LaTeX values.
\RequirePackage{xparse}
\RequirePackage{letltxmacro}
\RequirePackage{etoolbox}
\RequirePackage{xifthen}
\RequirePackage{xstring}
%%


%% Some utilities:
\LetLtxMacro\cl@ssw@rning\ClassWarning\relax
\DeclareDocumentCommand\ClassWarning{m+m}{%
  \ifdefined\warn@issued\else%
    \@lert{IMPORTANT: One or more Warning messages. Fix them!}%
  \fi%
  \gdef\warn@issued{true}%
  \cl@ssw@rning{#1}{#2}%
}
\LetLtxMacro\cl@ssw@rning@nl\ClassWarningNoLine\relax
\DeclareDocumentCommand\ClassWarningNoLine{m+m}{%
  \ifdefined\warn@issued\else%
    \@lert{IMPORTANT: One or more Warning messages. Fix them!}%
  \fi%
  \gdef\warn@issued{true}%
  \cl@ssw@rning@nl{#1}{#2}%
}
\LetLtxMacro\p@ck@gew@rning\PackageWarning\relax
\DeclareDocumentCommand\PackageWarning{m+m}{%
  \ifdefined\warn@issued\else%
    \@lert{IMPORTANT: One or more Warning messages. Fix them!}%
  \fi%
  \gdef\warn@issued{true}%
  \p@ck@gew@rning{#1}{#2}%
}
% Test if #1 is empty or spaces:
\def\IfNada#1#2#3{\ifthenelse{\equal{#1}{}\OR\equal{#1}{ }}{#2}{#3}}
% Something like case...esac:
\newif\ifcase@match
\def\case@test#1{\edef\case@@test{#1}\case@matchfalse}
\def\c@se#1#2{\ifthenelse{\equal{\case@@test}{#1}}{#2\case@matchtrue}{}}
% Numerical comparison, where #1 is something such as (3+4)>5 :
\def\comp@re#1#2#3{\ifthenelse{\fpeval{#1}=1}{#2}{#3}}
% Check if string can set a length (number with units):
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
%%


%% The heavy lifting:
\track@errors % In novelette-errors.sty.
\RequirePackage{novelette-settings}
\RequirePackage{novelette-interior}
%%


%% No user-added packages. Reason: Likely to destroy other things.
\LetLtxMacro\get@package\RequirePackage\relax
\NewDocumentCommand\out@of@luck{O{}m}{%
  \fatal@err{Additional packages not allowed.^^J%
    You cannot use \string\usepackage, or \string\RequirePackage.^^J%
    In particular, you cannot load fonts, because they are built-in.^^J%
    Novelette pre-loads only what is necessary. No frills allowed.^^J%
    Reason: Layout calculations are very tight, and are likely to be^^J%
    disturbed by added packages. Besides, you should not need them.}%
}
\LetLtxMacro\RequirePackage\out@of@luck\relax
\LetLtxMacro\usepackage\out@of@luck\relax
%%


%%
%% End of file `novelette.cls'.
