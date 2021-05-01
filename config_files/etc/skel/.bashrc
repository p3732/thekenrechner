#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source .profile

alias show-temperature="cat /sys/devices/virtual/thermal/thermal_zone0/temp"
