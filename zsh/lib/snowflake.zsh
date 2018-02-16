export SNOWFLAKE_PATH="/Applications/SnowSQL.app/Contents/MacOS"

function have_snowflake(){
    [[ -n $path[(r)$SNOWFLAKE_PATH] ]]
}

if ! have_snowflake ; then
  export PATH=$SNOWFLAKE_PATH:$PATH
fi
