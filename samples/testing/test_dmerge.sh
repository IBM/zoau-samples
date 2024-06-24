#!/bin/env bash
# 
# Run a few tests on dmerge to make sure it works
#

DSType()
{
	local DS="$1"
	local JUST_DS=${DS%%(*}
	if [ "${JUST_DS}" = "${DS}" ]; then
		echo "seq"
	else 
		echo "library"
	fi
}

Setup()
{
	local DS_INA="$1"
	local DS_INB="$2"
	local DS_MERGE="$3"
	local DS_EXPECTED="$4"
	local RECFM="$5"
	local LRECL="$6"

	local JUST_DS_INA=${DS_INA%%(*}
	local JUST_DS_INB=${DS_INB%%(*}
	local JUST_DS_MERGE=${DS_MERGE%%(*}
	local JUST_DS_EXPECTED=${DS_EXPECTED%%(*}

	DS_INA_TYPE=$( DSType "${DS_INA}" )
	DS_INB_TYPE=$( DSType "${DS_INB}" )
	DS_MERGE_TYPE=$( DSType "${DS_MERGE}" )
	DS_EXPECTED_TYPE=$( DSType "${DS_EXPECTED}" )

	drm -f "${JUST_DS_INA}" "${JUST_DS_INB}" "${JUST_DS_MERGE}" "${JUST_DS_EXPECTED}"

	dtouch -t"${DS_INA_TYPE}" -l"${LRECL}" -r"${RECFM}" "${JUST_DS_INA}"
	rca=$?
	dtouch -t"${DS_INB_TYPE}" -l"${LRECL}" -r"${RECFM}" "${JUST_DS_INB}"
	rcb=$?
	dtouch -t"${DS_MERGE_TYPE}" -l"${LRECL}" -r"${RECFM}" "${JUST_DS_MERGE}"
	rcmerge=$?
	dtouch -t"${DS_EXPECTED_TYPE}" -l"${LRECL}" -r"${RECFM}" "${JUST_DS_EXPECTED}"
	rcexpected=$?

	decho "Chang      Joe       278 232 6043
DeBeer     Jo        348 132 6023
Doe        Jack      878 222 5043
White      Belinda   178 222 5043" "${DS_INA}"
	rcad=$?

	decho "Doe        Jane      878 222 5043
Smith      Joe       778 232 6043
Smyth      Jo        748 132 6023" "${DS_INB}"
	rcbd=$?

	return $((rc1+rcb+rcmerge+rcad+rcbd))
}

Check()
{
	local DS_INA="$1"
	local DS_INB="$2"
	local DS_MERGE="$3"
	local DS_EXPECTED="$4"
	shift 4
	local DS_KEYS=$*

	if ! ${DMERGE} ${DS_KEYS} "${DS_INA}" "${DS_INB}" "${DS_MERGE}" ; then
		return 4
	fi

	if ! ddiff "${DS_MERGE}" "${DS_EXPECTED}" ; then
		return 8
	fi
}

ME=$(basename $0)
MYDIR="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd -P)"

DMERGE_DIR="${MYDIR}/../"
DMERGE_DIR="$(cd "${DMERGE_DIR}" > /dev/null 2>&1 && pwd -P)"
DMERGE="dmerge.sh"

export PATH="${DMERGE_DIR}:${PATH}"
if ! $( "${DMERGE}" --help >/dev/null ) ; then
	echo "${DMERGE} --help should run with rc 0"
	exit 4
fi

DS_INA="$(hlq).DMERGE.IN.A"
DS_INB="$(hlq).DMERGE.IN.B"
DS_MERGE="$(hlq).DMERGE.MERGE"
DS_EXPECTED="$(hlq).DMERGE.EXPECTED"

ASC_EXPECTED="Chang      Joe       278 232 6043
DeBeer     Jo        348 132 6023
Doe        Jack      878 222 5043
Doe        Jane      878 222 5043
Smith      Joe       778 232 6043
Smyth      Jo        748 132 6023
White      Belinda   178 222 5043"

ASC_DSC_EXPECTED="Chang      Joe       278 232 6043
DeBeer     Jo        348 132 6023
Doe        Jane      878 222 5043
Doe        Jack      878 222 5043
Smith      Joe       778 232 6043
Smyth      Jo        748 132 6023
White      Belinda   178 222 5043"

#
# Test1: allocate 3 datasets as FB 80 and sort by field 1,9 ascending
# 

if ! Setup "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "FB" "80" ; then
	echo "Test 1 Setup failed" >&2
	exit 4
fi

decho "${ASC_EXPECTED}" "${DS_EXPECTED}"

if ! Check "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "-K 1,9,CH,A" ; then
	echo "Test 1 Check failed" >&2
	exit 4
fi

#
# Test2: allocate 3 PDSs as FB 80 and sort by field 1,9 ascending
# 
if ! Setup "${DS_INA}(HW)" "${DS_INB}(HW)" "${DS_MERGE}(HW)" "${DS_EXPECTED}" "FB" "80" ; then
	echo "Test 2 Setup failed" >&2
	exit 4
fi

decho "${ASC_EXPECTED}" "${DS_EXPECTED}"

if ! Check "${DS_INA}(HW)" "${DS_INB}(HW)" "${DS_MERGE}(HW)" "${DS_EXPECTED}" "-K 1,9,CH,A" ; then
	echo "Test 2 Check failed" >&2
	exit 4
fi

#
# Test3: allocate 3 datasets as FB 80 and sort by field 1,9 ascending and then 10,8 descending
# 

if ! Setup "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "FB" "80" ; then
	echo "Test 3 Setup failed" >&2
	exit 4
fi

decho "${ASC_DSC_EXPECTED}" "${DS_EXPECTED}"

if ! Check "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "-K 1,9,CH,A" "-K10,8,CH,D" ; then
	echo "Test 3 Check failed" >&2
	exit 4
fi

#
# Test4: allocate 3 datasets as FB 80 and sort by field 1,9 ascending and then 10 to end ascending
# 

if ! Setup "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "FB" "80" ; then
	echo "Test 4 Setup failed" >&2
	exit 4
fi

decho "${ASC_EXPECTED}" "${DS_EXPECTED}"

if ! Check "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "-K 1,9,CH,A" "-K10" ; then
	echo "Test 4 Check failed" >&2
	exit 4
fi

#
# Test5: allocate 3 datasets as VB 80 and sort by field 1,9 ascending and then 10 to known end ascending
# 

if ! Setup "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "VB" "80" ; then
	echo "Test 5 Setup failed" >&2
	exit 4
fi

decho "${ASC_EXPECTED}" "${DS_EXPECTED}"

if ! Check "${DS_INA}" "${DS_INB}" "${DS_MERGE}" "${DS_EXPECTED}" "-K 1,9,CH,A" "-K10,23" ; then
	echo "Test 5 Check failed" >&2
	exit 4
fi
