#!/bin/bash

#   Copyright 2001-2004 The Apache Software Foundation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ANT_HOME=.
export ANT_HOME

# Extract launch and ant arguments, (see details below).
ant_exec_args=
no_config=false
use_jikes_default=false
ant_exec_debug=false
show_help=false
for arg in "$@" ; do
  if [ "$arg" = "--noconfig" ] ; then
    no_config=true
  elif [ "$arg" = "--usejikes" ] ; then
    use_jikes_default=true
  elif [ "$arg" = "--execdebug" ] ; then
    ant_exec_debug=true
  elif [ my"$arg" = my"--h"  -o my"$arg" = my"--help"  ] ; then
    show_help=true
    ant_exec_args="$ant_exec_args -h"
  else
    if [  my"$arg" = my"-h"  -o  my"$arg" = my"-help" ] ; then
      show_help=true
    fi
    ant_exec_args="$ant_exec_args \"$arg\""
  fi
done

# Source/default ant configuration
if $no_config ; then
  rpm_mode=false
  usejikes=$use_jikes_default
else
  # load system-wide ant configuration
  if [ -f "/etc/ant.conf" ] ; then
    . /etc/ant.conf
  fi

  # load user ant configuration
  if [ -f "$HOME/.ant/ant.conf" ] ; then
    . $HOME/.ant/ant.conf
  fi
  if [ -f "$HOME/.antrc" ] ; then
    . "$HOME/.antrc"
  fi

  # provide default configuration values
  if [ -z "$rpm_mode" ] ; then
    rpm_mode=false
  fi
  if [ -z "$usejikes" ] ; then
    usejikes=$use_jikes_default
  fi
fi

# Setup Java environment in rpm mode
if $rpm_mode ; then
  if [ -f /usr/share/java-utils/java-functions ] ; then
    . /usr/share/java-utils/java-functions
    set_jvm
    set_javacmd
  fi
fi

# OS specific support.  $var _must_ be set to either true or false.
cygwin=false;
darwin=false;
case "`uname`" in
  CYGWIN*) cygwin=true ;;
  Darwin*) darwin=true
           if [ -z "$JAVA_HOME" ] ; then
             JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home
           fi
           ;;
esac

if [ -z "$ANT_HOME" -o ! -d "$ANT_HOME" ] ; then
  # try to find ANT
  if [ -d /opt/ant ] ; then
    ANT_HOME=/opt/ant
  fi

  if [ -d "${HOME}/opt/ant" ] ; then
    ANT_HOME="${HOME}/opt/ant"
  fi

  ## resolve links - $0 may be a link to ant's home
  PRG="$0"
  progname=`basename "$0"`

  # need this for relative symlinks
  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
    else
    PRG=`dirname "$PRG"`"/$link"
    fi
  done

  ANT_HOME=`dirname "$PRG"`/..

  # make it fully qualified
  ANT_HOME=`cd "$ANT_HOME" && pwd`
fi

# For Cygwin, ensure paths are in UNIX format before anything is touched
if $cygwin ; then
  [ -n "$ANT_HOME" ] &&
    ANT_HOME=`cygpath --unix "$ANT_HOME"`
  [ -n "$JAVA_HOME" ] &&
    JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
fi

# set ANT_LIB location
ANT_LIB="${ANT_HOME}/lib"

if [ -z "$JAVACMD" ] ; then
  if [ -n "$JAVA_HOME"  ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
      # IBM's JDK on AIX uses strange locations for the executables
      JAVACMD="$JAVA_HOME/jre/sh/java"
    else
      JAVACMD="$JAVA_HOME/bin/java"
    fi
  else
    JAVACMD=`which java 2> /dev/null `
    if [ -z "$JAVACMD" ] ; then
        JAVACMD=java
    fi
  fi
fi

if [ ! -x "$JAVACMD" ] ; then
  echo "Error: JAVA_HOME is not defined correctly."
  echo "  We cannot execute $JAVACMD"
  exit 1
fi

# Build local classpath using just the launcher in non-rpm mode or
# use the Jpackage helper in rpm mode with basic and default jars
# specified in the ant.conf configuration. Because the launcher is
# used, libraries linked in ANT_HOME will also be include, but this
# is discouraged as it is not java-version safe. A user should
# request optional jars and their dependencies via the OPT_JAR_LIST
# variable
if $rpm_mode && [ -f /usr/bin/build-classpath ] ; then
  LOCALCLASSPATH="$(/usr/bin/build-classpath ant ant-launcher jaxp_parser_impl xml-commons-apis)"
  # If the user requested to try to add some other jars to the classpath
  if [ -n "$OPT_JAR_LIST" ] ; then
    _OPTCLASSPATH="$(/usr/bin/build-classpath $OPT_JAR_LIST 2> /dev/null)"
    if [ -n "$_OPTCLASSPATH" ] ; then 
      LOCALCLASSPATH="$LOCALCLASSPATH:$_OPTCLASSPATH"
    fi
  fi

  # Explicitly add javac path to classpath, assume JAVA_HOME set
  # properly in rpm mode
  if [ -f "$JAVA_HOME/lib/tools.jar" ] ; then
    LOCALCLASSPATH="$LOCALCLASSPATH:$JAVA_HOME/lib/tools.jar"
  fi
  if [ -f "$JAVA_HOME/lib/classes.zip" ] ; then
    LOCALCLASSPATH="$LOCALCLASSPATH:$JAVA_HOME/lib/classes.zip"
  fi

  # if CLASSPATH_OVERRIDE env var is set, LOCALCLASSPATH will be
  # user CLASSPATH first and ant-found jars after.
  # In that case, the user CLASSPATH will override ant-found jars
  #
  # if CLASSPATH_OVERRIDE is not set, we'll have the normal behaviour
  # with ant-found jars first and user CLASSPATH after
  if [ -n "$CLASSPATH" ] ; then
    # merge local and specified classpath 
    if [ -z "$LOCALCLASSPATH" ] ; then 
      LOCALCLASSPATH="$CLASSPATH"
    elif [ -n "$CLASSPATH_OVERRIDE" ] ; then
      LOCALCLASSPATH="$CLASSPATH:$LOCALCLASSPATH"
    else
      LOCALCLASSPATH="$LOCALCLASSPATH:$CLASSPATH"
    fi

    # remove class path from launcher -lib option
    CLASSPATH=""
  fi
else
  # not using rpm_mode; use launcher to determine classpaths
  if [ -z "$LOCALCLASSPATH" ] ; then
      LOCALCLASSPATH=$ANT_LIB/ant-launcher.jar
  else
      LOCALCLASSPATH=$ANT_LIB/ant-launcher.jar:$LOCALCLASSPATH
  fi
fi

if [ -n "$JAVA_HOME" ] ; then
  # OSX hack to make Ant work with jikes
  if $darwin ; then
    OSXHACK="${JAVA_HOME}/../Classes"
    if [ -d "${OSXHACK}" ] ; then
      for i in "${OSXHACK}"/*.jar
      do
        JIKESPATH="$JIKESPATH:$i"
      done
    fi
  fi
fi

# Allow Jikes support (off by default)
if $usejikes; then
  ANT_OPTS="$ANT_OPTS -Dbuild.compiler=jikes"
fi

# For Cygwin, switch paths to appropriate format before running java
if $cygwin; then
  if [ "$OS" = "Windows_NT" ] && cygpath -m .>/dev/null 2>/dev/null ; then
    format=mixed
  else
    format=windows
  fi
  ANT_HOME=`cygpath --$format "$ANT_HOME"`
  ANT_LIB=`cygpath --$format "$ANT_LIB"`
  JAVA_HOME=`cygpath --$format "$JAVA_HOME"`
  LOCALCLASSPATH=`cygpath --path --$format "$LOCALCLASSPATH"`
  if [ -n "$CLASSPATH" ] ; then
    CLASSPATH=`cygpath --path --$format "$CLASSPATH"`
  fi
  CYGHOME=`cygpath --$format "$HOME"`
fi

# Show script help if requested
if $show_help ; then
  echo $0 '[script options] [options] [target [target2 [target3] ..]]'
  echo 'Script Options:'
  echo '  --help, --h            print this message and ant help'
  echo '  --noconfig             suppress sourcing of /etc/ant.conf,'
  echo '                         $HOME/.ant/ant.conf, and $HOME/.antrc'
  echo '                         configuration files'
  echo '  --usejikes             enable use of jikes by default, unless'
  echo '                         set explicitly in configuration files'
  echo '  --execdebug            print ant exec line generated by this'
  echo '                         launch script'
  echo '  '
fi
# add a second backslash to variables terminated by a backslash under cygwin
if $cygwin; then
  case "$ANT_HOME" in
    *\\ )
    ANT_HOME="$ANT_HOME\\"
    ;;
  esac
  case "$CYGHOME" in
    *\\ )
    CYGHOME="$CYGHOME\\"
    ;;
  esac
  case "$JIKESPATH" in
    *\\ )
    JIKESPATH="$JIKESPATH\\"
    ;;
  esac
  case "$LOCALCLASSPATH" in
    *\\ )
    LOCALCLASSPATH="$LOCALCLASSPATH\\"
    ;;
  esac
  case "$CLASSPATH" in
    *\\ )
    CLASSPATH="$CLASSPATH\\"
    ;;
  esac
fi
# Execute ant using eval/exec to preserve spaces in paths,
# java options, and ant args
ant_sys_opts=
if [ -n "$CYGHOME" ]; then
  if [ -n "$JIKESPATH" ]; then
    ant_sys_opts="-Djikes.class.path=\"$JIKESPATH\" -Dcygwin.user.home=\"$CYGHOME\""
  else
    ant_sys_opts="-Dcygwin.user.home=\"$CYGHOME\""
  fi
else
  if [ -n "$JIKESPATH" ]; then
    ant_sys_opts="-Djikes.class.path=\"$JIKESPATH\""
  fi
fi
ant_exec_command="exec \"$JAVACMD\" $ANT_OPTS -classpath \"$LOCALCLASSPATH\" -Dant.home=\"$ANT_HOME\" -Dant.library.dir=\"$ANT_LIB\" $ant_sys_opts org.apache.tools.ant.launch.Launcher $ANT_ARGS -lib \"$CLASSPATH\" $ant_exec_args"
if $ant_exec_debug ; then
    echo $ant_exec_command
fi
eval $ant_exec_command
