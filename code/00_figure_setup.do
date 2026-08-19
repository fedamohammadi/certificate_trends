*===============================================================
* 00_figure_setup.do
* Shared figure settings. Run at the top of every fig_*.do file.
*===============================================================

* Fixed color palette, assigned by position
global c1 "31 119 180"    // blue
global c2 "214 39 40"     // red
global c3 "44 160 44"     // green
global c4 "255 127 14"    // orange
global c5 "148 103 189"   // purple
global c6 "140 86 75"     // brown
global c7 "127 127 127"   // gray

* Standard options applied to every figure
global gopts ///
    graphregion(color(white)) plotregion(color(white)) ///
    xsize(7) ysize(4.2) ///
    ytitle(, size(small)) xtitle(, size(small)) ///
    xlabel(, labsize(small)) ylabel(, angle(horizontal) labsize(small)) ///
    legend(rows(1) position(6) size(small) region(lstyle(none)))

global expopts "replace width(2100)"