#!/bin/bash
#
# Make a release of a given contrib
#
# Usage:
#   scripts/make_release.sh <ContribName>

# make sure we have an argument and it exists
contrib=$1
if [ -z $contrib ]; then
    echo "Usage:"
    echo "  register-new-contrib.sh <ContribName>"
    echo "A contrib name has to be specified"
    exit 1
fi

if [ ! -d $contrib ]; then
    echo "  $contrib does not exist"
    exit 1
fi


#------------------------------------------------------------------------
# make sure all the required files are present
cd $contrib
mandatory_files="VERSION"
missing_mandatory=""
missing_mandatory_on_svn=""
for fname in $mandatory_files; do
    if [[ ! -e ${fname} ]]; then
	missing_mandatory="${fname} ${missing_mandatory}"
    fi
    if [[ ! -z "`svn stat ${fname}`" ]]; then
	missing_mandatory_on_svn="${fname} ${missing_mandatory_on_svn}"
    fi
done
if [[ "x${missing_mandatory}" != "x" ]]; then
    echo "The following mandatory file(s) are miss1ng: ${missing_mandatory}"
    cd ..
    exit 1
fi
if [[ "x${missing_mandatory_on_svn}" != "x" ]]; then
    echo "The following mandatory file(s) are not committed: ${missing_mandatory_on_svn}"
    cd ..
    exit 1
fi
cd ..

#------------------------------------------------------------------------
# make sure everything is committed
check_pending_modifications $contrib || {
    echo "There are some pending modifications that need to be committed before the release"
    exit 1
}

#------------------------------------------------------------------------
# decide the version number
cd $contrib
version=`cat VERSION`

#------------------------------------------------------------------------
# ask confirmation that we can proceed with the release

. `dirname $0`/internal/common.sh

get_yesno_answer "Releasing version $version of $contrib?" || {
    echo "Checking if there is not an already-existing tag with the same name:"
    if svn ls ${svn_read}/contribs/${contrib}/tags | grep -q "$version/" ; then
	echo "Failed. Release aborted!"
	cd ..
	exit 1
    fi
    echo "Ok... proceeding with the release"
    
    # do the release
    if ! svn copy -m "Released version $version of $contrib" . ${svn_write}/contribs/${contrib}/tags/${version} ; then
	echo "Release failed"
	cd ..
	exit 1
    fi
    echo "Release done"
}

cd ..
