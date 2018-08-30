function rsink
  switch $argv[1]
    case copy cp
      rsync -avz --progress -h $argv[2..-1]
    case move mv
      rsync -avz --progress -h --remove-source-files $argv[2..-1]
    case sync synchronize
      rsync -avzu --delete --progress -h $argv[2..-1]
    case update
      rsync -avzu --progress -h $argv[2..-1]
    case --help -h help
      __rsink_print_help
    case \*
      printf "error: Unknown option %s\n" $argv[1]
  end
end

function __rsink_print_help
  printf "NAME\n"
  printf "\trsink - shortcuts for common rsync operations\n\n"
  printf "SYNOPSIS\n"
  printf "\t rsink (copy | cp | move | mv | sync | synchronize | update] | help) <source> <destination>\n\n"
  printf "DESCRIPTION\n"
  printf "\tA shortcut for common rsync commands that I tend to use often and\n"
  printf "\toften forget the syntax to. This was also an experiment in fish\n"
  printf "\tshell function writing.\n\n"
  printf "\tAny options you pass along to this command will also be passsed to the\n"
  printf "\tunderlying rsync call.\n\n"
  printf "OPTIONS\n"
  printf "\to   copy: Copy <source> to <destination> recursively.\n"
  printf "\t          Does not remove things at <destination> which do not exist\n"
  printf "\t          at <source>.\n\n"
  printf "\to   move: Move <source> to <destination> recursively, deleting <source> on success.\n\n"
  printf "\to   synchronize: Synchronize <source> to <destination> recursively.\n"
  printf "\t                 Removes things at <destination> which do not exist at <source>.\n\n"
  printf "\to   update: A optimized copy command that tries to copy only changed blocks of\n"
  printf "\t            files from <source> to <destination>.\n\n"
  printf "\to   help: Show this text and exit\n\n"
  printf "USAGE\n"
  printf "\tTODO: Put some examples here\n\n"
end
