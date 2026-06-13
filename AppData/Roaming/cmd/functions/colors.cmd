@echo off
:: Color utility functions

:: ============ Color test ============
doskey colors=echo. $T echo 0 = Black     8 = Gray $T echo 1 = Blue      9 = Light Blue $T echo 2 = Green     A = Light Green $T echo 3 = Aqua      B = Light Aqua $T echo 4 = Red       C = Light Red $T echo 5 = Purple    D = Light Purple $T echo 6 = Yellow    E = Light Yellow $T echo 7 = White     F = Bright White

:: ============ Set terminal color ============
:: Usage: setcolor 0A (black background, green text)
doskey setcolor=color $*