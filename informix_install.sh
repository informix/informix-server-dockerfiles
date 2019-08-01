
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu

. /usr/local/bin/informix_inf.env
$BASEDIR/informix/ids_install -i silent -f $BASEDIR/informix_install.properties


exit 0
