#!/bin/sh
# Download and version management functions

get_latest_xray_version() {
	curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r '.tag_name'
}

normalize_proxy_url() {
	_proxy="$1"

	# Remove trailing slashes
	_proxy=$(echo "${_proxy}" | sed 's:/*$::')

	# Add https:// prefix if missing
	case "${_proxy}" in
	http://* | https://*)
		# Already has protocol, use as-is
		;;
	*)
		# Add https:// prefix
		_proxy="https://${_proxy}"
		;;
	esac

	echo "${_proxy}"
}

download_from_source() {
	_output_file="$1"
	_original_url="$2"
	_use_proxy="$3"

	if [ -z "${_use_proxy}" ]; then
		# Direct download from GitHub
		log_info "Downloading directly from GitHub..."
		_download_url="${_original_url}"
	else
		# Use proxy
		_proxy=$(normalize_proxy_url "${_use_proxy}")
		log_info "Downloading via proxy: ${_proxy}"
		_download_url="${_proxy}/${_original_url}"
	fi

	if wget --timeout=30 -O "${_output_file}" "${_download_url}" 2>&1; then
		if [ -f "${_output_file}" ] && [ -s "${_output_file}" ]; then
			log_success "Download successful"
			return 0
		fi
	fi

	log_error "Download failed"
	return 1
}
