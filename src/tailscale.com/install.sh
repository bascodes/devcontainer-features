#!/bin/sh
# This script was generated using Makeself 2.5.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2765132927"
MD5="d01c4afe35c6ec67fd5a3a0bcce3541b"
SHA="2a6d052684ceec463ab09edd4031279b431fcc5170d862a97f86cedae03dae07"
SIGNATURE=""
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"
export USER_PWD
ARCHIVE_DIR=`dirname "$0"`
export ARCHIVE_DIR

label="Devcontainer.com Feature: tailscale.com"
script="./entrypoint.sh"
scriptargs=""
cleanup_script=""
licensetxt=""
helpheader=""
targetdir="."
filesizes="4399"
totalsize="4399"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"
decrypt_cmd=""
skip="718"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  PAGER=${PAGER:=more}
  if test x"$licensetxt" != x; then
    PAGER_PATH=`exec <&- 2>&-; which $PAGER || command -v $PAGER || type $PAGER`
    if test -x "$PAGER_PATH"; then
      echo "$licensetxt" | $PAGER
    else
      echo "$licensetxt"
    fi
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -k "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    # Test for ibs, obs and conv feature
    if dd if=/dev/zero of=/dev/null count=1 ibs=512 obs=512 conv=sync 2> /dev/null; then
        dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
        { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
          test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
    else
        dd if="$1" bs=$2 skip=1 2> /dev/null
    fi
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd "$@"
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 count=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.5.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
  $0 --verify-sig key Verify signature agains a provided key id

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet               Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script (implies --noexec-cleanup)
  --noexec-cleanup      Do not run embedded cleanup script
  --keep                Do not erase target directory after running
                        the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the target folder to the current user
  --chown               Give the target folder to the current user recursively
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --ssl-pass-src src    Use the given src as the source of password to decrypt the data
                        using OpenSSL. See "PASS PHRASE ARGUMENTS" in man openssl.
                        Default is to prompt the user to enter decryption password
                        on the current terminal.
  --cleanup-args args   Arguments to the cleanup script. Wrap in quotes to provide
                        multiple arguments.
  --                    Following arguments will be passed to the embedded script${helpheader}
EOH
}

MS_Verify_Sig()
{
    GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
    test -x "$GPG_PATH" || GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    test -x "$MKTEMP_PATH" || MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
	offset=`head -n "$skip" "$1" | wc -c | sed "s/ //g"`
    temp_sig=`mktemp -t XXXXX`
    echo $SIGNATURE | base64 --decode > "$temp_sig"
    gpg_output=`MS_dd "$1" $offset $totalsize | LC_ALL=C "$GPG_PATH" --verify "$temp_sig" - 2>&1`
    gpg_res=$?
    rm -f "$temp_sig"
    if test $gpg_res -eq 0 && test `echo $gpg_output | grep -c Good` -eq 1; then
        if test `echo $gpg_output | grep -c $sig_key` -eq 1; then
            test x"$quiet" = xn && echo "GPG signature is good" >&2
        else
            echo "GPG Signature key does not match" >&2
            exit 2
        fi
    else
        test x"$quiet" = xn && echo "GPG signature failed to verify" >&2
        exit 2
    fi
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n "$skip" "$1" | wc -c | sed "s/ //g"`
    fsize=`cat "$1" | wc -c | sed "s/ //g"`
    if test $totalsize -ne `expr $fsize - $offset`; then
        echo " Unexpected archive size." >&2
        exit 2
    fi
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" != x"$crc"; then
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2
			elif test x"$quiet" = xn; then
				MS_Printf " CRC checksums are OK." >&2
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

MS_Decompress()
{
    if test x"$decrypt_cmd" != x""; then
        { eval "$decrypt_cmd" || echo " ... Decryption failed." >&2; } | eval "gzip -cd"
    else
        eval "gzip -cd"
    fi
    
    if test $? -ne 0; then
        echo " ... Decompression failed." >&2
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." >&2; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. >&2; kill -15 $$; }
    fi
}

MS_exec_cleanup() {
    if test x"$cleanup" = xy && test x"$cleanup_script" != x""; then
        cleanup=n
        cd "$tmpdir"
        eval "\"$cleanup_script\" $scriptargs $cleanupargs"
    fi
}

MS_cleanup()
{
    echo 'Signal caught, cleaning up' >&2
    MS_exec_cleanup
    cd "$TMPROOT"
    rm -rf "$tmpdir"
    eval $finish; exit 15
}

finish=true
xterm_loop=
noprogress=n
nox11=y
copy=none
ownership=n
verbose=n
cleanup=y
cleanupargs=
sig_key=

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 20 KB
	echo Compression: gzip
	if test x"n" != x""; then
	    echo Encryption: n
	fi
	echo Date of packaging: Wed Jan 22 11:32:28 UTC 2025
	echo Built with Makeself version 2.5.0
	echo Build command was: "./makeself-2.5.0/makeself.sh \\
    \"--gzip\" \\
    \"--current\" \\
    \"--nox11\" \\
    \"--sha256\" \\
    \"/tmp/tailscale.com.yJRsiOcSl6/\" \\
    \"/home/runner/work/devcontainer-features/devcontainer-features/src/tailscale.com/install.sh\" \\
    \"Devcontainer.com Feature: tailscale.com\" \\
    \"./entrypoint.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
    echo CLEANUPSCRIPT=\"$cleanup_script\"
	echo archdirname=\".\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
    echo totalsize=\"$totalsize\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5sum\"
	echo SHAsum=\"$SHAsum\"
	echo SKIP=\"$skip\"
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`
	arg1="$2"
    shift 2 || { MS_Help; exit 1; }
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --verify-sig)
    sig_key="$2"
    shift 2 || { MS_Help; exit 1; }
    MS_Verify_Sig "$0"
    ;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
    cleanup_script=""
	shift
	;;
    --noexec-cleanup)
    cleanup_script=""
    shift
    ;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    shift 2 || { MS_Help; exit 1; }
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --chown)
        ownership=y
        shift
        ;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
	--ssl-pass-src)
	if test x"n" != x"openssl"; then
	    echo "Invalid option --ssl-pass-src: $0 was not encrypted with OpenSSL!" >&2
	    exit 1
	fi
	decrypt_cmd="$decrypt_cmd -pass $2"
    shift 2 || { MS_Help; exit 1; }
	;;
    --cleanup-args)
    cleanupargs="$2"
    shift 2 || { MS_Help; exit 1; }
    ;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    export USER_PWD="$tmpdir"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if test -t 1; then  # Do we have a terminal on stdout?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0 >&2
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -e "$0 --xwin $initargs"
                else
                    exec $XTERM -e "./$0 --xwin $initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 20 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = x"openssl"; then
	    echo "Decrypting and uncompressing $label..."
	else
        MS_Printf "Uncompressing $label"
	fi
fi
res=3
if test x"$keep" = xn; then
    trap MS_cleanup 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 20; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (20 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | MS_Decompress | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        MS_CLEANUP="$cleanup"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi

MS_exec_cleanup

if test x"$keep" = xn; then
    cd "$TMPROOT"
    rm -rf "$tmpdir"
fi
eval $finish; exit $res
� Lאg�;�s�6��j����)Y��t�q�۽�4�2��^潻DB�H�@�ʩ��� 	Ҕc�I^o��AI`��w�u�,Qb��0Q9}�5��^���w��~O��^���x���y��{�������{��{�������\�TT *"K&V��?������i7��;
P�+�]��S�y	O�ӿ�O<N��:T�3S6�a���G|4b��d�d��b�������ɯG�������y�h������*�O��>�X��3bŵ��ҮLj�:�0�F�s���u���V�������^���{������娖gՊ�G��s��Ⱦ��C�ߩ�����<�����}��g䈧N��l�[d�k9M|�9��mp~�.���{��; ��!}����{�E4���F��$�a�H��$jʈ��'I�)T�ɄȅT,�&4	��<� 
$��s�P�Udp�!�ϓ+D�'��j��!�Z0�0��R<`�����Jb
_�,�q��6a���
��� dĕ�1�c
��6�vyJ�OLH�P!�H��I�i ?�L6aI `���k�g��)��0�p��BT6�ȿZk�X�R��[VU8�IvM�P*���07�J�?���� ��~cD�hA8R�r��^ g#Kh�6��.S~�K3*�w� �&�e�C��ʲc�#s.f�g�́18�J�,35��3"�<�2b$��o���F�2���6�r#��ۚ�<��\��T0�S���(b�P�#�i�@�I8�\D��e�Ϥg,;�8h�[k���_����w�G?��d��݉�?|7������yF	0s���� J�܍<�}��bx����퇋����`L#ঝ�0Hd-z�4��i�ֆ��A{�_�G��E�[�5��^�/����ښy���c���|>�?u�܆�Y�r�����0��|�ԇ��_�M��e���z\�ٍw9���$�bL @vr���
�tP}���T��p�GN���h�PF�с�m�ΤC��4io���?�A{+�n�!�0�$��*�f��5�&�x�����M�G�㓳�_N��/��fW��AXa��w���lx逃� �Tr́i�a�: v}u�ҩs�Y�8=������DeK��2a<Y~�"L�*�f�ڡߌҪ`��W����M���R��\�ͬ���,Ҩ���)2�ǡ����y���<��2c�����Q��T�1��A�b��ά�p���d��B�䄳�T�5dc��w;����n���IE�5�`1��]�	�j���e.��R�7����gֱF��zd�p@�����}D�q,u�� )���O[]��1Y�bk�3	�m���C(��aL���Z�J΃��c��\Q�We���t���Dm}���-�N��/s|������XGٰLN��ގ�g��
Y�=Q��ŠWT,�}�'�~/2^~=2��WK %`QI�+܇p���Uw'��i�C�~�M�لY�e�x��*/���jl-3��\�h(Yr� �
͂���O���-r+=����3H~�#��'����M��VP]B,��߸G���Uʪ��c��M��6�B�|"��,��a ��&S�����:�y���0�`#T�t��(��������PoDq�O�PN����3������T�T���I��٨Z�r~�RfLv_}�r��pw�j�̣;)�*&U�C�r�-�"S�4H�M��	$�jiYe�"���N��o�X������RL݀���?�c�s	z���`	��l��QLu��L��
��)Kb�"��KI�	��R��ÕK?�Y`F�I�J:����Dʼ�7^4��8ӏ<��j�Rނq�5K��H�V�7&�ED\[�(a���M�2b�!��j�����T}\�i�(j�,El�X�ɅʡwZ�����4�`#�FIo��w'�T��%~P/1#�W<�o�d����,p��������\:�~��t�4��/|i�=��\�>�2+���|gL�Y%��R�T�X�ÛE7	�s��ޙ"�^i�9�X&��L��%�U��(8��U�3�);C,�ZxB̠~���2��늇����.R���%v���v�b�\������H:�l	���o��H�\q�+��/B�r�ˤσ�A��e�ڽ���G|�xM~Oh��tu#�O����1��y��Sl[�Ǵ��U�m�\�
���hD(�0y4��Dϕy?��N�)T.����"eRY�#�?~�+�-�n�a[yuu�'P�7�[y
n�a�0悑�ng�h�`�+W�����&Y�cɘg��R�b�S�}�[n|�\�#~�l�Lq[�e�����W���Bw�R� x�$��q5�SO4�B=�b&И�y�wA��ĝx@z����:!��JRh�Jb�����l`��K=����:���b�:.M�(V��LD�d(��E�F�<�"��	S�Rj�@M��sS�W`9�A�G��oZ�>�
MEk=���zcy���EE=	�Z=I��~'��kk���Y��m��Ѐmx�l���,����I��*;�V-�Y0���:� �̳aH�`xr1���Ϸ���n ��%�:?:ر��Ã�MMv�,���[d�$0v���~���;��ݧI�D#
��f�ʘ���`�ũ�5X�3�  d�	�Lu��aӐI��4S���zNO�+����GCb/6�u;��]��e��4�q�&�1;�|�=��g���·'�E�=��a�eB�2/�-M>�4��%���b��K'�=#GS������gt�Ё\>�2�(�L�+��>�"�P�1?��M�"�,�[��+`i?��URF�%�`8X��gT���ޫ�I4'
VKm���������Ag�Ҡ0ᶀΫ�P3�Ow�ͤ�ɟ�G�(O%��?$���o`k��_H+׀�u�|�~&�N���ܜ�^E�vMo�&��;�?-�Z�9����E��IwL�A/iñ^r����j	����c�K����+M}���4%:|n�;��Qdför���
���,���1{~�ka-'��tY����������Gyڅ^P��l1���n���O��)��3�=� #�C,:�
�<\#B<
���O��g��˷�wA�~x
��*��s ���jg���q���1����8�l�cw����n$
gx�u��31͢7b
��&��~,��v���p�u���I ���j"��O�C�Q���!�2��]�pf�'��i&����.�r�y�Xp���2�;7��@�Kl�5Չn^|v��m�c���<`.��HI��)jH0^�˓`���A"�r��-��L�5D�ڥ�G�Ɛo#�)�c^{x��|0B:qqy<8(�3��m�ٻ�W1}��Ѯ�2xc�{s��8���šn�)�d�zS���V-]�Av�<"���\9��ox|,>F����wq7��6����sǁ��p��tbRk�<\�5y��6f�x�2K5��F�]�O V	(��]���t#�٨X�;(Ǿ��1����܅l('m��y�f�6R�MȠ�9�����%~:�OΎ�蔜�*4�{+l�8��m!��u����sE�C�P�Ds;����"�y2I�tb]�ŭ�u��ςP���x^�v����>�/�T�n��tjUla��6ݽ_�ܡ��
SI
��+��C�F�T%XŘ�S �+��c��t�t;>p"�e�K81�m���v��c���W��j<�r��`��+u�����J�kVT��kc�-@��f4��W��i��ʼ\*h���Um�ɧъ��V��^d��P�-x^���L$ �2�3�v�8�Q���@�!����Bu���͸��vq����ɸ�px��v�=�6��nmTgՙ�8QC�� N���(Kiŝ�hd�Ȋ�w�U�3]�FY�4 a���}	EܵG,ᙥ4N���PB��x��i�ʥ<p�h��%]�:v�rz 7,�s�o�o����7���x�UDmH"~ຳI�ɭ$���ۮy��m��鬆���lv�;��'�C�y=L��j������0*�n',I?SY��@=n�a���P�'^�v��$�a�t�2�U8���S�]����a���Q#�����RM,2�y`�錩A(��L�e���
�^U_x�M��6�1�����A[�]�I���=1]�<�z�.u�ú�L���X��{����W���v�"��@��}أ�����ج����o�;Me�b��`��S򖣥�2�NF�^��ˌyq�o7=n�Yys;YJ%K�.�l�M����а?Z��g���}�����z�����z������p��o� P  