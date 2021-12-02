
    

if [ -e $ERROR ]; then
    echo "b"
else
    echo "ERROR:" $ERROR
    echo "$ERROR" >> test.log
fi

