local _ZPM_EXT_CACHE_DIR=${_ZPM_EXT_CACHE_DIR:-$ZPM_DIR/.cache/}
_ZPM_EXT_CACHE_FILENAME=$_ZPM_EXT_CACHE_DIR/.zpm-cache

# Be sure .cache directory exists
[[ ! -e $_ZPM_EXT_CACHE_DIR ]] && mkdir $_ZPM_EXT_CACHE_DIR

# logger command that prints the logged bundles
function -zpm-cache-package () {
    -zpm-package-source $(-zpm-parse-package-query "$@") | while read line; do
        if [[ -f "$line" ]]; then
            echo " # SOURCE: $line" >>! "$_ZPM_EXT_CACHE_FILENAME"
            # Fix script sourcing if there is a reference to $0 or ${0}
            if $_ZPM_EXT_CACHE_FIX_SCRIPT_SOURCE; then
                # TODO suffix __ZCACHE_FILE_PATH variable name with a PRN (from chksum?)
                # to avoid variable collision
                cat $line \
                    | sed "/\${0/i__ZCACHE_FILE_PATH='"$line"'" | sed -e "s/\${0/\${__ZCACHE_FILE_PATH/" \
                    | sed "/\$0/i__ZCACHE_FILE_PATH='"$line"'" | sed -e "s/\$0/\$__ZCACHE_FILE_PATH/" \
                    >>! "$_ZPM_EXT_CACHE_FILENAME"

            else
                cat $line >>! "$_ZPM_EXT_CACHE_FILENAME"
            fi

            echo ";\n" >>! "$_ZPM_EXT_CACHE_FILENAME"

        elif [[ -d "$line" ]]; then
            echo "fpath=($line \$fpath);\n" >>! "$_ZPM_EXT_CACHE_FILENAME"
            # load autocompletion
            fpath=($line $fpath)
        fi
    done
}

# disable loading ext and packages
function -zpm-cache-disable () {
    local funcname="$1"
    eval "function -original-$(functions -- $funcname)"
    $funcname () {}
}

# re-enable loading ext and packages
function -zpm-cache-enable () {
    local funcname="$1"
    eval "function $(functions -- -original-$funcname | sed 's/-original-//')"
}

# Cache clear action
function -zpm-cache-clear () {
    if [ -f "$_ZPM_EXT_CACHE_FILENAME" ]; then
        rm "$_ZPM_EXT_CACHE_FILENAME"
    fi
}

# Cache clear command
function zpm-cache-clear () {
  local force=false
  if [[ $1 == --force ]]; then
      force=true
  fi

  if $force || (echo -n '\nClear all cache? [y/N] '; read -q); then
      echo
      -zpm-cache-clear
      echo
      echo 'Done.'
      echo 'Please open a new shell to see the changes.'
  else
      echo
      echo Nothing deleted.
  fi
}
-zpm-ext-compadd "cache-clear"

if [ -f "$_ZPM_EXT_CACHE_FILENAME" ] ; then
    source "$_ZPM_EXT_CACHE_FILENAME" # cache exists, load it
    -zpm-cache-disable "zpm-load"
    -zpm-cache-disable "-zpm-load-package" # for themes and other ext using low-level functions
    #-zpm-cache-disable "-zpm-parse-package-query" # to avoid unneeded extra work
else
    # hook loading ext
    -zpm-ext-hook "zpm-load" "-zpm-cache-package"
fi
