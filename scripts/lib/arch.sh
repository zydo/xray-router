#!/bin/sh
# Architecture detection for Xray-core

detect_xray_arch() {
	local machine
	machine=$(uname -m)

	case "${machine}" in
	'i386' | 'i686')
		echo '32'
		;;
	'amd64' | 'x86_64')
		echo '64'
		;;
	'armv5tel')
		echo 'arm32-v5'
		;;
	'armv6l')
		# Check if VFP is supported, otherwise fallback to v5
		if grep -q 'vfp' /proc/cpuinfo 2>/dev/null; then
			echo 'arm32-v6'
		else
			echo 'arm32-v5'
		fi
		;;
	'armv7l' | 'armv7')
		# Check if VFP is supported, otherwise fallback to v5
		if grep -q 'vfp' /proc/cpuinfo 2>/dev/null; then
			echo 'arm32-v7a'
		else
			echo 'arm32-v5'
		fi
		;;
	'armv8' | 'aarch64')
		echo 'arm64-v8a'
		;;
	'mips')
		echo 'mips32'
		;;
	'mipsle')
		echo 'mips32le'
		;;
	'mips64')
		# Check if little endian
		if command -v lscpu >/dev/null 2>&1 && lscpu 2>/dev/null | grep -q "Little Endian"; then
			echo 'mips64le'
		else
			echo 'mips64'
		fi
		;;
	'mips64le')
		echo 'mips64le'
		;;
	*)
		# Unknown architecture
		echo ''
		return 1
		;;
	esac

	return 0
}
