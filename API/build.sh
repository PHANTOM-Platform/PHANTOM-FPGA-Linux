#!/bin/sh

sphinx-build -M latexpdf . _build

cp _build/latex/PHANTOM.pdf ./phantom_software_ip_api.pdf