function opus2m4a
  switch $argv[1]
    case --help -h help
      __opus2m4a_print_help
    case \*
      for infile in $argv
        set outfile (string replace --regex '\.opus$' '.m4a' $infile)
        printf "Running: ffmpeg -i $infile $outfile\n\n"
        ffmpeg -i $infile $outfile
      end
  end
end

function __opus2m4a_print_help
  printf "NAME\n"
  printf "\topus2m4a - convert opus audio files to m4a files using ffmpeg\n\n"
  printf "SYNOPSIS\n"
  printf "\t opus2m4a (--help) <source1> <source2> ...\n\n"
  printf "DESCRIPTION\n"
  printf "\tA wrapper around an ffmpeg call that converts all the .opus files passed\n"
  printf "\tto the wrapper into .m4a files using the ffmpeg CLI.\n"
  printf "OPTIONS\n"
  printf "\to   --help: Show this text and exit\n\n"
  printf "USAGE\n"
  printf "\tTODO: Put some examples here\n\n"
end
