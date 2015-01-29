#!/usr/bin/perl

require "ctime.pl";
require "getopts.pl";

# Default suffix list for recursive directory scans.

@default_suffixes=(".h",".c",".C",".cpp",".cc");

# Filename scope resolution operator
# Used by PERCEPS to generate filenames for output files referring to
# nested classes and unions.

$SRO="___";

# Set this to true if you are generating html documentation and have one of the
# versions of netscape that has problems parsing &lt;, &gt; and &amp; It will
# cause percps to substitute the appropriate ascii codes instead.

$USE_ASCII_CODES=1;

# Comment marker characters.  These are specail characters used by perceps to 
# classify different ypes of comments and global variables.  You may alter them here
# to provide a limited amount of user-customizability as far as commenting style.

# Short description comment marker; begins a short description.  Must be different
# than $USER_MARKER.
$SDESC_MARKER=':';

# Custom comment markers.  The first begins the custom comment. The second delimits
# the identifier for the comment (i.e. //!NAME:)
$USER_MARKER='!';
$USER_DELIM=':';

# Global variable markers.  The first begins the global variable line.  The second
# associates name/value pairs (i.e. //! NAME=VALUE)
$GLOBAL_MARKER='!';
$GLOBAL_EQUALS='=';

# Set creator info for non-html and html generated files on Macintosh
# MSIE = Explorer MOSS = netscape ALFA = Alpha R*ch = BBEdit, etc.
$MacFileCreator="R*ch";
$MacHTMLFileCreator="MSIE";


#                                  PERCEPS v 3.5.0 BETA
#                 A C++ Documentation generator Written in Perl
#                         Copyright (C) 1997-1998 Mark Peskin
#                            mpeskin@mail.utexas.edu
#
#          MacPerl support by : Ryan Davis (RWD) <zss@ZenSpider.com>
#
# usage: perceps [-abcefhmnqru] [-s suffixes] [-d odir] [-t tdir | -o tdir]
#                [-i idir] [(files|directories)...]
#
#   This program is free software; you can redistribute it and/or modify it 
#   under the terms of the GNU General Public License as published by the 
#   Free Software Foundation; either version 2 of the License, or (at your
#   option) any later version.
#
#   This program is distributed in the hope that it will be useful, but 
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#   or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
#   for more details.
#
#   Options:
#   
#         -a :		Autolink text.  This causes PERCEPS to scan 
#         		all comments, argument lists, etc. for 
#         		references to documented classes.  All such
#         		references are automatically linked to the
#         		html file ClassName.html.  For use with
#         		html output only.
#        
#         -b :          Comment placement.  By default PERCEPS assumes 
#			that comments refering to a class member follow
#                       the associated member.  The b-switch causes this
#                       assumption to be reversed, so comments coming before
#                       a class member refer to that member.
#        
#         -c :          Causes standard c-style comments to be included
#                       in documentation, unless they are embedded in C++
#                       style comments, in which case they are still
#                       ignored.
#
#         -e :          Document all.  Forces PERCEPS to attempt to document
#			ALL non-class items regardless of whether they are
#			commented.
#         		
#         -f :          Find all.  Causes all directores specified on
#			the command line to be searched RECURSIVELY for
#			input files matching the suffix list.
#         		
#         -h :          When set, causes header file comments to be 
#                       treated as html instead of plaintext.
#         
#         -m :          Merge function documentation.  Causes documentation
#			found with member function definitions to be
#			merged with the documetation for the associated
#			member declaration.  When set, member function
#			definitions will not be documented separately.
#
#         -n :          Selective class documentation.  Normally PERCEPS
#			documents every class in a project.  The -n switch
#			will cause only classes preceeded by comment info
#			to be documented.
#         		
#         -q :          Quiet mode, supresses diagnostic output
#         
#         -r :          Force re-build.  Force all output files to be
#                       re-generated even if the associated header
#                       and template files haven't been modified since
#                       the last build.
#         		                      
#         -u :          Normally, comments that come before a class
#                       definition are only included in the class
#                       description if the follow at least one "short
#                       description" line (i.e. //:).  The -u switch
#                       overrides this, causing ALL comments that
#                       follow the previous declaration/definition
#                       to be included.
#
#         -s suffixes :	A comma delimited list of file suffixes to match
#         		when searching directories for input.  Wildcards
#                       (*,?) are permissable. If -s is not specified,
#			a default suffix list is used (.h,.c,.C,.cpp).
#         		
#         -d odir :	Directory in which to place output files
#         		Defaults to the current working directory.
#         		
#         -t tdir :	Directory to scan for template files.
#         		Defaults to the output directory.
#
#         -o tdir :	Same as -t but uses the contents of the
#			PERCEPS environment variable as a base path
#         		
#         -i idir :	An additional path to insert before the
#         		include file name when the include file
#         		is referenced in documentation.
#         		
#         (files|directories)...  A list of C or C++ files to parse.
#                       Directories are searched for all files matching
#                       the suffix list. Defaults to the current working
#                       directory.

# RWD BEGIN:
# Cross platform support for Macintosh, UNIX, and DOS/WIN*
#
# Use $X for directory separators
# Use $HereDir for the equivalent of "in this directory" ('.' on unix/DOS)
if ($^O =~ /^MacOS/) { # macintosh
  print "Running in MacPerl, will create 'Macified' files\n";
  $X = ":";
  $HereDir = ":";
  # For Droplets, put in your favorite parameters
  if ($MacPerl::Version !~ /MPW/) {  
    unshift(@ARGV, "-a", "-h", "-d", "${X}html", "-t", "${X}templates");
  }
} 
else { # assume msdos or unix, '/' works on NT (at least)
  $X = "\/";
  $HereDir = ".";
}
# RWD END



#
# Item types
#

$CLASS=1;
$STRUCT=2;
$UNION=3;
$GLOBAL=4;
$TYPEDEF=5;
$MACRO=6;
$ENUM=7;
$FUNC=8;
$VAR=9;

$SDESC_MARKER=~s/(\W)/\\$1/g;
$USER_MARKER=~s/(\W)/\\$1/g;
$USER_DELIM=~s/(\W)/\\$1/g;
$GLOBAL_MARKER=~s/(\W)/\\$1/g;
$GLOBAL_EQUALS=~s/(\W)/\\$1/g;

#
# Tag substitution variables
#
$TO_sub="$;#";
$TC_sub="$;@";
$TO_default="\{";
$TC_default="\}";

$infourl="http://friga.mer.utexas.edu/mark/perl/perceps/";

&Getopts('abrcefumnqhd:t:i:s:o:');

  if ($opt_s) {
    @default_suffixes=split(",",$opt_s);
  }

  $autolink=$opt_a;
  $incpath=$opt_i;
  $outdir=$opt_d;
  $docall=$opt_e;
  $docselect=$opt_n;
  
  $useccomm=$opt_c;
  $unsafecomm=$opt_u;
  $beforecomm=$opt_b;
  
  $mergefunc=$opt_m;
  
  if (!$outdir) { $outdir=$HereDir; }
  if ($opt_t) { $tmpldir=$opt_t; }
  
  elsif ($opt_o) {       #J.S.
    $tmpldir = "";
    if($ENV{PERCEPS}) {
      $tmpldir = $ENV{PERCEPS};
    }
    if (! ($tmpldir =~ /$X$/)) {
      $tmpldir .= $X;
    }
    $tmpldir .= $opt_o;
  }   
  else { $tmpldir=$outdir; }
  
   
  # RWD: used $X in pathing
  $outdir=~s/$X$//o;
  $tmpldir=~s/$X$//o;
  $incpath=~s/$X$//o;
   
  $anynewer=0;
  # RWD: created $lastbuildFile, used $X in pathing
  $lastbuildFile = "$outdir$X.perceps";  
  if ( -e $lastbuildFile && !$opt_r ) {
    @fdata=stat($lastbuildFile);
    $lastbuild=$fdata[9];
  }
  else { $lastbuild=0; }
  
  opendir(TDIR,$tmpldir);
  
   @tfiles=();

   foreach $entry (readdir(TDIR)) {
     if ($entry=~/\.tmpl$/ && !($entry=~/^~/)) { push(@tfiles,$entry); }
     if ($entry=~/\.flt$/ && !($entry=~/^~/)) {
       @fdata=stat("$tmpldir$X$entry");
       if ($fdata[9]>$lastbuild) { $lastbuild=0; }
     }
   }
 
  closedir(TDIR);
  
  if (!@tfiles) {
    print "No template files have been specified.  You must specify one or\n";
    print "more template files that PERCEPS will use to create output\n\n";
    &PRINT_USAGE;
    exit(0);
  }

  open(LBT,">$lastbuildFile");
  &MacPerl::SetFileInfo($MacFileCreator, "TEXT", $lastbuildFile)
    if $MacPerl::Version;
  $buildtime=&ctime(time);
  print LBT "Last Build $buildtime";
  close (LBT);
  
if (!@ARGV) {
  @ARGV=($HereDir);
}

foreach $inputfile (@ARGV) {
  if ( -f $inputfile) { push (@inputfiles,$inputfile); }
  elsif ( -d $inputfile ) {
    push (@inputfiles,&GET_FILE_LIST($inputfile,$opt_f,@default_suffixes));
  }
}

if ($#inputfiles < 0) {
  print "No input files specified.\n\n";
  &PRINT_USAGE;
  exit (0);
}
    
foreach $inputfile (@inputfiles) {

  $sdesc_marker=$SDESC_MARKER;
  $user_marker=$USER_MARKER;
  $user_delim=$USER_DELIM;
  $global_marker=$GLOBAL_MARKER;
  $global_equals=$GLOBAL_EQUALS;
  

  open(INPUT,"<$inputfile");
  while(<INPUT>) {
    if ($inputfile ne $oldinput) {
      if ($buffer) {
    	if (!$opt_q) { print "Parsing $oldinput\n"; }
    	@fdata=stat("$oldinput");
    	&PROCINPUT($fdata[9]);
      }
      #
      #  Clear Global Variables
      #
      foreach $gb (keys(%global)) {
    	 $global{$gb}=""; 
      }
      $global{hfile}=$csd=$inputfile;
      $oldinput=$inputfile;
      $global{hfile}=~s/^\\$incpath$X(.*)/$1/;
      $csd=~s/(.*)$X[^$X]+$/$1/;
      #
      #  Handle Directory default globals
      #
      if ($dglobkeys{$csd}) {
        foreach $gb (split($;,$dglobkeys{$csd})) {
          $global{$gb}=$dirglob{"$csd$;$gb"};
        }
      }
      $csd=~s/^\.*$X(.*)/$1/;
      $global{subdir}=$csd;
      $buffer="";
      $buffer.=$_;
    }
    else {
      $buffer.=$_;
    }
  }
  close(INPUT);
}
if ($buffer) { 
  if (!$opt_q) { print "Parsing $oldinput\n"; }
  @fdata=stat("$oldinput");
  &PROCINPUT($fdata[9]);
}  

# foreach $thing (@items) { print "ITEM $thing -> $itype{$thing}\n"; }

@items=grep(/\w+/,@items);
@classes=grep(/\w+/,@classes);
@gfuncs=grep(/\w+/,@gfuncs);
@gvars=grep(/\w+/,@gvars);
@tdefs=grep(/\w+/,@tdefs);
@macros=grep(/\w+/,@macros);

foreach $class (@allclasses) {
  foreach $child (@allclasses) {
    foreach $parent (split(",",$parents{$child})) {
      $ind1=index($parent,$class);
      $ind2=index($parent,"<");
      if (($ind1 >= $[) && ($ind2 >= $[)) {
        if ($ind1 < $ind2) {
          $children{$class}.="$child$;";
        }
      }
      elsif ($ind1 >= $[ ) {
        $children{$class}.="$child$;";
      }
    }
  }
}

@classes=sort(@classes);
@allclasses=sort(@allclasses);

foreach $tfile (@tfiles) {
  $templateFile = "$tmpldir$X$tfile";
  @fdata=stat($templateFile);
  $tmodtime=$fdata[9];

  if (!$opt_q) { print "Processing $tfile\n"; }

  @tbuf=();
  @tbufot=();
  @tbufct=();
  
  $tbufot[0]=$tbufots[0]=$TO_default;
  $tbufct[0]=$tbufcts[0]=$TC_default;

  $tbufi=0;
  
  open(TMPL,"<$templateFile");

  while (<TMPL>) {

    # ignore backshlashed ("\\"."\n") newlines
    # except quoted backshlashes ("\\"."\\"."\n")
    # J.S.
    $_ .= <TMPL> while s/(^|[^\\])\\\n/$1/;

    if (/\s*#\s*PTAGS\s*(\S)\s*(\S)/i) {
      # READ USER DEFINED TAG DELIMITERS
      $tbufi++;
      $tbufot[$tbufi]=$tbufots[$tbufi]=$1;
      $tbufct[$tbufi]=$tbufcts[$tbufi]=$2;
      $tbufot[$tbufi]=~s/(\W)/\\$1/g;
      $tbufct[$tbufi]=~s/(\W)/\\$1/g;
    }
    else { 
      # PREP TAGS
      s/$tbufot[$tbufi]\s+/$tbufots[$tbufi]/g;
      $tbuf[$tbufi].=$_; }
  }
  
  
  close(TMPL);

  $*=1;

  $file=$tfile;
  $file=~s/\.tmpl$//;
  $file=~/(\.\w+)$/;
  $tmptype=$1;
  
  if ($file=~/CLASS/) {
    foreach $class (@classes) {
      $gfile=$file;
      $gfile=~s/CLASS/$class/;
      $gfile=~s/\:\:/$SRO/g;

      $cmod=0;
      foreach $child (split($;,$children{$class})) {
        if ( $modtime{$child} > $lastbuild ) { $cmod=1; last; }
      }

      $genFile = "$outdir$X$gfile"; # RWD: Defined $genFile using $X
      if ( ($tmodtime>$lastbuild) ||
           ($modtime{$class}>$lastbuild) ||
           $cmod || !( -e $genFile)) {
        if (!$opt_q) { print "Generating $genFile\n"; }
        $alopt="";
        open(OUTFILE,">$genFile");
        $FileCreator = $MacFileCreator;
        if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
          $FileCreator = $MacHTMLFileCreator;
        }
        &MacPerl::SetFileInfo($FileCreator, "TEXT", $genFile)
          if $MacPerl::Version;
        $htmlcomm=$opt_h;
        for ($i=0;$i<=$#tbuf;$i++) {
          $TO=$tbufot[$i];
          $TC=$tbufct[$i];
          $TOs=$tbufots[$i];
          $TCs=$tbufcts[$i];
          print OUTFILE &GENTEXT(0,$tbuf[$i],0,$class);
        }
        close(OUTFILE);
      }
    }
  }
  
  elsif ($file=~/\@(\w+)\@/) {
    $gnm=$1;
    %gvalid=();
    foreach $gval (split($;,$globalvalues{$gnm})) {
      $gfile=$file;
      $cgval=$gval;
      $cgval=~s/(\s|$X)/\_/g;
      $gfile=~s/\@$gnm\@/$cgval/;

      $cmod=0;

      $gvalid{$gnm}=$gval;

      $genFile = "$outdir$X$gfile"; # RWD: Defined $genFile using $X
      if ( ($tmodtime>$lastbuild) || $cmod || !( -e $genFile)) {
        if (!$opt_q) { print "Generating $genFile\n"; }
        $alopt="";
        open(OUTFILE,">$genFile");
        $FileCreator = $MacFileCreator;
        if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
          $FileCreator = $MacHTMLFileCreator;
        }
        &MacPerl::SetFileInfo($FileCreator, "TEXT", $genFile)
          if $MacPerl::Version;
        $htmlcomm=$opt_h;
        for ($i=0;$i<=$#tbuf;$i++) {
          $TO=$tbufot[$i];
          $TC=$tbufct[$i];
          $TOs=$tbufots[$i];
          $TCs=$tbufcts[$i];
          print OUTFILE &GENTEXT(0,$tbuf[$i],0,0,0,$gnm,%gvalid);
        }
        close(OUTFILE);
      }
    }
  }


  else {
      $genFile = "$outdir$X$file"; # RWD: Defined $genFile using $X in pathing
    if ( ($tmodtime>$lastbuild) || $anynewer || !( -e $genFile)) {
      if (!$opt_q) { print "Generating $genFile\n"; }
      $alopt="";
      open(OUTFILE,">$genFile");
        $FileCreator = $MacFileCreator;
        if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
          $FileCreator = $MacHTMLFileCreator;
        }
        &MacPerl::SetFileInfo($FileCreator, "TEXT", $genFile)
          if $MacPerl::Version;
      $htmlcomm=$opt_h;
      for ($i=0;$i<=$#tbuf;$i++) {
        $TO=$tbufot[$i];
        $TC=$tbufct[$i];
        $TOs=$tbufots[$i];
        $TCs=$tbufcts[$i];
        print OUTFILE &GENTEXT(0,$tbuf[$i],0);
      }
      close(OUTFILE);
    }
  }
}

#
# Generate output for documented nested classes
#

if (@nestedclasses) {

print "\nGenerating Nested Class Docs\n\n";

foreach $tfile (@tfiles) {
  if ($tfile=~/CLASS/) {
  $templateFile = "$tmpldir$X$tfile";
  @fdata=stat($templateFile);
  $tmodtime=$fdata[9];

  if (!$opt_q) { print "Processing $tfile\n"; }

  @tbuf=();
  @tbufot=();
  @tbufct=();

  $tbufot[0]=$tbufots[0]=$TO_default;
  $tbufct[0]=$tbufcts[0]=$TC_default;

  $tbufi=0;

  open(TMPL,"<$templateFile");

  while (<TMPL>) {


    # ignore backshlashed ("\\"."\n") newlines
    # except quoted backshlashes ("\\"."\\"."\n")
    # J.S.
    $_ .= <TMPL> while s/(^|[^\\])\\\n/$1/;

    if (/\s*#\s*PTAGS\s*(\S)\s*(\S)/i) {
      # READ USER DEFINED TAG DELIMITERS
      $tbufi++;
      $tbufot[$tbufi]=$tbufots[$tbufi]=$1;
      $tbufct[$tbufi]=$tbufcts[$tbufi]=$2;
      $tbufot[$tbufi]=~s/(\W)/\\$1/g;
      $tbufct[$tbufi]=~s/(\W)/\\$1/g;
    }
    else {
      # PREP TAGS
      s/$tbufot[$tbufi]\s+/$tbufots[$tbufi]/g;
      $tbuf[$tbufi].=$_; }
  }


  close(TMPL);

  $*=1;

  $file=$tfile;
  $file=~s/\.tmpl$//;
  $file=~/(\.\w+)$/;
  $tmptype=$1;

  if ($file=~/CLASS/) {
    foreach $class (@nestedclasses) {
      $gfile=$file;
      $gfile=~s/CLASS/$class/;
      $gfile=~s/\:\:/$SRO/g;

      $cmod=0;
      foreach $child (split($;,$children{$class})) {
        if ( $modtime{$child} > $lastbuild ) { $cmod=1; last; }
      }

      $genFile = "$outdir$X$gfile"; # RWD: Defined $genFile using $X
      if ( ($tmodtime>$lastbuild) ||
           ($modtime{$class}>$lastbuild) ||
           $cmod || !( -e $genFile)) {
        if (!$opt_q) { print "Generating $genFile\n"; }
        $alopt="";
        open(OUTFILE,">$genFile");
        $FileCreator = $MacFileCreator;
        if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
          $FileCreator = $MacHTMLFileCreator;
        }
        &MacPerl::SetFileInfo($FileCreator, "TEXT", $genFile)
          if $MacPerl::Version;
        $htmlcomm=$opt_h;
        for ($i=0;$i<=$#tbuf;$i++) {
          $TO=$tbufot[$i];
          $TC=$tbufct[$i];
          $TOs=$tbufots[$i];
          $TCs=$tbufcts[$i];
          print OUTFILE &GENTEXT(0,$tbuf[$i],0,$class);
        }
        close(OUTFILE);
      }
    }
  }
  }
}
}

#
# Generate Output From Templates
#

sub GENTEXT {


 local($inner,$str,$ord,$cname,$mname,$curglob,%curglobval)=@_;
 local(@arg,$args,$ml,$tmpstr,$srcstr,$member,$nest,@group,@newgroup);
 local(%appinfo,$cleaned,$value,$neg,$linkname,$dosort,$sortfunc);
 local($defclass,$index,$mloc,$mnm,$tmp,$tmp2,$glb,@globgroup);
 local($fname,$ok,%newglobval);
   
  if ($*) { $ml=0; }
  else { $ml=1; $*=1; }
  
  $mloc=$cname;
  $mnm=$mname;
  
  if ($mname=~/(.+)$;(.+)/) {
    $mloc=$1;
    $mnm=$2;
    if ($mloc ne $cname) {$defclass=$1;}
  }
  
  %filterflags=();
  
  if ($itype{$cname}<=$UNION) {
    $linkname=$cname;
    if ($container{$cname}) {
      $tmp=$container{$cname};
      $tmp=~s/\:\:/$SRO/g;
      $linkname=~s/^(\S+)\:\:(.+)$/\<A HREF\=\"$tmp\.html\"\>$1\<\/A\>\:\:$2/;
    }
  }
    
    while ($str=~/$TO([^$TO$TC]*)$TC/) {
    
      $args=$1;
      @arg=split(" ",$args,5);
#
#  Basic tags
#      
      if ($arg[0] eq "name") {
        if ($curglob) {
          $cleaned=&FILTER($curglobval{$curglob},"$tmpldir$X$curglob.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
          %filterflags=();
          if ($arg[1] eq "@") { $cleaned=~s/(\s|$X)/\_/g; }
          $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
        }
        elsif ($mname) {
          if ($type{$mloc,$mnm}=~/^\s*(class|struct|union)\s*$/) {
            $cleaned=$memname{$mloc,$mnm};
            # Add nested item to nested class list so docs will be generated
            push(@nestedclasses,"$mloc\:\:$cleaned");
            $printable{"$mloc\:\:$cleaned"} = 1;
            if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
              $cleaned=$memname{$mloc,$mnm};
              $cleaned=~s/$cleaned/\<A HREF\=\"$cname\:\:$cleaned\.html\"\>$cleaned\<\/A\>/;
            }
          }
          else { $cleaned=$memname{$mloc,$mnm}; }
          $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
        }
        elsif ($cname) {
          if ($itype{$cname}<$ENUM) {$str=~s/$TO([^$TO$TC]*)$TC/$cname/;}
          elsif ($itype{$cname}==$ENUM) {$str=~s/$TO([^$TO$TC]*)$TC/$renname{$cname}/;}
          elsif ($itype{$cname}==$FUNC) {$str=~s/$TO([^$TO$TC]*)$TC/$funcname{$cname}/;}
        }
        else { $str=~s/$TO([^$TO$TC]*)$TC//; }
      }
      elsif ($arg[0] eq "autolink") {
        $args=~s/autolink//;
        $autolink=1;
        $alopt=$args;
        $str=~s/$TO([^$TO$TC]*)$TC//;
      }
      elsif ($arg[0] eq "!autolink") {
        $autolink=0;
        $str=~s/$TO([^$TO$TC]*)$TC//;
      }
      elsif ($arg[0] eq "keephtml") {
        $htmlcomm=1;
        $str=~s/$TO([^$TO$TC]*)$TC//;
      }
      elsif ($arg[0] eq "!keephtml") {
        $htmlcomm=0;
        $str=~s/$TO([^$TO$TC]*)$TC//;
      }
      elsif ($arg[0] eq "templ") {
        $cleaned=&CLEANTEXT($template{$cname});
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "parents") {
        $cleaned=&CLEANTEXT($parents{$cname});
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "class") {
        $str=~s/$TO([^$TO$TC]*)$TC/$cname/;
      }
      elsif ($arg[0] eq "classname") {
        $str=~s/$TO([^$TO$TC]*)$TC/$cname/;
      }
      elsif ($arg[0] eq "classfile") {
        $tmp=$cname;
        $tmp=~s/\:\:/$SRO/g;
        $str=~s/$TO([^$TO$TC]*)$TC/$tmp/;
      }
      elsif ($arg[0] eq "classlinked") {
        $str=~s/$TO([^$TO$TC]*)$TC/$linkname/;
      }
      elsif ($arg[0] eq "buildtime") {
        $cleaned=&FILTER($buildtime,"$tmpldir${X}time.flt");
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "modtime") {
        $cleaned=&FILTER(&ctime($modtime{$cname}),"$tmpldir${X}time.flt");
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "member") {
        if ($func{$mloc,$mnm}) {
          $cleaned=&CLEANTEXT("$memname{$mloc,$mnm}($args{$mloc,$mnm})");
        }
        else { $cleaned=&CLEANTEXT($mnm); }
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "memberef") {
        $cleaned=$mname;
        $cleaned=~s/\W/_/g;
        $cleaned=~s/COMM//g;
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "mname") {
        $cleaned=$memname{$mloc,$mnm};
 	if ($type{$mloc,$mnm}=~/^\s*(class|struct|union)\s*$/) {
          # Add nested item to nested class list so docs will be generated
          push(@nestedclasses,"${mloc}\:\:$cleaned");
          $printable{"$mloc\:\:$cleaned"} = 1;
          if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
            $cleaned="<A HREF='$mloc$SRO$cleaned$tmptype'>$cleaned</A>";
          }
 	}
 	if (($mloc ne $cname) && ($access{$mloc,$mnm} ne "friend")) {
 	  if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
 	    $cleaned="<A HREF='$mloc$tmptype'>$mloc</A>::$cleaned";
 	  }
 	  else {
 	    $cleaned="${mloc}::$cleaned";
 	  }
 	}
 	$str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "defclass") {
        $cleaned=&CLEANTEXT($mloc);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "global") {
        $cleaned=&FILTER($curglobval{$curglob},"$tmpldir$X$curglob.flt");
        $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
        %filterflags=();
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "args") {
        if ($mname) { $cleaned=$args{$mloc,$mnm}; }
        else { $cleaned=$args{$cname}; }
        $cleaned=&REPLACE_SPECIAL($cleaned);
        $cleaned=&FILTER($cleaned,"$tmpldir${X}args.flt");
        %filterflags=();
        $cleaned=&CLEANTEXT($cleaned);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "throwclass") {
        if ($mname) { $cleaned=$exclass{$mloc,$mnm}; }
        else { $cleaned=$exclass{$cname}; }
        $cleaned=&CLEANTEXT($cleaned);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "throwargs") {
        if ($mname) { $cleaned=$exargs{$mloc,$mnm}; }
        else { $cleaned=$exargs{$cname}; }
        $cleaned=&REPLACE_SPECIAL($cleaned);
        $cleaned=&FILTER($cleaned,"$tmpldir${X}args.flt");
        %filterflags=();
        $cleaned=&CLEANTEXT($cleaned);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "rb") {
        $str=~s/$TO([^$TO$TC]*)$TC/$TC_sub/;
      }
      elsif ($arg[0] eq "lb") {
        $str=~s/$TO([^$TO$TC]*)$TC/$TO_sub/;
      }
      elsif (($arg[0] eq "br") || ($arg[0] eq "n")) {
        $str=~s/$TO([^$TO$TC]*)$TC/\n/;
      }
      elsif ($arg[0] eq "type") {
        if ($mname) { $cleaned=&CLEANTEXT($type{$mloc,$mnm}); }
        else { $cleaned=&CLEANTEXT($type{$cname}); }
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "brief") {
        if ($mname) {
          $cleaned=$sdesc{$mloc,$mnm};
          if ($related_func{$mloc,$mnm} && $mergefunc) {
            $cleaned=$sdesc{$related_func{$mloc,$mnm}};
          }
          if ($arg[1] eq "wrap") {
            $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
          }
          $cleaned=&FILTER($cleaned,"$tmpldir${X}brief_m.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}brief.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
          %filterflags=();
          $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        }
        else { 
          $cleaned=$sdesc{$cname};
          if ($arg[1] eq "wrap") {
            $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
          }
          $cleaned=&FILTER($cleaned,"$tmpldir${X}brief_c.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}brief.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
          %filterflags=();
          $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        }
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "detail") {
        if ($mname) {
          $cleaned=$desc{$mloc,$mnm};
          if ($related_func{$mloc,$mnm} && $mergefunc) {
	    if ($cleaned) { $cleaned.="\n"; }
            $cleaned.=$desc{$related_func{$mloc,$mnm}};
          }
          if ($arg[1] eq "wrap") {
            $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
          }
          $cleaned=&FILTER($cleaned,"$tmpldir${X}detail_m.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}detail.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
          %filterflags=();
          $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        }
        else { 
          $cleaned=$desc{$cname};
          if ($arg[1] eq "wrap") {
            $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
          }
          $cleaned=&FILTER($cleaned,"$tmpldir${X}detail_c.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}detail.flt");
          $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
          %filterflags=();
          $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        }
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($arg[0] eq "applet") {
        if (!$appinfo{str}) { %appinfo=&GENAPPLT($cname,$arg[1]." ".$arg[2]." ".$arg[3]." ".$arg[4]); }
        $str=~s/$TO([^$TO$TC]*)$TC/$appinfo{str}/;
      }
      elsif ($arg[0] eq "appheight") {
        if (!$appinfo{height}) { %appinfo=&GENAPPLT($cname); }
        $str=~s/$TO([^$TO$TC]*)$TC/$appinfo{height}/;
      }
      elsif ($arg[0] eq "appwidth") {
        if (!$appinfo{width}) { %appinfo=&GENAPPLT($cname); }
        $str=~s/$TO([^$TO$TC]*)$TC/$appinfo{width}/;
      }
#
#  For-next loops
#  
      elsif ($arg[0] eq "foreach") {
        $index=0;
        @group=();
        $tmpstr="";
        $srcstr=&GETBLOCK($str,"${TO}for","${TO}next",$TC);
        
        if ($arg[2] eq "sort") {
          $dosort=2;
        }
        elsif ($arg[3] eq "sort") {
          $dosort=3;
        }
 	if ($dosort && $arg[$dosort+1]) {
 	  $sortfunc=$dosort+1;
 	  $tmp=$arg[$sortfunc]." ".$arg[$sortfunc+1];
 	  if ($tmp=~/(\"|\')([^\1]+)\1/) {
 	    $sortstatments=$2;
 	  }
 	  else {
 	    $sortstatments="";
 	    open(SORTFILE,"<$tmpldir${X}$arg[$sortfunc]");
 	    while (<SORTFILE>) { $sortstatments.=$_; }
 	    close(SORTFILE);
 	  }
 	  eval "sub DOSORT { $sortstatments }";
 	}
        
              
        if ($arg[1] eq "item") {
          @group=@items;
          if (@group) {
            if ($dosort) { 
              if ($sortfunc) { @group = sort( DOSORT @group ); }
              else { @group = sort (@group); }
            }
            foreach $member (@group) {
              if ($index==$#group) { $index=-1; }
              $tmp=1;
              if (%curglobval) {
                foreach $glb (keys(%curglobval)) {
                  if (eval("\$U_$glb\{\$member\}") ne $curglobval{$glb}) {
                    $tmp=0;
                    last;
                  }
                }
              }
              if ($tmp) {
                if (!$container{$member} || $printable{$member}) {
 	          $tmpstr.=&GENTEXT(1,$srcstr,$index,$member,0,0,%curglobval);
                  $index++;
                }
 	      }
            }
          }
        }
        elsif ($arg[1]=~/class|parent|child|union/) {

          if ($arg[1] eq "class") { 
            @newgroup=@allclasses;
            foreach $member (@newgroup) {
              if ($itype{$member}==$CLASS || $itype{$member}==$STRUCT) {
                push(@group,$member);
              }
            }
          }

          if ($arg[1] eq "union") { 
            @newgroup=@allclasses;
            foreach $member (@newgroup) {
              if ($itype{$member}==$UNION) {
                push(@group,$member);
              }
            }
          }
                    
          if ($arg[1] eq "parent") {
            if ($arg[2]=~/all/i) {
              @group=&GETPARENTS($cname,1);
            }
            else { @group=&GETPARENTS($cname,0); }
          }
          
          if ($arg[1] eq "child") {
            if ($arg[2]=~/all/i) {
              @group=&GETCHILDREN($cname,1);
            }
            else { @group=&GETCHILDREN($cname,0); }
          }
          
          if (@group) {
            if ($dosort) { 
              if ($sortfunc) { @group = sort( DOSORT @group ); }
              else { @group = sort (@group); }
            }
 	    foreach $member (@group) {
 	      $member=~s/([\w\:]+).*/$1/;
              if ($index==$#group) { $index=-1; }
              $tmp=1;
              if (%curglobval) {
                foreach $glb (keys(%curglobval)) {
                  if (eval("\$U_$glb\{\$member\}") ne $curglobval{$glb}) {
                    $tmp=0;
                    last;
                  }
                }
              }
              if ($tmp) {
                if (!$container{$member} || $printable{$member} ||
	            $arg[1] eq "parent"  || $arg[1] eq "child") {
 	          $tmpstr.=&GENTEXT(1,$srcstr,$index,$member,0,0,%curglobval);
 	          $index++;
                }
 	      }
 	    }
 	  }
        }

        elsif ($arg[1]=~/func|global|typedef|macro/){

          if ($arg[1] eq "func") { 
            @group=@gfuncs;
          }
        
          if ($arg[1] eq "global") { 
            @group=@gvars;
          }

          if ($arg[1] eq "typedef") { 
            @group=@tdefs;
          }

          if ($arg[1] eq "macro") { 
            @group=@macros;
          }

          if (@group) {
            if ($dosort) { 
              if ($sortfunc) { @group = sort( DOSORT @group ); }
              else { @group = sort (@group); }
            }
 	    foreach $member (@group) {
 	      $tmp=1;
              if ($index==$#group) { $index=-1; }
              if (%curglobval) {
                foreach $glb (keys(%curglobval)) {
                  if (eval("\$U_$glb\{\$member\}") ne $curglobval{$glb}) {
                    $tmp=0;
                    last;
                  }
                }
              }
              if ($tmp) {
 	        $tmpstr.=&GENTEXT(1,$srcstr,$index,$member,0,0,%curglobval);
 	        $index++;
 	      }
 	    }
 	  }
        }
        
        elsif ($arg[1]=~/public|private|protected|friend|member/){
          if ($arg[2]=~/all/i) { @group=&GETMEMBERS($cname,$arg[1],1); }
          else { @group=&GETMEMBERS($cname,$arg[1],0); }
 	  if ($dosort) {
 	    if ($sortfunc) { @group = sort( DOSORT @group ); }
 	    else { @group = sort (@group); }
 	  }
          foreach $member (@group) {
            if ($index==$#group) { $index=-1; }
            $tmpstr.=&GENTEXT(1,$srcstr,$index,$cname,$member,0,%curglobval);
 	    $index++;
          }
        }
#
#  Global Variable for-next Loops
#
        elsif (&INARRAY($arg[1],keys(%global))) {
          @globgroup=split($;,$globalvalues{$arg[1]});
 	  if ($sortfunc) { @globgroup = sort( DOSORT @globgroup ); }
 	  else { @globgroup = sort (@globgroup); }
 	  %newglobval=%curglobval;
          foreach $value (@globgroup) {
            $newglobval{$arg[1]}=$value;
            $tmpstr.=&GENTEXT(1,$srcstr,$index,0,0,$arg[1],%newglobval);
            $index++;
          }
          if ($arg[2]=~/all/i){
            $newglobval{$arg[1]}="";
            $tmpstr.=&GENTEXT(1,$srcstr,$index,0,0,$arg[1],%newglobval);
          }
        }
        $srcstr=~s/(\W)/\\$1/g;
        $args=~s/(\W)/\\$1/g;
        $str=~s/$TO$args$TC$srcstr${TO}next[^$TC]*$TC/$tmpstr/;
      }
#
#  if-then blocks
#
      elsif ($arg[0] eq "if") {
        $tmpstr="";
        $srcstr=&GETBLOCK($str,"${TO}if","${TO}endif",$TC);
          $neg=0;
          if ($arg[1]=~s/^!(.+)/$1/) {$neg=1;}
          if ((($arg[1] eq "templ") && $template{$cname})  ||
              (($arg[1] eq "parents") && $parents{$cname}) ||
              (($arg[1] eq "type") && $type{$mloc,$mnm})  ||
              (($arg[1] eq "func") && $mname && $func{$mloc,$mnm})  ||
              (($arg[1] eq "func") && !$mname && ($itype{$cname}==$FUNC))  ||
              (($arg[1] eq "enum") && $mname && $enum{$mloc,$mnm})  ||
              (($arg[1] eq "enum") && !$mname && ($itype{$cname}==$ENUM))  ||
              (($arg[1] eq "throws") && $mname && $throwsex{$mloc,$mnm})  ||
              (($arg[1] eq "throws") && !$mname && $throwsex{$cname})  ||
              (($arg[1] eq "throwclass") && $mname && $exclass{$mloc,$mnm})  ||
              (($arg[1] eq "throwclass") && !$mname && $exclass{$cname})  ||
              (($arg[1] eq "throwargs") && $mname && $exargs{$mloc,$mnm})  ||
              (($arg[1] eq "throwargs") && !$mname && $exargs{$cname})  ||
              (($arg[1] eq "args") && $args{$mloc,$mnm})  ||
              (($arg[1] eq "children") && $children{$cname})  ||
              (($arg[1] eq "public") && $members{$cname,public})  ||
              (($arg[1] eq "anypublic") && &GETMEMBERS($cname,"public",1))  ||
              (($arg[1] eq "private") && $members{$cname,private})  ||
              (($arg[1] eq "anyprivate") && &GETMEMBERS($cname,"private",1))  ||
              (($arg[1] eq "protected") && $members{$cname,protected}) ||
              (($arg[1] eq "anyprotected") && &GETMEMBERS($cname,"protected",1))  ||
              (($arg[1] eq "friend") && $members{$cname,friend}) ||
              (($arg[1] eq "anyfriend") && &GETMEMBERS($cname,"friend",1))  ||
              (($arg[1] eq "inherited") && $defclass) ||
              (($arg[1] eq "class") && !$mname && ($itype{$cname}==$CLASS)) ||
              (($arg[1] eq "struct") && !$mname && ($itype{$cname}==$STRUCT)) ||
              (($arg[1] eq "union") && !$mname && ($itype{$cname}==$UNION)) ||
              (($arg[1] eq "global") && ($itype{$cname}==$GLOBAL)) ||
              (($arg[1] eq "typedef") && ($itype{$cname}==$TYPEDEF)) ||
              (($arg[1] eq "macro") && ($itype{$cname}==$MACRO)) ||
              (($arg[1] eq "const") && $isconst{$mloc,$mnm}) || 
              (($arg[1] eq "brief") && $mname && $sdesc{$mloc,$mnm})  ||
              (($arg[1] eq "brief") && $mname && $related_func{$mloc,$mnm} && $mergefunc && $sdesc{$related_func{$mloc,$mnm}})  ||
              (($arg[1] eq "brief") && !$mname && $sdesc{$cname})  ||
              (($arg[1] eq "detail") && $mname && $desc{$mloc,$mnm})  ||
              (($arg[1] eq "detail") && $mname && $related_func{$mloc,$mnm} && $mergefunc && $sdesc{$related_func{$mloc,$mnm}})  ||
              (($arg[1] eq "detail") && !$mname && $desc{$cname})  ||
              (($arg[1] eq "first") && $ord==0)  ||
              (($arg[1] eq "last") && $ord==-1)  ||
              (($arg[1] eq "mid") && $ord>0)  ||
              (($arg[1] eq "hasinlines") && $hasinlines{$cname})  ||
              (($arg[1] eq "abstract") && $isabstract{$cname})  ||
              (($arg[1] eq "pure") && $mname && $ispure{$mloc,$mnm})  ||
              ($mname && eval("\$U_$arg[1]\{\$mloc,\$mnm\};"))  ||
              ($mname && $related_func{$mloc,$mnm} && $mergefunc && eval("\$U_$arg[1]\{\$related_func\{\$mloc,\$mnm\}\};"))  ||
              (!$mname && eval("\$U_$arg[1]\{\$cname\};"))  ||
              ($curglob && ($arg[1] eq $curglob) && $curglobval{$curglob})){
                 if ($neg) { $doelse=1;}
                 else {
                   $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
                   $doelse=0;
                 }
          }
          elsif ((($arg[1] eq "class") && $mname && ($type{$mloc,$mnm}=~/^\s*(class)\s*$/)) ||
                 (($arg[1] eq "struct") && $mname && ($type{$mloc,$mnm}=~/^\s*(struct)\s*$/)) ||
                 (($arg[1] eq "union") && $mname && ($type{$mloc,$mnm}=~/^\s*(union)\s*$/)) ||
                 (($arg[1] eq "nested") && $mname && ($type{$mloc,$mnm}=~/^\s*(class|struct|union)\s*$/))) {
                   if ($neg) { $doelse=1;}
 		   else {
 		     $tmpstr=&GENTEXT(1,$srcstr,$ord,"$cname\:\:$mnm",,$curglob,%curglobval);
 		     $doelse=0;
 		   }
 	  }
          
          elsif (($arg[1] eq "name") && ($arg[2]=~/^\//)) {
            $tmp="$arg[2] $arg[3] $arg[4]";
            $tmp=~/\/(.*[^\\])\//;$tmp=$1;
            $tmp=~s/(\W)/\\$1/g;
 	    if ($curglob) { $tmp2=$curglobval{$curglob}; }
 	    elsif ($mname) { $tmp2=$memname{$mloc,$mnm}; }
 	    else {
 	      if ($itype{$cname}<$ENUM) {$tmp2=$cname;}
 	      elsif ($itype{$cname}==$ENUM) {$tmp2=$renname{$cname};}
 	      elsif ($itype{$cname}==$FUNC) {$tmp2=$funcname{$cname};}
 	    }
 	    if ($tmp2=~/$tmp/) {
              if ($neg) { $doelse=1;}
 	      else {
 	        $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
 	        $doelse=0;
 	      }
            }
            else {
              if ($neg) {
                $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
                $doelse=0;
              }
            }
          }
          elsif (($arg[1] eq "parent") && ($arg[2]=~/^\//)) {
            $tmp="$arg[2] $arg[3] $arg[4]";
            $tmp=~/\/(.*[^\\])\//;$tmp=$1;
            $tmp=~s/(\W)/\\$1/g;
            @group=&GETPARENTS($cname,1);
            $ok=0;
            foreach $tmp2 (@group) {
              if ($tmp2=~/$tmp/) { $ok=1; last; }
            }
 	    if ($ok) {
              if ($neg) { $doelse=1;}
 	      else {
 	        $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
 	        $doelse=0;
 	      }
            }
            else {
              if ($neg) {
                $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
                $doelse=0;
              }
            }
          }
          elsif (($arg[1] eq "child") && ($arg[2]=~/^\//)) {
            $tmp="$arg[2] $arg[3] $arg[4]";
            $tmp=~/\/(.*[^\\])\//;$tmp=$1;
            $tmp=~s/(\W)/\\$1/g;
            @group=&GETCHILDREN($cname,1);
            $ok=0;
            foreach $tmp2 (@group) {
              if ($tmp2=~/$tmp/) { $ok=1; last; }
            }
 	    if ($ok) {
              if ($neg) { $doelse=1;}
 	      else {
 	        $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
 	        $doelse=0;
 	      }
            }
            else {
              if ($neg) {
                $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
                $doelse=0;
              }
            }
          }
          else {
            if ($neg) {
              $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
              $doelse=0;
            }
            else {  $doelse=1;}
          }
        $srcstr=~s/(\W)/\\$1/g;
        $str=~s/$TO$args$TC$srcstr${TO}endif[^$TC]*$TC/$tmpstr/;
      }
#
#  else blocks
#
      elsif ($arg[0] eq "else") {
        $tmpstr="";
        $srcstr=&GETBLOCK($str,"${TO}else","${TO}endelse",$TC);
        if ($doelse) {
          $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
          $doelse=0;
        }
        $srcstr=~s/(\W)/\\$1/g;
        $str=~s/$TO$args$TC$srcstr${TO}endelse[^$TC]*$TC/$tmpstr/;
      }
#
#  Custom filters
#
      elsif ($arg[0] eq "filter") {
        $tmpstr="";
        $srcstr=&GETBLOCK($str,"${TO}filter","${TO}endfilter","$TC");
        $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
        if ($arg[1]=~/^\//) { $tmpstr=&FILTER($tmpstr,"$arg[1].flt"); }
        else { $tmpstr=&FILTER($tmpstr,"$tmpldir${X}$arg[1].flt"); }
        %filterflags=();
        if (!($arg[2]=~/kt/i)) {
          $tmpstr=~s/$TO/$TO_sub/g;
          $tmpstr=~s/$TC/$TC_sub/g;
        }
        $srcstr=~s/(\W)/\\$1/g;
        $str=~s/$TO$args$TC$srcstr${TO}endfilter[^$TC]*$TC/$tmpstr/;
      }
      
#
#  Ignore linebreak blocks
#
      elsif ($arg[0] eq "nobreak" ) {
        $tmpstr="";
        $srcstr=&GETBLOCK($str,"${TO}nobreak","${TO}endnobreak",$TC);
        $tmpstr=$srcstr;
        $tmpstr=~s/\n//g;
        $tmpstr=&GENTEXT(1,$tmpstr,$ord,$cname,$mname,$curglob,%curglobval);
        $srcstr=~s/(\W)/\\$1/g;
        $str=~s/$TO$args$TC$srcstr${TO}endnobreak[^$TC]*$TC/$tmpstr/;
      } 

#
#  Include files
#

      elsif ($arg[0] eq "include" ) {
        $tmpstr="";
        $srcstr="";
        if ($arg[1]=~/^\//) { open(INCLUDE,"<$arg[1]"); }
        else { open(INCLUDE,"<$tmpldir${X}$arg[1]"); }
        while (<INCLUDE>) {
          $_ .= <INCLUDE> while s/(^|[^\\])\\\n/$1/;
          $srcstr.=$_;
        }
        close(INCLUDE);
        $tmpstr=&GENTEXT(1,$srcstr,$ord,$cname,$mname,$curglob,%curglobval);
        $str=~s/$TO([^$TO$TC]*)$TC/$tmpstr/;
      }

#
#  File Generation blocks
#

      elsif ($arg[0] eq "genfile" ) {
        $srcstr=&GETBLOCK($str,"${TO}genfile","${TO}endgenfile",$TC);
        ($fname,$tmpstr)=split(/$TO\s*\|\s*$TC/,$srcstr,2);
        $fname=&GENTEXT(1,$fname,$ord,$cname,$mname,$curglob,%curglobval);
        $tmpstr=&GENTEXT(1,$tmpstr,$ord,$cname,$mname,$curglob,%curglobval);
        if (!($fname=~/stdout/i)) {
          if ($arg[1] eq "append" ) {
            if ($fname=~/^\//) { open(GENFILE,">>$fname"); }
            else { open(GENFILE,">>$outdir${X}$fname"); }
            if (!$opt_q) { print "Appending to $outdir${X}$fname\n"; }
          }
          else {
            if ($fname=~/^\//) { open(GENFILE,">$fname"); }
            else { open(GENFILE,">$outdir${X}$fname"); }
            if (!$opt_q) { print "Generating $outdir${X}$fname\n"; }
          }
          print GENFILE $tmpstr;
          close(GENFILE);
        }
        else { print $tmpstr; }
        $srcstr=~s/(\W)/\\$1/g;
        $str=~s/$TO$args$TC$srcstr${TO}endgenfile[^$TC]*$TC//;
      }

#
#  Custom comments and globals
#
      elsif ($mname && eval("\$U_$arg[0]\{\$mloc,\$mnm\};")) {
        $cleaned=eval("\$U_$arg[0]\{\$mloc,\$mnm\};");
        if ($related_func{$mloc,$mnm} && $mergefunc) {
          $cleaned.="\n" . eval("\$U_$arg[0]\{\$related_func\{\$mloc,\$mnm\}\};");
        }
 	if ($arg[1] eq "wrap") {
 	  $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
 	}
        $cleaned=&FILTER($cleaned,"$tmpldir$X$arg[0]_m.flt");
        $cleaned=&FILTER($cleaned,"$tmpldir$X$arg[0].flt");
        $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
        %filterflags=();
        $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif ($mname && $related_func{$mloc,$mnm} && $mergefunc &&
             eval("\$U_$arg[0]\{\$related_func\{\$mloc,\$mnm\}\};") ) {
        $cleaned=eval("\$U_$arg[0]\{\$related_func\{\$mloc,\$mnm\}\};");
 	if ($arg[1] eq "wrap") {
 	  $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
 	}
        $cleaned=&FILTER($cleaned,"$tmpldir$X$arg[0]_m.flt");
        $cleaned=&FILTER($cleaned,"$tmpldir$X$arg[0].flt");
        $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
        %filterflags=();
        $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif (!$mname && eval("\$U_$arg[0]\{\$cname\};")) {
        $cleaned=eval("\$U_$arg[0]\{\$cname\};");
 	if ($arg[1] eq "wrap") {
 	  $cleaned=&WRAP($cleaned,$arg[2],$arg[3]);
 	}
        $cleaned=&FILTER($cleaned,"$tmpldir$X$arg[0]_c.flt");
        $cleaned=&FILTER($cleaned,"$tmpldir$X$arg[0].flt");
        $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
        %filterflags=();
        $cleaned=&CLEANTEXT($cleaned,$htmlcomm);
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      elsif (!$mname && $curglobval{$arg[0]}) {
        $cleaned=&FILTER($curglobval{$arg[0]},"$tmpldir$X$arg[0].flt");
        $cleaned=&FILTER($cleaned,"$tmpldir${X}comment.flt");
        %filterflags=();
        if ($arg[1] eq "@") { $cleaned=~s/(\s|$X)/\_/g; }
        $str=~s/$TO([^$TO$TC]*)$TC/$cleaned/;
      }
      else { $str=~s/$TO([^$TO$TC]*)$TC//; }
    }

  if (!$inner)  {
    $str=~s/$TC_sub/$TCs/g;
    $str=~s/$TO_sub/$TOs/g;
    $str=REPLACE_SPECIAL($str);
  }
  
    
  if ($ml) { $*=0; }  
  $str;
    
}


sub PROCINPUT  {

  local($modtime)=@_;
  local($block,$macdata,$temp,$temp2,%temp);
  
  if ($modtime>$lastbuild) { $anynewer=1; }

  $buffer=&FILTER($buffer,"$tmpldir${X}input.flt");

  $*=1;
  
  $buffer=&MASKSPECIAL($buffer);
  
  
  $*=0;
  %precomm=();
  $macdata="";

#
#  Process File
#  

  $inblock=0;
  foreach (split("\n",$buffer)) {
  
    $_.="\n";
#
#  Extract statement blocks
#
    if (!$inblock) {
      if (/\S+/) {
  	if (/^\s*\/\/$sdesc_marker\s*(.*)$/) {
  	  $precomm{sdesc}.=&REPLACE_SPECIAL($1);
	}
        elsif (s/^\s*\/\/$user_marker\s*([\w\d]+)\s*$user_delim(.*)$//) {
 	  $globals=&REPLACE_SPECIAL($2);
  	  if ($precomm{sdesc} || $unsafecomm) { $precomm{"U_".$1}.="$globals\n"; }
  	}
 	elsif (/^\s*\/\/$global_marker(.*)/) {
 	  $globals=&REPLACE_SPECIAL($1);
 	  while ($globals=~s/[^\w\d]([\w\d]+)\s*$global_equals\s*([^"'\s]+)//) { $global{$1}=$2; }
 	  while ($globals=~s/[^\w\d]([\w\d]+)\s*$global_equals\s*(\"|\')([^\2]+)\2//) { $global{$1}=$3; }
 	}
        elsif (/^\s*\/\/(.*)$/) {
  	  if ($precomm{sdesc} || $unsafecomm) { $precomm{desc}.=&REPLACE_SPECIAL($1)."\n"; }
  	}
  	elsif (/^\s*\#/ || $macdata) {
  	  if (/^\s*\#define\s+/ || $macdata) {
 	    if (s/\\$//) {
 	      $macdata.=$_;
 	    }
 	    else {
 	      $macdata.=$_;
 	      if (%precomm || $doall) {
 	    	&PROCMACRO($macdata);
 	    	%precomm=();
 	      }
 	      $macdata="";
 	    }
 	  }
  	}
        else {
 	  $inblock=1;
 	  $isdef=0;$bcount=0;
 	  $block.=$_;
 	  if (/\{/) {
 	    $isdef=1;
 	  }
 	  $bcount+=&COUNT("{",$_);
 	  $bcount-=&COUNT("}",$_);
          if ($bcount<1 && ((/;/) || $isdef)) {
  	    $inblock=0;
  	    $process=1;
          }
  	}
      }
    }
    else { 	  
      $block.=$_;
      if (/\{/) {
  	$isdef=1;
      }
      $bcount+=&COUNT("{",$_);
      $bcount-=&COUNT("}",$_);
      if ($bcount<1 && ((/;/) || $isdef)) {
  	$inblock=0;
  	$process=1;
      }
    }
#
#  Examine extracted statement blocks: Determine type and process appropriately
#    
    if ($process) {
        
      $*=1;
            
      if ($isdef && ($block=~/^\s*template\s*(\<.+\>)\s+(class|struct|union)\s+(\w+)/) && (%precomm || !$docselect)) {&PROCCLASS($block);}
      elsif ($isdef && ($block=~/^\s*(class|struct|union)\s+(\w+)/) && (%precomm || !$docselect)) {&PROCCLASS($block);}
      elsif ($isdef && ($block=~/^\s*(struct|union)\s*\{/) && (%precomm || !$docselect)) {&PROCCLASS($block);}
      elsif (%precomm || $docall) {
        if ($block=~/^\s*typedef\s+/) {&PROCDEF($block);}
        elsif ($isdef && ($block=~/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(\S+|operator\s*\S+)\s*\(([^\{\)]*)\)\s*(const|)/)) {&PROCFUNC($block);}
        elsif ($isdef && ($block=~/^\s*(\S+|operator\s*\S+)\s*\(([^\{\)]*)\)\s*(const|)/)) {&PROCFUNC($block);}
        elsif ($isdef && ($block=~/^\s*enum\W+/)) {&PROCENUM($block);}
        elsif ($block=~/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(\w[\w\s:\[\]]*)\s*\=*\s*\S*([,;])/) {&PROCVAR($block);}
      }
      $*=0;
      $process=0;
      $bcount=0;
      $block="";
      %precomm=();
      
    }
  }
}



# Mask special characters in arglists & quoted strings
sub MASKSPECIAL {

  local($str)=@_;
  local($tmp1,$tmp2);

  # Handle escaped quotes
  $str=~s/\\\"/&&QUOTD/g;
  $str=~s/\\\'/&&QUOTS/g;

  while ( $str=~/(\'|\"|\/\*|\/\/)/ ) {
    $tmp1=$1;
    if ($tmp1=~/\/\//) {
      $str=~/\/\/([^\n]*\n)/;
      $tmp1=$&;
      $tmp2="&&X$1";
      $tmp2=~s/\/\*[^\n]*\*\///g;
    }
    elsif ($tmp1=~/\/\*/) {
      $tmp2=&GETBLOCK($str,"/*","*/","","",1);
      $tmp1="/*$tmp2*/";
      if ($useccomm) {
        $tmp2=~s/\s*\n\s*\**/&&NEWLINE/g;
        $tmp2="&&X$tmp2";
      }
      else { 
        $tmp2="";
      }
    }
    elsif ($tmp1=~/\"/) {
      $str=~/\"([^\"]*)\"/;
      $tmp1=$&;
      $tmp2="&&QUOTD${1}&&QUOTD";
    }
    else {
      $str=~/\'([^\']*)\'/;
      $tmp1=$&;
      $tmp2="&&QUOTS${1}&&QUOTS";
    }
    $tmp2=~s/\"/&&QUOTD/g;
    $tmp2=~s/\'/&&QUOTS/g;
    $tmp2=~s/\(/&&BRAKO/g;
    $tmp2=~s/\)/&&BRAKC/g;
    $tmp2=~s/\;/&&SEMI/g;
    $tmp2=~s/\{/&&BRACEO/g;
    $tmp2=~s/\}/&&BRACEC/g;
    $tmp2=~s/\,/&&COMM/g;
    $tmp2=~s/\/\*/&&CCOMMO/g;
    $tmp2=~s/\*\//&&CCOMMC/g;
    $tmp2=~s/\/\//&&CPCOMM/g;
    $tmp1=~s/(\W)/\\$1/g;
    $str=~s/$tmp1/$tmp2/;
  }
  while ( $str=~/\(/ ) {
    $tmp1=$1;
    $tmp2=&GETBLOCK($str,"\(","\)");
    $tmp1="($tmp2)";
    $tmp2="&&TBO${tmp2}&&TBC";
    $tmp2=~s/\"/&&QUOTD/g;
    $tmp2=~s/\'/&&QUOTS/g;
    $tmp2=~s/\(/&&BRAKO/g;
    $tmp2=~s/\)/&&BRAKC/g;
    $tmp2=~s/\;/&&SEMI/g;
    $tmp2=~s/\{/&&BRACEO/g;
    $tmp2=~s/\}/&&BRACEC/g;
    $tmp2=~s/\,/&&COMM/g;
    $tmp2=~s/\/\*/&&CCOMMO/g;
    $tmp2=~s/\*\//&&CCOMMC/g;
    $tmp2=~s/\/\//&&CPCOMM/g;
    $tmp1=~s/(\W)/\\$1/g;
    $str=~s/$tmp1/$tmp2/;
  }
  
  
  $str=~s/&&TBO/\(/g;
  $str=~s/&&TBC/\)/g;
  $str=~s/&&X/\/\//g;
  
  return $str;
}


sub REPLACE_SPECIAL {

  local($str)=@_;
  
   if ($str=~/&&/) {
     $str=~s/&&SEMI/;/g;
     $str=~s/&&BRACEO/$TO_sub/g;
     $str=~s/&&BRACEC/$TC_sub/g;
     $str=~s/&&COMM/,/g;
     $str=~s/&&BRAKO/(/g;
     $str=~s/&&BRAKC/)/g;
     $str=~s/&&QUOTD/\"/g;
     $str=~s/&&QUOTS/\'/g;
     $str=~s/&&CCOMMO/\/*/g;
     $str=~s/&&CCOMMC/*\//g;
     $str=~s/&&CPCOMM/\/\//g;
     $str=~s/&&NEWLINE/\n/g;
   }
   
   return $str;
}


sub GENAPPLT {

  local($cname,$arguments) = @_;
  local($str,@p,@c,$ah,$aw,$ctr,$fclass);
  local (%param,$parm,$arg,$opt);
  local (%ret);
  
  @p=split($;,$pclasses{$class});
  @c=split($;,$children{$class});
  
  foreach (@p) { s/(\w+).*/$1/; }
  foreach (@c) { s/(\w+).*/$1/; }

  $ah="100%";
  $aw="100%"; 
  
  foreach $arg (split(" ",$arguments)) {
    $arg=~/(\S+)\s*=\s*(\S+)/;
    if ($1 eq "height") { $ah=$2; }
    elsif ($1 eq "width") { $aw=$2; }
    else { $opt.="<param name=$1 value=\"$2\">\n"; }
  }
  
  if ($infourl ne "") {
    $opt.="<param name=infourl value=\"$infourl\">\n"; 
  }
  
  $str="<APPLET CODE=\"ClassGraph.class\" WIDTH=$aw HEIGHT=$ah>\n";
  $str.="<param name=classname value=\"$cname\">\n";
  
  foreach $fclass (@p) {
    $param{parents}.="$fclass,";
    if (&ISCLASS($fclass)) { 
      $param{parents}.="$fclass.html,";
      $str.="<param name=$fclass value=\"$sdesc{$fclass}\">\n"
    }
    else { 
      $param{parents}.="none,";
      $str.="<param name=$fclass value=\"Undocumented Class\">\n"
    }
  }
  
  
  foreach $fclass (@c) {
    $param{children}.="$fclass,";
    if (&ISCLASS($fclass)) { 
      $param{children}.="$fclass.html,";
      $str.="<param name=$fclass value=\"$sdesc{$fclass}\">\n"
    }
    else { 
      $param{children}.="none,";
      $str.="<param name=$fclass value=\"Undocumented Class\">\n"
    }
  }
    
  foreach $parm (keys(%param)) {
    chop($param{$parm});
    $str.="<param name=$parm value=\"$param{$parm}\">\n";
  }
    
  $str.=$opt;
  
  $str.="</APPLET>\n";
  
  $ret{str}=$str;
  $ret{height}=$ah;
  $ret{width}=$aw;
  
  %ret;
  
}
   

sub COUNT {
  
  local($target,$str)=@_;
  local($pos)=$[;
  local($count)=0;
  
  while (($pos = index($str,$target,$pos)) >= $[ ) {
    $count++;
    $pos++;
  }
  
  $count;
}
  

sub CLEANTEXT {
  
  local($str,$keephtml)=@_;
  local($c);
  study($str);

  &REPLACE_SPECIAL($str);
    
  if (($tmptype eq ".html") || ($tmptype eq ".htm")) {
    
    if (!$keephtml) {
      if ($USE_ASCII_CODES) {
        $str=~s/\&/\&#38\;/g;
        $str=~s/\>/\&#62\;/g;
        $str=~s/\</\&#60\;/g;
      }
      else {
        $str=~s/\&/\&amp\;/g;
        $str=~s/\>/\&gt\;/g;
        $str=~s/\</\&lt\;/g;
      }
    }
    
    if ($autolink) {
      foreach $c (@classes) {
        if ($keephtml) { $str=~s/(<[^<>]*)$c([^<>]*>)/$1PUTCNAMEHERE__$2/g; }
        $str=~s/(\W|&\w+)$c(\W)/$1<A HREF=\"$c.html\" $alopt>$c<\/A>$2/g;
        $str=~s/^$c(\W)/<A HREF=\"$c.html\" $alopt>$c<\/A>$1/g;
        $str=~s/^$c$/<A HREF=\"$c.html\" $alopt>$c<\/A>/g;
        $str=~s/(\W|&\w+)$c$/$1<A HREF=\"$c.html\" $alopt>$c<\/A>/g;
        if ($keephtml) { $str=~s/PUTCNAMEHERE__/$c/g; }
      }
    }
  }
  else {
    if ($keephtml) { $str=~s/<[^<>]*>//g; }
  }

  if (!$keeptags) {
    $str=~s/$TC/$TC_sub/g;
    $str=~s/$TO/$TO_sub/g;
  }
  
  $keeptags=0;
  
  $str;
}


sub ISCLASS {

  local($str)=@_;
  
  foreach $c (@classes) {
    if ($str eq $c) { return 1; }
  }
  
  return 0;
  
}


sub GETNEXTDEF {
  
  local($str,$pattern) = @_;
  
  $str=&GETBLOCK($str,$pattern,"\}","\{","\{");
  
}



sub GETBLOCK {

  local($str,$pat1,$pat2,$closer,$altpat,$nonest) = @_;
  local($sub,$start,$end,$newend,$cnt1,$cnt2);
  
  $pat1=~s/\\(\W)/$1/g;
  $pat2=~s/\\(\W)/$1/g;
  $closer=~s/\\(\W)/$1/g;
  $altpat=~s/\\(\W)/$1/g;
  
  $start=index($str,$pat1)+length($pat1);
  if ($start==$[-1) {
    return "";
  }
  if ($closer) {
    $start=index($str,$closer,$start);
    if ($start==$[-1) {
      return "";
    }
    $start++;
  }
  
    
  $cnt1=1;
  $cnt2=0;
  $end=$start;
  
  if ($altpat) { $pat1=$altpat; }
  
  while ($cnt1>$cnt2) {
    if ($end>$start) { $newend=index($str,$pat2,$end+1); }
    else { $newend=index($str,$pat2,$end); }
    if ($newend==$[-1) {
      $end=length($str);
      last;
    }
    $cnt2++;
    $sub=substr($str,$end,$newend-$end);
    if (!$nonest) { $cnt1+=&COUNT($pat1,$sub); }
    $end=$newend;
  }
  
  substr($str,$start,$end-$start);
}


sub FILTER {
  
  local($str,$file) =@_;
  local($ml,$buffer);
  
  if ($*) { $ml=1; }
  else { $ml=0; }
  
   
  if ( -e $file ) {
    open(FILT,"<$file");
    while (<FILT>) { $buffer.=$_; }
    close(FILT);
    eval($buffer);
    $str=&filter($str);
  }
  
  if ($ml) { $*=1; }
  else { $*=0; }
  
  $str;
}


sub INARRAY {
  
  local($str,@array)=@_;
  local($element);
  
  foreach $element (@array) {
    if ($str eq $element) { return 1; }
  }
  
  return 0;
}



sub PROCCLASS {

  local($block,$nest)=@_;
  local($classname,$membername,$varname,$subdef,$defptype,$ptype,$targ,%temp);
  local($echk1,$echk2,$echk3,$echk4,$echkmod,$scnm,$scnmod,$temp,$temp1,$temp2);
  local($temp3,$temp4,$temp5,$locname,$mmem,$newmem,$sttype,@multidef);
  local($ptemp,$haspar,$tempvars,$tempcomm,$fid);
#
#  Extract Data From Class Definition Blocks
# 
          
  if ($block=~/^\s*template\s*(\<.+\>)\s+(class|struct|union)\s+(\w+)/) {
    $locname=$classname=$3;
    if ($nest) {
      $classname="${nest}\:\:$classname";
      $container{$classname}=$nest;
    }
    if ($duplicates{$classname}>0) {
      $duplicates{$classname}++;
      if (!$opt_q) { print "WARNING: Found duplicate version of class $classname\n"; }
      $classname.="__$duplicates{$classname}";
      if (!$opt_q) { print "	      Will reference duplicate class as $classname\n"; }
    }
    else { $duplicates{$classname}=1; }
    $template{$classname}="$1";
    if ($2 eq "class") { $itype{$classname}=$CLASS; }
    if ($2 eq "struct") { $itype{$classname}=$STRUCT; }
    if ($2 eq "union") { $itype{$classname}=$UNION; }
  }
  elsif ($block=~/^\s*(class|struct|union)\s+(\w+)/) {
    $locname=$classname=$2;
    if ($nest) {
      $classname="${nest}\:\:$classname";
      $container{$classname}=$nest;
    }
    if ($duplicates{$classname}>0) {
      $duplicates{$classname}++;
      if (!$opt_q) { print "WARNING: Found duplicate version of class $classname\n"; }
      $classname.="__$duplicates{$classname}";
      if (!$opt_q) {  print "	      Will reference duplicate class as $classname\n"; }
    }
    else { $duplicates{$classname}=1; }
    if ($1 eq "class") { $itype{$classname}=$CLASS; }
    if ($1 eq "struct") { $itype{$classname}=$STRUCT; }
    if ($1 eq "union") { $itype{$classname}=$UNION; }
    $sttype=$1;
    if ($block=~/\}(\s*|\s*\/\/.*)\s*([\w\s,\[\]]+)\s*;(\s*|\s*\/\/.*)$/) {
      if (!($block=~/$2\s*;[\s\S]*\}/)) {
        &PROCVAR("$sttype $classname $2\;\n$1\n$3",1,1);
        $block=~s/\}$1\s*$2\s*;$3$/\}/;
      }
    }
  }
  elsif ($block=~/^\s*(struct|union)\s*\{/) {
    $sttype=$1;
    if ($block=~/\}(\s*|\s*\/\/.*)\s*([\w\s,\[\]]+)\s*;(\s*|\s*\/\/.*)$/) {
      if (!($block=~/$2\s*;[\s\S]*\}/)) {
        $tempvars=$2;
        $tempcomm="$1\n$3";
        $block=~s/\}$1\s*$2\s*;$3$/\}/;
        $tempvars=~/^\s*(\w+)/;
        $classname="_$1"; 
        if ($nest) {
          $classname="${nest}\:\:$classname";
          $container{$classname}=$nest;
        }
        if ($duplicates{$classname}>0) {
          $duplicates{$classname}++;
          if (!$opt_q) {  print "WARNING: Found duplicate version of class $classname\n"; }
          $classname.="__$duplicates{$classname}";
          if (!$opt_q) { print "	      Will reference duplicate class as $classname\n"; }
        }
        else { $duplicates{$classname}=1; }
        if ($sttype eq "struct") { $itype{$classname}=$STRUCT; }
        if ($sttype eq "union") { $itype{$classname}=$UNION; }
        &PROCVAR("$sttype $classname $tempvars\;\n$tempcomm",0,1);
      }
    }
  }
     
  if ($modtime>$modtime{$classname}) { $modtime{$classname}=$modtime; }
    
  if (!$nest) {
    foreach $varname (keys(%precomm)) {
      eval "\$$varname\{\$classname\} = \$precomm\{$varname\}; ";
    }
  }
          
  if (!$nest) {
    $printable{$classname} = 1;
    push(@classes,$classname);

  }
  push(@allclasses,$classname);
  push(@items,$classname);

  foreach $varname (keys(%global)) {
    eval "\$U_$varname\{\$classname\} = \$global\{$varname\}; ";
    if (!&INARRAY($global{$varname},split($;,$globalvalues{$varname}))) {
      $globalvalues{$varname}.="$global{$varname}$;";
    }
  }
  
  # handle comments after inheritance list
  
  if ($block=~/(class|struct)\s+$locname\s*(\:)*\s*([^\{]*)\s*\{/) {
    $ptemp=$3;
    $haspar=$2;
    while ($ptemp=~/\/\/.*/) {
      # Match Short Description Comments
      if ($ptemp=~s/\/\/$sdesc_marker\s*(.*)$//) {
  	$sdesc{$classname}.=&REPLACE_SPECIAL($1);
      }
      # Match Custom Comments
      elsif ($ptemp=~s/\/\/$user_marker\s*([\w\d]+)\s*$user_delim(.*)$//) {
  	eval qq/\$U_$1\{$classname\}.=&REPLACE_SPECIAL(\$2)."\n";/;
      }
      # Match Description Comments
      elsif ($ptemp=~s/\/\/(.*)$//) {
  	$desc{$classname}.=&REPLACE_SPECIAL($1)."\n";
      }
    }
    if ($haspar) {
      $parents{$classname}=$ptemp;
      $parents{$classname}=~s/\n\s*/ /g;
      $parents{$classname}=~s/([^\n\S])[^\n\S]+/$1/g;
    }
  }

  # Parse parentage
  $modp=$parents{$classname};
  $modp=~s/<.*>//g;
  foreach (split(",",$modp)) {
    if (/^\s*(\w|\w[\w\s]*\w)\s+(\w+)\s*$/) {
      $pclasses{$classname}.="$2$;";
      $ihtype{$classname,$2}.="$1";
    }
    elsif (/(\w+)/) {
      $pclasses{$classname}.="$1$;";
      $ihtype{$classname,$1}.="private";
    }
  }
  

  # Strip Everything up to first brace
  $block=substr($block,index($block,"{")+1);
    
  # Remove comments from argument lists
  while ($block=~/\([^\)]*\/\/.*/) {
    $block=~s/\(([^\)]*)\/\/.*/\($1/;
  }

  # Remove line breaks from argument lists
  $block=~s/\(([^\)\n]*)\n\s*(\S)([^\)]*)\)/\($1 $2$3\)/g;

  # Remove Constructor-Initializer lists
  $block=~s/($locname\s*[^\{:\;]*)\s*:[^\{\}]*\{/$1\{/g;
  
  # Handle nested classes and unions
  while ($block=~/^(\s*)(class|struct|union)([^\<\(\:\{\;]*)([^\(\{\;]*)\{/) {
    $scnm="$1$2$3";
    $temp2="$1$2 ";
    $temp3=$3;
    $temp4=$4;
    $scnmod="$1$2$3$4";
    $subdef=&GETNEXTDEF($block,$scnmod);
    $temp= "$scnmod\{$subdef\}";
    $temp=~s/(\W)/\\$1/g;
    if (!($temp3=~/\S+/)) {
      $scnm=$temp2;
      if ($block=~/$temp\s*(\w+)\s*\;/) {
        $scnm.=$1;
      }
      else { $scnm.="NONAME"; }
    }
    $scnm=~s/^\s+//;
    $scnm=~s/\s+$//;
    &PROCCLASS("$scnm$temp4\{$subdef\}",$classname);
    $*=1;
    $block=~s/$temp[^\;]*\;/$scnm;/;
  }
  
  #keep enums from getting stripped & clean comments
  while ($block=~/^(\s*)enum([^\{\<\;]*)\{([^\}]*)\}\s*(\w*)/) {
    $echk1=$1; $echk4=$echk2=$2; $echk3=$3;
    if ($4) { $echk4=$4; }
    $echk3=~s/(\/\/.*)\n//g;
    $block=~s/${echk1}enum$echk2\{[^\}]*\}/${echk1}enum $echk4<$echk3>/;
  }

  # Clean up line breaks
  while ($block=~s/(\/\/.*):/$1&&COLON/) {}
  if ($beforecomm) {
    $block=~s/^(.*\S.*)(\/\/.*)\n/$2\n$1\n/g;
  }
  $block=~s/(\/\/.*)\n/$1$;/g;
  $block=~s/\n\s*/ /g;
  $block=~s/([^\n\S])[^\n\S]+/$1/g;
  $block=~s/([;\}\{])/$1\n/g;
  $block=~s/([^:]):([^:])/$1:\n$2/g;
  $block=~s/$;/\n/g;
  $block=~s/&&COLON/:/g;
  
  # Remove inline definitions
  while ($block=~/(\S\s*)\{[^\{\}]*\}/) {
    $hasinlines{$classname}=1;
    $block=~s/(\S\s*)\{[^\{\}]*\}/$1\n/g;
  }
      
  # Extract members
    
  $*=0;
  if ($itype{$classname}==$STRUCT || $itype{$classname}==$UNION) { 
    $defptype="public";
  }
  else { $defptype="private"; }
  $membername="";
  
  @lines=split("\n",$block);
  $newmem=0;
  foreach (@lines) {
      $ptype=$defptype;
      if (/(^|\s+)(private|protected|public|friend)(\s*[\s:]+)/) {
        $ptype=$2;
        if ($3=~/:/) {
          $defptype=$ptype;
        }
      }
      # Match Short Description Comments
      if (s/\/\/$sdesc_marker\s*(.*)$//) {
        $temp{sdesc}.=&REPLACE_SPECIAL($1);
      }
      # Match Custom Comments
      elsif (s/\/\/$user_marker\s*([\w\d]+)\s*$user_delim(.*)$//) {
        $temp{"U_$1"}.="$2\n";
      }
      # Match Description Comments
      elsif (s/\/\/(.*)$//) {
        $temp{desc}.=&REPLACE_SPECIAL($1)."\n";
      }
      # Match Untyped Member Functions
      elsif (/^\s*(\S+|operator\s*\S\s*\S?)\s*\(([^\{\)]*)\)s*(const|)\s*(\=|throw\s*\w*\s*\([^\{\)]*\)\s*=?|)/) {
        $temp1=$1,$temp2=$2,$temp3=$3,$temp4=$4,$temp5=$5;
        $fid=&PROCARGS($temp2);
        $newmem=1;
        $membername="$temp1($fid)";
        $members{$classname,$ptype}.="$membername$;";
        $access{$classname,$membername}=$ptype;
        $memname{$classname,$membername}=$temp1;
        $args{$classname,$membername}=$temp2;
        $func{$classname,$membername}=1;
        $type{$classname,$membername}="";
        if ($temp3 eq "const") { 
          $isconst{$classname,$membername}=1;
        }
        if ($temp4 eq "\=") {
          $ispure{$classname,$membername}=1;
          $isabstract{$classname}=1;
        }
        elsif ($temp4=~/throw\s*(\w*)\s*\(([^\{\)]*)\)\s*(=?)/) {
          $throwsex{$classname,$membername}=1;
          $exclass{$classname,$membername}=$1;
          $exargs{$classname,$membername}=$2;
 	  if ($3 eq "\=") {
 	    $ispure{$classname,$membername}=1;
 	    $isabstract{$classname}=1;
 	  }
        }
      }
      # Match Typed Operator Functions
      elsif (/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(operator\s*\S\s*\S?)\s*\(([^\{\)]*)\)\s*(const|)\s*(\=|throw\s*\w*\s*\([^\{\)]*\)\s*=?|)/) {
        $temp1=$1,$temp2=$2,$temp3=$3,$temp4=$4,$temp5=$5;
        $fid=&PROCARGS($temp3);
        $newmem=1;
        $membername="$temp2($fid) $temp4";
        $members{$classname,$ptype}.="$membername$;";
        $access{$classname,$membername}=$ptype;
        $memname{$classname,$membername}=$temp2;
        $args{$classname,$membername}=$temp3;
        $func{$classname,$membername}=1;
        $type{$classname,$membername}=$temp1;
        if ($temp4 eq "const") { 
          $isconst{$classname,$membername}=1;
        }
        if ($temp5 eq "\=") {
          $ispure{$classname,$membername}=1;
          $isabstract{$classname}=1;
        }
        elsif ($temp5=~/throw\s*(\w*)\s*\(([^\{\)]*)\)\s*(=?)/) {
          $throwsex{$classname,$membername}=1;
          $exclass{$classname,$membername}=$1;
          $exargs{$classname,$membername}=$2;
 	  if ($3 eq "\=") {
 	    $ispure{$classname,$membername}=1;
 	    $isabstract{$classname}=1;
 	  }
        }
      }
      # Match Typed Member Functions
      elsif (/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(\S+)\s*\(([^\{\)]*)\)\s*(const|)\s*(\=|throw\s*\w*\s*\([^\{\)]*\)\s*=?|)/) {
        $temp1=$1,$temp2=$2,$temp3=$3,$temp4=$4,$temp5=$5;
        $fid=&PROCARGS($temp3);
        $newmem=1;
        $membername="$temp2($fid) $temp4";
        $members{$classname,$ptype}.="$membername$;";
        $access{$classname,$membername}=$ptype;
        $memname{$classname,$membername}=$temp2;
        $args{$classname,$membername}=$temp3;
        $func{$classname,$membername}=1;
        $type{$classname,$membername}=$temp1;
        if ($temp4 eq "const") { 
          $isconst{$classname,$membername}=1;
        }
        if ($temp5 eq "\=") {
          $ispure{$classname,$membername}=1;
          $isabstract{$classname}=1;
        }
        elsif ($temp5=~/throw\s*(\w*)\s*\(([^\{\)]*)\)\s*(=?)/) {
          $throwsex{$classname,$membername}=1;
          $exclass{$classname,$membername}=$1;
          $exargs{$classname,$membername}=$2;
 	  if ($3 eq "\=") {
 	    $ispure{$classname,$membername}=1;
 	    $isabstract{$classname}=1;
 	  }
        }
      }
      # Match Enumerations
      elsif (/^\s*enum\s+(\w*)\s*<([^>]+)>/) {
        $newmem=1;
        $enumcount++;
        if ($1) { 
          $membername="enum $1";
          $memname{$classname,$membername}=$membername;
        }
        else { 
          $membername="enum&$enumcount";
          $memname{$classname,$membername}="enum";
        }
        $members{$classname,$ptype}.="$membername$;";
        $access{$classname,$membername}=$ptype;
        $args{$classname,$membername}=$2;
        $enum{$classname,$membername}=1;
      }
      # Match Member Variables
      elsif (/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(\w[\w\s\[\]]*)\s*\=*\s*[^,;]*([,;])/) {
        $newmem=1;
        $membername=$2;
        $targ=$1;
        if ($3 eq ",") {
          @multidef=split(",",$_);
          for ($mmem=1;$mmem<=$#multidef;$mmem++) {
            if ($multidef[$mmem]=~/\s*([\*&]?)\s*(\w[\w\s\[\]]*)\s*\=*\s*\S*/ ) { 
              $membername.=", $1$2";
            }
          }
        }
        if ($targ=~/^\s*enum\s+(\w+)\s*$/) { 
          $args{$classname,"enum $1"}=$membername;
          $membername="enum $1";
          $enum{$classname,$membername}=1;
        }
        else { $type{$classname,$membername}=$targ; }
        $members{$classname,$ptype}.="$membername$;";
        $access{$classname,$membername}=$ptype;
        $memname{$classname,$membername}=$membername;
      }

      # Process Comments
      if ($beforecomm) {
        if ($newmem) {
          $newmem=0;
          foreach $varname (keys(%temp)) {
            eval "\$$varname\{\$classname,\$membername\} .= \$temp\{$varname\}; ";
          }
          %temp=();
        }
      }
      else {
 	foreach $varname (keys(%temp)) {
 	  if ($membername) {
 	    eval "\$$varname\{\$classname,\$membername\} .= \$temp\{$varname\}; ";
 	  }
 	  else {
 	    eval "\$$varname\{\$classname\} .= \$temp\{$varname\}; ";
 	  }
 	}
 	%temp=();
      }
        
  }

}

# Function to create consistent arglist-based identifiers based on type
# information only.

sub PROCARGS {

  local($arglist)=@_;
  local($element,$pelem,@elements);
  
  $arglist=~s/&&COMM/,/g;
  @elements=split(",",$arglist);
  $arglist="";
  foreach $element (@elements) {
    $element=~/^\s*(\w+[\s\&\*]*)/;
    $pelem=$1;
    while ($element=~s/\[[^\]]*\]//) { $pelem.='*'; }
    $arglist.=$pelem;
  }
  $arglist=~s/\s+//g;
    
  return $arglist;

}



sub PROCFUNC {

  local($block)=@_;
  local ($gfunc,$rclass,$nsname,$nonscoped);
    
  # Remove function body
  while ($block=~/(\S\s*)\{[^\{\}]*\}/) {
    $block=~s/(\S\s*)\{[^\{\}]*\}/$1\n/g;
  }
  
  $block=~s/\n/ /g;

  # Match Untyped Functions
  if ($block=~/^\s*(\S+|operator\s*\S\s*\S?)\s*\(([^\{\)]*)\)\s*(const|)\s*(throw\s*\w*\s*\([^\{\)]*\)|)/) {
    $temp1=$1,$temp2=$2,$temp3=$3,$temp4=$4,$temp5=$5;
    $fid=&PROCARGS($temp2);
    $gfunc="$temp1($fid)";
    $funcname{$gfunc}=$temp1;
    $args{$gfunc}=$temp2;
    $type{$gfunc}="";
    if ($temp3 eq "const") {
      $isconst{$gfunc}=1;
    }
    if ($temp4=~/throw\s*(\w*)\s*\(([^\{\)]*)\)/) {
      $throwsex{$gfunc}=1;
      $exclass{$gfunc}=$1;
      $exargs{$gfunc}=$2;
    }
  }
  # Match Typed Operator Functions
  elsif ($block=~/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(operator\s*\S\s*\S?)\s*\(([^\{\)]*)\)\s*(const|)\s*(throw\s*\w*\s*\([^\{\)]*\)|)/) {
    $temp1=$1,$temp2=$2,$temp3=$3,$temp4=$4,$temp5=$5;
    $fid=&PROCARGS($temp3);
    $gfunc="$temp2($fid) $temp4";
    $funcname{$gfunc}=$temp2;
    $args{$gfunc}=$temp3;
    $type{$gfunc}=$temp1;
    if ($temp4 eq "const") {
      $isconst{$gfunc}=1;
    }
    if ($temp5=~/throw\s*(\w*)\s*\(([^\{\)]*)\)/) {
      $throwsex{$gfunc}=1;
      $exclass{$gfunc}=$1;
      $exargs{$gfunc}=$2;
    }
  }
  # Match Typed Functions
  elsif ($block=~/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(\S+)\s*\(([^\{\)]*)\)\s*(const|)\s*(throw\s*\w*\s*\([^\{\)]*\)|)/) {
    $temp1=$1,$temp2=$2,$temp3=$3,$temp4=$4,$temp5=$5;
    $fid=&PROCARGS($temp3);
    $gfunc="$temp2($fid) $temp4";
    $funcname{$gfunc}=$temp2;
    $args{$gfunc}=$temp3;
    $type{$gfunc}=$temp1;
    if ($temp4 eq "const") {
      $isconst{$gfunc}=1;
    }
    if ($temp5=~/throw\s*(\w*)\s*\(([^\{\)]*)\)/) {
      $throwsex{$gfunc}=1;
      $exclass{$gfunc}=$1;
      $exargs{$gfunc}=$2;
    }
  }
    # Clean up line breaks
    $args{$gfunc}=~s/(\/\/.*)\n//g;
    $args{$gfunc}=~s/\n\s*/ /g;
    $args{$gfunc}=~s/([^\n\S])[^\n\S]+/$1/g;
  
  $modtime{$gfunc}=$modtime;
  
  $itype{$gfunc}=$FUNC;
  
  # If member function set relation flags for documentation merging.
  if ($funcname{$gfunc}=~/(.+)::(.+)/) {
    $rclass=$1;
    $nsname=$2;
    $nonscoped=$gfunc;
    $nonscoped=~s/$funcname{$gfunc}/$nsname/;
    $related_func{$rclass,$nonscoped}=$gfunc;
    if ($modtime>$modtime{$rclass}) { $modtime{$rclass}=$modtime; }
    if (!$mergefunc) {
      push(@gfuncs,$gfunc);
      push(@items,$gfunc);
    }
  }
  else {
    push(@gfuncs,$gfunc);
    push(@items,$gfunc);
  }
  
  
  &DOINFO($block,$gfunc);

}



sub PROCVAR {

  local($block,$npc,$useall)=@_;
  local($gname,$mmem,@multidef);

  $block=~s/\n/ /g;
   
  if ($block=~/^\s*([\w<>:\,\s\*&]*[\w<>:\*&]\s[\s\*&]*)(\w[\w\s\[\]\:]*)\s*(\=*\s*[^,;]*)([,;])/) {
      $gname=$2;
      $args{$gname}=$3;
      if ($4 eq ",") {
        @multidef=split(",",$_);
        for ($mmem=1;$mmem<=$#multidef;$mmem++) {
          if ($multidef[$mmem]=~/\s*([\*&]?)\s*(\w[\w\s\[\]\:]+)\s*(\=*\s*[^;]*)/ ) {
            $gname.=", $1$2";      
            $args{$gname}=$3;
          }
        }
      }
      $type{$gname}=$1;
    
      $modtime{$gname}=$modtime;
  
      $itype{$gname}=$GLOBAL;
              
      push(@gvars,$gname);
      push(@items,$gname);
      
      &DOINFO($block,$gname,$npc);

  }
}


sub PROCENUM {
  
  local($block)=@_;
  local($ename,$eargs);

  $block=~s/\n/ /g;
  
  if ($block=~/^\s*enum(\s+\w*|\s*)\{([^\}]+)\}\s*(\w*)/) {
    $enumcount++;
    $eargs=$2;
    if ($1=~/\s+(\w*)/) {
      $ename="enum $1";
      $renname{$ename}=$ename;
    }
    elsif ($3) {
      $ename="enum $3";
      $renname{$ename}=$ename;
    }
    else {
      $ename="enum&$enumcount";
      $renname{$ename}="enum";
    }
    $args{$ename}=$eargs;
    

    # Clean up line breaks
    $args{$ename}=~s/(\/\/.*)\n//g;
    $args{$ename}=~s/\n\s*/ /g;
    $args{$ename}=~s/([^\n\S])[^\n\S]+/$1/g;

    $modtime{$ename}=$modtime;
  
    $itype{$ename}=$ENUM;
  
    push(@gvars,$ename);
    push(@items,$ename);
    
    &DOINFO($block,$ename);

  }
}  


sub PROCDEF {
  
  local($block)=@_;
  local ($tname);

  
  # Handle struct and union typedefs like class declarations
  if ($block=~/^\s*typedef\s+(struct|union)\s*\w*\s*(\{[\S\s]*\})\s*(\w+)\s*;(\s*|\s*\/\/.*)$/) {
    &PROCCLASS("$1 $3 $2");
  }
  elsif ($block=~/^\s*typedef\s+([^;]+)\s+(\w+)\s*;/) {
      $tname=$2;
      $type{$tname}=$1;
    
      $modtime{$tname}=$modtime;
  
      $itype{$tname}=$TYPEDEF;
    
      push(@tdefs,$tname);
      push(@items,$tname);
      
      &DOINFO($block,$tname);

  }
}


sub PROCMACRO {
  
  local($block)=@_;
  local ($mname,$mlflag);
  
  if (!$*) { $*=1; $mlflag=1; }
  if ($block=~/^\s*#define\s+([^\(\s]+|\S+\s*\([^\)]*\))\s+(\S[\s\S]*)/) {
    $mname=$1;
    $args{$mname}=$2;
    $modtime{$mname}=$modtime;
  
    $itype{$mname}=$MACRO;
  
  
    push(@macros,$mname);
    push(@items,$mname);

    &DOINFO($block,$mname);
  }
  if ($mlflag) { $*=0; }  
}



sub DOINFO {

  local($block,$itemname,$noprecomm)=@_;
  local($varname,@lines);
  
  if (!$noprecomm) {
    foreach $varname (keys(%precomm)) {
      eval "\$$varname\{\$itemname\} = \$precomm\{$varname\}; ";
    }
  }

  foreach $varname (keys(%global)) {
    eval "\$U_$varname\{\$itemname\} = \$global\{$varname\}; ";
    if (!&INARRAY($global{$varname},split($;,$globalvalues{$varname}))) {
      $globalvalues{$varname}.="$global{$varname}$;";
    }
  }

  @lines=split("\n",$block);
  foreach (@lines) {
      # Match Short Description Comments
      if (s/\/\/$sdesc_marker\s*(.*)$//) {
  	$sdesc{$itemname}.=&REPLACE_SPECIAL($1);
      }
      # Match Custom Comments
      if (s/\/\/$user_marker\s*([\w\d]+)\s*$user_delim(.*)$//) {
  	eval qq/\$U_$1\{$itemname\}.=&REPLACE_SPECIAL(\$2)."\n";/;
      }
      # Match Description Comments
      if (s/\/\/(.*)$//) {
  	$desc{$itemname}.=&REPLACE_SPECIAL($1)."\n";
      }
  }
}


sub GET_FILE_LIST {

  local($dir,$recursive,@suffixes)=@_;
  local($file,$suffix,$csf,@infiles,$pgval);
  local(@dirlist);
  
  if ( -f "$dir${X}.perceps_conf" ) {
    open(DCONF,"<$dir${X}.perceps_conf");
    while (<DCONF>) {
      if (/^\s*suffixes\s+(\S+)/i) {
        @suffixes=split(",",$1);
      }
      if (/^\s*\-recursive\s*$/i) {
        $recursive=0;
      }
      if (/^\s*\+recursive\s*$/i) {
        $recursive=1;
      }
      if (/^\s*global\s+([\w\d]+)\s*=\s*([^"'\s]+)/i) {
        $dirglob{"$dir$;$1"}=$2;
        $dglobkeys{$dir}.="$1$;";
      }
      if (/^\s*global\s+([\w\d]+)\s*=\s*["']([^"']+)["']/i) {
        $dirglob{"$dir$;$1"}=$2;
        $dglobkeys{$dir}.="$1$;";
     }
    }
  }
  
  if (grep(/^\*$/,@suffixes)) { @suffixes=(); }
  
  opendir(DIR,$dir);
  @dirlist=readdir(DIR);
  closedir(DIR);
  
  foreach $file (@dirlist) {
    if ( !(($file eq ".") || ($file eq ".."))) {
    $file="$dir$X$file";
    if ( -f $file) { 
      if (@suffixes) {
        foreach $csf (@suffixes) {
          $suffix=$csf;
          $suffix=~s/\./\\\./g;
          $suffix=~s/\*/\.\*/g;
          $suffix=~s/\?/\./g;
          if ($file=~/$suffix$/) {
            push(@infiles,$file);
            last;
          }
        }
      }
      else {
        push(@infiles,$file);
      }
    }
    elsif ( (-d $file) && $recursive ) {
      $dglobkeys{$file}=$dglobkeys{$dir};
      foreach $pgval (split($;,$dglobkeys{$dir})) {
        $dirglob{"$file$;$pgval"}=$dirglob{"$dir$;$pgval"};
      }
      push(@infiles,&GET_FILE_LIST($file,1,@suffixes));
    } 
   }
 
  }
  
   @infiles;
}
 

sub MASK {
  local($str,$open,$close,$maskchar,$maskrep)=@_;
  
  while ($str=~/$open[^$close]*$maskchar[^$close]*$close/) {
    $str=~s/($open[^$close]*)$maskchar([^$close]*$close)/$1$maskrep$2/;
  }
  
  $str;
}



sub SAFECHAR {

  local($str)=@_;
  
  $str=~s/$TO/$TO_sub/g;
  $str=~s/$TC/$TC_sub/g;
  
  return $str;
}

sub GETPARENTS {

  local($cname,$recursive)=@_;
  local($p,@group);
  
  @group=split($;,$pclasses{$cname});
  
  if ($recursive) {
    foreach $p (@group) {
      push(@group,&GETPARENTS($p,1));
    }
  }

  return @group;
}


sub GETCHILDREN {

  local($cname,$recursive)=@_;
  local($c,@group);
  
  @group=split($;,$children{$cname});
  
  if ($recursive) {
    foreach $c (@group) {
      push(@group,&GETCHILDREN($c,1));
    }
  }

  return @group;
}

  

sub GETMEMBERS {

  local($cname,$mtype,$recursive)=@_;
  local($i,$nam,$parent,@group,@newgroup);
  
  if ($mtype eq "public") { push(@newgroup,split($;,$members{$cname,public})) }
  if ($mtype eq "private") { push(@newgroup,split($;,$members{$cname,private})) }
  if ($mtype eq "protected") { push(@newgroup,split($;,$members{$cname,protected})) }
  if ($mtype eq "friend") { push(@newgroup,split($;,$members{$cname,friend})); }
  if ($mtype eq "member") {
      push(@newgroup,split($;,$members{$cname,public}));
      push(@newgroup,split($;,$members{$cname,protected}));
      push(@newgroup,split($;,$members{$cname,private}));
  }
  
  for($i=0;$i<=$#newgroup;$i++) {
    $nam=$memname{$cname,$newgroup[$i]};
    if ($recursive<2 || (($nam ne $cname) && ($nam ne "~$cname"))) {
      push(@group,"$cname$;$newgroup[$i]");
    }
  }
  
  if ($recursive && $parents{$cname}) {
    $recursive++;
    foreach $parent (split($;,$pclasses{$cname})) {
      if ($mtype eq "member") {
        push(@group,&GETMEMBERS($parent,"public",$recursive));
        push(@group,&GETMEMBERS($parent,"protected",$recursive));
      }
      elsif ($ihtype{$cname,$parent}=~/public/) {
        if ($mtype eq "public") { push(@group,&GETMEMBERS($parent,"public",$recursive)); }
        if ($mtype eq "protected") { push(@group,&GETMEMBERS($parent,"protected",$recursive)); }
        if ($mtype eq "friend") { push(@group,&GETMEMBERS($parent,"friend",$recursive)); }
      }
      elsif ($ihtype{$cname,$parent}=~/protected/) {
        if ($mtype eq "protected") { 
          push(@group,&GETMEMBERS($parent,"public",$recursive));
          push(@group,&GETMEMBERS($parent,"protected",$recursive)); 
        }
        if ($mtype eq "friend") { push(@group,&GETMEMBERS($parent,"friend",$recursive)); }
      }
      else {
        if ($mtype eq "private") { 
          push(@group,&GETMEMBERS($parent,"public",$recursive));
          push(@group,&GETMEMBERS($parent,"protected",$recursive)); 
        }
        if ($mtype eq "friend") { push(@group,&GETMEMBERS($parent,"friend",$recursive)); }
      }
    }
  }
  
  return @group;
}


sub WRAP {

  local($str,$wraplength,$rcode)=@_;
  local($pos,$length);
  
  $str=~s/\n/ /g;
  $str=~s/\t/\t /g;
  
  $length=length($str);
  
  while ($length-$pos>$wraplength) {
    $pos=rindex($str," ",$pos+$wraplength);
    substr($str,$pos,1) = $;;
  }
  
  $str=~s/\t /\t/g; 
  $str=~s/$;/$rcode\n/g;
  
  return $str;
  
}


sub PRINT_USAGE {
  
  print "                           PERCEPS v3.5.0 BETA\n";
  print "          A C++ Documentation generator Written in Perl\n";
  print "               Copyright (C) 1997-1998 Mark Peskin\n\n";
  print "usage: perceps [-abefrmnhcuq] [-s list] [-d odir] [-t tdir | -o tdir] [-i idir] [(files|directories)...]\n\n";
  print " -a :          Autolink generated text\n";
  print " -b :          Comments in classes come before associated member\n";
  print " -e :          Document ALL non-class items\n";
  print " -f :          Search subdirectories recursively for input\n";
  print " -r :          Force re-generation of all output files\n";
  print " -h :          Treat comments as html\n";
  print " -m :          Merge member function documentation\n";
  print " -n :          Document only pre-commented classes\n";
  print " -c :          Include c-style comments in documentation\n";
  print " -u :          Include ALL comments before definition (see docs)\n";
  print " -q :          Quiet mode: supress diagnostic output\n";
  print " -s list :     A comma delimited list of file suffixes to match when\n";
  print "                      searching subdirectories.\n";
  print " -d odir :     Produce output files in outdir\n";
  print " -t tdir :     Search for template files in tdir\n";
  print " -o tdir :     Search for template files in $PERCEPS/tdir\n";
  print " -i idir :     Path to specify for includes in documentation\n";
  print " (files|directories) : Files or directories to search for input\n\n";

}
