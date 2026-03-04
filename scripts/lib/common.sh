#!/bin/sh
# Common utility functions

check_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		return 1
	fi
	return 0
}
