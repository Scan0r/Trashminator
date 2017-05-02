#!/bin/bash

##
# Trahsminator: Simple and useful bash script to main clean Gnu/Linux systems.
# 
# Author: Scanor
# Version: 0.1
# Lincense: GNU General Public License v3.0
###


f_usage()
{
  echo 'Command usage: [--debug] [-c] [-d "PATHDIR"] [-D "NAMEDIR"] [-e "EXT"] [-h] [-i] [-m]'
  echo '               [-o "ORIGINDIR"] [-q] [-r] [-R] [-s "SHREDCMD"] [-t] [-T] [-w "TAGS"] [-y]'
  echo
  echo 'Options:'
  echo ' -c             Removes content of every cache directory.'
  echo
  echo ' -d "PATHDIR"   Removes the directory given by the absolute path'
  echo
  echo ' -D "NAMEDIR"   Removes every directory matched with the given name'
  echo
  echo ' -e "EXTENSION" Removes files with the name extension given.'
  echo
  echo ' -h             Displays this help.'
  echo
  echo ' -i             Enables interactive mode.'
  echo
  echo ' -I             Disables interactive mode.'
  echo
  echo ' -m             Skips media devices.'
  echo
  echo ' -o "ORIGINDIR" Starts from the given directory'
  echo
  echo ' -q             Enables quiet mode. Any output is discarted.'
  echo
  echo ' -r             Starts from / directory and requires to be root.'
  echo '                As a secure measure the interactive mode is enabled,'
  echo '                uses -I option to disable it.'
  echo
  echo ' -R             Disables recursive mode.'
  echo
  echo ' -s "SHREDCMD"  Shred files with the shred command passed instead of removing them.'
  echo '                Must starts with shred and may have options after. e.g: -s "shred -uzv"'
  echo
  echo ' -t             Removes the /tmp content and all content of tmp directorys'
  echo '                in the tree if the recursive mode is enabled'
  echo
  echo ' -T             Removes the content of every .Trash directory.'
  echo
  echo ' -w "TAG LIST"  Sweeps rubbish files depending the comma separeted list of tags:'
  echo '                 * TILDE: Removes file~'
  echo '                 * SWAP:  Removes file.swp'
  echo '                 * TMP:   Removes file.tmp'
  echo '                 * LOCK:  Removes [file].lock'
  echo '                 * LOG:   Removes file.log'
  echo '                 * BAK:   Removes file.bak, file.bkp and file.backup'
  echo '                 * OLD:   Removes file.old'
  echo '                 * INFO:  Removes [.][file]info[.*]'
  echo
  echo ' -y             Enables summary.'
  echo
  echo ' --debug        Enables set -xve, asserts and more verbose exit status.'
  echo '                Must be the first command option to work.'
  echo

  if [ -n "$1" ];then
    exit 0
  fi
}

##############################
#				ERROR FUNCTIONS	     #
##############################

# ERROR CODES
# 0  Means success
# 1  Means error
# 1X Means User input error
# 2X Means Command error
# 3X Means Warning for bad usage

f_catch()
{
  if [ ${options['DEBUG']} = 0 ];then
    options['DEBUG']=2
    set +xve
  fi

  local error="$1"
  local type=""
  local msg=""
  local reason=""
  local status=""
  shift

  case "$error" in
    "INVALID_OPTION_ERROR")
      type="error"
      msg="option '$1' doesnt exists."
      reason="${erreasons[1]}"
      status="11"
    ;;
    "REQUIRE_ARGUMENT_ERROR")
      type="error"
      msg="option '$1' requires an argument."
      reason="${erreasons[1]}"
      status="12"
    ;;
    "INVALID_ARGUMENT_ERROR")
      type="error"
      msg="option '$1' has a invalid argument '$2'."
      reason="${erreasons[1]}"
      status="13"
    ;;
    "INVALID_DIRECTORY_ERROR")
      type="error"
      msg="option '$1' found an invalid directory '$2' or not enough access rights."
      reason="${erreasons[1]}"
      status="14"
    ;;
    "INVALID_DIRECTORY_WARNING")
      type="warning"
      msg="found invalid directory $2 processing option $1."
      reason="${erreasons[3]}"
      status="31"
    ;;
    "SHRED_FAILED_WARNING")
      type="warning"
      msg="shred proccess failed with '$1' file or directory."
      reason="${erreasons[3]}"
      status="21"
    ;;
    "NO_COMMAND_ACTION_WARNING")
      type="warning"
      msg="there are no actions specified for the command to do."
      reason="${erreasons[3]}"
      status="33"
    ;;
    "DEBUG_BAD_USAGE_WARNING")
      type="warning"
      msg="bad usage of debug option. Debugging didnt work."
      reason="${erreasons[3]}"
      status="34"
    ;;
    *) # Unknown case
    	exit 1
    ;;
  esac

  if [ "$type" = "warning" ];then
    if [ ${options['DEBUG']} -eq 2 ];then
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      echo "[warning]: $msg"
      echo "[reason]: $reason"
      echo "[status]: $status"
      echo "[action]: skips"
      echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      set -xve
    else
      echo "[warning]: $msg"
      echo "SKIPPING..."
    fi
    return 0
  else
    if [ ${options['DEBUG']} -eq 2 ];then
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      echo "[error]: $msg"
      echo "[reason]: $reason"
      echo "[status]: $status"
      echo "[action]: forced exit"
      echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      set -xve
    else
      echo "[error]: $msg"
    fi
    exit $status
  fi
}

##############################
#      ACTION FUNCTIONS      #
##############################

f_sweep()
{
local OFS=$IFS
IFS=","
  for tag in ${options['SWEEP_TAGS_LIST']}
  do
    case $tag in
      TILDE|SWAP|TMP|LOCK|LOG|BAK|OLD|INFO);;
      *)
        f_catch "INVALID_ARGUMENT_ERROR" "-w" "$tag"
      ;;
    esac
  done
IFS="$OFS"

touch .pendingtags
echo "====[[ SWEEPING TAGFILES ]]===="
  for swpopt in $(echo "${options['SWEEP_TAGS_LIST']}" | sed -e 's/,/ /gi')
  do
  {
    case "$swpopt" in
      "TILDE")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*~"
      ;;
      "SWAP")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.swp" -o -iname "*.swo"
      ;;
      "TMP")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.tmp"
      ;;
      "LOCK")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.lock"
      ;;
      "LOG")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.log"
      ;;
      "BAK")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.bak" -o -iname "*.bkp" -o -iname "*.backup"
      ;;
      "OLD")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.old"
      ;;
      "INFO")
        ${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*info*"
      ;;
    esac
  } >> .pendingtags
  done

  for pendfile in $(cat .pendingtags)
  do
    [ ${options['IGNORE_ROOT_DIR']} -eq 0 ] && f_contains_rootdir "$pendfile" && continue
    if [ ${options['TO_DO_SHRED']} -eq 0 ];then
      f_shred_data "$pendfile"
    else
      ${options['SUDO']} rm -frv ${options['INTERACTIVE']} "$pendfile"
    fi
    if [ ${options['TO_DO_SUMMARY']} -eq 0 ];then
      f_add_to_summary "$pendfile"
    fi
  done
  rm -f .pendfile
}

f_delete_trashs()
{
echo "====[[ REMOVING TRASHS ]]===="
  for trash in $(${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type d -regextype 'egrep' -iregex "^(.+)?\.?([Tt]rash\-[0-9]+|[Tt]rash)")
  do
    [ ${options['IGNORE_ROOT_DIR']} = 0 ] && f_contains_rootdir "$trash" && continue

    if ! [[ -x "$trash" && -w "$trash" ]];then
      f_catch "INVALID_DIRECTORY_WARNING" "-T" "$trash"
    fi

    if [ ${options['TO_DO_SHRED']} -eq 0 ];then
      f_shred_data "$trash"
    else
      for trashfile in $(ls -A1 "$trash")
      do
        ${options['SUDO']} rm -drfv ${options['INTERACTIVE']} "$trash/$trashfile"
      done
    fi

    f_is_emptydir "$trash" && f_add_to_summary "$trash" "DIR"
  done
}

f_delete_tmp()
{
echo "====[[ REMOVING TMPS ]]===="
  if [ ${options['TO_DO_SHRED']} -eq 0 ];then
    for obj in $(ls -A1 /tmp)
    do
      f_shred_data "/tmp/$obj"
    done
  else
    for obj in $(ls -A1 /tmp)
    do
      ${options['SUDO']} rm -drfv ${options['INTERACTIVE']} "/tmp/$obj"
    done
  fi

  f_add_to_summary "/tmp" "DIR"

  for tmpdir in $(${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type d -iname "tmp")
  do
    [ ${options['IGNORE_ROOT_DIR']} -eq 0 ] && f_contains_rootdir "$tmpdir" && continue

    for obj in $(ls -A1 "$tmpdir")
    do
      if [ ${options['TO_DO_SHRED']} -eq 0 ];then
        f_shred_data "$tmpdir/$obj"
      else
        ${options['SUDO']} rm -dfrv ${options['INTERACTIVE']} "$tmpdir/$obj"
      fi
    done

    f_is_emptydir "$tmpdir" && f_add_to_summary "$tmpdir" "DIR"
  done
}

f_delete_caches()
{
echo "====[[ REMOVING CACHES ]]===="
  for cachedir in $(${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type d -iname "*cache*")
  do
    [ ${options['IGNORE_ROOT_DIR']} -eq 0 ] && f_contains_rootdir "$cachedir" && continue

    for obj in $(ls -A1 "$cachedir")
    do
      if [ ${options['TO_DO_SHRED']} -eq 0 ];then
        f_shred_data "$cachedir/$obj"
      else
        ${options['SUDO']} rm -dfrv ${options['INTERACTIVE']} "$cachedir/$obj"
      fi
    done

    f_is_emptydir "$cachedir" && f_add_to_summary "$cachedir" "DIR"
  done
}

f_delete_extension_files()
{
echo "====[[ REMOVING EXTENSIONS ]]===="
  for ext in "${arrexts[@]}"
  do
    for fext in $(${options['SUDO']} find "${options['ORIGIN']}" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -iname "*.$ext")
    do
      [ ${options['IGNORE_ROOT_DIR']} = 0 ] && f_contains_rootdir "$fext" && continue

      if [ ${options['TO_DO_SHRED']} -eq 0 ];then
        f_shred_data "$fext"
      else
        ${options['SUDO']} rm -frv ${options['INTERACTIVE']} "$fext"
      fi

      ! [ -f "$fext" ] && f_add_to_summary "$fext" "FILE"
    done
  done
}

f_delete_directory_paths()
{
echo "====[[ REMOVING PATHS ]]===="
  for path in "${arrdirpaths[@]}"
  do
    ! [ -d "$path" ] && f_catch "INVALID_DIRECTORY_WARNING" "-d" "$path" && continue

    if [ ${options['TO_DO_SHRED']} -eq 0 ];then
      f_shred_data "$path"
    else
      ${options['SUDO']} rm -drfv ${options['INTERACTIVE']} "$path"
    fi

    f_is_emptydir "$path" && f_add_to_summary "$path" "DIR"
  done
}

f_delete_directory_names()
{
echo "====[[ REMOVING DIRNAMES ]]===="
  for name in "${arrdirnames[@]}"
  do
    for dirname in $(find ${options['ORIGIN']} ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type d -iname "$name")
    do
      [ ${options['IGNORE_ROOT_DIR']} -eq 0 ] && f_contains_rootdir "$dirname" && continue

      if [ ${options['TO_DO_SHRED']} -eq 0 ];then
        f_shred_data "$dirname"
      else
        ${options['SUDO']} rm -drfv ${options['INTERACTIVE']} "$dirname"
      fi

      ! [ -f "$dirname" ] && f_add_to_summary "$dirname"
    done
  done
}

#################################
#      SUBACTION FUNCTIONS      #
#################################

f_summary()
{
  if ! [ -s ${options['SUMMARY_FILE']} ];then
    echo "[info]: summary empty, nothing happened."
    return
  fi

  echo '+-------------------------------------+'
  echo "Summary: Cleaned files and directorys:"
  cat "${options['SUMMARY_FILE']}"
  echo '+-------------------------------------+'
}

f_add_to_summary()
{
  [ ${options['TO_DO_SUMMARY']} = 1 ] && return 1

  local entrytype=""
  if [ "$2" = "DIR" ];then
    entrytype="> [Directory]:"
  else
    entrytype="> [File]:"
  fi
  echo "$entrytype '$1'" >> "${options['SUMMARY_FILE']}"
}

f_shred_data()
{
  local exitcode

  if [ -d "$1" ];then
    ${options['SUDO']} find "$1" ${options['SKIP_MEDIA']} ${options['RECURSIVE']} -type f -exec ${options['SHRED_CMD']} {} \;
    exitcode="$?"
    ${options['SUDO']} rm -drfv ${options['INTERACTIVE']} "$1"
  else
    ${options['SUDO']} ${options['SHRED_CMD']} "$1"
    exitcode="$?"
  fi

  [ "$exitcode" != 0 ] && f_catch "SHRED_FAILED_WARNING" "$1"
}

#######################################
#      CONDITION/STATUS FUNCTIONS     #
#######################################

f_silence_output()
{
  exec &>/dev/null
}

###############################
#     USEFULL FUNCTIONS       #
###############################

f_contains_rootdir()
{
  echo "$1" | grep -qE "(\/)?root(\/)?" && return 0 || return 1
}

f_is_emptydir()
{
  [[ "$(ls -A1 "$1" | wc -l)" = 0 ]] && return 0 || return 1
}

f_is_dir()
{
  [[ -d "$1" && -r "$1" && -w "$1" ]] && return 0 || return 1
}

f_is_extension()
{
  $(echo "$1" | grep -Eq "[a-zA-Z1-9]") && return 0 || return 1
}

f_is_option()
{
  $(echo "$1" | grep -Eq "^-.+") && return 0 || return 1
}


###############################
#     DEBUG FUNCTIONS       #
###############################

f_dump_vars_values()
{
  set +xve
  echo '[DUMP START]'
  echo "-> arrdirnames=${arrdirnames[@]}"
  echo "-> arrdirpaths=${arrdirpaths[@]}"
  echo "-> arrexts=${arrexts[@]}"
  echo "-> erreasons=${erreasons[@]}"
  echo "-> CMD_NAME=${options['CMD_NAME']}"
  echo "-> DEBUG=${options['DEBUG']}"
  echo "-> ORIGIN=${options['ORIGIN']}"
  echo "-> D_CACHE=${options['D_CACHE']}"
  echo "-> D_TMP=${options['D_TMP']}"
  echo "-> D_TRASH=${options['D_TRASH']}"
  echo "-> D_EXTS=${options['D_EXTS']}"
  echo "-> D_DIRS_BY_NAME=${options['D_DIRS_BY_NAME']}"
  echo "-> D_DIRS_BY_PATH=${options['D_DIRS_BY_PATH']}"
  echo "-> INTERACTIVE=${options['INTERACTIVE']}"
  echo "-> TO_DO_SHRED=${options['TO_DO_SHRED']}"
  echo "-> SHRED_CMD=${options['SHRED_CMD']}"
  echo "-> SUDO=${options['SUDO']}"
  echo "-> IGNORE_ROOT_DIR=${options['IGNORE_ROOT_DIR']}"
  echo "-> RECURSIVE=${options['RECURSIVE']}"
  echo "-> QUIET=${options['QUIET']}"
  echo "-> SKIP_MEDIA=${options['SKIP_MEDIA']}"
  echo "-> D_SWEEP=${options['D_SWEEP']}"
  echo "-> SWEEP_TAGS_LIST=${options['SWEEP_TAGS_LIST']}"
  echo "-> TO_DO_SUMMARY=${options['TO_DO_SUMMARY']}"
  echo "-> SUMMARY_FILE=${options['SUMMARY_FILE']}"
  echo '[DUMP END]'
  set -xve
}

#####################################################################

declare -A options
declare -a erreasons    \
           arrdirnames  \
           arrdirpaths  \
           arrexts

# For debugging
erreasons[0]="Nothing happened."
erreasons[1]="User invalid input."
erreasons[2]="Command execution error."
erreasons[3]="Bad user command usage."

#### Default command options values ###
## INTEGER (BOOLEAN) VARS [0|1]
options['D_CACHE']=1
options['D_DIRS_BY_NAME']=1
options['D_DIRS_BY_PATH']=1
options['D_EXTS']=1
options['D_SWEEP']=1
options['D_TMP']=1
options['D_TRASH']=1
options['DEBUG']=1
options['IGNORE_ROOT_DIR']=$(test "$UID" = 0 && echo 1 || echo 0) # Enabled if root
options['QUIET']=1
options['TO_DO_SHRED']=1
options['TO_DO_SUMMARY']=1
## STRING VARS
options['CMD_NAME']="$(basename -s .sh $(echo $0 | cut -f1))"
options['INTERACTIVE']=""
options['ORIGIN']="$(pwd)"
options['RECURSIVE']=""
options['SHRED_CMD']=""
options['SKIP_MEDIA']=""
options['SUDO']=""
options['SUMMARY_FILE']="cleaned.sum"
options['SWEEP_TAGS_LIST']=""

main()
{
  # No args
  if [ $# -eq 0 ];then
    echo 'Use -h option to show help.'
    exit 0
  fi

  # Pre-start
  [ -f ${options['SUMMARY_FILE']} ] && rm -f ${options['SUMMARY_FILE']} 2>/dev/null
  if ! f_is_dir "$(pwd)";then
    echo "Error: the current directory must have write/read permissions to perform some tasks."
    exit 1
  fi

  if [ "$1" = "--debug" ];then
    options['DEBUG']=0
    set -xve
    shift
  fi

  while [ -n "$1" ]
  do
    to_shift=1
    case "$1" in
      ################################################
      -c)
        options['D_CACHE']=0
      ;;
      ################################################
      -d)
        if [ -z "$2" ] || f_is_option "$2";then
          f_catch "REQUIRE_ARGUMENT_ERROR" "-d"
        fi

        if ! f_is_dir "$2";then
          f_catch "INVALID_DIRECTORY_ERROR" "-d" "$2"
        fi

        options['D_DIRS_BY_PATH']=0
        arrdirpaths[${#arrdirpaths[@]}]="$2"
        to_shift=2
      ;;
      ################################################
      -D)
        if [ -z "$2" ] || f_is_option "$2";then
          f_catch "REQUIRE_ARGUMENT_ERROR" "-D"
        fi

        options['D_DIRS_BY_NAME']=0
        arrdirnames[${#arrdirnames}]="$2"
        to_shift=2
      ;;
      ################################################
      -e)
        local ext=${2#.} # Removes the initial '.' in ".extension"

        if [ -z "$ext" ] || f_is_option "$ext";then
          f_catch "REQUIRE_ARGUMENT_ERROR" "-e"
        fi

        if ! f_is_extension "$ext";then
          f_catch "INVALID_OPTION_ERROR" "-e" "$2"
        fi

        options['D_EXTS']=0
        arrexts[${#arrexts[@]}]="$ext"
        to_shift=2
        unset ext
      ;;
      ################################################
      -h)
        f_usage 0
      ;;
      ################################################
      -i)
        options['INTERACTIVE']=" -i "
        options['QUIET']=1
      ;;
      ################################################
      -I)
        options['INTERACTIVE']=""
      ;;
      ################################################
      -m)
        options['SKIP_MEDIA']=' -mount -xdev '
      ;;
      ################################################
      -q)
        options['QUIET']=0
        options['INTERACTIVE']=1
        f_silence_output
      ;;
      ################################################
      -r)
        options['SUDO']='sudo '
        options['ORIGIN']="/"
        options['IGNORE_ROOT_DIR']=1
        options['INTERACTIVE']=" -i "
      ;;
      ################################################
      -R)
        options['RECURSIVE']=" -maxdepth 1 "
	    ;;
      ################################################
      -o)
        if [ -z "$2" ] || f_is_option "$2";then
          f_catch "REQUIRE_ARGUMENT_ERROR" "-o"
        fi

        if ! f_is_dir "$2";then
          f_catch "INVALID_DIRECTORY_ERROR" "-o" "$2"
        fi

        options['ORIGIN']="$2"
        to_shift=2
      ;;
      ################################################
      -t)
        options['D_TMP']=0
      ;;
      ################################################
      -T)
        options['D_TRASH']=0
      ;;
      ################################################
      -s)
        if [ -z "$2" ] || f_is_option "$2";then
          f_catch "REQUIRE_ARGUMENT_ERROR" "-s"
        fi

        if ! [[ "$2" =~ ^shred* ]];then
          f_catch "INVALID_ARGUMENT_ERROR" "-s" "$2"
        fi

        options['TO_DO_SHRED']=0
        options['SHRED_CMD']="$2"
        to_shift=2
      ;;
      ################################################
      -w)
        if [ -z "$2" ] || f_is_option "$2";then
          f_catch "REQUIRE_ARGUMENT_ERROR" "-w"
        fi
        
        options['D_SWEEP']=0
        options['SWEEP_TAGS_LIST']="$2"
        to_shift=2
      ;;
      ################################################
      -y)
        if f_is_dir "$(pwd)";then
          options['TO_DO_SUMMARY']=0
        else
          f_catch "INVALID_DIRECTORY_ERROR"
        fi
        
        ${options['SUDO']} touch "${options['SUMMARY_FILE']}"
      ;;
      ################################################
      --debug)
        f_catch "DEBUG_BAD_USAGE_WARNING"
      ;;
      ################################################
      -*|*)
        f_catch "INVALID_OPTION_ERROR" "$1"
      ;;
      ################################################
    esac
    shift $to_shift
  done

  [ ${options['DEBUG']} = 0 ] && f_dump_vars_values

  # There're any action to do?
  if [[ ${options['D_SWEEP']} = 0 || ${options['D_TMP']} = 0          || ${options['D_CACHE']} = 0        || \
        ${options['D_TRASH']} = 0 || ${options['D_DIRS_BY_PATH']} = 0 || ${options['D_DIRS_BY_NAME']} = 0 || \
        ${options['D_EXTS']}  = 0 ]];
  then
    [ "${options['D_SWEEP']}" = 0 ] &&  f_sweep
    [ "${options['D_TMP']}"   = 0 ] &&  f_delete_tmp
    [ "${options['D_CACHE']}" = 0 ] &&  f_delete_caches
    [ "${options['D_TRASH']}" = 0 ] &&  f_delete_trashs
    [ "${options['D_EXTS']}"  = 0 ] &&  f_delete_extension_files
    [ "${options['D_DIRS_BY_PATH']}"  = 0 ] &&  f_delete_directory_paths
    [ "${options['D_DIRS_BY_NAME']}"  = 0 ] &&  f_delete_directory_names

    # Summary
    [ ${options['TO_DO_SUMMARY']} -eq 0 ] && f_summary
  else
    f_catch "NO_COMMAND_ACTION_WARNING"
  fi
}

main "$@"
exit 0

