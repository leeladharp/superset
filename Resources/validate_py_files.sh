#!/bin/bash
find . -iname "*.py" | xargs pylint  
find . -iname "*.py" | xargs flake8
