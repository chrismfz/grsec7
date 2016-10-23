#!/bin/bash
#
# Original author unknown.
#

if [ ! -x `which rpmbuild` ];then echo "ERROR: rpmbuild required."; exit 1; fi

ARCH=''
DESCRIPTION=''
GROUP='Applications'
LICENSE='GPLv2'
NAME=''
PRINTSPEC=false
RELEASE=$(date +%Y.%m.%d+%S)
SUMMARY=''
TARFILE=''
TARGET=''
URL=''
VERSION='1'
REQUIRES=''

function usage {
    echo "Usage: $0 [option1 ... optionN] <TARFILE.tar>"
    echo "  Required flags:"
    echo "      --target       | -t <target>  The directory to extract the files into during installation."
    echo "                              Must be an absolute path"
    echo "  Optional flags:"
    echo "      --arch         | -a <arch>        The build architecture of the package."
    echo "                                        Default: autodetect"
    echo "      --descr        | -d <description> A longer description of the package. Default: <summary>"
    echo "      --group        | -g <group>       The group this package belongs to. Default: '$GROUP'"
    echo "      --license      | -l <license>     The name of the lincense that governs use of this"
    echo "                                        software. Default: '$LICENSE'"
    echo "      --name         | -n <name>        The name of the package."
    echo "                                        Default: '<TARFILE>' (without the '.tar')"
    echo "      --release      | -r <release>     The release number. Default: '$RELEASE'"
    echo "      --requires     | -rq <requires>   Other package requirements"
    echo "      --provides     | -prov <provides> This package provides tag(s)"
    echo "      --summary      | -s <summary>     A description of the package."
    echo "                                        Default: 'Provides <NAME>'"
    echo "      --url          | -u <url>         A URI where more information on the package can be"
    echo "                                        found. Default: none"
    echo
    echo "      --postinstall  | -po <file>       Use <file> as a post install script."
    echo "      --preinstall   | -pr <file>       Use <file> as a pre install script."
    echo "      --postuninstall| -poun <file>     Use <file> as a post uninstall script."
    echo "      --preuninstall | -prun <file>     Use <file> as a pre uninstall script."
    echo
    echo "      --version      | -v <version>     The version number. Default: '$VERSION'"
    echo "      --nocompress   | -nc              Stop automatic compression. Fixes bug with man.1 pages."
    echo "  Misc:"
    echo "      --help Show this message"
    echo "      --print        | -p               Instead building the RPM, print the .spec file"
}

function spec {
    # this is a hack to prevent rpmbuild from compressing .1 man pages and breaking the build
    if [ -n "$NOCOMPRESS" ]; then
     echo "%global __os_install_post %{nil}"
    fi
    echo "Name: $NAME"
    echo "Summary: $SUMMARY"
    echo "Version: $VERSION"
    echo "Group: $GROUP"
    echo "License: $LICENSE"
    echo "Release: $RELEASE"
    echo "Prefix: $TARGET"
    #echo "BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-$(whoami)-%(%{__id_u} -n)"
    echo "BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}"
    if [ -n "$PROVIDES" ]; then
        echo "Provides: $PROVIDES"
    fi
    if [ -n "$ARCH" ]; then
        echo "BuildArch: $ARCH"
    elif [ -n "$URL" ]; then
        echo "URL: $URL"
    fi
    if [ ! -z "$REQUIRES" ]; then
     echo "Requires: $REQUIRES"
     echo
    fi
    echo "%description"
    echo $DESCRIPTION
    echo
    echo "%build"
    echo "cp $TARFILE %{_builddir}/archive.tar"
    echo 
    if [ -f "$PREINSTALL" ];then
     echo "%pre"
     cat $PREINSTALL
     echo
    fi
    if [ -f "$PREUNINSTALL" ];then
     echo "%preun"
     cat $PREUNINSTALL
     echo
    fi
    echo "%install"
    echo "mkdir -p \$RPM_BUILD_ROOT$TARGET"
    echo "mv %{_builddir}/archive.tar \$RPM_BUILD_ROOT/archive.tar"
    echo "cd \$RPM_BUILD_ROOT$TARGET"
    echo "tar -xf \$RPM_BUILD_ROOT/archive.tar"
    echo "rm \$RPM_BUILD_ROOT/archive.tar"
    echo 
    if [ -f "$POSTINSTALL" ];then
     echo "%post"
     cat $POSTINSTALL
     echo
    fi
    if [ -f "$POSTUNINSTALL" ];then
     echo "%postun"
     cat $POSTUNINSTALL
     echo
    fi
    echo "%clean"
    echo "rm -fr \$RPM_BUILD_ROOT"
    echo
    echo "%files"
    #echo "/"

# hack to fix directories with spaces bug and to fix duplicate file bug by adding dir's
tar -tf $TARFILE > /tmp/tarlist.$$
while read -r line; do

 # hack to omit directories from the list to stop a duplicate file warning
 clean=$(echo "$TARGET/$line" | sed -e 's/\/\//\//g' | sed -e 's/%$//g')
 if [ "$(echo ${clean: -1})" != "/" ];then
        # the last character in the string isn't an / so it's not a dir, so we echo it into the spec
        echo \"$clean\";
 fi

done < /tmp/tarlist.$$
rm -f /tmp/tarlist.$$

}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        -n|--name)
            NAME=$2
            shift
            ;;
        -s|--summary)
            SUMMARY=$2
            shift
            ;;
        -rq|--requires)
            REQUIRES=$2
            shift
            ;;
        -t|--target)
            TARGET=$2
            shift
            if [ "${TARGET:0:1}" != '/' ]; then
                usage
                echo "ERROR: target '$TARGET' is not an absolute path"
                exit 1
            fi
            ;;
        -v|--version)
            VERSION=$2
            shift
            ;;
        -a|--arch)
            ARCH=$2
            shift
            ;;
        -d|--descr)
            DESCRIPTION=$2
            shift
            ;;
        -g|--group)
            GROUP=$2
            shift
            ;;
        -l|--license)
            LICENSE=$2
            shift
            ;;
        -r|--release)
            RELEASE=$2
            shift
            ;;
        -u|--url)
            URL=$2
            shift
            ;;
        -prov|--provides)
            PROVIDES=$2
            shift
            ;;
        -pr|--preinstall)
            PREINSTALL=$2
            shift
            ;;
        -po|--postinstall)
            POSTINSTALL=$2
            shift
            ;;
        -prun|--preuninstall)
            PREUNINSTALL=$2
            shift
            ;;
        -poun|--postuninstall)
            POSTUNINSTALL=$2
            shift
            ;;
        -p|--print)
            PRINTSPEC=true
            ;;
        -nc|--nocompress)
            NOCOMPRESS=true
            ;;
        -*)
            usage
            echo "ERROR: '$1' is not a valid flag"
            exit 1
            ;;
        *)
            if [ -n "$TARFILE" ]; then
                usage
                echo "ERROR: Only one TARFILE can be specified"
                exit 1
            fi
            # Normalize path
            TARFILE=$(readlink -m $1)

            # Do we have a tar file?
            if [ "${TARFILE##*.}" != 'tar' ]; then
                echo "ERROR: '$TARFILE' is not a tar file"
                exit 1
            fi

            # Does the file exist?
            if [ ! -f "$TARFILE" ];then
                echo "ERROR: '$TARFILE' does not exist"
                exit 1
            fi

            ;;
    esac
    shift
done

# Check for errors
if [ -z "$TARGET" ]; then
    usage
    echo "ERROR: --target | -t <target> is a required flag"
    exit 1
elif [ -z "$TARFILE" ]; then
    usage
    echo "ERROR: <TARFILE.tar> is a required argument"
    exit 1
fi

# Auto-populate optional fields
if [ -z "$NAME" ]; then
    NAME=$(basename $TARFILE)
    NAME=${NAME%.*}
fi
if [ -z "$SUMMARY" ]; then            
    SUMMARY="Provides $NAME."
fi
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION=$SUMMARY
fi

if $PRINTSPEC; then
    # Just print out the spec file
    spec
else
    # Build the RPM

        mkdir -p /tmp/$NAME-$VERSION-$RELEASE/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
        if [ $? -ne 0 ];then
        #error
                echo "ERROR: unable to mkdir -p /tmp/$NAME-$VERSION-$RELEASE/{BUILD,RPMS,SOURCES,SPECS,SRPMS}"
                exit 1
        fi    
        echo "%_topdir /tmp/$NAME-$VERSION-$RELEASE
        %_signature gpg
        %_gpg_name PLACEHOLDER" > ~/.rpmmacros

    spec > /tmp/tar2rpm-$$.spec
    rpmbuild -bb /tmp/tar2rpm-$$.spec > /tmp/tar2rpm-$$.log
    #rpmbuild -bb /tmp/tar2rpm-$$.spec > /tmp/tar2rpm-$$.log 2>&1
    cat /tmp/tar2rpm-$$.log | grep -i "Wrote:.*$NAME-$VERSION-$RELEASE.*rpm"
    if [ $? -gt 0 ]; then
        echo "ERROR: RPM build failed. Check log: /tmp/tar2rpm-$$.log Spec file: /tmp/tar2rpm-$$.spec"
        exit 1
    fi
    rm /tmp/tar2rpm-$$.spec
    rm /tmp/tar2rpm-$$.log
fi
exit 0
