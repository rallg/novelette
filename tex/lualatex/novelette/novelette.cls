%% This is file `novelette.cls', lualatex `novelette' document class.
%% Copyright 2023 Robert Allgeyer.
%% Contact: Username `rallg' on GitHub and stackexchange. `RobtAll' on CTAN.
%%
%% This file may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, either version 1.3c
%% of this license or (at your option) any later version.
%% The latest version of this license is in
%%    http://www.latex-project.org/lppl.txt
%% and version 1.3c or later is part of all distributions of LaTeX
%% version 2005/12/01 or later.
%% 
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{novelette}[2023/01/20 v0.2 LuaLaTeX document class]
%%


%% DESCRIPTION:
%% ----------------------------------------------------------------------------
% Class `novelette' is a simplified version of the `novel' document class.
% It is designed for print fiction: novels or short stories. Most features
% needed for academic publications are disabled. It cannot produce an Ebook.
%   There are pre-configured designs for the most commonly used choices of
% trim size (finished book width and height), and internal design consistent
% with fiction. The user can over-ride the pre-configured settings.
%   The class will automatically create PDF/X-1a:2001 files upon request,
% using self-contained macros.
%   Program lualatex is required, and input files must be encoded utf-8.
% Command-line:  lualatex your-document.tex
% Some systems use this:  luahbtex --fmt=lualatex your-document.tex
%   Fonts are loaded by luaotfload and fontspec, and massaged by microtype.
% For best results, use modern Open Type fonts, or TrueType fonts.
%   The EB Garamond font family, if installed, is default.
% The Libertinus Serif font family, if installed, is second default.
% Last-choice default is Latin Modern Roman; using it generates a warning.
%   Images must be png monochrome, 1-bit per pixel, usually 600 pixels/inch.
%%


%% REQUIRE LUALATEX and do some preliminary setup.
%% ----------------------------------------------------------------------------
\RequirePackage{iftex} % Detects format.
\RequirePackage{luatex85} % Compatibility with old versions.
\RequirePackage{pdftexcmds} % Compatibility.
\ifluatex % Actually, lualatex.
  \pdfvariable suppressoptionalinfo 511 % Writes only ID to PDF Catalog.
\else
  \ClassError{novelette}{Must compile with lualatex}%
    {Either `lualatex' or `luahbtex --fmt=lualatex' at command line.}%
\fi
\nofiles % Does not need aux. Better without it.
\pdfimageresolution=600 % Default pixels/inch for monochrome bitmap images.
\pdfcompresslevel=0
\pdfobjcompresslevel=0
\pdfminorversion=3 % Required for optional PDF/X-1a:2001 conformance.
\gdef\thepdfminorversion{\pdfminorversion}
\gdef\@PDFversion{PDF/X-1}
%% Novelette uses these in a slightly different way than in other classes:
\protect\long\gdef\title#1{\gdef\nvt@title{#1}}
\protect\long\gdef\author#1{\gdef\nvt@author{#1}}
\newcommand\application[1]{\gdef\@application{#1}}
\newcommand\producer[1]{\gdef\@producer{#1}}
\newcommand\intent[1]{\gdef\@intent{#1}}
\@onlypreamble\title
\@onlypreamble\author
\@onlypreamble\application
\@onlypreamble\producer
\@onlypreamble\intent
%% \subtitle is for convenience. Not in PDF metadata.
\long\gdef\subtitle#1{\gdef\@subtitle{#1}\gdef\thesubtitle{#1}}
\@onlypreamble\subtitle
\subtitle{} % Default empty.
%%

%% BOOLEANS (Used here, and in other Novelette files.)
\newif\if@ok % Local scratch boolean. Typically used for and/or series.
\newif\ifcolors@ % Always false.
\newif\if@sent@colormsg % When true, prevents color warning duplicates.
\newif\if@inopening % True within opening environment.
\newif\if@indisplay % True within display environment.
\newif\if@nvterr % True if Novelette (not LaTeX) issued an error.
\newif\if@has@header % True if design style has header.
\newif\if@has@footer % True if design style has footer.
\newif\if@pnital % True if page numbers are italicized.
\newif\if@zmark % True if footnote is in opening. Omits the marker. 
\newif\ifnow@frontmatter % True in frontmatter.
\newif\ifnow@mainmatter % True in mainmatter or backmatter.
\newif\if@cleartoend % True if cleartoend issued. Prevents duplicate.
\newif\if@shadelines % True if class option shadelines.
\newif\if@shademargins % True if class option shademargins.
\newif\ifmsdoc % Manuscript, always false. Compatibility with some packages.
\newif\if@nvtdraft % True unless final mode.
%%


%% LENGTHS (Used in various Novelette files.)
\newlength\temp@l % Local scratch length.
\newlength\@totalh % Printable height, between top/bottom margins.
\newlength\adj@totalh % Printable height, minus font ascender and descender.
\newlength\@typesize % Main font size.
\newlength\@leading % Standard baseline skip.
\newlength\@desc % Main font descender (depth of JQgjpqy).
\newlength\@asc % Main font ascender (height of accented Latin-1 capitals).
\newlength\@spad % Padding at sides of textblock, to allow for protrusion.
\newlength\@trimw % Trim width.
\newlength\@trimh % Trim height.
\newlength\normalindent % Standard paragraph indent.
\newlength\@mtop % Margin top.
\newlength\@mout % Margin outside.
\newlength\@mbot % Margin bottom.
\newlength\@mins % Margin inside. At spine (binding).
\newlength\@imagewidth % Image width (TeX pt).
\newlength\@imageheight % Image height (TeX pt).
\newlength\@imgadj % Pads image height to integer number of lines.
\newlength\@trimleft % Pagesize position of left edge of trimsize.
\newlength\@spinew % Nominal width of spine glue area.
\newlength\mylsblen % Used by Lua code. Character left side bearing.
\newlength\myrsblen % Used by Lua code. Character right side bearing.
%%


%% NUMBERS AND STRINGS (`23' could be treated as number or string.)
\def\temp@s{} % Local scratch, usually string.
\def\temp@n{} \def\temp@d{} \def\temp@r{} % Local scratch, usually numbers.
\def\temp@t{} \def\temp@o{} \def\temp@b{} \def\temp@i{} % Special-purpose.
\def\temp@w{} \def\temp@h{} % Special-purpose.
\def\temp@ckln{} % Special-purpose.
%%


%% REQUIRE SOME PACKAGES
%% ----------------------------------------------------------------------------
\RequirePackage{xparse} % For writing cool-looking commands.
\RequirePackage{letltxmacro} % For re-defining some macros.
\RequirePackage{etoolbox} % general good stuff
\RequirePackage{xifthen} % improved ifthenelse handling
\RequirePackage{xstring} % parses strings
\RequirePackage{novelette-infwarerr}
% Package fontspec requires normalsize. Trick: Tentative normalsize.
% Novelette calculates real normalsize AtEndPreamble.
\renewcommand\normalsize{\@setfontsize\normalsize{11pt}{14pt}}\normalsize
\RequirePackage[no-math,quiet]{fontspec}
%%


%% CLASS OPTIONS (none!), MODE
%% ----------------------------------------------------------------------------
% Novelette does not use class options. Dimensions, font size, and everything
% are are set by specific commands in Preamble.
%   \mode{choose} selects draft, shade, align, final. Default draft.
\ifdefined\@raw@classoptionslist
  \ifthenelse{\equal{\@raw@classoptionslist}{}}{}{
    \typeout{^^JALERT: Novelette has no class options. Ignored!^^J}
  }
\fi
\def\@raw@classoptionslist{}
\def\@classoptionslist{}
\newcommand\mode[1]{
  \@okfalse
  \StrDel{#1}{ }[\temp@s]
  \ifdefined\nvt@mode % Prevent duplicates.
    \def\temp@s{draft}
    \ClassWarning{novelette}{Multiple usage of \string\mode^^J%
      All ignored. Using draft mode instead.}
  \fi
  \ifthenelse{\equal{\temp@s}{draft}}{
    \@oktrue\@nvtdrafttrue\gdef\nvt@mode{draft}
    \@shademarginsfalse\@shadelinesfalse
  }{}
  \ifthenelse{\equal{\temp@s}{shade}}{
    \@oktrue\@nvtdrafttrue\gdef\nvt@mode{shade}
    \@shademarginstrue\@shadelinesfalse
  }{}
  \ifthenelse{\equal{\temp@s}{align}}{
    \@oktrue\@nvtdrafttrue\gdef\nvt@mode{align}
    \@shademarginstrue\@shadelinestrue
  }{}
  \ifthenelse{\equal{\temp@s}{final}}{
    \@oktrue\@nvtdraftfalse\gdef\nvt@mode{final}
    \@shademarginsfalse\@shadelinesfalse
  }{}
  \if@ok\else
    \gdef\nvt@mode{draft}
    \ClassWarning{novelette}{Unknown \string\mode{\temp@s}.^^J%
      Ignored. Using draft mode instead.}
  \fi
}
\@onlypreamble\mode
%%


%% MORE PACKAGES
%% ----------------------------------------------------------------------------
\RequirePackage{novelette-language}
\RequirePackage[nomessages]{fp} % Calculations.
\FPmessagesfalse
\RequirePackage{silence}
\WarningFilter{microtype}{I cannot find a protrusion list}
\WarningFilter{microtype}{protrusion}
\WarningFilter{microtype}{Redefining}
\WarningsOff[Fancyhdr,fancyhdr]
\RequirePackage{calc} % Length expression calculations.
\RequirePackage{atbegshi} % For header changes.
\RequirePackage{changepage} % Block indents, etc. Do not use strict!
\RequirePackage{noindentafter} % For unindented chapter and scene starts.
\RequirePackage{novelette-utilities}
\RequirePackage{novelette-settings}
\RequirePackage{novelette-design}
\RequirePackage{novelette-fonts}
%%


%% PROHIBIT ADDING MORE PACKAGES
%% ----------------------------------------------------------------------------
% Many packages introduce code that disrupts the uniform line grid,
% or writes information disallowed by PDF/X. Solution: No user-added packages.
\LetLtxMacro\@get@package\RequirePackage\relax
\NewDocumentCommand\out@of@luck{O{}m}{\@errCURP} % Cannot use \RequirePackage.
\LetLtxMacro\RequirePackage\out@of@luck\relax
\LetLtxMacro\usepackage\out@of@luck\relax
%%


%% AT END PREAMBLE
%% ----------------------------------------------------------------------------
%% Process user settings, set defaults, calculate page design.
\AtEndPreamble{
  \ifdefined\nvt@mode\else\gdef\nvt@mode{draft}\fi
  \ifthenelse{\equal{\nvt@mode}{final}}{
    \global\deflength\overfullrule{0pt}
  }{
    \global\deflength\overfullrule{6pt}
  }
  \LetLtxMacro\RequirePackage\@get@package\relax
  \LetLtxMacro\usepackage\@get@package\relax
  \ifundef{\nvt@title}{
    \global\@nvtdrafttrue
    \gdef\@title{Untitled Document}
    \gdef\thetitle{Untitled Document}
  }{
    \xdef\@title{\nvt@title}
    \xdef\thetitle{\nvt@title}
  }
  \ifundef{\nvt@author}{
    \global\@nvtdrafttrue
    \gdef\@author{Anonymous Author}
    \gdef\theauthor{Anonymous Author}
  }{
    \xdef\@author{\nvt@author}
    \xdef\theauthor{\nvt@author}
  }
  \ifundef{\@application}{\gdef\@application{Novelette}}{}
  \ifundef{\@producer}{\gdef\@producer{Novelette}}{}
  \ifundef{\@intent}{\gdef\@intent{none}}{}
  \@process@margins
  \@process@design
  \RequirePackage{novelette-fonts}
  \@process@mainfont
  \@rescale@mainfont
  \@calculate@leading
  \@renew@normalsize % The real value.
  \DeclareDocumentCommand\lipsum{sO{}o}{\@errLINL} % Lipsum is not loaded.
  \@process@language
  \RequirePackage[\@setmtoptions]{microtype}
  \def\MT@find@file#1{} % Prevents loading mt-*.cfg files AtBeginDocument.
  \@process@headfont
  \@rescale@headfont
  \@process@otherfonts
  \RequirePackage{novelette-footnotes}
  \RequirePackage{novelette-opendisp}
  \RequirePackage{novelette-graphics}
  \RequirePackage{fancyhdr}
  \RequirePackage{novelette-headers}
  \@process@hfstyle
  \@process@openings
  \RequirePackage{novelette-fillertext}
%  \directlua{require "novelette-sidebearings"}
%  \def\lsidebearing#1{\directlua{packagedata.sidebearings.left [[#1]]}}
%  \def\rsidebearing#1{\directlua{packagedata.sidebearings.right [[#1]]}}
  \if@shademargins\RequirePackage{novelette-shades}\fi
  \ifthenelse{\equal{\nvt@mode}{draft}}{\@labeldraft}{}
  \ifthenelse{\equal{\nvt@mode}{shade}}{\@labelshade}{}
  \ifthenelse{\equal{\nvt@mode}{align}}{\@labelalign}{}
  \RequirePackage{novelette-metadata}
  \@process@pdfboxes
}
%%


%% AT BEGIN DOCUMENT (Finish the setup. Some values not available until here.)
%% ----------------------------------------------------------------------------
\AtBeginDocument{
  \global\deflength\textfloatsep{0pt plus \@leading minus \@leading}
  \global\deflength\parindent{\normalindent}
  \gdef\forceindent{\ifvmode\else\unskip\fi\stake\hspace{\normalindent}}
  \gdef\backindent{\ifvmode\else\unskip\fi\hspace{-\normalindent}}
  \DeclareDocumentCommand\textls{sO{}+m}{#3} % Do-nothing.
  \let\lsstyle\relax
  \hyphenpenalty=1000
  \exhyphenpenalty=1000
}
%%


%% AFTER END PREAMBLE (Tacked onto the end of AtBeginDocument.)
%% ----------------------------------------------------------------------------
\AfterEndPreamble{
  \versohead{Verso}\rectohead{Recto} % Dummy fill.
}
%%


%% AT END DOCUMENT (Document is still writeable here.)
%% ----------------------------------------------------------------------------
\AtEndDocument{
  \cleartoend
  \pdfinfo{%
    /CreationDate(\pdffeedback creationdate) %
    /ModDate(\pdffeedback creationdate) %
  }
  \@process@metadata
  \@process@xmp
  \ifthenelse{\equal{\@intent}{none}}{}{\@process@intent}
}
%%


%% AFTER END DOCUMENT (Log final messages and summary.)
%% ----------------------------------------------------------------------------
\AfterEndDocument{
  \typeout{^^J}
  \typeout{*******************************************************************}
  \typeout{SUMMARY FOR JOBNAME \jobname\space\if@nvtdraft DRAFT MODE\fi}
  \typeout{*******************************************************************}
  \typeout{These are the actual values used. If different from your settings,}
  \typeout{it means Novelette used defaults, or needed to over-ride yours:}
  \typeout{\string\title{\@title}}
  \typeout{\string\subtitle{\@subtitle}}
  \typeout{\string\author{\@author}}
  \typeout{\string\application{\@application}}
  \typeout{\string\producer{\@producer}}
  \typeout{\string\intent{\@intent}}
  \typeout{\string\mode{\nvt@mode}}
  \typeout{\string\setlang{\nvt@lang}}
  \typeout{\log@trimsize}
  \typeout{\log@sheetfeed}
  \typeout{\log@margins}
  \typeout{\log@design}
  \typeout{\log@openings}
  \typeout{\log@markers}
  \FPround{\temp@n}{\strip@pt\@typesize}{2}
  \FPclip{\temp@n}{\temp@n}
  \FPmul{\temp@d}{\temp@n}{.996264}
  \FPround{\temp@d}{\temp@d}{2}
  \FPclip{\temp@d}{\temp@d}
  \typeout{Calculated main font size: \temp@n pt TeX (\temp@d pt PostScript)}
  \FPround{\temp@n}{\strip@pt\@leading}{2}
  \FPclip{\temp@n}{\temp@n}
  \FPmul{\temp@d}{\temp@n}{.996264}
  \FPround{\temp@d}{\temp@d}{2}
  \FPclip{\temp@d}{\temp@d}
  \typeout{Calculated leading (baselineskip): %
    \temp@n pt TeX (\temp@d pt PostScript)}
  \FPdiv{\temp@n}{\strip@pt\@leading}{\strip@pt\@typesize}
  \FPround{\temp@n}{\temp@n}{2}
  \FPclip{\temp@n}{\temp@n}
  \typeout{Calculated ratio leading/fontsize: \temp@n}
  \typeout{\log@mainfont}
  \typeout{\log@headfont}
  \typeout{\log@namefont}
  \typeout{\log@descfont}
  \typeout{\log@notefont}
  \typeout{\log@decofont}
  \log@imagespecs
  \typeout{\@signoffmsg}
  \if@nvterr
    \typeout{*** NOVELETTE ERROR. OUTPUT IS INVALID. ***}
    \typeout{*** PDF CANNOT MEET PDF/X REQUIREMENTS. ***}
  \fi
  \typeout{*******************************************************************}
  \typeout{^^J}
}
%%


%  \catcode`\$=12
%  \catcode`\&=12
%  \def\({(} % No math mode.
%  \def\){)}




%%
%% End of file `novelette.cls'.
