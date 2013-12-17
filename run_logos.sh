#!/bin/bash

./logos/bin/logos.pl main.xm | sed -e '/logos\.h/d' > main.mm
