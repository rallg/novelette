%% This is file `novelette-cover.cls', part of `novelette' document class.
%% Copyright 2024 Robert Allgeyer.
%%
%% This file may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, version 1.3c.
%% License URL: https://www.latex-project.org/lppl/lppl-1-3c.txt
%% A copy of this license is distributed with LaTeX 2008+.
%%
\NeedsTeXFormat{LaTeX2e}[2020/10/01]
\ProvidesClass{novelette-cover}%
[2024/01/18 v0.35 LuaLaTeX document class (color cover).]
\def\class@ver{35} % Above version = v0.\class@ver. Also update other files.
% If 30<=\class@ver<40, this is BETA TEST.
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
\def\prev@lerts{} % Accumulates \@lert{message}.
\def\@lert#1{%
  \edef\temp@lert{\prev@lerts}%
  \edef\this@lert{! #1}%
  \xdef\prev@lerts{\prev@lerts^^J\this@lert}%
}
%%


%%
\newif\ifcover@rt \cover@rttrue % Always true for cover.
\pdfvariable imageresolution 300 % Default for cover image. Pixels/inch.
%%


%% Preliminary settings:
\nofiles % Does not use aux.
\pdfvariable suppressoptionalinfo 511 % Writes only ID to PDF Catalog.
\pdfvariable compresslevel 0
\pdfvariable objcompresslevel 0
\pdfvariable minorversion 3 % Required for optional PDF/X-1a:2001 conformance.
\setlength\overfullrule{0pt}
\newif\ifmsdoc % Always false. Compatibility with some old packages.
\newif\if@ok % Local scratch boolean. Typically used for and/or series.
\newif\ifnocle@rtoend \nocle@rtoendtrue
\newlength\temp@l % Local scratch length.
\newcounter{temp@count} % Scratch counter.
\newsavebox\image@box
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
\def\@mode{final}
\def\mode@tail{(default)}
%% Trim Size (finished interior page size).
\newlength\trim@w \newlength\trim@h % No defaults. Must be set.
\newcommand\trimsize[1]{ % w=length,h=length. Must be h>=w.
  \xdef\trim@size{#1}
  \StrDel{#1,}{ }[\temp@s]
  \StrBehind{\temp@s}{w=}[\temp@n]
  \StrBefore{\temp@n}{,}[\temp@n]
  \check@length{\temp@n}
  \if@ok
    \global\deflength\trim@w{\temp@n}
    \StrBehind{\temp@s}{h=}[\temp@n]
    \StrBefore{\temp@n}{,}[\temp@n]
    \check@length{\temp@n}
    \if@ok
      \global\deflength\trim@h{\temp@n}
    \fi
  \fi
  \if@ok
    \ifthenelse{\dimtest{\trim@h}{<}{\trim@w}}{\@okfalse}{}
  \fi
  \if@ok\else
    \fatal@err{Bad or missing \string\trimsize{w=W,h=H}.^^J%
     W and H must have units in|mm. Also, H>=W.^^J%
     You must set both of them. No default values.}%
  \fi
}
%% Intent (PDF/X Output Intent)
\def\@intent{SWOP} \def\intent@tail{(default)}
\newcommand\intent[1]{
  \StrSubstitute{#1}{FOGRA39L}{FOGRA39}[\temp@s]
  \IfSubStr{:none:SWOP:FOGRA39:JC200103:}{:\temp@s:}{
    \xdef\@intent{\temp@s} \gdef\intent@tail{}
  }{
    \nvt@err{Bad setting for \string\intent{setting}}%
      {Choose one setting: none SWOP FOGRA39 JC200103.^^J%
       Docs explain what the choices mean. Default SWOP.^^J%
       If choice none, PDF will not declare PDF/X conformance.^J%
       Others declare PDF/X conformance with chosen Output Intent,
       but only in final mode.}%
  }
}
%% Cover Image (only when option [cover])
%    Novelette cannot create cover artwork, but it can process a cover image
%  to standards. The image must be jpg format (not vector drawing),
%  at 300 pixels/inch, CMYK at 240% ink limit. These requirements are met
%  by pre-processing your artwork with script cmyk4nvt, included with the
%  Novelette documentation.
%    When you use option [cover], Novelette will ascertain that the image
%  was pre-processed by cmyk4nvt. If not, then (depending on what you provide)
%  it may either reject the image, or continue to a result in draft mode.
%    Format: \coverimage{filename.jpg} with extension.
%      Also: \coverimage{subfolder/filename.jpg} relative to main document.
\newcommand\coverimage[1]{
  \@oktrue
  \IfBeginWith{#1}{/}{\@okfalse}{}
  \IfSubStr{#1}{://}{\@okfalse}{}
  \IfBeginWith{#1}{..}{\@okfalse}{}
  \if@ok\else
    \fatal@err{Bad location for coverimage file.^^J%
      It may be same directory as main document,^^J%
      or in a subdirectory path, relative to main document.^^J%
      But you may not use an absolute path (beginning with / or ://)^^J%
      and you cannot use ../ to move up directory.}%
  \fi
  \IfEndWith{#1}{.jpg}{}{
    \fatal@err{Cover image must have `.jpg' file extension. No fake.}%
  }
  \gdef\cover@image{#1}
}
%% Cover Trim (finished cover size, after bleed removed)
%    The finished cover image wraps around the book block, including the
%  rear cover, spine, and front cover.
%    You will actually prepare a larger image, which exceeds the above,
%  by a bleed area on all four sides. Typical width of bleed area is 0.125in
%  or 3mm.
%    \covertrim{w=width,h=height} tells Novelette what the finished cover size
%  will be, after bleed is removed. In other words, it is rear+spine+front.
%    The covertrim height must be exactly the same as the interior page height.
%  The covertrim width must be more than double the interior page width.
%  Novelette checks these. If they do not make sense, an error results.  
%%
\newlength\covertrim@w \newlength\covertrim@h
\newcommand\covertrim[1]{
  \StrSubstitute{#1,}{ }{}[\temp@s]
  \StrBehind{\temp@s}{w=}[\temp@n]
  \StrBefore{\temp@n}{,}[\temp@n]
  \check@length{\temp@n}
  \if@ok
    \StrBehind{\temp@s}{h=}[\temp@d]
    \StrBefore{\temp@d}{,}[\temp@d]
    \check@length{\temp@d}
  \fi
  \if@ok
    \gdef\cover@trim{#1}
    \global\deflength\covertrim@w{\temp@n}
    \global\deflength\covertrim@h{\temp@d}
  \else
    \fatal@err{Bad \string\covertrim{w=W,h=H}.^^J%
      W is width of trimmed cover, units in|mm|cm.^^J%
      H is height of trimmed cover, units in|mm|cm.^^J%
      The covertrim is the finished cover size,^^J%
      after surrounding bleed has been trimmed off.^^J%
      The finished size includes rear cover, spine, front cover.^^J%
      The full size of the input cover image is larger,^^J%
      because it must include surrounding bleed areas.}%
  \fi
}
%%

%%% Sanity check. Image size, covertrim, and trimsize must be related.
\def\sanity@check{
  \setlength\temp@l{3mm+\trim@w+2mm+\trim@w+3mm} % Narrow spine.
  \ifthenelse{\dimtest{\wd\image@box}{<}{\temp@l}}{%
    \@okfalse%
    \nvt@err{Width of cover image is too small}%
     {Cover image includes front, back, spine, bleed.^^J%
      Even the thinnest book has cover image width more than twice^^J%
      the width of interior pages. Your cover image width is not enough.^^J%
      Caution: Novelette does not know what the actual width should be.}%
  }{\@oktrue}
  \setlength\temp@l{3mm+\trim@w+50mm+\trim@w+3mm} % War and Peace?
  \ifthenelse{\dimtest{\wd\image@box}{>}{\temp@l}}{%
    \@okfalse%
    \nvt@err{Width of cover image is too large}%
      {Cover image includes front, back, spine, bleed.^^J%
       So, the cover image width is more than 2x width of interior pages.^^J%
       But you provided a cover image that is so wide, only a massive book^^J%
       would fit it. Even `War and Peace' would be smaller.^^J%
       Caution: Novelette does not know what the actual width should be.}%
  }{}%
  \if@ok\typeout{Passed sanity check.}\fi%
}
%%%

%%% Validate Cover Image (necessary for PDF/X conformance).
\def\validate@cover@image#1{%
  \setcounter{temp@count}{7654321}%
  \addtocounter{temp@count}{\nvt@filesize{#1}}%
  \def\temp@n{%
    \directlua{
      img1=img.scan{filename="#1"}
      tex.print(img1.xsize)
    }%
  }%
  \IfInteger{\temp@n}{\addtocounter{temp@count}{\temp@n}}{}%
  \def\temp@d{%
    \directlua{
      img1=img.scan{filename="#1"}
      tex.print(img1.ysize)
    }%
  }%
  \IfInteger{\temp@d}{\addtocounter{temp@count}{\temp@d}}{}%
  \def\temp@s{-nvtc\arabic{temp@count}.}%
  \IfSubStr{#1}{\temp@s}{%
    \typeout{Cover image passed validation.}%
    \xdef\cover@size{width=\temp@n, height=\temp@d, pixels @300 pixels/in.}%
  }{%
    \nvt@err{Cover image did not pass validation}%
      {Unless \string\intent{none}, the cover image^^J%
       must be pre-processed by script `cmyk4nvt'. That creates^^J%
       another image with an encoded file name. This test failed^^J%
       because the encoded name did not agree with the image properties.}%
    \gdef\cover@size{unknown}%
  }%
}
%%%

%%% Process user settings, set defaults, calculate page layout:
\AtEndPreamble{
  \renewcommand\normalsize{\@setfontsize\normalsize{12pt}{16pt}} % Unused.
  \normalsize
  \ifdefined\@intent\else\gdef\@intent{SWOP}\fi
  \IfFileExists{\cover@image}{
    \validate@cover@image{\cover@image}
  }{
    \fatal@err{Did not find the requested cover image file.^^J%
      Must be *jpg. Must be in same folder as main document, or subfolder^^J%
      relative to main document.}%
  }
  \@addtofilelist{\cover@image}%
  \ProvidesFile{\cover@image}[jpg image]%
  \saveimageresource attr{/Interpolate true } cropbox {\cover@image}%
  \sbox\image@box{\useimageresource\the\lastsavedimageresourceindex}%
  \global\deflength\pagewidth{\wd\image@box}
  \global\deflength\pageheight{\ht\image@box}
  \global\deflength\topmargin{-1in}
  \global\deflength\oddsidemargin{-1in}
  \global\deflength\parindent{0pt}
  \global\deflength\textwidth{\pagewidth}
  \global\deflength\textheight{\pageheight}
  \sanity@check
  \LetLtxMacro\RequirePackage\get@package\relax
  \LetLtxMacro\usepackage\get@package\relax
  \ifthenelse{\dimtest{\trim@w}{=}{0pt}\OR\dimtest{\trim@h}{=}{0pt}}{
    \fatal@err{For cover, you must specify \string\trimsize{w=W,h=H}^^J%
      identical to the trimsize of book interior pages.}%
  }{}
  \ifthenelse{\dimtest{\covertrim@w}{=}{0pt}\OR\dimtest{\covertrim@h}{=}{0pt}}{
    \fatal@err{\string\covertrim\space was not set.^^J%
      The covertrim is the size of the finished cover, including^^J%
      back, spine, and front, after surrounding bleed has been cut off.^^J%
      It is less than the full size of the cover artwork, which includes^^J%
      bleed area on all four sides.^^J%
      In Preamble: \string\covertrim{w=W,h=H}^^J%
      \space\space W = Finished cover (units in|mm).^^J%
      \space\space H = Finished height (units in|mm).^^J%
      Example: \string\covertrim{w=11.87in,h=8.5in}}%
  }{}
  \ifdimcomp{\covertrim@h}{=}{\trim@h}{}{%
    \nvt@err{Heights of covertrim and trimsize are unequal}%
      {Print-on-demand softcover technology requires that^^J%
       (trimmed cover image height) = (trimmed interior page height).^^J%
       But they are set to different values.}%
  }
  \@oktrue
  \setlength\temp@l{2\trim@w+.15in} % A very thin book!
  \ifdimcomp{\covertrim@w}{<}{\temp@l}{\@okfalse}{}
  \setlength\temp@l{2\trim@w+2in} % War and Peace?
  \ifdimcomp{\covertrim@w}{>}{\temp@l}{\@okfalse}{}
  \if@ok\else
    \nvt@err{Unusually small or large covertrim width}%
      {The covertrim width must exceed 2x interior trimsize^^J%
      width by >=0.15in, but <=2in, for very thin or thick books.^^J%
      Typical popular fiction has covertrim width = 2x bookwidth + S,^^J%
      where spine width S is 0.4in to 1.0in.}%
  \fi
  \RequirePackage{novelette-metadata}
  \process@metadata
  \process@pdfboxes
}
%%%

%%% Finish the setup.
\AtBeginDocument{\pagestyle{empty}}
%%%

%%%
\AfterEndPreamble{% Write the image, and ignore anything in document body.
  \usebox{\image@box}%
  \clearpage%
}
%%%

%%% Runs at \end{document}. Document is still writeable here:
\AtEndDocument{
  \pdfextension info{%
    /CreationDate(\pdffeedback creationdate) % Needs space percent.
    /ModDate(\pdffeedback creationdate) % Needs space percent.
  }
  \iferrorsissued{\global\b@dtrue}{}
  \ifthenelse{\equal{\@title}{Untitled Document}}{\global\b@dtrue}{}
  \ifthenelse{\equal{\@author}{Anonymous Author}}{\global\b@dtrue}{}
  \gdef\mode@tail{} \gdef\intent@tail{}
  \ifb@d
    \gdef\@mode{draft}
    \gdef\@intent{none}
    \gdef\intent@tail{(due to compile error)}
    \gdef\mode@tail{(no final mode when error)}
    \gdef\mod@xmplabel{DRAFT COVER }
  \fi
  \attach@metadata
  \attach@xmp
  \ifthenelse{\equal{\@intent}{none}}{}{\attach@intent}
}
%%%

%% Log final messages and summary:
\AfterEndDocument{
  \typeout{^^J}
  \typeout{*******************************************************************}
  \typeout{SUMMARY FOR COVER \jobname}%
  \typeout{*******************************************************************}
  \typeout{These are the actual values used. If different from your settings,}
  \typeout{it means Novelette used defaults, or needed to over-ride yours:}
  \typeout{\string\title{\@title}}
  \typeout{\string\author{\@author}}
  \ifthenelse{\equal{\@mode}{draft}}{
    \typeout{PDF is not final, due to compile error.}
  }{}
  \typeout{\string\intent{\@intent}}
  \typeout{\string\coverimage{\cover@image}}
  \typeout{\string\covertrim{\cover@trim} (after trimming bleed area)}
  \typeout{Book interior \string\trimsize{\trim@size}}
  \typeout{Document Class novelette v0.\class@ver. Processed by lualatex.}
  \ifb@d
    \typeout{!!!!! ERROR OR CRITICAL WARNING. OUTPUT IS INVALID. !!!!!}
  \fi
  \typeout{*******************************************************************}
  \typeout{^^J}
}
%%%





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
%% End of file `novelette-cover.cls'.
