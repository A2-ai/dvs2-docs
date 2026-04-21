function tree
    set -l dir $PWD
    set -l ignore ""
    while test "$dir" != "/"
        if test -f "$dir/.treeignore"
            set ignore "$dir/.treeignore"
            break
        end
        set dir (dirname "$dir")
    end
    if test -n "$ignore"
        command tree --gitfile "$ignore" $argv
    else
        command tree $argv
    end
end
