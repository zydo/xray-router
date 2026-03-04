#!/bin/sh
# Logging functions

log_info() {
	echo "[ INFO ] $*"
}

log_success() {
	echo "[  OK  ] $*"
}

log_error() {
	echo "[ FAIL ] $*"
}

log_warn() {
	echo "[ WARN ] $*"
}
