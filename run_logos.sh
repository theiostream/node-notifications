#!/bin/bash

logos.pl main.xm | sed -e '/logos\.h/d' > main.mm
